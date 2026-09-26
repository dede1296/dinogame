import * as Phaser from "phaser";
import { WorldScene } from "./scenes/WorldScene.js";
import { BattleScene } from "./scenes/BattleScene.js";
import { createDino, normalizeDino, heal } from "./battle/dino.js";
import { hud } from "./ui/hud.js";
import { resetState, state, setFlag, useSlot, autosave } from "./state/game.js";
import { setupTitle } from "./ui/title.js";
import { unlockAudio } from "./audio/sounds.js";
import { consumeJump } from "./debug/debug.js";
import { setupServiceWorker, requestPersistentStorage, autosaveOnHide } from "./pwa.js";

unlockAudio();
import { speciesIndex } from "./story/scripts.js";

// Render at device resolution (capped) so the vector-style art stays sharp.
const DPR = Math.min(2, window.devicePixelRatio || 1);
const size = () => ({ w: Math.round(window.innerWidth * DPR), h: Math.round(window.innerHeight * DPR) });

hud.init();

let game = null;

// Installable app: offline cache and updates (production only), and saves kept safe.
setupServiceWorker({
  onUpdate: () => {
    // On the title screen, simply reload into the new version; in a game, tell the player.
    if (document.getElementById("title")) location.reload();
    else hud.toast("Nouvelle version d'Ambrelune installée : elle s'appliquera au prochain lancement.");
  },
});
requestPersistentStorage();
// Only in a stable moment: exploring the map, no battle, cutscene or menu open.
autosaveOnHide(() => {
  if (!game || window.__noAutosave) return false;
  const world = game.scene.getScene("World");
  return game.scene.isActive("World") && !game.scene.isActive("Battle") && !!world && !world.scriptRunning;
}, autosave);

function start(newGame) {
  if (newGame) resetState();
  state.party = state.party.map(normalizeDino);
  // Test hook: the automated tests set this flag to start with a healed team.
  if (state.healOnLoad) { state.party.forEach(heal); delete state.healOnLoad; }
  const { w, h } = size();
  game = new Phaser.Game({
    type: Phaser.AUTO,
    parent: "game",
    width: w,
    height: h,
    backgroundColor: "#0c0f08",
    scale: { mode: Phaser.Scale.NONE },
    render: { antialias: true, roundPixels: false },
    scene: [],
  });
  // Test hook: ?carte=…&x=…&y=… spawns the player anywhere.
  const q = new URLSearchParams(location.search);
  const spawn = q.has("x") ? { x: +q.get("x"), y: +q.get("y"), dir: "down" } : null;
  if (q.has("dino")) {
    const i = speciesIndex(q.get("dino"));
    state.party = [createDino({ head: i, teeth: i, frontLegs: i, backLegs: i, back: i, tail: i, color: i }, +(q.get("niveau") || 5), "Test")];
    state.bag = { fougere: 3, baie: 2, collier: 5 };
    setFlag("starter"); setFlag("maia_met");
  }
  if (q.has("pieces")) state.money = +q.get("pieces");
  window.__game = game; // debug handles for the automated tests
  window.__state = state;
  game.scene.add("World", WorldScene, true, { newGame: newGame && !spawn, map: q.get("carte") || undefined, spawn });
  game.scene.add("Battle", BattleScene, false);
  window.addEventListener("resize", () => {
    const s = size();
    game.scale.resize(s.w, s.h);
  });
}

// ?demarrer : lance directement une nouvelle partie dans la sauvegarde débug (tests).
if (new URLSearchParams(location.search).has("demarrer")) {
  document.getElementById("title").remove();
  useSlot("debug");
  start(true);
} else if (consumeJump()) {
  // Debug mode just picked a checkpoint (saved in the debug slot): go straight into the game.
  document.getElementById("title").remove();
  useSlot("debug");
  start(false);
} else {
  const title = document.getElementById("title");
  setupTitle(title, (slot, isNew) => {
    title.remove();
    useSlot(slot);
    start(isNew);
  });
}
