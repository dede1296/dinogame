// Title screen: main menu (Continue, New game, Load, Settings), save slots and debug.

import { SLOTS, slotInfo, deleteSlot, hasSave } from "../state/game.js";
import { getVolume, setVolume, play } from "../audio/sounds.js";
import { getCryVolume, setCryVolume, playCry } from "../audio/cries.js";
import { getVoiceVolume, setVoiceVolume, blip } from "../audio/voices.js";
import { speciesIndex } from "../story/scripts.js";
import { debugEnabled, watchTitleTaps, CHECKPOINTS, jumpTo } from "../debug/debug.js";
import { VERSION, VERSION_LABEL } from "../version.js";

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
const slotName = (s) => (s === "debug" ? "Partie débug" : `Partie ${s}`);
const parseSlot = (v) => (v === "debug" ? "debug" : +v);

function chapterOf(flags = {}) {
  if (flags.tronc_coupe) return "Chapitre 2";
  return flags.starter ? "Chapitre 1" : "Prologue";
}

function describe(info) {
  const lead = info.lead ? `${esc(info.lead.nickname)} · Niv. ${info.lead.level}${info.count > 1 ? ` · ${info.count} dinos` : ""}` : "Pas encore de dino";
  const date = info.savedAt ? new Date(info.savedAt).toLocaleDateString("fr-FR", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) : "";
  return { line: `${chapterOf(info.flags)} · ${lead}`, date };
}

// The most recently saved real slot (debug excluded), or null.
function lastSlot() {
  let best = null;
  for (const s of SLOTS) {
    const info = slotInfo(s);
    if (info && (!best || (info.savedAt || 0) > best.savedAt)) best = { slot: s, savedAt: info.savedAt || 0 };
  }
  return best?.slot ?? null;
}

function slotCard(s, mode) {
  const info = slotInfo(s);
  if (!info) return `<button class="slot empty" data-slot="${s}"><b>${slotName(s)}</b><small>Vide${mode === "new" ? " — commencer ici" : ""}</small></button>`;
  const { line, date } = describe(info);
  const del = mode === "load" ? `<span class="del" data-del="${s}" role="button" aria-label="Effacer ${slotName(s)}">🗑</span>` : "";
  return `<button class="slot" data-slot="${s}"><b>${slotName(s)}</b><small>${line}</small><small>${date}</small>${del}</button>`;
}

const back = `<button class="back" data-go="main">← Retour</button>`;

const SCREENS = {
  main() {
    const last = lastSlot();
    const cont = last ? `<button class="primary" id="btn-continue" data-slot="${last}">Continuer<small>${slotName(last)} · ${describe(slotInfo(last)).line}</small></button>` : "";
    const anySave = SLOTS.some((s) => hasSave(s)) || (debugEnabled() && hasSave("debug"));
    return cont +
      `<button class="${last ? "" : "primary"}" id="btn-new" data-go="new">Nouvelle partie</button>` +
      `<button id="btn-load" data-go="load" ${anySave ? "" : "disabled"}>Charger une partie</button>` +
      `<button id="btn-settings" data-go="settings">Réglages</button>` +
      (debugEnabled() ? `<button class="debug" id="btn-debug" data-go="debug">🛠 Mode débug</button>` : "");
  },
  new() {
    return `<h2>Nouvelle partie</h2><p class="hint">Choisis un emplacement. Une partie existante serait effacée.</p>` +
      SLOTS.map((s) => slotCard(s, "new")).join("") + back;
  },
  load() {
    const cards = SLOTS.filter((s) => hasSave(s)).map((s) => slotCard(s, "load"));
    if (debugEnabled() && hasSave("debug")) cards.push(slotCard("debug", "load"));
    return `<h2>Charger une partie</h2>` + (cards.join("") || `<p class="hint">Aucune partie sauvegardée.</p>`) + back;
  },
  settings() {
    return `<h2>Réglages</h2>
      <div class="setting"><label for="vol">🔊 Effets sonores <output id="vol-out">${Math.round(getVolume() * 100)} %</output></label>
        <input id="vol" type="range" min="0" max="100" step="5" value="${Math.round(getVolume() * 100)}"></div>
      <div class="setting"><label for="cryvol">🦖 Cris des dinos <output id="cryvol-out">${Math.round(getCryVolume() * 100)} %</output></label>
        <input id="cryvol" type="range" min="0" max="100" step="5" value="${Math.round(getCryVolume() * 100)}"></div>
      <div class="setting"><label for="voicevol">🗣️ Voix des personnages <output id="voicevol-out">${Math.round(getVoiceVolume() * 100)} %</output></label>
        <input id="voicevol" type="range" min="0" max="100" step="5" value="${Math.round(getVoiceVolume() * 100)}"></div>
      <div class="setting"><b>🎮 Commandes</b>
        <small><b>A</b> (Espace / Entrée) : parler, fouiller, valider</small>
        <small><b>B</b> (Échap) : retour, annuler</small>
        <small><b>Maintenir B</b> (ou Maj) : courir</small>
        <small><b>☰</b> (M) : menu du jeu</small></div>` + back;
  },
  debug() {
    return `<h2>🛠 Mode débug</h2><p class="hint">Partie séparée : tes 3 sauvegardes ne sont pas touchées.</p>` +
      CHECKPOINTS.map((c) => `<button class="slot" data-cp="${c.id}"><b>${c.label}</b><small>${c.sub}</small></button>`).join("") + back;
  },
};

/** Builds the title screen menu; `onPick(slot, isNew)` starts the game. */
export function setupTitle(title, onPick) {
  const menu = title.querySelector("#menu");
  title.querySelector("#version").textContent = `Version ${VERSION} · ${VERSION_LABEL}`;
  const show = (screen) => {
    menu.dataset.screen = screen;
    menu.innerHTML = SCREENS[screen]();
    menu.querySelector("button:not([disabled])")?.focus({ preventScroll: true });
  };

  menu.addEventListener("click", (e) => {
    const del = e.target.closest("[data-del]");
    if (del) {
      e.stopPropagation();
      const s = parseSlot(del.dataset.del);
      if (confirm(`Effacer la ${slotName(s).toLowerCase()} ? C'est définitif.`)) { deleteSlot(s); show("load"); }
      return;
    }
    const b = e.target.closest("button");
    if (!b || b.disabled) return;
    play("ui_ok", { volume: 0.5 });
    if (b.dataset.go) return show(b.dataset.go);
    if (b.dataset.cp) return jumpTo(b.dataset.cp);
    if (b.dataset.slot) {
      const s = parseSlot(b.dataset.slot);
      const isNew = menu.dataset.screen === "new";
      if (isNew && hasSave(s) && !confirm(`Remplacer la ${slotName(s).toLowerCase()} par une nouvelle partie ?`)) return;
      onPick(s, isNew || !hasSave(s));
    }
  });
  menu.addEventListener("input", (e) => {
    if (e.target.id === "vol") setVolume(e.target.value / 100);
    else if (e.target.id === "cryvol") setCryVolume(e.target.value / 100);
    else if (e.target.id === "voicevol") setVoiceVolume(e.target.value / 100);
    else return;
    menu.querySelector(`#${e.target.id}-out`).textContent = `${e.target.value} %`;
  });
  // Let the player hear the new level: a click for the effects, a raptor call for the cries.
  menu.addEventListener("change", (e) => {
    if (e.target.id === "vol") play("ui_ok", { volume: 0.6 });
    if (e.target.id === "voicevol") [0, 70, 140].forEach((ms) => setTimeout(() => blip("Maïa"), ms));
    if (e.target.id === "cryvol") { const i = speciesIndex("Velociraptor"); playCry({ head: i, teeth: i, frontLegs: i, backLegs: i, back: i, tail: i, color: i }); }
  });

  // Hidden: 5 quick taps on the logo toggle debug mode.
  watchTitleTaps(title.querySelector("h1"), (on) => {
    show("main");
    alert(on ? "Mode débug activé" : "Mode débug désactivé");
  });
  show("main");
}
