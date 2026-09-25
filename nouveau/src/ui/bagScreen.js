// Bag screen, Pokémon style: pockets (Care, Capture, Treasures), item details, "Use".

import { state } from "../state/game.js";
import { statsOf, fernHeal } from "../battle/dino.js";
import { ITEMS, FOSSIL_PARTS } from "../data/items.js";
import { play } from "../audio/sounds.js";
import { openScreen, actionSheet, esc } from "./screen.js";
import { artImg } from "./art.js";

// Illustration name for each bag entry (the grouped treasures reuse an item picture).
const artOf = (id) => ({ _ambre: "ambre", _fossiles: "fossile" }[id] || id);

const POCKETS = [
  { id: "soins", icon: "🌿", name: "Soins", items: ["fougere", "baie"] },
  { id: "capture", icon: "📿", name: "Capture", items: ["collier"] },
  { id: "tresors", icon: "💎", name: "Trésors", items: null }, // everything else
];
const LISTED = new Set(POCKETS.flatMap((p) => p.items || []));

// How each item can be used outside battle.
const USE_HINT = {
  fougere: null, // usable here
  baie: "Se croque pendant un combat : augmente l'attaque de ton dino.",
  collier: "Se lance pendant un combat sur un dino sauvage affaibli.",
};

function entries(pocket) {
  const owned = Object.entries(state.bag).filter(([, q]) => q > 0);
  if (pocket.items) return owned.filter(([id]) => pocket.items.includes(id)).map(([id, q]) => ({ id, q, ...ITEMS[id] }));
  const rows = owned.filter(([id]) => !LISTED.has(id) && ITEMS[id]).map(([id, q]) => ({ id, q, ...ITEMS[id] }));
  if (state.amber.length) rows.push({ id: "_ambre", q: state.amber.length, icon: "🟠", name: "Fragments d'ambre", desc: `ADN de : ${state.amber.join(", ")}. L'hybrideur du Cabinet permet de greffer ces espèces.` });
  if (state.fossils.length) rows.push({ id: "_fossiles", q: state.fossils.length, icon: "🦴", name: "Fossiles", desc: `Parties trouvées (${state.fossils.length}/5) : ${state.fossils.map((p) => FOSSIL_PARTS[p]).join(", ")}.` });
  return rows;
}

export function openBag(hud) {
  let pocket = POCKETS[0].id;
  let selected = null;
  return openScreen(hud, {
    title: "Sac", icon: artImg("sac", "🎒"), className: "bag",
    render(body, api) {
      const p = POCKETS.find((x) => x.id === pocket);
      const list = entries(p);
      if (!list.some((x) => x.id === selected)) selected = list[0]?.id ?? null;
      const cur = list.find((x) => x.id === selected);
      body.innerHTML = `
        <div class="pockets">${POCKETS.map((x) => `<button data-p="${x.id}" class="${x.id === pocket ? "on" : ""}"><span>${x.icon}</span>${x.name}</button>`).join("")}</div>
        ${list.map((x) => `<button class="item ${x.id === selected ? "on" : ""}" data-it="${x.id}"><div class="ic">${artImg(artOf(x.id), x.icon)}</div><div>${esc(x.name)}</div><div class="qty">×${x.q}</div></button>`).join("") || `<div class="scr-empty">Cette poche est vide.</div>`}
        ${cur ? `<div class="item-desc"><div class="big">${artImg(artOf(cur.id), cur.icon)}</div><b>${esc(cur.name)}</b><br>${esc(cur.desc)}${cur.id === "fougere" ? `<button class="btn-main" data-use="fougere">Utiliser sur un dino</button>` : USE_HINT[cur.id] ? `<br><i style="opacity:0.8">${esc(USE_HINT[cur.id])}</i>` : ""}</div>` : ""}
        <div class="money">${artImg("piece", "🪙")} ${state.money} pièces</div>`;
      body.onclick = async (e) => {
        const pk = e.target.closest("[data-p]");
        if (pk) { pocket = pk.dataset.p; selected = null; play("ui_move", { volume: 0.4 }); return api.rerender(); }
        const it = e.target.closest("[data-it]");
        if (it) { selected = it.dataset.it; play("ui_move", { volume: 0.4 }); return api.rerender(); }
        if (e.target.closest("[data-use]")) { await useFern(hud, api); api.rerender(); }
      };
    },
  });
}

async function useFern(hud, api) {
  const opts = state.party.map((d) => {
    const max = statsOf(d).hp;
    return { label: `${d.nickname} · ${d.hp}/${max} PV`, sub: d.hp <= 0 ? "Trop épuisé : va te reposer" : d.hp >= max ? "PV au maximum" : "", disabled: d.hp <= 0 || d.hp >= max };
  });
  const i = await actionSheet(hud, "Soigner quel dino ?", opts);
  if (i < 0) return;
  const d = state.party[i];
  state.bag = { ...state.bag, fougere: (state.bag.fougere || 0) - 1 };
  const { amount, curedBleeding } = fernHeal(d);
  play("item", { volume: 0.5 });
  api.toast(`${d.nickname} récupère ${amount} PV.${curedBleeding ? " Le saignement s'arrête." : ""}`);
}
