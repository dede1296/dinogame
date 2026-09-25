import * as Phaser from "phaser";
import { WorldScene } from "./scenes/WorldScene.js";
import { EncounterScene } from "./scenes/EncounterScene.js";
import { hud } from "./ui/hud.js";
import { hasSave, resetState, state, setFlag } from "./state/game.js";
import { speciesIndex } from "./story/scripts.js";

// Render at device resolution (capped) so the vector-style art stays sharp.
const DPR = Math.min(2, window.devicePixelRatio || 1);
const size = () => ({ w: Math.round(window.innerWidth * DPR), h: Math.round(window.innerHeight * DPR) });

hud.init();

let game = null;

function start(newGame) {
  if (newGame) resetState();
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
    state.party = [{ speciesIdx: i, speciesName: q.get("dino"), nickname: "Test", level: 5, xp: 0, build: { head: i, teeth: i, frontLegs: i, backLegs: i, back: i, tail: i, color: i } }];
    setFlag("starter"); setFlag("maia_met");
  }
  game.scene.add("World", WorldScene, true, { newGame: newGame && !spawn, map: q.get("carte") || undefined, spawn });
  game.scene.add("Encounter", EncounterScene, false);
  window.addEventListener("resize", () => {
    const s = size();
    game.scale.resize(s.w, s.h);
  });
}

// ?demarrer : lance directement une nouvelle partie (tests).
if (new URLSearchParams(location.search).has("demarrer")) {
  document.getElementById("title").remove();
  start(true);
} else {
  const title = document.getElementById("title");
  const cont = document.getElementById("continue");
  if (hasSave()) cont.hidden = false;
  cont.addEventListener("click", () => { title.remove(); start(false); });
  document.getElementById("new").addEventListener("click", () => {
    if (hasSave() && !confirm("Commencer une nouvelle partie ? La progression actuelle sera effacée.")) return;
    title.remove();
    start(true);
  });
}
