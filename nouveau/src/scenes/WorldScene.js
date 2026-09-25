// The explorable world: grid movement, collisions, interactions, warps, wild
// encounters and ambient life.

import * as Phaser from "phaser";
import { MAPS } from "../world/maps/index.js";
import { TILE, TILES } from "../world/tiles.js";
import { hash } from "../world/mapBuilder.js";
import { paintGround } from "../art/groundArt.js";
import { anchors, propTexture, buildingTexture, furnitureTexture, characterTexture, dinoTexture, butterflyTexture } from "../engine/textures.js";
import { hud } from "../ui/hud.js";
import { state, save, flag, setFlag, addItem } from "../state/game.js";
import { ITEMS, JOURNAL, FOSSIL_PARTS } from "../data/items.js";
import { SCRIPTS, STARTERS, speciesIndex } from "../story/scripts.js";
import { ENCOUNTERS, ENCOUNTER_RATE } from "../data/encounters.js";

const CHUNK = 12;
const FOLLOWER_SCALE = 0.25; // px per art unit
const STEP_MS = 190;
const DELTA = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] };
const OPPOSITE = { up: "down", down: "up", left: "right", right: "left" };

const PROP_VARIANTS = { tree: 3, pine: 2, bush: 2, rock: 2 };

export class WorldScene extends Phaser.Scene {
  constructor() {
    super("World");
  }

  init(data) {
    this.mapId = data.map || state.map;
    this.spawn = data.spawn || null;
    this.newGame = !!data.newGame;
  }

  create() {
    const map = MAPS[this.mapId];
    this.map = map;
    this.rows = map.rows;
    this.W = this.rows[0].length;
    this.H = this.rows.length;
    this.solid = this.rows.map((row) => [...row].map((ch) => !!(TILES[ch] || {}).solid));
    this.occupied = new Map();
    this.entities = [];
    this.tallGrass = new Map();
    this.scriptRunning = false;
    this.moving = false;
    this.stepParity = 0;
    // The scene object is reused across restarts (warps): reset per-map state.
    this.follower = null;
    this.idleFrames = 0;

    this.buildGround();
    this.buildProps();
    this.buildEntities();
    this.createPlayer();
    this.setupCamera();
    if (!map.interior) this.createAmbience();

    this.onA = () => this.interact();
    this.onMenu = () => this.openMenu();
    hud.handlers.a = [this.onA];
    hud.handlers.menu = [this.onMenu];
    hud.handlers.b = [];

    this.scale.on("resize", () => this.fitCamera());
    this.currentZone = null;
    this.updateZone(true);

    state.map = this.mapId;
    this.cameras.main.fadeIn(350, 0, 0, 0);
    if (this.newGame) setTimeout(() => this.runScript("intro"), 700);
  }

  // ---------------------------------------------------------------- ground
  buildGround() {
    const cols = Math.ceil(this.W / CHUNK), rowsN = Math.ceil(this.H / CHUNK);
    this.groundQueue = [];
    for (let cy = 0; cy < rowsN; cy++) {
      for (let cx = 0; cx < cols; cx++) {
        const key = `gr-${this.mapId}-${cx}-${cy}`;
        const w = Math.min(CHUNK, this.W - cx * CHUNK), h = Math.min(CHUNK, this.H - cy * CHUNK);
        const chunk = { key, cx, cy, w, h };
        if (this.textures.exists(key)) this.placeChunk(chunk);
        else this.groundQueue.push(chunk);
      }
    }
    // Paint the chunks around the player first, then the rest progressively.
    const start = this.spawnPoint();
    this.groundQueue.sort((a, b) => {
      const da = Math.hypot(a.cx * CHUNK + CHUNK / 2 - start.x, a.cy * CHUNK + CHUNK / 2 - start.y);
      const db = Math.hypot(b.cx * CHUNK + CHUNK / 2 - start.x, b.cy * CHUNK + CHUNK / 2 - start.y);
      return da - db;
    });
    for (let i = 0; i < 4 && this.groundQueue.length; i++) this.paintChunk(this.groundQueue.shift());
  }

  // Chunks in view are painted right away; the others trickle in during idle frames.
  paintPendingChunks() {
    if (!this.groundQueue.length) return;
    const v = this.cameras.main.worldView, S = CHUNK * TILE;
    const visible = (c) => c.cx * S < v.right + S && (c.cx + 1) * S > v.x - S && c.cy * S < v.bottom + S && (c.cy + 1) * S > v.y - S;
    const i = this.groundQueue.findIndex(visible);
    if (i >= 0) { this.paintChunk(this.groundQueue.splice(i, 1)[0]); return; }
    this.idleFrames = (this.idleFrames || 0) + 1;
    if (this.idleFrames % 8 === 0) this.paintChunk(this.groundQueue.shift());
  }

  paintChunk(chunk) {
    const c = document.createElement("canvas");
    c.width = chunk.w * TILE;
    c.height = chunk.h * TILE;
    const t0 = performance.now();
    paintGround(c.getContext("2d"), this.rows, chunk.cx * CHUNK, chunk.cy * CHUNK, chunk.w, chunk.h);
    if (location.search.includes("perf")) console.log(`PERF chunk ${chunk.key} ${Math.round(performance.now() - t0)}ms`);
    this.textures.addCanvas(chunk.key, c);
    this.placeChunk(chunk);
  }

  placeChunk(chunk) {
    this.add.image(chunk.cx * CHUNK * TILE, chunk.cy * CHUNK * TILE, chunk.key).setOrigin(0).setDepth(-10000);
  }

  // ---------------------------------------------------------------- props
  placeSprite(key, x, y, depth) {
    const a = anchors[key] || { x: 0.5, y: 1 };
    return this.add.image(x, y, key).setOrigin(a.x, a.y).setDepth(depth ?? y);
  }

  buildProps() {
    for (let y = 0; y < this.H; y++) {
      for (let x = 0; x < this.W; x++) {
        const t = TILES[this.rows[y][x]];
        if (!t || !t.prop || ["flowers", "fern", "bones"].includes(t.prop)) continue;
        const n = PROP_VARIANTS[t.prop] || 1;
        const variant = Math.floor(hash(x, y, 5) * n);
        const cx = x * TILE + TILE / 2, by = (y + 1) * TILE;
        if (t.prop === "tallgrass") {
          const v = Math.floor(hash(x, y, 6) * 3);
          const key = propTexture(this, "tallgrass", v * 2);
          propTexture(this, "tallgrass", v * 2 + 1);
          const s = this.placeSprite(key, cx + (hash(x, y, 7) - 0.5) * 8, by + 2, by + 1).setScale(1, 0.8 + hash(x, y, 9) * 0.12);
          s.grassVariant = v;
          this.tallGrass.set(`${x},${y}`, s);
        } else {
          const jitter = t.prop === "tree" || t.prop === "pine" ? (hash(x, y, 8) - 0.5) * 10 : 0;
          const key = propTexture(this, t.prop, variant);
          this.placeSprite(key, cx + jitter, by - 2);
        }
      }
    }
  }

  // ---------------------------------------------------------------- entities
  occupy(x, y, ent) {
    this.occupied.set(`${x},${y}`, ent);
  }

  entityAt(x, y) {
    return this.occupied.get(`${x},${y}`);
  }

  buildEntities() {
    for (const e of this.map.entities) {
      const ent = { ...e };
      if (ent.flag && flag(ent.flag)) continue; // already collected
      if (ent.flagHidden && flag(ent.flagHidden)) continue;
      this.entities.push(ent);
      const cx = ent.x * TILE + TILE / 2, by = (ent.y + 1) * TILE;
      switch (ent.type) {
        case "building": {
          const key = buildingTexture(this, ent.kind, ent.w, ent.h);
          const a = anchors[key];
          ent.sprite = this.add.image(ent.x * TILE, (ent.y + ent.h) * TILE, key).setOrigin(a.x, a.y).setDepth((ent.y + ent.h) * TILE);
          for (let j = ent.y; j < ent.y + ent.h; j++) {
            for (let i = ent.x; i < ent.x + ent.w; i++) {
              if (ent.door && i === ent.door.x && j === ent.door.y) continue;
              this.occupy(i, j, ent);
            }
          }
          if (ent.door) this.occupy(ent.door.x, ent.door.y, { type: "door", ...ent.door, building: ent });
          break;
        }
        case "decor": {
          const w = ent.w || 1, h = ent.h || 1;
          const isFurniture = !!this.map.interior;
          const key = isFurniture ? furnitureTexture(this, ent.kind, w, h) : propTexture(this, ent.kind);
          const a = anchors[key];
          const x = isFurniture ? ent.x * TILE : ent.x * TILE, y = (ent.y + h) * TILE;
          ent.sprite = this.add.image(x, y, key).setOrigin(a.x, a.y).setDepth(y);
          if (ent.solid) for (let j = ent.y; j < ent.y + h; j++) for (let i = ent.x; i < ent.x + w; i++) this.occupy(i, j, ent);
          if (ent.kind === "pedestal" && flag("starter") && state.flags.starterIndex === ent.starter) ent.sprite.setTint(0x999999);
          break;
        }
        case "sign":
          ent.sprite = this.placeSprite(propTexture(this, "sign"), cx, by - 2);
          this.occupy(ent.x, ent.y, ent);
          break;
        case "blocker": {
          const key = ent.kind === "log" ? propTexture(this, "log", ent.w || 2) : propTexture(this, "boulder");
          const a = anchors[key];
          ent.sprite = this.add.image(ent.x * TILE + (ent.kind === "log" ? 0 : TILE / 2), by, key).setOrigin(a.x, a.y).setDepth(by);
          for (let i = 0; i < (ent.w || 1); i++) this.occupy(ent.x + i, ent.y, ent);
          if (ent.kind === "boulder") {
            // Cave mouth in the cliff behind the boulder.
            const cave = propTexture(this, "cave");
            this.placeSprite(cave, cx, ent.y * TILE, ent.y * TILE - 1);
          }
          break;
        }
        case "item": {
          const key = propTexture(this, "orb");
          ent.sprite = this.placeSprite(key, cx, by - 6, by - 10);
          this.tweens.add({ targets: ent.sprite, y: by - 11, duration: 900, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
          this.occupy(ent.x, ent.y, ent);
          break;
        }
        case "hidden":
          this.occupy(ent.x, ent.y, ent);
          break;
        case "npc": {
          const key = characterTexture(this, ent.look);
          const a = anchors[key];
          ent.sprite = this.add.sprite(cx, by, key, `${ent.dir}-0`).setOrigin(a.x, a.y).setDepth(by - 1);
          ent.home = { x: ent.x, y: ent.y };
          this.occupy(ent.x, ent.y, ent);
          if (ent.wander) this.time.addEvent({ delay: 2200 + Math.random() * 1800, loop: true, callback: () => this.wander(ent) });
          break;
        }
        default:
          break;
      }
    }
  }

  wander(ent) {
    if (this.scriptRunning || ent.moving || !ent.sprite?.active) return;
    const dirs = Object.keys(DELTA);
    const dir = dirs[Math.floor(Math.random() * 4)];
    const [dx, dy] = DELTA[dir];
    const nx = ent.x + dx, ny = ent.y + dy;
    ent.sprite.setFrame(`${dir}-0`);
    ent.dir = dir;
    if (Math.abs(nx - ent.home.x) > ent.wander || Math.abs(ny - ent.home.y) > ent.wander || this.blocked(nx, ny)) return;
    this.occupied.delete(`${ent.x},${ent.y}`);
    ent.x = nx; ent.y = ny;
    this.occupy(nx, ny, ent);
    ent.moving = true;
    ent.sprite.setFrame(`${dir}-1`);
    this.tweens.add({
      targets: ent.sprite, x: nx * TILE + TILE / 2, y: (ny + 1) * TILE, duration: STEP_MS * 1.4,
      onUpdate: () => ent.sprite.setDepth(ent.sprite.y - 1),
      onComplete: () => { ent.moving = false; ent.sprite.setFrame(`${dir}-0`); },
    });
  }

  // ---------------------------------------------------------------- player
  spawnPoint() {
    if (this.spawn) return this.spawn;
    if (state.map === this.mapId && state.x !== null) return { x: state.x, y: state.y, dir: state.dir };
    return this.map.start || { x: 1, y: 1, dir: "down" };
  }

  createPlayer() {
    const p = this.spawnPoint();
    this.px = p.x;
    this.py = p.y;
    this.dir = p.dir || "down";
    const key = characterTexture(this, "chloe");
    const a = anchors[key];
    this.player = this.add.sprite(this.px * TILE + TILE / 2, (this.py + 1) * TILE, key, `${this.dir}-0`).setOrigin(a.x, a.y);
    this.player.setDepth(this.player.y - 1);
    this.trail = [];
    this.createFollower();
  }

  async createFollower() {
    const d = state.party[0];
    if (!d || this.follower) return;
    // Side, front and back views at the same scale; the follower turns to face its path.
    const [side, front, backView] = await Promise.all(["side", "front", "back"].map((view) => dinoTexture(this, d.build, 0, { view, unitScale: FOLLOWER_SCALE })));
    if (!side || !this.scene.isActive() || this.follower) return;
    this.followerKeys = { side, front: front || side, back: backView || side };
    const key = this.dir === "up" ? this.followerKeys.back : this.dir === "down" ? this.followerKeys.front : side;
    const a = anchors[key];
    const back = DELTA[OPPOSITE[this.dir]];
    this.fx = this.px + back[0];
    this.fy = this.py + back[1];
    if (this.blocked(this.fx, this.fy, true)) { this.fx = this.px; this.fy = this.py; }
    this.follower = this.add.image(this.fx * TILE + TILE / 2, (this.fy + 1) * TILE - 4, key).setOrigin(a.x, a.y);
    this.follower.setDepth(this.follower.y - 2);
    this.followerBreath = this.tweens.add({ targets: this.follower, scaleY: 1.03, duration: 1100, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
  }

  faceFollower(dx, dy) {
    if (!this.followerKeys || (!dx && !dy)) return;
    const k = dy > 0 ? "front" : dy < 0 ? "back" : "side";
    const key = this.followerKeys[k];
    if (this.follower.texture.key !== key) {
      const a = anchors[key];
      this.follower.setTexture(key).setOrigin(a.x, a.y);
    }
    this.follower.setFlipX(k === "side" && dx < 0);
  }

  blocked(x, y, ignoreEntities = false) {
    if (x < 0 || y < 0 || x >= this.W || y >= this.H) return true;
    if (this.solid[y][x]) return true;
    if (ignoreEntities) return false;
    const e = this.entityAt(x, y);
    if (!e) return false;
    if (e.type === "door") return !!e.locked;
    if (e.type === "hidden" || e.type === "trigger" || e.type === "warp") return false;
    return true;
  }

  update() {
    this.paintPendingChunks();
    if (this.moving || this.scriptRunning || hud.busy) return;
    const d = hud.dir;
    if (!d) {
      if (this.player.frame.name !== `${this.dir}-0`) this.player.setFrame(`${this.dir}-0`);
      return;
    }
    this.dir = d;
    const [dx, dy] = DELTA[d];
    const nx = this.px + dx, ny = this.py + dy;
    if (this.blocked(nx, ny)) {
      this.player.setFrame(`${d}-0`);
      return;
    }
    this.step(nx, ny);
  }

  step(nx, ny) {
    this.moving = true;
    const prev = { x: this.px, y: this.py };
    this.px = nx;
    this.py = ny;
    this.stepParity ^= 1;
    this.player.setFrame(`${this.dir}-${this.stepParity ? 1 : 2}`);
    this.tweens.add({
      targets: this.player,
      x: nx * TILE + TILE / 2,
      y: (ny + 1) * TILE,
      duration: STEP_MS,
      onUpdate: () => this.player.setDepth(this.player.y - 1),
      onComplete: () => {
        this.moving = false;
        this.onStepEnd();
      },
    });
    if (this.follower) {
      const fx = prev.x, fy = prev.y;
      this.faceFollower(fx - this.fx, fy - this.fy);
      this.fx = fx; this.fy = fy;
      this.tweens.add({
        targets: this.follower, x: fx * TILE + TILE / 2, y: (fy + 1) * TILE - 4, duration: STEP_MS,
        onUpdate: () => this.follower.setDepth(this.follower.y - 2),
      });
    }
    const grass = this.tallGrass.get(`${nx},${ny}`);
    if (grass) this.rustle(grass);
  }

  rustle(sprite) {
    const v = sprite.grassVariant || 0;
    sprite.setTexture(`prop-tallgrass-${v * 2 + 1}`);
    const sy = sprite.scaleY;
    this.tweens.add({ targets: sprite, scaleY: sy * 0.88, duration: 90, yoyo: true, onComplete: () => sprite.setTexture(`prop-tallgrass-${v * 2}`) });
  }

  onStepEnd() {
    state.x = this.px;
    state.y = this.py;
    state.dir = this.dir;
    const e = this.entityAt(this.px, this.py);
    if (e?.type === "door" && !e.locked) return this.warp(e.to);
    const warp = this.entities.find((w) => w.type === "warp" && w.x === this.px && w.y === this.py);
    if (warp) return this.warp(warp.to);
    const trig = this.entities.find((t) => t.type === "trigger" && this.px >= t.x && this.px < t.x + t.w && this.py >= t.y && this.py < t.y + t.h);
    if (trig) this.runScript(trig.script);
    this.updateZone();
    if ((TILES[this.rows[this.py][this.px]] || {}).encounter) this.maybeEncounter();
  }

  // ---------------------------------------------------------------- zones & warps
  zoneAt(y) {
    return (this.map.zones || []).find((z) => y >= z.y0 && y < z.y1) || { name: this.map.name };
  }

  updateZone(force = false) {
    const z = this.zoneAt(this.py);
    if (z.name !== this.currentZone || force) {
      this.currentZone = z.name;
      hud.banner(z.name, this.map.interior ? "" : "Ambrelune");
    }
  }

  async warp(to) {
    this.scriptRunning = true;
    await hud.fade(true);
    state.map = to.map;
    state.x = to.x;
    state.y = to.y;
    state.dir = to.dir;
    save();
    this.scene.restart({ map: to.map, spawn: { x: to.x, y: to.y, dir: to.dir } });
    setTimeout(() => hud.fade(false), 120);
  }

  // ---------------------------------------------------------------- interaction
  facing() {
    const [dx, dy] = DELTA[this.dir];
    return { x: this.px + dx, y: this.py + dy };
  }

  interact() {
    if (this.moving || this.scriptRunning) return;
    const { x, y } = this.facing();
    const e = this.entityAt(x, y);
    if (!e) {
      const t = TILES[this.rows[y]?.[x]];
      if (t?.ground === "water") this.runLines(["L'eau est profonde et claire. Des petits poissons filent entre les algues."]);
      return;
    }
    switch (e.type) {
      case "npc":
        e.sprite.setFrame(`${OPPOSITE[this.dir]}-0`);
        return this.runScript(e.script);
      case "sign":
        return this.runLines([e.text]);
      case "blocker":
        return this.runLines([e.text]);
      case "door":
        if (e.locked) return this.runLines([e.locked]);
        return;
      case "item":
        return this.pickUp(e);
      case "hidden":
        return this.pickUp(e, true);
      case "decor":
        if (e.kind === "pedestal") return this.runScript("starter", e.starter);
        if (e.script) return this.runScript(e.script);
        if (e.text) return this.runLines([e.text]);
        return;
      default:
        return;
    }
  }

  async pickUp(e, hidden = false) {
    if (e.flag && flag(e.flag)) return;
    this.scriptRunning = true;
    hud.setBusy(true);
    if (e.flag) setFlag(e.flag);
    this.occupied.delete(`${e.x},${e.y}`);
    if (e.sprite) {
      this.tweens.killTweensOf(e.sprite);
      this.tweens.add({ targets: e.sprite, y: e.sprite.y - 24, alpha: 0, duration: 300, onComplete: () => e.sprite.destroy() });
    }
    const it = ITEMS[e.item];
    let line;
    if (e.item === "journal") {
      if (!state.journal.includes(e.page)) state.journal.push(e.page);
      line = `Tu as trouvé une page du journal d'Hélène !\n« ${JOURNAL[e.page].title} » — à lire dans Menu › Journal.`;
    } else if (e.item === "ambre") {
      if (!state.amber.includes(e.species)) state.amber.push(e.species);
      line = `Tu as trouvé un fragment d'ambre ! Il contient l'ADN d'un ${e.species}.`;
    } else if (e.item === "fossile") {
      if (!state.fossils.includes(e.part)) state.fossils.push(e.part);
      line = `Tu as trouvé un fragment de fossile : ${FOSSIL_PARTS[e.part]} !`;
    } else if (e.item === "piece") {
      state.money += e.qty;
      line = `Tu as trouvé ${e.qty} pièces !`;
    } else {
      addItem(e.item, e.qty || 1);
      line = `Tu as trouvé : ${it.name}${(e.qty || 1) > 1 ? ` ×${e.qty}` : ""} !`;
    }
    this.cameras.main.flash(120, 255, 230, 160);
    await hud.say(null, hidden ? `Il y a quelque chose ici… ${line}` : line);
    save();
    hud.setBusy(false);
    this.scriptRunning = false;
  }

  runLines(lines) {
    return this.runScript(async ({ say }) => { for (const l of lines) await say(null, l); });
  }

  async runScript(nameOrFn, arg) {
    const fn = typeof nameOrFn === "function" ? nameOrFn : SCRIPTS[nameOrFn];
    if (!fn || this.scriptRunning) return;
    this.scriptRunning = true;
    hud.setBusy(true);
    try {
      await fn(this.scriptApi(), arg);
    } finally {
      hud.setBusy(false);
      this.scriptRunning = false;
    }
  }

  scriptApi() {
    return {
      say: (n, t) => hud.say(n, t),
      choose: (o) => hud.choose(o),
      toast: (t) => hud.toast(t),
      wait: (ms) => new Promise((r) => setTimeout(r, ms)),
      flag,
      setFlag,
      save: () => save(),
      heal: () => {},
      giveStarter: (i) => this.giveStarter(i),
      pushBack: () => this.pushBack(),
      hideNpc: (id) => this.hideNpc(id),
      npcFace: (id, dir) => this.entities.find((e) => e.id === id)?.sprite?.setFrame(`${dir}-0`),
    };
  }

  giveStarter(i) {
    const s = STARTERS[i];
    const idx = speciesIndex(s.species);
    const build = { head: idx, teeth: idx, frontLegs: idx, backLegs: idx, back: idx, tail: idx, color: idx };
    state.party.push({ speciesIdx: idx, speciesName: s.species, nickname: s.nickname, level: 5, xp: 0, build });
    setFlag("starter");
    state.flags.starterIndex = i;
    const ped = this.entities.find((e) => e.kind === "pedestal" && e.starter === i);
    ped?.sprite?.setTint(0x999999);
    save();
    this.createFollower();
  }

  pushBack() {
    const [dx, dy] = DELTA[OPPOSITE[this.dir]];
    const nx = this.px + dx, ny = this.py + dy;
    if (this.blocked(nx, ny)) return;
    this.dir = OPPOSITE[this.dir];
    this.px = nx; this.py = ny;
    state.x = nx; state.y = ny;
    this.tweens.add({ targets: this.player, x: nx * TILE + TILE / 2, y: (ny + 1) * TILE, duration: STEP_MS, onUpdate: () => this.player.setDepth(this.player.y - 1) });
    this.player.setFrame(`${this.dir}-0`);
  }

  hideNpc(id) {
    const e = this.entities.find((x) => x.id === id);
    if (!e) return;
    this.occupied.delete(`${e.x},${e.y}`);
    this.tweens.add({ targets: e.sprite, alpha: 0, y: e.sprite.y - 60, duration: 900, onComplete: () => e.sprite.destroy() });
  }

  async openMenu() {
    if (this.scriptRunning) return;
    this.scriptRunning = true;
    hud.setBusy(true);
    await hud.openMenu();
    hud.setBusy(false);
    this.scriptRunning = false;
  }

  // ---------------------------------------------------------------- encounters
  maybeEncounter() {
    const zone = this.zoneAt(this.py);
    if (!zone.encounters || !state.party.length || this.scriptRunning) return;
    if (Math.random() > (location.search.includes("rencontre") ? 1 : ENCOUNTER_RATE)) return;
    const table = ENCOUNTERS[zone.encounters];
    this.scriptRunning = true;
    hud.setBusy(true);
    const cam = this.cameras.main;
    cam.shake(250, 0.006);
    cam.flash(180, 255, 255, 255);
    this.time.delayedCall(260, () => cam.flash(180, 255, 255, 255));
    this.time.delayedCall(560, () => {
      cam.fadeOut(260, 0, 0, 0);
      cam.once("camerafadeoutcomplete", () => {
        this.scene.pause();
        this.scene.launch("Encounter", { table, zoneName: zone.name, zoneKey: zone.encounters });
      });
    });
  }

  resumeFromEncounter() {
    this.cameras.main.fadeIn(300, 0, 0, 0);
    hud.setBusy(false);
    this.scriptRunning = false;
  }

  // ---------------------------------------------------------------- camera
  setupCamera() {
    const cam = this.cameras.main;
    cam.setBackgroundColor(this.map.interior ? "#140e0a" : "#1c4f6a");
    this.fitCamera();
    cam.startFollow(this.player, true, 0.14, 0.14);
  }

  fitCamera() {
    const cam = this.cameras.main;
    const w = this.scale.width, h = this.scale.height;
    // Portrait phones see ~11 tiles across; landscape screens see a wider area.
    const [tx, ty] = w > h ? [17, 10] : [11, 9];
    const zoom = Math.min(w / (tx * TILE), h / (ty * TILE));
    cam.setZoom(zoom);
    const mw = this.W * TILE, mh = this.H * TILE;
    const vw = w / zoom, vh = h / zoom;
    // Small maps (interiors) are centered instead of clamped to an edge.
    const bx = mw < vw ? (mw - vw) / 2 : 0, by = mh < vh ? (mh - vh) / 2 : 0;
    cam.setBounds(bx, by, Math.max(mw, vw), Math.max(mh, vh));
  }

  // ---------------------------------------------------------------- ambience
  createAmbience() {
    // Drifting cloud shadows.
    if (!this.textures.exists("cloudshadow")) {
      const c = document.createElement("canvas");
      c.width = 520; c.height = 320;
      const g = c.getContext("2d");
      for (const [x, y, r] of [[180, 160, 130], [320, 150, 150], [250, 110, 110], [400, 190, 100]]) {
        const grad = g.createRadialGradient(x, y, 0, x, y, r);
        grad.addColorStop(0, "rgba(10,20,30,0.5)");
        grad.addColorStop(1, "rgba(10,20,30,0)");
        g.fillStyle = grad;
        g.fillRect(0, 0, 520, 320);
      }
      this.textures.addCanvas("cloudshadow", c);
    }
    const mw = this.W * TILE, mh = this.H * TILE;
    for (let i = 0; i < 4; i++) {
      const s = this.add.image(Math.random() * mw, Math.random() * mh, "cloudshadow").setDepth(90000).setAlpha(0.22).setScale(1.5 + Math.random());
      this.tweens.add({ targets: s, x: s.x + 1400, y: s.y + 500, duration: 90000 + Math.random() * 40000, repeat: -1, onRepeat: () => { s.x = -600; s.y = Math.random() * mh; } });
    }
    // Butterflies over the grass.
    const colors = ["#f2c94c", "#f28bb3", "#fdfdf5", "#8fc6f5"];
    for (let i = 0; i < 7; i++) {
      const key = butterflyTexture(this, colors[i % colors.length], i);
      const b = this.add.image(this.player.x + (Math.random() - 0.5) * 500, this.player.y + (Math.random() - 0.5) * 500, key).setDepth(80000);
      this.tweens.add({ targets: b, scaleX: 0.3, duration: 110 + Math.random() * 60, yoyo: true, repeat: -1 });
      const fly = () => {
        if (!b.active) return;
        const tx = this.player.x + (Math.random() - 0.5) * 520, ty = this.player.y + (Math.random() - 0.5) * 520;
        this.tweens.add({ targets: b, x: tx, y: ty, duration: 2500 + Math.random() * 2500, ease: "Sine.easeInOut", onComplete: fly });
      };
      fly();
    }
    // Glints on the water near the camera.
    const sparkleKey = propTexture(this, "sparkle");
    this.time.addEvent({
      delay: 280, loop: true, callback: () => {
        const view = this.cameras.main.worldView;
        for (let k = 0; k < 6; k++) {
          const x = Math.floor((view.x + Math.random() * view.width) / TILE), y = Math.floor((view.y + Math.random() * view.height) / TILE);
          if (TILES[this.rows[y]?.[x]]?.ground !== "water") continue;
          const s = this.add.image(x * TILE + Math.random() * TILE, y * TILE + Math.random() * TILE, sparkleKey).setDepth(-9000).setAlpha(0).setScale(0.6);
          this.tweens.add({ targets: s, alpha: 0.9, scale: 1, duration: 450, yoyo: true, onComplete: () => s.destroy() });
          break;
        }
      },
    });
  }
}
