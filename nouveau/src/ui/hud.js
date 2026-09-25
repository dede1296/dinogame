// DOM overlay on top of the game canvas: touch controls, dialogue, choices,
// notifications and menus. Text lives in the DOM so it stays crisp on every screen.

import { state, save } from "../state/game.js";
import { ITEMS, JOURNAL, FOSSIL_PARTS } from "../data/items.js";

const CSS = `
.hud { position: fixed; inset: 0; z-index: 5; pointer-events: none; font-family: system-ui, -apple-system, "Segoe UI", sans-serif; color: #f6ecd2; user-select: none; -webkit-user-select: none; }
.hud * { box-sizing: border-box; }
.hud button { font: inherit; color: inherit; }
.pad { position: absolute; left: 16px; bottom: calc(18px + env(safe-area-inset-bottom)); width: 150px; height: 150px; pointer-events: auto; touch-action: none; }
.pad div { position: absolute; width: 52px; height: 52px; border-radius: 14px; background: rgba(20,24,16,0.55); border: 2px solid rgba(246,236,210,0.25); display: grid; place-items: center; font-size: 20px; backdrop-filter: blur(4px); }
.pad div.on { background: rgba(232,160,32,0.55); border-color: #f2c14e; }
.pad .u { left: 49px; top: 0; } .pad .d { left: 49px; bottom: 0; } .pad .l { left: 0; top: 49px; } .pad .r { right: 0; top: 49px; }
.btns { position: absolute; right: 16px; bottom: calc(26px + env(safe-area-inset-bottom)); width: 140px; height: 120px; pointer-events: auto; touch-action: none; }
.btns div { position: absolute; border-radius: 50%; display: grid; place-items: center; font-weight: 800; background: rgba(20,24,16,0.55); border: 2px solid rgba(246,236,210,0.3); backdrop-filter: blur(4px); }
.btns .a { width: 68px; height: 68px; right: 0; top: 0; font-size: 22px; border-color: #f2c14e; color: #f2c14e; }
.btns .b { width: 54px; height: 54px; left: 4px; bottom: 0; font-size: 18px; }
.btns div.on { background: rgba(232,160,32,0.6); color: #1a1208; }
.menubtn { position: absolute; right: 14px; top: calc(12px + env(safe-area-inset-top)); pointer-events: auto; width: 46px; height: 46px; border-radius: 12px; background: rgba(20,24,16,0.6); border: 2px solid rgba(246,236,210,0.25); font-size: 22px; display: grid; place-items: center; }
.dialog { position: absolute; left: 50%; transform: translateX(-50%); bottom: calc(190px + env(safe-area-inset-bottom)); width: min(560px, calc(100% - 24px)); min-height: 96px; padding: 16px 18px 20px; border-radius: 16px; background: linear-gradient(180deg, rgba(34,30,20,0.95), rgba(20,18,12,0.95)); border: 2px solid #c9953a; box-shadow: 0 10px 30px rgba(0,0,0,0.5); pointer-events: auto; font-size: 17px; line-height: 1.45; white-space: pre-line; }
.dialog .name { position: absolute; top: -14px; left: 16px; padding: 3px 12px; border-radius: 10px; background: #c9953a; color: #1a1208; font-weight: 800; font-size: 13px; letter-spacing: 0.5px; }
.dialog .more { position: absolute; right: 14px; bottom: 6px; font-size: 13px; color: #f2c14e; animation: bob 0.8s ease-in-out infinite; }
@keyframes bob { 50% { transform: translateY(3px); } }
.choices { position: absolute; right: max(12px, calc(50% - 280px)); bottom: calc(300px + env(safe-area-inset-bottom)); display: flex; flex-direction: column; gap: 6px; pointer-events: auto; }
.choices button { min-width: 170px; padding: 11px 16px; border-radius: 12px; text-align: left; background: rgba(34,30,20,0.96); border: 2px solid #6b5530; font-size: 16px; }
.choices button:hover, .choices button:focus { border-color: #f2c14e; outline: none; }
.toast { position: absolute; left: 50%; top: calc(70px + env(safe-area-inset-top)); transform: translateX(-50%); padding: 10px 18px; border-radius: 12px; background: rgba(20,18,12,0.92); border: 2px solid #c9953a; font-weight: 700; animation: toast 2.6s ease forwards; white-space: nowrap; }
@keyframes toast { 0% { opacity: 0; transform: translate(-50%, -10px); } 10%, 85% { opacity: 1; transform: translate(-50%, 0); } 100% { opacity: 0; } }
.banner { position: absolute; left: 16px; top: calc(14px + env(safe-area-inset-top)); padding: 8px 16px 8px 12px; border-left: 4px solid #f2c14e; background: linear-gradient(90deg, rgba(20,18,12,0.85), rgba(20,18,12,0)); font-weight: 800; font-size: 18px; letter-spacing: 0.5px; animation: banner 3.2s ease forwards; }
.banner small { display: block; font-weight: 500; font-size: 12px; opacity: 0.7; letter-spacing: 1px; text-transform: uppercase; }
@keyframes banner { 0% { opacity: 0; transform: translateX(-20px); } 12%, 80% { opacity: 1; transform: none; } 100% { opacity: 0; } }
.overlay { position: absolute; inset: 0; background: rgba(8,10,6,0.82); backdrop-filter: blur(6px); pointer-events: auto; display: flex; flex-direction: column; padding: calc(16px + env(safe-area-inset-top)) 16px calc(16px + env(safe-area-inset-bottom)); }
.overlay h2 { margin: 4px 0 12px; font-size: 20px; color: #f2c14e; letter-spacing: 1px; }
.tabs { display: flex; gap: 6px; margin-bottom: 12px; flex-wrap: wrap; }
.tabs button { padding: 9px 14px; border-radius: 10px; background: rgba(255,255,255,0.06); border: 2px solid transparent; font-weight: 700; }
.tabs button.on { border-color: #f2c14e; color: #f2c14e; }
.panel { flex: 1; overflow-y: auto; -webkit-overflow-scrolling: touch; }
.row { display: flex; gap: 12px; align-items: center; padding: 12px; border-radius: 12px; background: rgba(255,255,255,0.05); margin-bottom: 8px; }
.row .ic { font-size: 26px; width: 34px; text-align: center; }
.row .t { font-weight: 700; } .row .s { font-size: 13px; opacity: 0.7; }
.page { padding: 16px; border-radius: 12px; background: #efe2c2; color: #3a2a18; margin-bottom: 10px; font-family: Georgia, serif; white-space: pre-line; line-height: 1.5; }
.page h3 { margin: 0 0 8px; font-size: 17px; }
.close { margin-top: 12px; padding: 13px; border-radius: 12px; background: #c9953a; color: #1a1208; font-weight: 800; border: none; font-size: 16px; }
.empty { opacity: 0.6; font-style: italic; padding: 12px; }
.fade { position: absolute; inset: 0; background: #000; opacity: 0; transition: opacity 0.35s; pointer-events: none; }
.fade.on { opacity: 1; }
.hud.busy .pad, .hud.busy .btns .b { opacity: 0.35; }
`;

const KEYS = { ArrowUp: "up", ArrowDown: "down", ArrowLeft: "left", ArrowRight: "right", z: "up", w: "up", s: "down", q: "left", a: "left", d: "right" };

class Hud {
  constructor() {
    this.dirStack = [];
    this.handlers = { a: [], b: [], menu: [] };
    this.busy = false;
    this.advance = null;
  }

  init() {
    const style = document.createElement("style");
    style.textContent = CSS;
    document.head.appendChild(style);
    this.root = document.createElement("div");
    this.root.className = "hud";
    this.root.innerHTML = `
      <div class="fade"></div>
      <div class="pad"><div class="u">▲</div><div class="l">◀</div><div class="r">▶</div><div class="d">▼</div></div>
      <div class="btns"><div class="a">A</div><div class="b">B</div></div>
      <button class="menubtn" aria-label="Menu">☰</button>`;
    document.body.appendChild(this.root);
    this.fadeEl = this.root.querySelector(".fade");
    this.bindPad();
    this.bindButtons();
    this.bindKeys();
  }

  // ---------------------------------------------------------------- input
  get dir() {
    return this.busy ? null : this.dirStack[this.dirStack.length - 1] || null;
  }

  pressDir(d) { if (!this.dirStack.includes(d)) this.dirStack.push(d); }
  releaseDir(d) { this.dirStack = this.dirStack.filter((x) => x !== d); }

  bindPad() {
    const pad = this.root.querySelector(".pad");
    const map = { u: "up", d: "down", l: "left", r: "right" };
    let current = null;
    const pick = (e) => {
      const t = e.touches ? e.touches[0] : e;
      if (!t) return null;
      const r = pad.getBoundingClientRect();
      const dx = t.clientX - (r.left + r.width / 2), dy = t.clientY - (r.top + r.height / 2);
      if (Math.hypot(dx, dy) < 14) return null;
      return Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? "right" : "left") : dy > 0 ? "down" : "up";
    };
    const set = (d) => {
      if (current) this.releaseDir(current);
      current = d;
      if (d) this.pressDir(d);
      pad.querySelectorAll("div").forEach((el) => el.classList.toggle("on", map[el.className.split(" ")[0]] === d));
    };
    const move = (e) => { e.preventDefault(); set(pick(e)); };
    pad.addEventListener("touchstart", move, { passive: false });
    pad.addEventListener("touchmove", move, { passive: false });
    pad.addEventListener("touchend", (e) => { e.preventDefault(); set(null); });
    pad.addEventListener("mousedown", (e) => { set(pick(e)); const up = () => { set(null); window.removeEventListener("mouseup", up); }; window.addEventListener("mouseup", up); });
  }

  bindButtons() {
    const hook = (el, name) => {
      const fire = (e) => { e.preventDefault(); el.classList.add("on"); this.fire(name); };
      el.addEventListener("touchstart", fire, { passive: false });
      el.addEventListener("mousedown", fire);
      const off = () => el.classList.remove("on");
      el.addEventListener("touchend", off);
      el.addEventListener("mouseup", off);
      el.addEventListener("mouseleave", off);
    };
    hook(this.root.querySelector(".btns .a"), "a");
    hook(this.root.querySelector(".btns .b"), "b");
    this.root.querySelector(".menubtn").addEventListener("click", () => this.fire("menu"));
  }

  bindKeys() {
    window.addEventListener("keydown", (e) => {
      const d = KEYS[e.key] || KEYS[e.key.toLowerCase?.()];
      if (d) { this.pressDir(d); e.preventDefault(); return; }
      if (e.repeat) return;
      if (e.key === " " || e.key === "Enter") { this.fire("a"); e.preventDefault(); }
      else if (e.key === "Escape" || e.key === "Backspace") this.fire("b");
      else if (e.key === "m" || e.key === "Tab") { this.fire("menu"); e.preventDefault(); }
    });
    window.addEventListener("keyup", (e) => {
      const d = KEYS[e.key] || KEYS[e.key.toLowerCase?.()];
      if (d) this.releaseDir(d);
    });
    window.addEventListener("blur", () => { this.dirStack = []; });
  }

  on(name, fn) { this.handlers[name].push(fn); }

  fire(name) {
    // A dialogue or menu currently open consumes the press.
    if (this.advance && (name === "a" || name === "b")) { this.advance(name); return; }
    if (this.busy) return;
    for (const fn of this.handlers[name]) fn();
  }

  setBusy(b) {
    this.busy = b;
    this.root.classList.toggle("busy", b);
  }

  // ---------------------------------------------------------------- dialogue
  say(name, text) {
    return new Promise((resolve) => {
      const box = document.createElement("div");
      box.className = "dialog";
      box.innerHTML = `${name ? `<div class="name"></div>` : ""}<span class="txt"></span><span class="more" hidden>▼</span>`;
      if (name) box.querySelector(".name").textContent = name;
      this.root.appendChild(box);
      const txt = box.querySelector(".txt"), more = box.querySelector(".more");
      let i = 0, done = false;
      const timer = setInterval(() => {
        i += 2;
        txt.textContent = text.slice(0, i);
        if (i >= text.length) finish();
      }, 22);
      const finish = () => { clearInterval(timer); txt.textContent = text; done = true; more.hidden = false; };
      const next = () => {
        if (!done) { finish(); return; }
        this.advance = null;
        box.remove();
        resolve();
      };
      this.advance = next;
      box.addEventListener("click", next);
    });
  }

  choose(options) {
    return new Promise((resolve) => {
      const box = document.createElement("div");
      box.className = "choices";
      options.forEach((label, i) => {
        const b = document.createElement("button");
        b.textContent = label;
        b.addEventListener("click", () => { this.advance = null; box.remove(); resolve(i); });
        box.appendChild(b);
      });
      this.root.appendChild(box);
      // A picks the first option, B the last (usually "Non" / "Annuler").
      this.advance = (btn) => {
        this.advance = null;
        box.remove();
        resolve(btn === "a" ? 0 : options.length - 1);
      };
      box.querySelector("button").focus();
    });
  }

  toast(text) {
    const t = document.createElement("div");
    t.className = "toast";
    t.textContent = text;
    this.root.appendChild(t);
    setTimeout(() => t.remove(), 2700);
  }

  banner(title, subtitle = "") {
    this.root.querySelector(".banner")?.remove();
    const b = document.createElement("div");
    b.className = "banner";
    b.innerHTML = `<small></small><span></span>`;
    b.querySelector("small").textContent = subtitle;
    b.querySelector("span").textContent = title;
    this.root.appendChild(b);
    setTimeout(() => b.remove(), 3300);
  }

  fade(on) {
    this.fadeEl.classList.toggle("on", on);
    return new Promise((r) => setTimeout(r, 360));
  }

  // ---------------------------------------------------------------- menu
  openMenu() {
    return new Promise((resolve) => {
      const ov = document.createElement("div");
      ov.className = "overlay";
      ov.innerHTML = `<h2>MENU</h2>
        <div class="tabs"><button data-t="party" class="on">Équipe</button><button data-t="bag">Sac</button><button data-t="journal">Journal</button><button data-t="save">Sauvegarder</button></div>
        <div class="panel"></div><button class="close">Fermer</button>`;
      const panel = ov.querySelector(".panel");
      const show = (tab) => {
        ov.querySelectorAll(".tabs button").forEach((b) => b.classList.toggle("on", b.dataset.t === tab));
        panel.innerHTML = this.renderTab(tab);
        if (tab === "save") {
          const ok = save();
          panel.innerHTML = `<div class="row"><div class="ic">${ok ? "💾" : "⚠️"}</div><div><div class="t">${ok ? "Partie sauvegardée" : "Sauvegarde impossible"}</div><div class="s">${ok ? new Date().toLocaleString("fr-FR") : "Le stockage du navigateur est indisponible."}</div></div></div>`;
        }
      };
      ov.querySelectorAll(".tabs button").forEach((b) => b.addEventListener("click", () => show(b.dataset.t)));
      const close = () => { this.advance = null; ov.remove(); resolve(); };
      ov.querySelector(".close").addEventListener("click", close);
      this.advance = (btn) => { if (btn === "b") close(); };
      this.root.appendChild(ov);
      show("party");
    });
  }

  renderTab(tab) {
    const esc = (s) => String(s).replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c]));
    if (tab === "party") {
      if (!state.party.length) return `<div class="empty">Tu n'as pas encore de dino. Va voir le Professeur Roc au Cabinet.</div>`;
      return state.party.map((d) => `<div class="row"><div class="ic">🦖</div><div><div class="t">${esc(d.nickname)}</div><div class="s">${esc(d.speciesName)} · Niv. ${d.level}</div></div></div>`).join("");
    }
    if (tab === "bag") {
      const rows = Object.entries(state.bag).filter(([, q]) => q > 0).map(([id, q]) => {
        const it = ITEMS[id];
        return `<div class="row"><div class="ic">${it.icon}</div><div><div class="t">${esc(it.name)} ×${q}</div><div class="s">${esc(it.desc)}</div></div></div>`;
      });
      if (state.amber.length) rows.push(`<div class="row"><div class="ic">🟠</div><div><div class="t">Fragments d'ambre (${state.amber.length})</div><div class="s">${state.amber.map(esc).join(", ")}</div></div></div>`);
      if (state.fossils.length) rows.push(`<div class="row"><div class="ic">🦴</div><div><div class="t">Fossiles (${state.fossils.length}/5)</div><div class="s">${state.fossils.map((p) => FOSSIL_PARTS[p]).join(", ")}</div></div></div>`);
      rows.push(`<div class="row"><div class="ic">🪙</div><div><div class="t">${state.money} pièces</div></div></div>`);
      return rows.join("");
    }
    if (tab === "journal") {
      if (!state.journal.length) return `<div class="empty">Aucune page trouvée. Les pages du journal d'Hélène sont cachées partout sur l'île.</div>`;
      return [...state.journal].sort((a, b) => a - b).map((n) => `<div class="page"><h3>Page ${n} — ${esc(JOURNAL[n].title)}</h3>${esc(JOURNAL[n].text)}</div>`).join("") + `<div class="empty">${state.journal.length} page(s) sur 40</div>`;
    }
    return "";
  }
}

export const hud = new Hud();
