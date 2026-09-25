// Color helpers for the vector dino art.

function parse(hex) {
  const n = parseInt(hex.replace("#", ""), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function toHex([r, g, b]) {
  return "#" + [r, g, b].map((v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0")).join("");
}

export function mix(a, b, t) {
  const A = parse(a), B = parse(b);
  return toHex(A.map((v, i) => v + (B[i] - v) * t));
}

export const lighten = (c, t) => mix(c, "#ffffff", t);
export const darken = (c, t) => mix(c, "#000000", t);

// Saturation boost so the muted museum colors of the data read well on screen.
function vivid(hex, amount = 0.35) {
  const [r, g, b] = parse(hex);
  const avg = (r + g + b) / 3;
  return toHex([r, g, b].map((v) => v + (v - avg) * amount));
}

// Palette for one dino, derived from its donor color.
export function makePalette(baseColor, accentColor) {
  const base = vivid(lighten(baseColor, 0.06), 0.14);
  const accent = vivid(accentColor || mix(baseColor, "#c98a2a", 0.45), 0.25);
  return {
    base,
    light: lighten(base, 0.28),
    shade: darken(base, 0.28),
    deep: darken(base, 0.5),
    belly: mix(base, "#e9dbb6", 0.5),
    bellyShade: mix(base, "#b9a276", 0.45),
    outline: mix(base, "#140c08", 0.78),
    accent,
    accentLight: lighten(accent, 0.3),
    accentShade: darken(accent, 0.3),
    claw: "#efe3c2",
    clawShade: "#b9a67c",
    tooth: "#fbf5e4",
    mouth: "#5a1b1b",
    eyeWhite: "#fffbe9",
  };
}
