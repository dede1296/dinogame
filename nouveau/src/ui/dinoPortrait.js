// Side-view picture of a dino as an <img> source (the same drawing as in the game).

import { buildDino } from "../art/dinoArt.js";

const cache = new Map();

export function portraitSrc(d) {
  const key = `${Object.values(d.build).join("-")}-${d.tint || ""}`;
  if (!cache.has(key)) {
    const { svg } = buildDino(d.build, { id: `p${cache.size}`, customColor: d.tint });
    cache.set(key, `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`);
  }
  return cache.get(key);
}
