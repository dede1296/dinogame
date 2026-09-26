// Debug: pick any species to add at the head of the team (to test Monture, and later
// Nage, Vol…). Only reachable from the debug game's menu.

import { DINOS } from "../../../src/data/dinos.js";
import { state } from "../state/game.js";
import { createDino } from "../battle/dino.js";
import { ABILITIES, hasAbility } from "../data/abilities.js";
import { openScreen, esc } from "./screen.js";
import { portraitSrc } from "./dinoPortrait.js";

const MAX_PARTY = 4;
const DEFAULT_LEVEL = 15;

const pure = (i) => ({ head: i, teeth: i, frontLegs: i, backLegs: i, back: i, tail: i, color: i });
const badges = (i) => Object.entries(ABILITIES).filter(([id]) => hasAbility({ build: pure(i) }, id)).map(([, a]) => a.icon).join("");

/** Puts a new dino of species `i` at the head of the team; returns a message. */
export function giveDebugDino(i) {
  const level = Math.max(DEFAULT_LEVEL, ...state.party.map((d) => d.level));
  const d = createDino(pure(i), level);
  d.dexSpecies = DINOS[i].name;
  const party = [d, ...state.party];
  if (party.length > MAX_PARTY) state.box = [...(state.box || []), ...party.splice(MAX_PARTY)];
  state.party = party;
  return `${DINOS[i].name} (niv. ${level}) rejoint l'équipe en tête.`;
}

export function openDinoPicker(hud) {
  return openScreen(hud, {
    title: "Choisir un dino", icon: "🛠", className: "dex",
    render(body, api) {
      body.innerHTML = `<div class="scr-hint">Il rejoint l'équipe en tête (le 5e part au Cabinet). 💥 Charge · 🗡️ Tranche · 🐾 Monture</div>
        <div class="dgrid">${DINOS.map((sp, i) => `<button class="dcard caught" data-i="${i}"><span class="dnum" style="font-size:15px;opacity:1;letter-spacing:2px">${badges(i)}</span>
          <div class="dpic"><img class="caught" src="${portraitSrc({ build: pure(i) })}" alt=""></div><div class="dname">${esc(sp.name)}</div></button>`).join("")}</div>`;
      body.onclick = (e) => {
        const c = e.target.closest(".dcard");
        if (!c) return;
        api.toast(giveDebugDino(+c.dataset.i));
        api.close();
      };
    },
  });
}
