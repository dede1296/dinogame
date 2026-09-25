// DOM overlay for battles: info cards, HP/XP bars, command menus, battle messages.

import { MOVES, TYPE_COLORS, TYPE_NAMES } from "../battle/moves.js";
import { statsOf, typeOf, xpToNext } from "../battle/dino.js";
import { STATUS } from "../battle/engine.js";
import { ITEMS } from "../data/items.js";

const CSS = `
.bhud { position: fixed; inset: 0; z-index: 6; pointer-events: none; font-family: system-ui, -apple-system, "Segoe UI", sans-serif; color: #f6ecd2; }
.bhud * { box-sizing: border-box; }
.card { position: absolute; width: min(250px, 58vw); padding: 9px 12px 10px; border-radius: 14px; background: linear-gradient(180deg, rgba(34,30,20,0.94), rgba(20,18,12,0.94)); border: 2px solid #c9953a; box-shadow: 0 6px 18px rgba(0,0,0,0.45); transition: opacity 0.3s, transform 0.3s; }
.card.hidden { opacity: 0; transform: translateY(-8px); }
.card.foe { left: 12px; top: calc(14px + env(safe-area-inset-top)); }
.card.me { right: 12px; bottom: calc(318px + env(safe-area-inset-bottom)); width: min(230px, 52vw); }
.card .top { display: flex; justify-content: space-between; align-items: baseline; gap: 6px; }
.card .nm { font-weight: 800; font-size: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.card .lv { font-size: 12px; font-weight: 700; color: #f2c14e; white-space: nowrap; }
.card .tags { display: flex; gap: 4px; margin: 4px 0 5px; }
.card .tag { font-size: 10px; font-weight: 800; padding: 1px 7px; border-radius: 8px; color: #1a1208; letter-spacing: 0.5px; }
.bar { height: 9px; border-radius: 5px; background: rgba(0,0,0,0.5); overflow: hidden; border: 1px solid rgba(0,0,0,0.6); }
.bar > div { height: 100%; width: 100%; border-radius: 4px; transition: width 0.6s ease, background-color 0.6s; }
.hp > div { background: #4cc46a; }
.hp.mid > div { background: #e8c23a; } .hp.low > div { background: #e2503a; }
.hpnum { font-size: 12px; text-align: right; margin-top: 3px; font-variant-numeric: tabular-nums; opacity: 0.9; }
.xp { height: 5px; margin-top: 4px; } .xp > div { background: #5aa8e8; }
.bpanel { position: absolute; left: 0; right: 0; bottom: 0; padding: 12px 12px calc(14px + env(safe-area-inset-bottom)); background: linear-gradient(180deg, rgba(20,18,12,0), rgba(20,18,12,0.92) 18%); pointer-events: auto; }
.bmsg { min-height: 62px; padding: 12px 16px; border-radius: 14px; background: rgba(34,30,20,0.96); border: 2px solid #c9953a; font-size: 17px; line-height: 1.4; margin-bottom: 10px; }
.bgrid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.bgrid button { padding: 11px 10px; border-radius: 12px; font: 800 16px system-ui, sans-serif; color: #f6ecd2; background: rgba(46,40,28,0.97); border: 2px solid #6b5530; text-align: left; display: flex; flex-direction: column; gap: 2px; }
.bgrid button small { font-weight: 600; font-size: 11px; opacity: 0.75; }
.bgrid button:disabled { opacity: 0.4; }
.bgrid button.act { border-color: #f2c14e; }
.bgrid .mv { border-left-width: 8px; }
.bback { margin-top: 8px; width: 100%; padding: 10px; border-radius: 12px; background: transparent; border: 2px solid #6b5530; color: #f6ecd2; font: 700 14px system-ui; }
`;

export class BattleHud {
  constructor() {
    const style = document.createElement("style");
    style.textContent = CSS;
    document.head.appendChild(style);
    this.root = document.createElement("div");
    this.root.className = "bhud";
    this.root.innerHTML = `
      <div class="card foe hidden"><div class="top"><span class="nm"></span><span class="lv"></span></div><div class="tags"></div><div class="bar hp"><div></div></div></div>
      <div class="card me hidden"><div class="top"><span class="nm"></span><span class="lv"></span></div><div class="tags"></div><div class="bar hp"><div></div></div><div class="hpnum"></div><div class="bar xp"><div></div></div></div>
      <div class="bpanel"><div class="bmsg"></div><div class="bmenu"></div></div>`;
    document.body.appendChild(this.root);
    this.msgEl = this.root.querySelector(".bmsg");
    this.menuEl = this.root.querySelector(".bmenu");
    this.skip = null;
    this.root.querySelector(".bmsg").addEventListener("click", () => this.skip?.());
    this.keyHandler = (e) => {
      if (e.key === " " || e.key === "Enter") { if (this.skip) { this.skip(); e.preventDefault(); } }
    };
    window.addEventListener("keydown", this.keyHandler);
  }

  destroy() {
    window.removeEventListener("keydown", this.keyHandler);
    this.root.remove();
  }

  // ---------------------------------------------------------------- cards
  showCard(side, dino) {
    const el = this.root.querySelector(`.card.${side === "player" ? "me" : "foe"}`);
    el.classList.remove("hidden");
    el.querySelector(".nm").textContent = side === "player" ? dino.nickname : dino.speciesName;
    el.querySelector(".lv").textContent = `Niv. ${dino.level}`;
    this.updateTags(side, dino);
    this.setHp(side, dino.hp, statsOf(dino).hp, true);
    if (side === "player") this.setXp(dino, true);
  }

  hideCard(side) {
    this.root.querySelector(`.card.${side === "player" ? "me" : "foe"}`).classList.add("hidden");
  }

  updateTags(side, dino) {
    const el = this.root.querySelector(`.card.${side === "player" ? "me" : "foe"} .tags`);
    const t = typeOf(dino.build);
    el.innerHTML = `<span class="tag" style="background:${TYPE_COLORS[t]}">${TYPE_NAMES[t].toUpperCase()}</span>` +
      (dino.status ? `<span class="tag" style="background:#e8d8b0">${STATUS[dino.status.id].icon} ${STATUS[dino.status.id].name}</span>` : "");
  }

  setHp(side, hp, max, instant = false) {
    const card = this.root.querySelector(`.card.${side === "player" ? "me" : "foe"}`);
    const bar = card.querySelector(".hp"), fill = bar.firstElementChild;
    if (instant) fill.style.transition = "none";
    const r = Math.max(0, hp / max);
    fill.style.width = `${r * 100}%`;
    bar.classList.toggle("mid", r <= 0.5 && r > 0.2);
    bar.classList.toggle("low", r <= 0.2);
    if (instant) { void fill.offsetWidth; fill.style.transition = ""; }
    const num = card.querySelector(".hpnum");
    if (num) num.textContent = `${Math.max(0, hp)} / ${max} PV`;
  }

  setXp(dino, instant = false) {
    const fill = this.root.querySelector(".card.me .xp > div");
    if (instant) fill.style.transition = "none";
    fill.style.width = `${Math.min(100, (dino.xp / xpToNext(dino.level)) * 100)}%`;
    if (instant) { void fill.offsetWidth; fill.style.transition = ""; }
    this.root.querySelector(".card.me .lv").textContent = `Niv. ${dino.level}`;
  }

  // ---------------------------------------------------------------- messages
  message(text, { hold = 900 } = {}) {
    this.menuEl.innerHTML = "";
    return new Promise((resolve) => {
      let i = 0, timer = null, done = false, holdTimer = null;
      const finish = () => { clearInterval(timer); this.msgEl.textContent = text; done = true; holdTimer = setTimeout(end, hold); };
      const end = () => { clearTimeout(holdTimer); this.skip = null; resolve(); };
      this.skip = () => (done ? end() : finish());
      timer = setInterval(() => {
        i += 2;
        this.msgEl.textContent = text.slice(0, i);
        if (i >= text.length) finish();
      }, 18);
    });
  }

  // ---------------------------------------------------------------- menus
  menu(buttons, { back } = {}) {
    return new Promise((resolve) => {
      this.menuEl.innerHTML = `<div class="bgrid"></div>${back ? `<button class="bback">← Retour</button>` : ""}`;
      const grid = this.menuEl.querySelector(".bgrid");
      buttons.forEach((b, i) => {
        const el = document.createElement("button");
        el.innerHTML = b.html;
        if (b.style) el.setAttribute("style", b.style);
        if (b.className) el.className = b.className;
        el.disabled = !!b.disabled;
        el.addEventListener("click", () => resolve(i));
        grid.appendChild(el);
      });
      if (back) this.menuEl.querySelector(".bback").addEventListener("click", () => resolve(-1));
    });
  }

  async chooseAction(dino, bag, canCatch) {
    for (;;) {
      this.msgEl.textContent = `Que doit faire ${dino.nickname} ?`;
      const top = await this.menu([
        { html: "⚔️ Attaque", className: "act" },
        { html: "🎒 Sac" },
        { html: "🦖 Équipe" },
        { html: "🏃 Fuite" },
      ]);
      if (top === 0) {
        const i = await this.menu(dino.moves.map((m) => {
          const mv = MOVES[m.id];
          return {
            html: `${mv.name}<small>${TYPE_NAMES[mv.type]} · ${mv.power ? `Puiss. ${mv.power}` : "Effet"} · PP ${m.pp}/${mv.pp}</small>`,
            className: "mv",
            style: `border-left-color:${TYPE_COLORS[mv.type]}`,
            disabled: m.pp <= 0,
          };
        }), { back: true });
        if (i >= 0) return { type: "move", index: i };
      } else if (top === 1) {
        const items = ["fougere", "baie", ...(canCatch ? ["collier"] : [])].filter((id) => bag[id] > 0);
        if (!items.length) { await this.message("Le sac est vide.", { hold: 500 }); continue; }
        const i = await this.menu(items.map((id) => ({ html: `${ITEMS[id].icon} ${ITEMS[id].name}<small>×${bag[id]}</small>` })), { back: true });
        if (i >= 0) return { type: "item", item: items[i] };
      } else if (top === 2) {
        return { type: "team" };
      } else {
        return { type: "run" };
      }
    }
  }

  chooseDino(team, activeIndex, { forced = false } = {}) {
    this.msgEl.textContent = forced ? "Choisis le prochain dino !" : "Quel dino envoyer ?";
    return this.menu(team.map((d, i) => ({
      html: `${d.nickname}<small>Niv. ${d.level} · ${d.hp}/${statsOf(d).hp} PV${i === activeIndex ? " · au combat" : ""}</small>`,
      disabled: d.hp <= 0 || i === activeIndex,
    })), { back: !forced });
  }
}
