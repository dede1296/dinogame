// Wild encounter presentation. The full battle system comes in step 2; for now the
// wild dino appears, cries, gets registered as seen, and the player can flee.

import * as Phaser from "phaser";
import { hud } from "../ui/hud.js";
import { state, save } from "../state/game.js";
import { dinoTexture, anchors } from "../engine/textures.js";
import { speciesIndex } from "../story/scripts.js";
import { HYBRID_RATE } from "../data/encounters.js";
import { playCry } from "../../../src/audio/cry.js";

function pickWeighted(table) {
  const total = table.reduce((s, [, w]) => s + w, 0);
  let r = Math.random() * total;
  for (const row of table) { r -= row[1]; if (r <= 0) return row; }
  return table[0];
}

function rollWild(table) {
  const [species, , [lo, hi]] = pickWeighted(table);
  const idx = speciesIndex(species);
  const level = lo + Math.floor(Math.random() * (hi - lo + 1));
  const build = { head: idx, teeth: idx, frontLegs: idx, backLegs: idx, back: idx, tail: idx, color: idx };
  let hybrid = false;
  if (Math.random() < HYBRID_RATE) {
    hybrid = true;
    for (const k of ["teeth", "back", "tail", "color"]) {
      if (Math.random() < 0.6) build[k] = speciesIndex(pickWeighted(table)[0]);
    }
  }
  return { species, level, build, hybrid };
}

export class EncounterScene extends Phaser.Scene {
  constructor() {
    super("Encounter");
  }

  init(data) {
    this.data_ = data;
  }

  async create() {
    const { width: W, height: H } = this.scale;
    const wild = rollWild(this.data_.table);
    this.drawArena(W, H);

    const size = Math.min(W, H) * 0.34;
    const [wildKey, mineKey] = await Promise.all([
      dinoTexture(this, wild.build, Math.round(size)),
      state.party[0] ? dinoTexture(this, state.party[0].build, Math.round(size * 1.1)) : null,
    ]);

    // Wild dino on the far platform, facing the player.
    const ex = W * 0.7, ey = H * 0.38;
    const enemy = this.add.image(W + size, ey, wildKey).setOrigin(anchors[wildKey].x, anchors[wildKey].y).setFlipX(true);
    if (wild.hybrid) enemy.setTint(0xfff2d0);
    this.tweens.add({ targets: enemy, x: ex, duration: 700, ease: "Back.easeOut" });
    this.tweens.add({ targets: enemy, scaleY: 1.02, duration: 1200, yoyo: true, repeat: -1, ease: "Sine.easeInOut", delay: 700 });

    // Player's dino, seen closer, on the near platform.
    if (mineKey) {
      const mine = this.add.image(-size, H * 0.66, mineKey).setOrigin(anchors[mineKey].x, anchors[mineKey].y);
      this.tweens.add({ targets: mine, x: W * 0.28, duration: 700, ease: "Back.easeOut", delay: 200 });
    }

    this.cameras.main.fadeIn(250, 0, 0, 0);
    this.time.delayedCall(650, () => { try { playCry(wild.build); } catch {} });

    state.seen = state.seen || {};
    state.seen[wild.species] = true;
    save();

    await new Promise((r) => this.time.delayedCall(800, r));
    await hud.say(null, wild.hybrid
      ? `Incroyable ! Un ${wild.species} HYBRIDE sauvage (Niv. ${wild.level}) surgit des herbes !`
      : `Un ${wild.species} sauvage (Niv. ${wild.level}) surgit des herbes !`);
    const c = await hud.choose(["Combattre", "Fuir"]);
    if (c === 0) await hud.say(null, "Les combats arrivent très bientôt ! Pour l'instant, vous vous observez… puis il s'enfuit.");
    else await hud.say(null, "Tu t'éloignes prudemment.");

    this.cameras.main.fadeOut(300, 0, 0, 0);
    this.cameras.main.once("camerafadeoutcomplete", () => {
      this.scene.stop();
      const world = this.scene.get("World");
      this.scene.resume("World");
      world.resumeFromEncounter();
    });
  }

  drawArena(W, H) {
    const g = this.add.graphics();
    // Sky and distant hills.
    g.fillGradientStyle(0x8fcbe8, 0x8fcbe8, 0xd8eed0, 0xd8eed0, 1);
    g.fillRect(0, 0, W, H * 0.55);
    g.fillStyle(0x7fae6a, 1);
    for (let i = 0; i < 6; i++) g.fillEllipse((i + 0.3) * (W / 5), H * 0.5, W * 0.4, H * 0.18);
    g.fillStyle(0x5f9139, 1);
    g.fillRect(0, H * 0.5, W, H * 0.5);
    g.fillGradientStyle(0x6a9c40, 0x6a9c40, 0x3f6b22, 0x3f6b22, 1);
    g.fillRect(0, H * 0.55, W, H * 0.45);
    // Platforms.
    g.fillStyle(0x000000, 0.18);
    g.fillEllipse(W * 0.7, H * 0.39, W * 0.42, H * 0.07);
    g.fillEllipse(W * 0.28, H * 0.67, W * 0.5, H * 0.08);
    g.fillStyle(0x88b653, 1);
    g.fillEllipse(W * 0.7, H * 0.38, W * 0.4, H * 0.06);
    g.fillEllipse(W * 0.28, H * 0.66, W * 0.48, H * 0.07);
    // Grass tufts.
    g.lineStyle(2, 0x3f6b22, 1);
    for (let i = 0; i < 40; i++) {
      const x = Math.random() * W, y = H * 0.56 + Math.random() * H * 0.44;
      g.lineBetween(x, y, x - 3, y - 8);
      g.lineBetween(x + 3, y, x + 5, y - 9);
    }
  }
}
