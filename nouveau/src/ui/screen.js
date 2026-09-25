// Full-screen menus (team, bag, journal…) opened over the game, Pokémon style.
// B (or the ✕ button) closes the top screen; screens can be stacked.

import { play } from "../audio/sounds.js";
import { SCREEN_CSS } from "./screenStyles.js";

let styled = false;

export const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

/**
 * Opens a screen. `render(body, api)` fills it; api = { close, rerender, toast }.
 * Resolves when the screen closes.
 */
export function openScreen(hud, { title, icon = "", className = "", render }) {
  if (!styled) {
    const style = document.createElement("style");
    style.textContent = SCREEN_CSS;
    document.head.appendChild(style);
    styled = true;
  }
  return new Promise((resolve) => {
    const el = document.createElement("div");
    el.className = `scr ${className}`;
    el.innerHTML = `<div class="scr-win" role="dialog" aria-label="${esc(title)}"><header class="scr-head"><h2>${icon ? `<span class="scr-ic">${icon}</span>` : ""}${esc(title)}</h2><button class="scr-x" aria-label="Fermer">✕</button></header><div class="scr-body"></div></div>`;
    const body = el.querySelector(".scr-body");
    const prevAdvance = hud.advance;
    let closed = false;
    const close = () => {
      if (closed) return;
      closed = true;
      play("ui_close", { volume: 0.45 });
      hud.advance = prevAdvance;
      el.remove();
      if (!hud.root.querySelector(".scr")) hud.root.classList.remove("screen-open");
      resolve();
    };
    const api = { close, rerender: () => render(body, api), toast: (t) => hud.toast(t) };
    el.querySelector(".scr-x").addEventListener("click", close);
    // Tapping the dimmed game around the window closes it too.
    el.addEventListener("click", (e) => { if (e.target === el) close(); });
    hud.advance = (btn) => { if (btn === "b") close(); };
    hud.root.appendChild(el);
    hud.root.classList.add("screen-open");
    hud.root.querySelectorAll(".toast").forEach((t) => t.remove());
    play("ui_open", { volume: 0.45 });
    render(body, api);
  });
}

/** Small bottom sheet of choices; resolves with the chosen index or -1. */
export function actionSheet(hud, title, options) {
  return new Promise((resolve) => {
    const el = document.createElement("div");
    el.className = "scr-sheet";
    el.innerHTML = `<div class="scr-sheet-box"><div class="scr-sheet-t">${esc(title)}</div>${options.map((o, i) => `<button data-i="${i}" ${o.disabled ? "disabled" : ""}>${esc(o.label)}${o.sub ? `<small>${esc(o.sub)}</small>` : ""}</button>`).join("")}<button data-i="-1" class="cancel">Annuler</button></div>`;
    const prevAdvance = hud.advance;
    const done = (i) => { hud.advance = prevAdvance; el.remove(); resolve(i); };
    el.addEventListener("click", (e) => {
      if (e.target === el) return done(-1);
      const b = e.target.closest("button");
      if (!b || b.disabled) return;
      play(+b.dataset.i < 0 ? "ui_back" : "ui_ok", { volume: 0.45 });
      done(+b.dataset.i);
    });
    hud.advance = (btn) => { if (btn === "b") { play("ui_back", { volume: 0.45 }); done(-1); } };
    hud.root.appendChild(el);
    el.querySelector("button:not([disabled])")?.focus();
  });
}

/** HP bar colour, like Pokémon: green, then yellow, then red. */
export function hpColor(ratio) {
  if (ratio > 0.5) return "linear-gradient(90deg, #22c55e, #4ade80)";
  if (ratio > 0.2) return "linear-gradient(90deg, #f59e0b, #fcd34d)";
  return "linear-gradient(90deg, #ef4444, #f87171)";
}
