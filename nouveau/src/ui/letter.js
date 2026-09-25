// A handwritten letter or journal page on illustrated old paper. A / B / tap closes it.

import { play } from "../audio/sounds.js";
import { artUrl } from "./art.js";
import { esc } from "./screen.js";

const CSS = `
.letter { position: absolute; inset: 0; z-index: 4; pointer-events: auto; display: grid; place-items: center; padding: 20px;
  background: rgba(6,8,12,0.55); backdrop-filter: blur(3px); -webkit-backdrop-filter: blur(3px); animation: letter-fade 0.25s ease-out; }
.letter-paper { position: relative; width: min(420px, 100%); aspect-ratio: 3 / 4; max-height: 100%; box-sizing: border-box;
  background: center / 100% 100% no-repeat; padding: 12% 12% 31% 13%; color: #3b2a1a;
  font-family: "Caveat", "Segoe Print", "Bradley Hand", cursive; font-size: clamp(17px, 4.7vw, 21px); line-height: 1.3;
  filter: drop-shadow(0 18px 30px rgba(0,0,0,0.55)); animation: letter-in 0.45s cubic-bezier(0.16, 1, 0.3, 1); overflow: hidden; }
.letter-paper p { margin: 0 0 0.7em; white-space: pre-line; }
.letter-paper .sign { text-align: right; margin-top: 0.4em; }
.letter-hint { position: absolute; bottom: calc(14px + env(safe-area-inset-bottom)); left: 0; right: 0; text-align: center; color: rgba(243,241,236,0.7); font: 600 12.5px system-ui, sans-serif; }
@keyframes letter-fade { from { opacity: 0; } to { opacity: 1; } }
@keyframes letter-in { from { opacity: 0; transform: translateY(24px) rotate(-2deg) scale(0.96); } to { opacity: 1; transform: rotate(-0.6deg); } }
@media (prefers-reduced-motion: reduce) { .letter, .letter-paper { animation: none; } }
`;

let styled = false;

/** Shows `paragraphs` (array of strings) signed by `sign`; resolves when closed. */
export function showLetter(hud, paragraphs, sign = "") {
  if (!styled) {
    const style = document.createElement("style");
    style.textContent = CSS;
    document.head.appendChild(style);
    styled = true;
  }
  return new Promise((resolve) => {
    const el = document.createElement("div");
    el.className = "letter";
    el.innerHTML = `<div class="letter-paper" style="background-image:url('${artUrl("papier")}')">${paragraphs.map((p) => `<p>${esc(p)}</p>`).join("")}${sign ? `<p class="sign">${esc(sign)}</p>` : ""}</div><div class="letter-hint">Touche l'écran ou appuie sur A pour ranger la lettre</div>`;
    const prevAdvance = hud.advance;
    const close = () => { hud.advance = prevAdvance; el.remove(); play("page", { volume: 0.5 }); resolve(); };
    el.addEventListener("click", close);
    hud.advance = close;
    hud.root.appendChild(el);
    play("page", { volume: 0.6 });
  });
}
