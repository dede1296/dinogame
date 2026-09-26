// Dinodex screen, like the Pokédex: a numbered grid of every species.
// Unseen: an egg and the name (tap for hints). Seen: faded picture. Caught: full colour.

import { DINOS } from "../../../src/data/dinos.js";
import { FAMILY_TYPES } from "../../../src/game/types.js";
import { computeStats } from "../../../src/game/stats.js";
import { dexStatus, dexInfo, dexCounts, dexHints, formatNumber } from "../data/dex.js";
import { play } from "../audio/sounds.js";
import { openScreen, esc } from "./screen.js";
import { portraitSrc } from "./dinoPortrait.js";
import { typeTag, matchups } from "./partyScreen.js";
import { artImg, artUrl } from "./art.js";

const FAMILY_NAMES = {
  tyrant: "Grand prédateur", raptor: "Raptor", ceratopsian: "Cératopsien", sauropod: "Sauropode", armored: "Cuirassé",
  spino: "Spinosauridé", hadrosaur: "Hadrosaure", flyer: "Ptérosaure", marine: "Reptile marin",
};
const RARITY_NAMES = { rare: "Rare", epic: "Mystérieux", legendary: "Légendaire" };
const FILTERS = [["all", "Tous"], ["seen", "Vus"], ["caught", "Possédés"]];

const pureDino = (i) => ({ build: { head: i, teeth: i, frontLegs: i, backLegs: i, back: i, tail: i, color: i } });
const when = (t) => new Date(t).toLocaleDateString("fr-FR", { day: "numeric", month: "long" });

function picture(i, status, cls = "") {
  if (status === "unseen") return `<img class="egg ${cls}" src="${artUrl("oeuf")}" alt="">`;
  return `<img class="${status} ${cls}" src="${portraitSrc(pureDino(i))}" alt="">`;
}

function card(sp, i) {
  const status = dexStatus(sp.name);
  return `<button class="dcard ${status}" data-i="${i}" aria-label="${esc(sp.name)}">
    <span class="dnum">${formatNumber(i + 1)}</span>${status === "caught" ? `<span class="dball">${artImg("collier", "✓")}</span>` : ""}
    <div class="dpic">${picture(i, status)}</div><div class="dname">${esc(sp.name)}</div></button>`;
}

export function openDex(hud) {
  let filter = "all";
  return openScreen(hud, {
    title: "Dinodex", icon: artImg("dex", "📖"), className: "dex",
    render(body, api) {
      const { seen, caught, total } = dexCounts();
      const list = DINOS.map((sp, i) => ({ sp, i })).filter(({ sp }) => filter === "all" || (filter === "seen" ? dexStatus(sp.name) !== "unseen" : dexStatus(sp.name) === "caught"));
      body.innerHTML = `
        <div class="dex-count"><span>Vus <b>${seen}</b></span><span>Possédés <b>${caught}</b></span><span class="of">sur ${total}</span></div>
        <div class="pockets">${FILTERS.map(([id, label]) => `<button data-f="${id}" class="${id === filter ? "on" : ""}">${label}</button>`).join("")}</div>
        <div class="dgrid">${list.map(({ sp, i }) => card(sp, i)).join("") || `<div class="scr-empty">Rien ici pour l'instant.</div>`}</div>`;
      body.onclick = async (e) => {
        const f = e.target.closest("[data-f]");
        if (f) { filter = f.dataset.f; play("ui_move", { volume: 0.4 }); return api.rerender(); }
        const c = e.target.closest(".dcard");
        if (c) await openEntry(hud, +c.dataset.i);
      };
    },
  });
}

function openEntry(hud, i) {
  const sp = DINOS[i];
  const status = dexStatus(sp.name);
  const { seen, caught } = dexInfo(sp.name);
  const type = FAMILY_TYPES[sp.family];
  return openScreen(hud, {
    title: `Dinodex ${formatNumber(i + 1)}`, className: "dex-entry",
    render(body) {
      const badge = { unseen: "🥚 Pas encore vu", seen: "👁️ Vu", caught: "✅ Possédé" }[status];
      const top = `<div class="sum-top dex-top"><div class="dex-big">${picture(i, status)}</div>
        <div><h3>${esc(sp.name)}</h3><div class="sp">${badge}</div>
        ${status !== "unseen" ? `${typeTag(type)}<div class="sp" style="margin-top:6px">${FAMILY_NAMES[sp.family] || ""} · ${esc(sp.era)}${sp.rarity ? ` · ${RARITY_NAMES[sp.rarity] || ""}` : ""}</div>` : `<div class="sp">Un œuf mystérieux… Trouve cette espèce pour en savoir plus.</div>`}</div></div>`;
      const log = status === "unseen" ? "" : `<div class="sum-sec"><h4>Carnet</h4>
        <div class="ms">Vu pour la première fois ${seen?.place ? `: ${esc(seen.place)}, ` : ""}le ${when(seen.at)}${seen.count > 1 ? ` · croisé ${seen.count} fois` : ""}.</div>
        ${caught ? `<div class="ms">Possédé depuis le ${when(caught.at)}${caught.place ? ` (${esc(caught.place)})` : ""}.</div>` : ""}</div>`;
      const hints = status === "caught" ? "" : `<div class="sum-sec"><h4>Où le trouver</h4>${dexHints(sp.name).map((h) => `<div class="ms">• ${esc(h)}</div>`).join("")}</div>`;
      body.innerHTML = top + log + (status !== "unseen" ? typesSection(type) : "") + (status === "caught" ? statsSection(i) : "") + hints;
    },
  });
}

function typesSection(t) {
  const { strong, weak, resists } = matchups(t);
  const tags = (list) => list.map(typeTag).join("") || "—";
  return `<div class="sum-sec"><h4>Forces et faiblesses</h4>
    <div class="ms">Super efficace contre : ${tags(strong)}</div>
    <div class="ms">Craint : ${tags(weak)}</div>
    <div class="ms">Résiste à : ${tags(resists)}</div></div>`;
}

// Base stats of the pure species (0–10 scale in the species data).
const STAT_SCALE = 10;
function statsSection(i) {
  const b = computeStats(pureDino(i).build);
  const rows = [["Attaque", b.attaque], ["Défense", b.defense], ["Vitesse", b.vitesse], ["Force", b.force], ["Taille", b.taille]];
  return `<div class="sum-sec"><h4>Statistiques de base</h4>${rows.map(([label, v]) => `<div class="stat"><span>${label}</span><b>${Math.round(v)}</b><div class="bar"><i style="width:${Math.min(100, (v / STAT_SCALE) * 100)}%"></i></div></div>`).join("")}</div>`;
}
