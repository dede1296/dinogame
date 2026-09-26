// Team screen, Pokémon style: one card per dino (picture, level, HP, type, status).
// Tap a dino: Summary, Move (reorder, the first one follows Chloé), or give a Fern.

import { state } from "../state/game.js";
import { statsOf, typeOf, xpToNext, fernHeal } from "../battle/dino.js";
import { MOVES, TYPE_COLORS, TYPE_NAMES } from "../battle/moves.js";
import { STATUS } from "../battle/engine.js";
import { ABILITIES, hasAbility } from "../data/abilities.js";
import { TYPE_CHART, TYPE_EMOJI } from "../../../src/game/types.js";
import { play } from "../audio/sounds.js";
import { openScreen, actionSheet, esc, hpColor } from "./screen.js";
import { portraitSrc } from "./dinoPortrait.js";
import { artImg } from "./art.js";

// Tinted pill: the type colour as text and border over a faint wash of it.
const pill = (color, text) => `<span class="tag" style="color:${color};background:${color}26;border:1px solid ${color}59">${text}</span>`;
export const typeTag = (t) => pill(TYPE_COLORS[t], `${TYPE_EMOJI[t] || ""} ${TYPE_NAMES[t].toUpperCase()}`);
const statusTag = (d) => (d.status ? pill("#e8d8b0", `${STATUS[d.status.id].icon} ${STATUS[d.status.id].name.toUpperCase()}`) : "");

export function hpBar(d) {
  const max = statsOf(d).hp, ratio = Math.max(0, d.hp / max);
  return `<div class="hpbar">PV<div class="bar"><i style="width:${ratio * 100}%;background:${hpColor(ratio)}"></i></div></div><div class="hpnum">${d.hp} / ${max}</div>`;
}

function card(d, i, pickFrom) {
  const cls = ["pcard", i === 0 ? "lead" : "", d.hp <= 0 ? "ko" : "", pickFrom === i ? "pick" : ""].join(" ");
  return `<button class="${cls}" data-i="${i}">
    <div class="pic"><img src="${portraitSrc(d)}" alt=""></div>
    <div><div class="nm">${esc(d.nickname)}<small>Niv. ${d.level}</small></div>
      <div class="sp">${esc(d.speciesName)}${i === 0 ? `<span class="lead-badge">En tête</span>` : ""}</div>
      ${typeTag(typeOf(d.build))}${statusTag(d)}${d.hp <= 0 ? pill("#f87171", "K.O.") : ""}
      ${hpBar(d)}</div></button>`;
}

/** Opens the team screen. Resolves when closed. */
export function openParty(hud) {
  let pickFrom = null; // index of the dino being moved, if any
  return openScreen(hud, {
    title: "Équipe", icon: artImg("equipe", "🦖"), className: "party",
    render(body, api) {
      if (!state.party.length) {
        body.innerHTML = `<div class="scr-empty">Tu n'as pas encore de dino.<br>Va voir le Professeur Roc au Cabinet.</div>`;
        return;
      }
      body.innerHTML = state.party.map((d, i) => card(d, i, pickFrom)).join("") +
        `<div class="scr-hint">${pickFrom !== null ? `Choisis la place de ${esc(state.party[pickFrom].nickname)}.` : "Le premier dino de la liste te suit et combat en premier."}</div>` +
        (state.box?.length ? `<div class="scr-hint">${state.box.length} dino(s) en pension au Cabinet.</div>` : "");
      body.onclick = async (e) => {
        const b = e.target.closest(".pcard");
        if (!b) return;
        const i = +b.dataset.i;
        if (pickFrom !== null) {
          if (i !== pickFrom) {
            const party = [...state.party];
            [party[pickFrom], party[i]] = [party[i], party[pickFrom]];
            state.party = party;
            play("ui_ok", { volume: 0.5 });
          }
          pickFrom = null;
          return api.rerender();
        }
        await dinoActions(hud, i, api, (from) => { pickFrom = from; api.rerender(); });
      };
    },
  });
}

async function dinoActions(hud, i, api, startMove) {
  const d = state.party[i];
  const max = statsOf(d).hp;
  const ferns = state.bag.fougere || 0;
  const choice = await actionSheet(hud, `${d.nickname} · Niv. ${d.level}`, [
    { label: "Résumé", sub: "Stats, attaques, forces et faiblesses" },
    { label: "Changer de place", sub: "Le premier te suit et combat en premier", disabled: state.party.length < 2 },
    { label: `Donner une Fougère curative (${ferns})`, sub: d.hp <= 0 ? "Trop épuisé : va te reposer" : d.hp >= max ? "PV déjà au maximum" : "Rend 40 % des PV", disabled: !ferns || d.hp <= 0 || d.hp >= max },
  ]);
  if (choice === 0) await openSummary(hud, d);
  if (choice === 1) startMove(i);
  if (choice === 2) {
    state.bag = { ...state.bag, fougere: ferns - 1 };
    const { amount, curedBleeding } = fernHeal(d);
    play("item", { volume: 0.5 });
    api.toast(`${d.nickname} récupère ${amount} PV.${curedBleeding ? " Le saignement s'arrête." : ""}`);
  }
  api.rerender();
}

// Types this dino's own type hits hard, and the types that hit it hard.
export function matchups(t) {
  const strong = Object.keys(TYPE_CHART[t] || {}).filter((x) => TYPE_CHART[t][x] > 1);
  const weak = Object.keys(TYPE_CHART).filter((a) => (TYPE_CHART[a][t] || 1) > 1);
  const resists = Object.keys(TYPE_CHART).filter((a) => (TYPE_CHART[a][t] || 1) < 1);
  return { strong, weak, resists };
}

const STAT_MAX_SHOWN = 200;

export function openSummary(hud, d) {
  return openScreen(hud, {
    title: d.nickname, icon: "📋", className: "summary",
    render(body) {
      const t = typeOf(d.build), s = statsOf(d), { strong, weak, resists } = matchups(t);
      const tags = (list) => list.map(typeTag).join("") || "—";
      const stat = (label, v) => `<div class="stat"><span>${label}</span><b>${v}</b><div class="bar"><i style="width:${Math.min(100, (v / STAT_MAX_SHOWN) * 100)}%"></i></div></div>`;
      const moves = d.moves.map((m) => {
        const mv = MOVES[m.id];
        const detail = mv.power ? `Puissance ${mv.power} · Précision ${Math.round(mv.accuracy * 100)} %` : `Attaque de statut · Précision ${Math.round(mv.accuracy * 100)} %`;
        const extra = [mv.priority ? "Frappe en premier" : "", mv.crit ? "Coups critiques fréquents" : "", mv.desc && !mv.priority ? mv.desc : ""].filter(Boolean).join(" · ");
        return `<div class="move" style="--c:${TYPE_COLORS[mv.type]}"><div class="mt">${esc(mv.name)} ${typeTag(mv.type)}</div><div class="ms">${detail} · PP ${m.pp ?? mv.pp}/${mv.pp}</div>${extra ? `<div class="ms">${esc(extra)}</div>` : ""}</div>`;
      }).join("");
      const abil = Object.entries(ABILITIES).filter(([id]) => hasAbility(d, id)).map(([, a]) => `<div class="ms">${a.icon} <b>${a.name}</b> — ${esc(a.desc)}</div>`).join("");
      body.innerHTML = `
        <div class="sum-top"><img src="${portraitSrc(d)}" alt="">
          <div><h3>${esc(d.nickname)}</h3><div class="sp">${esc(d.speciesName)} · Niv. ${d.level}</div>${typeTag(t)}${statusTag(d)}${hpBar(d)}
          <div class="hpnum">Expérience : ${d.xp} / ${xpToNext(d.level)}</div></div></div>
        <div class="sum-sec"><h4>Statistiques</h4>${stat("PV max", s.hp)}${stat("Attaque", s.atk)}${stat("Défense", s.def)}${stat("Vitesse", s.spd)}</div>
        <div class="sum-sec"><h4>Forces et faiblesses</h4>
          <div class="ms">Ses attaques ${TYPE_NAMES[t]} sont <b>super efficaces</b> contre : ${tags(strong)}</div>
          <div class="ms" style="margin-top:6px">Il <b>craint</b> les attaques : ${tags(weak)}</div>
          <div class="ms" style="margin-top:6px">Il <b>résiste</b> aux attaques : ${tags(resists)}</div>
          <div class="ms" style="margin-top:6px;opacity:0.7">Super efficace = ×1,5 · Peu efficace = ×0,7 · Neutre = ×1</div></div>
        <div class="sum-sec"><h4>Attaques</h4>${moves}</div>
        ${abil ? `<div class="sum-sec"><h4>Exploration</h4>${abil}</div>` : ""}`;
    },
  });
}
