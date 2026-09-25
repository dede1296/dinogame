// Rolls the wild dino met in a zone's tall grass.

import { DINOS } from "../../../src/data/dinos.js";
import { createDino } from "./dino.js";
import { HYBRID_RATE } from "../data/encounters.js";

const indexOf = (name) => DINOS.findIndex((d) => d.name.startsWith(name));

function pickWeighted(table, rng) {
  const total = table.reduce((s, [, w]) => s + w, 0);
  let r = rng() * total;
  for (const row of table) { r -= row[1]; if (r <= 0) return row; }
  return table[0];
}

export function rollWild(table, rng = Math.random) {
  const [species, , [lo, hi]] = pickWeighted(table, rng);
  const idx = indexOf(species);
  const level = lo + Math.floor(rng() * (hi - lo + 1));
  const build = { head: idx, teeth: idx, frontLegs: idx, backLegs: idx, back: idx, tail: idx, color: idx };
  // Rarely, a natural hybrid of the zone's species.
  if (rng() < HYBRID_RATE) {
    for (const k of ["teeth", "back", "tail", "color"]) if (rng() < 0.6) build[k] = indexOf(pickWeighted(table, rng)[0]);
  }
  return createDino(build, level);
}
