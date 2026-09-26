// Shiny ("chromatique") dinos, like shiny Pokémon: a rare alternative colouring.

import { DINOS } from "../../../src/data/dinos.js";

// About one wild dino in 40: with the visible dinos on each map, a few per chapter.
export const SHINY_RATE = 1 / 40;

// The species' colour turned round the colour wheel and made brighter.
const HUE_SHIFT = 150;

/** Colour of the shiny form of the species at `speciesIdx`. */
export function shinyColor(speciesIdx) {
  const hex = DINOS[speciesIdx]?.color || "#888888";
  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);
  const max = Math.max(r, g, b), min = Math.min(r, g, b), l = (max + min) / 2, d = max - min;
  let h = 0;
  if (d) h = max === r ? ((g - b) / d) % 6 : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
  const hue = (h * 60 + HUE_SHIFT + 360) % 360;
  const sat = Math.min(0.85, (d ? d / (1 - Math.abs(2 * l - 1)) : 0) + 0.25);
  const light = Math.min(0.62, Math.max(0.42, l + 0.08));
  return hsl(hue, sat, light);
}

function hsl(h, s, l) {
  const c = (1 - Math.abs(2 * l - 1)) * s, x = c * (1 - Math.abs(((h / 60) % 2) - 1)), m = l - c / 2;
  const [r, g, b] = h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x] : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x];
  return `#${[r, g, b].map((v) => Math.round((v + m) * 255).toString(16).padStart(2, "0")).join("")}`;
}

/** Makes `d` shiny (its colour follows its colour part's species). */
export function makeShiny(d) {
  d.shiny = true;
  d.tint = shinyColor(d.build.color);
  return d;
}
