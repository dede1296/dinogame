// Battle presentation: plays back the engine's events with animations.

import * as Phaser from "phaser";
import { Battle } from "../battle/engine.js";
import { MOVES, TYPE_COLORS } from "../battle/moves.js";
import { statsOf } from "../battle/dino.js";
import { BattleHud } from "../ui/battleHud.js";
import { hud } from "../ui/hud.js";
import { state, save } from "../state/game.js";
import { dinoTexture, anchors, propTexture } from "../engine/textures.js";
import { paintArena, paintPlatform, paintSpark } from "../art/battleArt.js";
import { playCry } from "../../../src/audio/cry.js";
import { playSfx } from "../../../src/audio/sfx.js";
import { play } from "../audio/sounds.js";

const hex = (c) => parseInt(c.replace("#", ""), 16);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Solid white flash on hit (Phaser 4 tint modes).
function flashWhite(sprite, on) {
  if (on) sprite.setTint(0xffffff).setTintMode(Phaser.TintModes.FILL);
  else sprite.clearTint().setTintMode(Phaser.TintModes.MULTIPLY);
}

export class BattleScene extends Phaser.Scene {
  constructor() {
    super("Battle");
  }

  init(data) {
    this.opts = data;
  }

  async create() {
    const W = this.scale.width, H = this.scale.height;
    this.W = W; this.H = H;
    hud.root.classList.add("in-battle");

    // Backdrop, platforms and particle texture.
    const zone = this.opts.zone || "plaines";
    const arenaKey = `arena-${zone}-${W}x${H}`;
    if (!this.textures.exists(arenaKey)) this.textures.addCanvas(arenaKey, paintArena(W, H, zone));
    this.add.image(0, 0, arenaKey).setOrigin(0);
    if (!this.textures.exists("spark")) this.textures.addCanvas("spark", paintSpark());

    // Positions: foe up-right, player closer, bottom-left (above the command panel).
    const unit = Math.min(W, H * 0.62);
    this.pos = {
      foe: { x: W * 0.68, y: H * 0.38, w: unit * 0.55, h: H * 0.2 },
      player: { x: W * 0.32, y: H * 0.585, w: unit * 0.66, h: H * 0.24 },
    };
    for (const side of ["foe", "player"]) {
      const p = this.pos[side];
      const plat = paintPlatform(Math.round(p.w * 1.1), zone);
      const key = `plat-${zone}-${side}-${W}x${H}`;
      if (!this.textures.exists(key)) this.textures.addCanvas(key, plat.canvas);
      this.add.image(p.x, p.y, key).setOrigin(0.5, plat.footY / plat.canvas.height);
    }

    this.ui = new BattleHud();
    this.battle = new Battle({
      player: { team: state.party },
      foe: this.opts.trainer ? { team: this.opts.trainer.team, trainer: this.opts.trainer } : { team: [this.opts.wild] },
      bag: state.bag,
    });
    this.sprites = {};
    this.cameras.main.fadeIn(300, 0, 0, 0);
    try {
      await this.run();
    } catch (e) {
      console.error(e);
      this.leave("run");
    }
  }

  // ---------------------------------------------------------------- flow
  async run() {
    const b = this.battle;
    await this.enter("foe", true);
    await this.ui.message(b.wild ? `Un ${b.active("foe").speciesName} sauvage (Niv. ${b.active("foe").level}) surgit !`
      : b.trainer.boss ? (b.trainer.intro || `${b.active("foe").nickname} se dresse devant toi !`) : `${b.trainer.name} veut se battre !`);
    await this.enter("player");
    await this.ui.message(`Vas-y, ${b.active("player").nickname} !`, { hold: 500 });

    while (!b.over) {
      let action = await this.ui.chooseAction(b.active("player"), state.bag, b.wild);
      if (action.type === "team") {
        const i = await this.ui.chooseDino(b.sides.player.team, b.sides.player.active);
        if (i < 0) continue;
        action = { type: "switch", index: i };
      }
      if (action.type === "item" && action.item === "collier") this.pendingThrow = true;
      await this.play(b.turn(action));
      if (!b.over && this.needSwitch) {
        this.needSwitch = false;
        const i = await this.ui.chooseDino(b.sides.player.team, b.sides.player.active, { forced: true });
        await this.play(b.replaceFainted(i));
      }
    }
    await this.finishBattle(b.result);
  }

  async play(events) {
    for (const e of events) {
      switch (e.type) {
        case "text": await this.ui.message(e.text); break;
        case "move": {
          await this.ui.message(e.text, { hold: 250 });
          await this.animateMove(e.side, e.move);
          break;
        }
        case "miss":
          playSfx("dodge");
          this.dodge(e.side === "player" ? "foe" : "player");
          await this.ui.message(e.text);
          break;
        case "damage":
          await this.hit(e);
          break;
        case "heal":
          this.healFx(e.side);
          this.ui.setHp(e.side, e.hp, e.maxHp);
          await this.ui.message(e.text);
          break;
        case "status":
          this.ui.updateTags(e.side, this.battle.active(e.side));
          if (e.text) await this.ui.message(e.text);
          break;
        case "stat":
          this.statFx(e.side, e.delta > 0);
          await this.ui.message(e.text);
          break;
        case "faint":
          await this.faint(e.side);
          await this.ui.message(e.text);
          break;
        case "xp": {
          await this.ui.message(e.text, { hold: 300 });
          this.ui.setXp(this.battle.active("player"));
          await sleep(700);
          break;
        }
        case "level":
          this.levelFx();
          this.ui.showCard("player", this.battle.active("player"));
          await this.ui.message(e.text);
          break;
        case "learn": await this.ui.message(e.text); break;
        case "switch":
          if (e.side === "player") {
            await this.ui.message(e.text, { hold: 300 });
            await this.leaveSide("player");
          }
          await this.enter(e.side);
          if (e.side === "foe" && e.text) await this.ui.message(e.text);
          break;
        case "needSwitch": this.needSwitch = true; break;
        case "run":
          await this.ui.message(e.text);
          break;
        case "catch":
          await this.ui.message(e.text, { hold: 200 });
          await this.throwCollar(e.shakes, e.success);
          break;
        case "end": break;
        default: break;
      }
    }
  }

  async finishBattle(result) {
    if (result === "win") {
      playSfx("victory");
      const t = this.battle.trainer;
      await this.ui.message(!t ? "Victoire !" : t.boss ? `Tu as vaincu ${this.battle.active("foe").nickname} !` : `Tu as battu ${t.name} !`);
      if (t?.reward) {
        state.money += t.reward;
        play("coins");
        await this.ui.message(`Tu gagnes ${t.reward} pièces.`);
      }
    } else if (result === "catch") {
      playSfx("victory");
      const d = this.battle.active("foe");
      d.nickname = d.speciesName;
      d.hp = Math.max(1, d.hp);
      if (state.party.length < 4) {
        state.party.push(d);
        await this.ui.message(`${d.speciesName} rejoint ton équipe !`);
      } else {
        state.box = state.box || [];
        state.box.push(d);
        await this.ui.message(`Ton équipe est complète : ${d.speciesName} est envoyé au Cabinet.`);
      }
    } else if (result === "lose") {
      playSfx("defeat");
      await this.ui.message("Tous tes dinos sont K.O. … Tu cours te mettre à l'abri.");
    }
    save();
    await sleep(300);
    this.leave(result);
  }

  leave(result) {
    this.cameras.main.fadeOut(350, 0, 0, 0);
    this.cameras.main.once("camerafadeoutcomplete", () => {
      this.ui?.destroy();
      hud.root.classList.remove("in-battle");
      this.scene.stop();
      this.scene.resume("World");
      this.scene.get("World").resumeFromBattle(result);
    });
  }

  // ---------------------------------------------------------------- sprites
  async enter(side, first = false) {
    const d = this.battle.active(side);
    const p = this.pos[side];
    const key = await dinoTexture(this, d.build, 0, { fit: { w: Math.round(p.w), h: Math.round(p.h) }, customColor: d.tint });
    this.sprites[side]?.destroy();
    const a = anchors[key];
    const startX = side === "foe" ? this.W + p.w : -p.w;
    const s = this.add.image(startX, p.y, key).setOrigin(a.x, a.y).setFlipX(side === "foe");
    s.setDepth(side === "foe" ? 1 : 2);
    this.sprites[side] = s;
    await new Promise((r) => this.tweens.add({ targets: s, x: p.x, duration: 650, ease: "Back.easeOut", onComplete: r }));
    this.breathe(side);
    if (first || side === "foe") { try { playCry(d.build); } catch {} }
    this.ui.showCard(side, d);
    await sleep(side === "foe" && first ? 350 : 150);
  }

  breathe(side) {
    const s = this.sprites[side];
    this.tweens.killTweensOf(s);
    s.setScale(1);
    this.tweens.add({ targets: s, scaleY: 1.025, duration: 1100 + Math.random() * 300, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
  }

  async leaveSide(side) {
    const s = this.sprites[side];
    if (!s) return;
    this.ui.hideCard(side);
    await new Promise((r) => this.tweens.add({ targets: s, x: side === "foe" ? this.W + this.pos[side].w : -this.pos[side].w, duration: 350, onComplete: r }));
  }

  // ---------------------------------------------------------------- effects
  async animateMove(side, moveId) {
    const move = MOVES[moveId];
    const s = this.sprites[side], other = side === "player" ? "foe" : "player", t = this.sprites[other];
    const color = hex(TYPE_COLORS[move.type]);
    const fx = move.fx;
    this.tweens.killTweensOf(s);
    if (["roar", "shield", "heal"].includes(fx)) {
      if (fx === "roar") { try { playCry(this.battle.active(side).build); } catch {} this.rings(s.x, s.y - s.displayHeight * 0.6, color); this.cameras.main.shake(300, 0.006); }
      if (fx === "shield") this.rings(s.x, s.y - s.displayHeight * 0.45, hex("#f2c14e"), true);
      await this.bounce(s);
      this.breathe(side);
      return;
    }
    // Lunge toward the target and back.
    const dx = (t.x - s.x) * 0.45, dy = (t.y - s.y) * 0.35;
    await new Promise((r) => this.tweens.add({ targets: s, x: s.x + dx, y: s.y + dy, scale: 1.08, duration: 180, ease: "Quad.easeIn", onComplete: r }));
    this.impactFx(fx, t, color);
    await new Promise((r) => this.tweens.add({ targets: s, x: this.pos[side].x, y: this.pos[side].y, scale: 1, duration: 260, ease: "Quad.easeOut", onComplete: r }));
    this.breathe(side);
  }

  impactFx(fx, t, color) {
    const cx = t.x, cy = t.y - t.displayHeight * 0.45;
    const g = this.add.graphics().setDepth(10);
    if (fx === "bite") {
      g.lineStyle(6, 0xffffff, 1);
      for (const dir of [-1, 1]) {
        g.beginPath();
        for (let i = 0; i <= 6; i++) g.lineTo(cx - 60 + i * 20, cy + dir * (i % 2 ? 10 : 34));
        g.strokePath();
      }
      this.tweens.add({ targets: g, scaleY: 0.2, alpha: 0, duration: 280, ease: "Quad.easeIn", onComplete: () => g.destroy() });
      g.setPosition(0, 0);
    } else if (fx === "claw") {
      g.lineStyle(5, 0xffffff, 1);
      for (let i = -1; i <= 1; i++) g.lineBetween(cx - 50 + i * 22, cy - 50, cx + 30 + i * 22, cy + 50);
      g.lineStyle(2, 0xe2503a, 1);
      for (let i = -1; i <= 1; i++) g.lineBetween(cx - 48 + i * 22, cy - 46, cx + 28 + i * 22, cy + 46);
      this.tweens.add({ targets: g, alpha: 0, duration: 380, onComplete: () => g.destroy() });
    } else if (fx === "quake") {
      g.destroy();
      this.cameras.main.shake(450, 0.018);
      for (let i = 0; i < 10; i++) this.puff(t.x + (Math.random() - 0.5) * t.displayWidth, t.y, 0xb8a078, 26);
    } else if (fx === "wind" || fx === "wave") {
      g.lineStyle(5, color, 0.9);
      for (let i = 0; i < 3; i++) { g.beginPath(); g.arc(cx, cy, 30 + i * 18, -2.4 + i * 0.3, -0.4 + i * 0.3); g.strokePath(); }
      this.tweens.add({ targets: g, alpha: 0, duration: 450, onComplete: () => g.destroy() });
    } else {
      g.lineStyle(6, 0xfff3c0, 1);
      g.strokeCircle(cx, cy, 20);
      this.tweens.add({ targets: g, scale: 2.2, alpha: 0, duration: 380, onUpdate: () => g.setPosition(cx - cx * g.scale, cy - cy * g.scale), onComplete: () => g.destroy() });
    }
    for (let i = 0; i < 14; i++) this.spark(cx, cy, color);
  }

  async hit(e) {
    const s = this.sprites[e.side];
    const max = e.maxHp;
    if (!e.bleed) {
      playSfx(e.crit ? "crit" : "hit");
      play(e.crit ? "hit_1" : "hit_0", { volume: 0.8, jitter: 0.08 });
      try { navigator.vibrate?.(e.crit ? 120 : 40); } catch {}
      this.cameras.main.shake(e.crit ? 300 : 160, e.crit ? 0.012 : 0.005);
      if (e.crit) this.cameras.main.flash(120, 255, 255, 255);
      for (let i = 0; i < 3; i++) this.time.delayedCall(i * 110, () => flashWhite(s, true));
      for (let i = 0; i < 3; i++) this.time.delayedCall(55 + i * 110, () => flashWhite(s, false));
      const kb = e.side === "foe" ? 18 : -18;
      this.tweens.add({ targets: s, x: s.x + kb, duration: 70, yoyo: true, repeat: 1 });
    } else {
      s.setTint(0xff8080);
      this.time.delayedCall(260, () => s.clearTint());
    }
    this.floatNumber(s.x, s.y - s.displayHeight * 0.75, `-${e.amount}`, e.crit ? "#ffd84a" : e.bleed ? "#e2503a" : "#ffffff", e.crit);
    this.ui.setHp(e.side, e.hp, max);
    await sleep(650);
    if (e.bleed) await this.ui.message(e.text);
  }

  async faint(side) {
    const s = this.sprites[side];
    try { playCry(this.battle.active(side).build); } catch {}
    this.tweens.killTweensOf(s);
    await new Promise((r) => this.tweens.add({ targets: s, y: s.y + 60, alpha: 0, angle: side === "foe" ? 8 : -8, duration: 700, ease: "Quad.easeIn", onComplete: r }));
    this.ui.hideCard(side);
  }

  dodge(side) {
    const s = this.sprites[side];
    this.tweens.add({ targets: s, x: s.x + (side === "foe" ? 40 : -40), alpha: 0.5, duration: 140, yoyo: true });
  }

  healFx(side) {
    const s = this.sprites[side];
    for (let i = 0; i < 18; i++) {
      const p = this.add.image(s.x + (Math.random() - 0.5) * s.displayWidth * 0.7, s.y - Math.random() * s.displayHeight * 0.5, "spark").setTint(0x7ee07a).setScale(0.4).setDepth(10);
      this.tweens.add({ targets: p, y: p.y - 80 - Math.random() * 40, alpha: 0, duration: 900 + Math.random() * 400, delay: i * 30, onComplete: () => p.destroy() });
    }
  }

  statFx(side, up) {
    const s = this.sprites[side];
    for (let i = 0; i < 10; i++) {
      const p = this.add.image(s.x + (Math.random() - 0.5) * s.displayWidth * 0.6, s.y - (up ? 0 : s.displayHeight), "spark").setTint(up ? 0xf2c14e : 0x5a8fd0).setScale(0.5).setDepth(10);
      this.tweens.add({ targets: p, y: p.y + (up ? -1 : 1) * 90, alpha: 0, duration: 700, delay: i * 40, onComplete: () => p.destroy() });
    }
  }

  levelFx() {
    const s = this.sprites.player;
    playSfx("victory");
    s.setTint(0xffe7a0);
    this.time.delayedCall(500, () => s.clearTint());
    this.statFx("player", true);
  }

  bounce(s) {
    return new Promise((r) => this.tweens.add({ targets: s, y: s.y - 18, duration: 140, yoyo: true, repeat: 1, onComplete: r }));
  }

  rings(x, y, color, inward = false) {
    for (let i = 0; i < 3; i++) {
      const g = this.add.graphics().setDepth(10);
      g.lineStyle(4, color, 0.9);
      g.strokeCircle(0, 0, 30);
      g.setPosition(x, y).setScale(inward ? 3 : 0.5);
      this.tweens.add({ targets: g, scale: inward ? 0.6 : 3.2, alpha: 0, duration: 600, delay: i * 140, onComplete: () => g.destroy() });
    }
  }

  spark(x, y, color) {
    const p = this.add.image(x, y, "spark").setTint(color).setScale(0.35 + Math.random() * 0.4).setDepth(11).setBlendMode(Phaser.BlendModes.ADD);
    const a = Math.random() * Math.PI * 2, d = 40 + Math.random() * 80;
    this.tweens.add({ targets: p, x: x + Math.cos(a) * d, y: y + Math.sin(a) * d, alpha: 0, scale: 0.1, duration: 420 + Math.random() * 300, ease: "Quad.easeOut", onComplete: () => p.destroy() });
  }

  puff(x, y, color, size) {
    const p = this.add.image(x, y, "spark").setTint(color).setScale(size / 32).setAlpha(0.8).setDepth(9);
    this.tweens.add({ targets: p, y: y - 30 - Math.random() * 30, scale: (size / 32) * 2.2, alpha: 0, duration: 700, onComplete: () => p.destroy() });
  }

  floatNumber(x, y, text, color, big) {
    const t = this.add.text(x, y, text, {
      fontFamily: "system-ui, sans-serif", fontSize: `${Math.round(this.H * (big ? 0.045 : 0.034))}px`, fontStyle: "900",
      color, stroke: "#1a1208", strokeThickness: 6,
    }).setOrigin(0.5).setDepth(20);
    this.tweens.add({ targets: t, y: y - 60, alpha: 0, duration: 1000, ease: "Quad.easeOut", onComplete: () => t.destroy() });
  }

  async throwCollar(shakes, success) {
    const foe = this.sprites.foe;
    const orbKey = propTexture(this, "orb");
    const orb = this.add.image(this.W * 0.1, this.H * 0.8, orbKey).setScale(2).setDepth(15);
    const tx = foe.x, ty = foe.y - foe.displayHeight * 0.4;
    // Arc throw.
    await new Promise((r) => this.tweens.addCounter({
      from: 0, to: 1, duration: 600,
      onUpdate: (tw) => {
        const k = tw.getValue();
        orb.x = Phaser.Math.Linear(this.W * 0.1, tx, k);
        orb.y = Phaser.Math.Linear(this.H * 0.8, ty, k) - Math.sin(k * Math.PI) * this.H * 0.25;
        orb.angle = k * 720;
      },
      onComplete: r,
    }));
    this.tweens.killTweensOf(foe);
    foe.setTint(0xffc060);
    this.cameras.main.flash(150, 255, 210, 120);
    await new Promise((r) => this.tweens.add({ targets: foe, scale: 0.05, alpha: 0.2, x: tx, y: ty + foe.displayHeight * 0.4, duration: 400, ease: "Quad.easeIn", onComplete: r }));
    foe.setVisible(false);
    // Drop to the ground and wobble.
    await new Promise((r) => this.tweens.add({ targets: orb, y: this.pos.foe.y - 14, duration: 350, ease: "Bounce.easeOut", onComplete: r }));
    for (let i = 0; i < shakes; i++) {
      await sleep(350);
      await new Promise((r) => this.tweens.add({ targets: orb, angle: { from: -25, to: 25 }, duration: 110, yoyo: true, repeat: 1, onComplete: () => { orb.angle = 0; r(); } }));
    }
    await sleep(400);
    if (success) {
      for (let i = 0; i < 24; i++) this.spark(orb.x, orb.y, 0xf2c14e);
      orb.setTint(0xb0a080);
    } else {
      orb.destroy();
      foe.setVisible(true).clearTint();
      for (let i = 0; i < 16; i++) this.spark(tx, ty, 0xffffff);
      await new Promise((r) => this.tweens.add({ targets: foe, scale: 1, alpha: 1, x: this.pos.foe.x, y: this.pos.foe.y, duration: 300, ease: "Back.easeOut", onComplete: r }));
      this.breathe("foe");
    }
  }
}
