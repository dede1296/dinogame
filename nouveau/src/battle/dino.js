// Dino instances: stats from parts and level, experience, move learning.

import { DINOS } from "../../../src/data/dinos.js";
import { computeStats } from "../../../src/game/stats.js";
import { FAMILY_TYPES } from "../../../src/game/types.js";
import { MOVES, learnset } from "./moves.js";

export const MAX_LEVEL = 50;
export const MAX_MOVES = 4;

export const typeOf = (build) => FAMILY_TYPES[DINOS[build.head]?.family] || "terre";

// Battle stats. Part stats are ~1..10; they scale with level like Pokémon base stats.
export function statsOf(d) {
  const b = computeStats(d.build);
  const L = d.level;
  return {
    hp: Math.floor(((b.defense + b.taille) * 2.2 + 14) * L / 12) + L + 12,
    atk: Math.floor((b.attaque * 2 + b.force) * L / 12) + 6,
    def: Math.floor((b.defense * 2 + b.taille) * L / 12) + 6,
    spd: Math.floor((b.vitesse * 3) * L / 12) + 5,
  };
}

// Experience needed to go from `level` to `level + 1`.
export const xpToNext = (level) => Math.floor(10 + level * level * 1.6);

// Experience given by beating `foe`.
export function xpReward(foe, trainer = false) {
  return Math.floor((18 + foe.level * 7) * (trainer ? 1.5 : 1));
}

function movesAtLevel(build, level) {
  const known = learnset(build, DINOS).filter((m) => m.level <= level);
  return known.slice(-MAX_MOVES).map(({ id }) => ({ id, pp: MOVES[id].pp }));
}

export function speciesName(build) {
  const head = DINOS[build.head].name;
  const pure = Object.values(build).every((v) => v === build.head);
  return pure ? head : `${head} hybride`;
}

export function createDino(build, level, nickname) {
  const d = { build: { ...build }, level, xp: 0, nickname: nickname || speciesName(build), speciesName: speciesName(build), status: null };
  d.moves = movesAtLevel(build, level);
  d.hp = statsOf(d).hp;
  return d;
}

// Upgrades dinos saved by older versions of the game (no moves / hp yet).
export function normalizeDino(d) {
  if (!d.moves) d.moves = movesAtLevel(d.build, d.level);
  if (d.hp === undefined) d.hp = statsOf(d).hp;
  if (d.xp === undefined) d.xp = 0;
  if (!d.speciesName) d.speciesName = speciesName(d.build);
  if (d.status === undefined) d.status = null;
  return d;
}

export function heal(d) {
  d.hp = statsOf(d).hp;
  d.status = null;
  for (const m of d.moves) m.pp = MOVES[m.id].pp;
}

/**
 * Adds experience; returns the list of events it caused:
 * { type: "level", level } and { type: "learn", move, replaced }.
 */
export function gainXp(d, amount) {
  const events = [];
  d.xp += amount;
  while (d.level < MAX_LEVEL && d.xp >= xpToNext(d.level)) {
    d.xp -= xpToNext(d.level);
    const before = statsOf(d).hp;
    d.level += 1;
    d.hp += statsOf(d).hp - before;
    events.push({ type: "level", level: d.level });
    for (const m of learnset(d.build, DINOS).filter((x) => x.level === d.level)) {
      if (d.moves.some((k) => k.id === m.id)) continue;
      let replaced = null;
      if (d.moves.length >= MAX_MOVES) {
        // Forget the weakest attack to make room.
        const weakest = d.moves.reduce((w, k) => (MOVES[k.id].power < MOVES[w.id].power ? k : w));
        replaced = weakest.id;
        d.moves = d.moves.filter((k) => k !== weakest);
      }
      d.moves.push({ id: m.id, pp: MOVES[m.id].pp });
      events.push({ type: "learn", move: m.id, replaced });
    }
  }
  if (d.level >= MAX_LEVEL) d.xp = 0;
  return events;
}

// How hard a species is to catch: exclusives and big dinos resist more.
export function catchDifficulty(build) {
  const head = DINOS[build.head];
  if (head.rarity === "legendary") return 0.25;
  if (head.rarity === "epic") return 0.4;
  if (head.rarity === "rare") return 0.55;
  return head.head.size >= 8 ? 0.7 : 0.9;
}
