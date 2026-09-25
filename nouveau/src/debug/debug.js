// Debug mode (hidden: tap the title 5 times). Jump to any point of the story and
// use a few cheats (level up, heal, pass any obstacle, no random encounters).

import { state, resetState, save, setFlag, useSlot } from "../state/game.js";
import { createDino, heal, MAX_LEVEL } from "../battle/dino.js";
import { speciesIndex } from "../story/scripts.js";

const ENABLED_KEY = "dino-debug";
const GO_KEY = "dino-debug-go";

export function debugEnabled() {
  try { return localStorage.getItem(ENABLED_KEY) === "1"; } catch { return false; }
}

function setDebugEnabled(on) {
  try { on ? localStorage.setItem(ENABLED_KEY, "1") : localStorage.removeItem(ENABLED_KEY); } catch { /* storage unavailable */ }
}

const pure = (name) => { const i = speciesIndex(name); return { head: i, teeth: i, frontLegs: i, backLegs: i, back: i, tail: i, color: i }; };
const vif = (level, grafts = {}) => {
  const build = { ...pure("Velociraptor") };
  for (const [part, species] of Object.entries(grafts)) build[part] = speciesIndex(species);
  return createDino(build, level, "Vif");
};

const ARRIVAL = ["met_roc", "starter", "roc_after", "letter_read", "maia_met"];
const CAVE = [...ARRIVAL, "hybrideur_vu", "rocher_brise"];
const ALPHA = [...CAVE, "sbire1_battu", "sbire2_battu", "hybride_battu"];
const TRUNK = [...ALPHA, "alpha_battu", "crane_hint"];
const FOREST = [...TRUNK, "tronc_coupe", "maia_battue"];

// Each checkpoint: where Chloé stands, the story flags already set, her team and bag.
export const CHECKPOINTS = [
  { id: "ch1", label: "Chapitre 1 — Début", sub: "Vif vient d'être choisi, au Cabinet", map: "cabinet", x: 6, y: 5, dir: "up", flags: ARRIVAL,
    party: () => [vif(5)], amber: [] },
  { id: "ch1-grotte", label: "Chapitre 1 — Grotte des Échos", sub: "Charge obtenue, rocher brisé", map: "ambreluneSud", x: 36, y: 23, dir: "up", flags: CAVE,
    party: () => [vif(9, { head: "Protoceratops" }), createDino(pure("Protoceratops"), 7)], amber: ["Protoceratops"] },
  { id: "ch1-alpha", label: "Chapitre 1 — Tricératops Alpha", sub: "Grotte finie, devant l'Alpha", map: "grotte2", x: 22, y: 18, dir: "left", flags: ALPHA,
    party: () => [vif(13, { head: "Protoceratops" }), createDino(pure("Protoceratops"), 11), createDino(pure("Pteranodon"), 10)], amber: ["Protoceratops"] },
  { id: "ch1-tronc", label: "Chapitre 1 — Le tronc et Maïa", sub: "Sceau des Plaines obtenu", map: "ambreluneSud", x: 22, y: 3, dir: "up", flags: TRUNK,
    party: () => [vif(15, { head: "Protoceratops" }), createDino(pure("Protoceratops"), 13), createDino(pure("Pteranodon"), 12)], amber: ["Protoceratops", "Velociraptor"], bag: { sceau_plaines: 1 } },
  { id: "ch2", label: "Chapitre 2 — Forêt Jurassique", sub: "Tronc coupé, Maïa battue", map: "ambreluneSud", x: 22, y: 2, dir: "up", flags: FOREST,
    party: () => [vif(17, { head: "Protoceratops" }), createDino(pure("Protoceratops"), 15), createDino(pure("Pteranodon"), 14)], amber: ["Protoceratops", "Velociraptor"], bag: { sceau_plaines: 1 } },
];

/** Replaces the debug save with a checkpoint (the three real saves are never touched). */
export function applyCheckpoint(id) {
  const cp = CHECKPOINTS.find((c) => c.id === id);
  if (!cp) return false;
  useSlot("debug");
  resetState();
  Object.assign(state, { map: cp.map, x: cp.x, y: cp.y, dir: cp.dir, party: cp.party(), amber: [...cp.amber], money: 200 });
  state.bag = { fougere: 5, baie: 3, collier: 10, ...(cp.bag || {}) };
  cp.flags.forEach((f) => setFlag(f));
  state.flags.starterIndex = 0;
  state.respawn = { map: "cabinet", x: 6, y: 5, dir: "up", name: "au Cabinet" };
  save();
  return true;
}

/** Applies a checkpoint then reloads the page straight into the game. */
export function jumpTo(id) {
  if (!applyCheckpoint(id)) return;
  try { sessionStorage.setItem(GO_KEY, "1"); } catch { /* storage unavailable */ }
  location.reload();
}

/** True once, right after jumpTo() reloaded the page. */
export function consumeJump() {
  try {
    const go = sessionStorage.getItem(GO_KEY) === "1";
    sessionStorage.removeItem(GO_KEY);
    return go;
  } catch { return false; }
}

// ---------------------------------------------------------------- title screen
const TAPS_TO_TOGGLE = 5;
const TAP_WINDOW_MS = 2500;

/** Tapping `el` 5 times quickly toggles debug mode; `onToggle(on)` is called after. */
export function watchTitleTaps(el, onToggle) {
  let taps = [];
  el.addEventListener("click", () => {
    const now = Date.now();
    taps = [...taps.filter((t) => now - t < TAP_WINDOW_MS), now];
    if (taps.length < TAPS_TO_TOGGLE) return;
    taps = [];
    const on = !debugEnabled();
    setDebugEnabled(on);
    onToggle(on);
  });
}

// ---------------------------------------------------------------- in-game menu tab
const onOff = (k) => (state.flags[k] ? "ON" : "OFF");

export function debugTabHtml() {
  const btn = (act, label, sub) => `<button class="row dbg" data-dbg="${act}" style="width:100%;text-align:left;cursor:pointer;font:inherit;color:inherit;background:rgba(255,255,255,0.05);border:1px solid rgba(246,236,210,0.2);border-radius:10px"><div class="ic">🛠</div><div><div class="t">${label}</div><div class="s">${sub}</div></div></button>`;
  return btn("levels", "+5 niveaux", "Toute l'équipe gagne 5 niveaux.") +
    btn("heal", "Soigner l'équipe", "PV et statut remis à neuf.") +
    btn("pass", `Passe-partout : ${onOff("debug_pass")}`, "Le premier dino peut utiliser toutes les capacités (Charge, Tranche…).") +
    btn("noenc", `Rencontres dans les herbes : ${state.flags.debug_noenc ? "OFF" : "ON"}`, "Les dinos visibles restent sur la carte.") +
    CHECKPOINTS.map((c) => btn(`cp:${c.id}`, `Aller à : ${c.label}`, c.sub)).join("");
}

/** Runs a debug action; returns a short message to show. */
export function runDebugAction(act) {
  if (act === "levels") {
    state.party = state.party.map((d) => {
      const up = createDino(d.build, Math.min(MAX_LEVEL, d.level + 5), d.nickname);
      return { ...up, hp: up.hp };
    });
    return "Équipe montée de 5 niveaux.";
  }
  if (act === "heal") { state.party.forEach(heal); return "Équipe soignée."; }
  if (act === "pass") { state.flags.debug_pass = !state.flags.debug_pass; return `Passe-partout ${onOff("debug_pass")}.`; }
  if (act === "noenc") { state.flags.debug_noenc = !state.flags.debug_noenc; return `Rencontres ${state.flags.debug_noenc ? "désactivées" : "activées"}.`; }
  if (act.startsWith("cp:") && confirm("Aller à ce point de l'histoire ? Ta partie reste sauvegardée : tu joueras dans la partie débug.")) jumpTo(act.slice(3));
  return "";
}
