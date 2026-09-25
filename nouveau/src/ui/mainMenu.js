// The ☰ menu, like Pokémon's Start menu: a list on the right side of the screen.

import { state, save } from "../state/game.js";
import { JOURNAL } from "../data/items.js";
import { debugEnabled, debugTabHtml, runDebugAction } from "../debug/debug.js";
import { openScreen, esc } from "./screen.js";
import { openParty } from "./partyScreen.js";
import { openBag } from "./bagScreen.js";

const ENTRIES = [
  { id: "party", icon: "🦖", label: "Équipe" },
  { id: "bag", icon: "🎒", label: "Sac" },
  { id: "journal", icon: "📜", label: "Journal" },
  { id: "save", icon: "💾", label: "Sauvegarder" },
  { id: "home", icon: "🏠", label: "Accueil" },
];

export function openMainMenu(hud) {
  return openScreen(hud, {
    title: "Menu", className: "mainmenu",
    render(body, api) {
      const entries = debugEnabled() ? [...ENTRIES, { id: "debug", icon: "🛠", label: "Débug" }] : ENTRIES;
      body.innerHTML = entries.map((e) => `<button class="mm${e.id === "home" ? " home" : ""}" data-m="${e.id}"><span>${e.icon}</span>${e.label}</button>`).join("");
      body.querySelector(".mm")?.focus();
      body.onclick = async (ev) => {
        const id = ev.target.closest("[data-m]")?.dataset.m;
        if (id === "party") await openParty(hud);
        if (id === "bag") await openBag(hud);
        if (id === "journal") await openJournal(hud);
        if (id === "debug") await openDebug(hud);
        if (id === "save") api.toast(save() ? "Partie sauvegardée !" : "Sauvegarde impossible : le stockage du navigateur est indisponible.");
        if (id === "home" && confirm("Revenir à l'écran d'accueil ? Ta partie sera sauvegardée.")) { save(); location.reload(); }
      };
    },
  });
}

function openJournal(hud) {
  return openScreen(hud, {
    title: "Journal d'Hélène", icon: "📜",
    render(body) {
      if (!state.journal.length) {
        body.innerHTML = `<div class="scr-empty">Aucune page trouvée. Les pages du journal d'Hélène sont cachées partout sur l'île.</div>`;
        return;
      }
      body.innerHTML = [...state.journal].sort((a, b) => a - b)
        .map((n) => `<div class="page"><h3>Page ${n} — ${esc(JOURNAL[n].title)}</h3>${esc(JOURNAL[n].text)}</div>`).join("") +
        `<div class="scr-hint">${state.journal.length} page(s) sur 40</div>`;
    },
  });
}

function openDebug(hud) {
  return openScreen(hud, {
    title: "Débug", icon: "🛠",
    render(body, api) {
      body.innerHTML = debugTabHtml();
      body.onclick = (e) => {
        const b = e.target.closest("[data-dbg]");
        if (!b) return;
        const msg = runDebugAction(b.dataset.dbg);
        api.rerender();
        if (msg) api.toast(msg);
      };
    },
  });
}
