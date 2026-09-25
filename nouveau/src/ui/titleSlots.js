// Title screen: the three save slots (plus the debug slot when debug mode is on).

import { SLOTS, slotInfo, deleteSlot, hasSave } from "../state/game.js";
import { debugEnabled } from "../debug/debug.js";

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

function chapterOf(flags = {}) {
  if (flags.tronc_coupe) return "Chapitre 2";
  return flags.starter ? "Chapitre 1" : "Prologue";
}

function cardHtml(slot, label) {
  const info = slotInfo(slot);
  const del = info ? `<span class="del" data-del="${slot}" role="button" aria-label="Effacer">🗑</span>` : "";
  if (!info) return `<button class="slot empty" data-slot="${slot}"><b>${label}</b><small>Vide — nouvelle partie</small></button>`;
  const lead = info.lead ? `${esc(info.lead.nickname)} · Niv. ${info.lead.level}${info.count > 1 ? ` · ${info.count} dinos` : ""}` : "Pas encore de dino";
  const date = info.savedAt ? new Date(info.savedAt).toLocaleDateString("fr-FR", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) : "";
  return `<button class="slot" data-slot="${slot}"><b>${label}</b><small>${chapterOf(info.flags)} · ${lead}</small><small>${date}</small>${del}</button>`;
}

/** Shows the slots; `onPick(slot, isNew)` starts the game. */
export function renderSlots(container, onPick) {
  const draw = () => {
    container.innerHTML = SLOTS.map((s) => cardHtml(s, `Partie ${s}`)).join("") +
      (debugEnabled() && hasSave("debug") ? cardHtml("debug", "🛠 Partie débug") : "");
  };
  container.addEventListener("click", (e) => {
    const del = e.target.closest("[data-del]");
    if (del) {
      e.stopPropagation();
      const s = del.dataset.del === "debug" ? "debug" : +del.dataset.del;
      if (confirm(`Effacer la ${s === "debug" ? "partie débug" : `partie ${s}`} ? C'est définitif.`)) { deleteSlot(s); draw(); }
      return;
    }
    const card = e.target.closest("[data-slot]");
    if (!card) return;
    const s = card.dataset.slot === "debug" ? "debug" : +card.dataset.slot;
    onPick(s, !hasSave(s));
  });
  draw();
}
