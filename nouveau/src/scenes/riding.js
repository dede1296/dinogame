// Riding a dino on the map (ability "Monture"): Chloé sits on the back of a big enough
// dino and moves much faster. Mixed into WorldScene (see the end of WorldScene.js).
//
// The mount is the follower sprite itself: while riding it walks on Chloé's tile, and
// Chloé's sprite is drawn on its back, cropped at the hips (her legs are on either side).

import { state } from "../state/game.js";
import { abilityUser } from "../data/abilities.js";
import { anchors } from "../engine/textures.js";
import { FRAME_W } from "../art/characterArt.js";
import { playCry } from "../audio/cries.js";
import { play } from "../audio/sounds.js";
import { hud } from "../ui/hud.js";

const TILE = 48;
// A step while riding takes this fraction of a walking step (and less with B held).
export const RIDE_FACTOR = 0.5;
export const RIDE_RUN_FACTOR = 0.36;
// Chloé's frame: feet at y 62; her hips are this many pixels above her feet.
const HIPS_ABOVE_FEET = 17;
const HIPS_Y = 62 - HIPS_ABOVE_FEET;
const HOP_MS = 180;
// The companion is drawn small; as a mount it grows to carry Chloé convincingly.
const MOUNT_SCALE = 1.4;

const DELTA = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] };

export const riding = {
  /** The dino that can carry Chloé here, or null (none in the team, or indoors / in a cave). */
  mountDino() {
    if (this.map.interior || this.map.cave) return null;
    return abilityUser(state.party, "monture");
  },

  /** Shows the HUD ride button when riding is possible (or to get off). */
  refreshRideButton() {
    hud.setRideButton(this.riding ? "dismount" : this.mountDino() ? "mount" : "hidden");
  },

  toggleRide() {
    if (this.riding) this.dismount();
    else this.mount();
  },

  async mount() {
    if (this.riding || this.scriptRunning || this.moving) return;
    const d = this.mountDino();
    if (!d) return;
    this.scriptRunning = true;
    hud.setBusy(true);
    // The rideable dino may not be the one following Chloé: call it over.
    if (this.followerDino !== d) {
      this.follower?.destroy();
      this.follower = null;
      await this.createFollower(d);
    }
    const f = this.follower;
    if (!f) { this.scriptRunning = false; hud.setBusy(false); return; }
    const [dx, dy] = DELTA[this.dir];
    this.faceFollower(dx, dy);
    await new Promise((r) => this.tweens.add({ targets: f, x: this.px * TILE + TILE / 2, y: (this.py + 1) * TILE - 4, duration: 260, ease: "Quad.easeOut", onComplete: r }));
    this.fx = this.px; this.fy = this.py; this.trail = [];
    this.followerBreath?.pause();
    await new Promise((r) => this.tweens.add({ targets: f, scaleX: MOUNT_SCALE, scaleY: MOUNT_SCALE, duration: 200, ease: "Back.easeOut", onComplete: r }));
    // Chloé hops on.
    this.riding = true;
    this.player.setFrame(`${this.dir}-0`).setCrop(0, 0, FRAME_W, HIPS_Y);
    this.placeRider();
    const y = this.player.y;
    this.player.y -= 22;
    await new Promise((r) => this.tweens.add({ targets: this.player, y, duration: HOP_MS, ease: "Quad.easeIn", onComplete: r }));
    playCry(d, { mood: "happy" });
    play("cloth", { volume: 0.4 });
    this.scriptRunning = false;
    hud.setBusy(false);
    this.refreshRideButton();
  },

  /** Gets off; `instant` skips the hop (battles, doors). */
  dismount(instant = false) {
    if (!this.riding) return;
    this.riding = false;
    this.player.setCrop();
    this.follower?.setScale(1);
    this.followerBreath?.resume();
    this.player.setPosition(this.px * TILE + TILE / 2, (this.py + 1) * TILE).setDepth((this.py + 1) * TILE - 1);
    if (!instant) {
      const y = this.player.y;
      this.player.y -= 18;
      this.tweens.add({ targets: this.player, y, duration: HOP_MS, ease: "Quad.easeIn" });
      play("cloth", { volume: 0.35 });
    }
    // The dino steps back behind Chloé when there is room.
    const [bx, by] = DELTA[this.dir].map((v) => -v);
    if (!this.blocked(this.px + bx, this.py + by, true)) {
      this.fx = this.px + bx; this.fy = this.py + by;
      this.follower?.setPosition(this.fx * TILE + TILE / 2, (this.fy + 1) * TILE - 4).setDepth((this.fy + 1) * TILE - 2);
    }
    this.trail = [];
    // The lead dino follows again.
    if (this.followerDino !== state.party[0]) this.refreshFollower();
    this.refreshRideButton();
  },

  /** Puts Chloé on her mount's back (called every frame while riding). */
  placeRider() {
    const f = this.follower;
    if (!f) return;
    const a = anchors[f.texture.key];
    const seat = a.seat || { x: a.x, y: a.y * 0.55 };
    const sx = f.flipX ? 1 - seat.x : seat.x;
    this.player.setPosition(f.x + (sx - a.x) * f.displayWidth, f.y + (seat.y - a.y) * f.displayHeight + HIPS_ABOVE_FEET);
    this.player.setDepth(f.depth + 1);
  },

  /** One step on dino-back: the mount carries Chloé to the next tile. */
  rideStep(nx, ny) {
    this.moving = true;
    const ms = this.stepMs * (hud.bHeld ? RIDE_RUN_FACTOR : RIDE_FACTOR);
    this.faceFollower(nx - this.px, ny - this.py);
    this.player.setFrame(`${this.dir}-0`);
    this.px = nx; this.py = ny;
    this.fx = nx; this.fy = ny;
    this.tweens.add({
      targets: this.follower, x: nx * TILE + TILE / 2, y: (ny + 1) * TILE - 4, duration: ms,
      onUpdate: () => { this.follower.setDepth(this.follower.y - 2); this.placeRider(); },
      onComplete: () => { this.moving = false; this.onStepEnd(); },
    });
    const grass = this.tallGrass.get(`${nx},${ny}`);
    if (grass) this.rustle(grass);
    // Heavier, slower footfalls than Chloé's.
    play("step_stone", { volume: 0.35, rate: 0.6, jitter: 0.1 });
  },
};
