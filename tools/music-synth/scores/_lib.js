// Small helpers for writing scores (README.md § Partition).

/** `item` (a "line" item such as "Bb2:1") `n` times, separated by spaces. */
export const rep = (item, n) => Array.from({ length: n }, () => item).join(" ");

/** Bars joined with " | ". */
export const bars = (...b) => b.join(" | ");

/** A rest line of `n` bars of `spb` steps. */
export const rests = (n, spb) => bars(...Array.from({ length: n }, () => `r:${spb}`));

// ---------------------------------------------------------------- leitmotifs of the game's music
// (written in their original keys and octaves; a layer's `transpose` moves them)
export const MOTIFS = {
  // titre.ogg — Chloé's theme (D major, eighth-note steps, 8 per bar): phrases A1, A2, B1, B2.
  chloeA1: "F#5:4 E5:2 D5:2 | E5:2 F#5:2 B4:4 | D5:4 E5:2 D5:1 B4:1 | C#5:4 A4:4",
  chloeA2: "F#5:4 E5:2 D5:2 | C#5:2 D5:2 A5:4 | G5:2 F#5:2 E5:2 D5:2 | E5:6 r:2",
  chloeB1: "D5:2 B4:2 F#5:4 | G5:2 F#5:2 D5:2 B4:2 | A4:3 D5:3 F#5:2 | E5:4 C#5:2 A4:2",
  chloeB2: "B4:2 D5:2 F#5:2 B5:2 | A5:2 G5:2 F#5:2 D5:2 | E5:4 D5:2 E5:2 | C#5:6 r:2",
  // ombre.ogg — the Ombre Noire (E phrygian): its head.
  ombre: "E5:3 B4:3 E5:1 F5:1 | G5:2 F5:2 E5:2 C5:2",
  // rivale.ogg — Maïa (D major): its head.
  maia: "A5:2 F#5:1 A5:2 F#5:1 D5:2 | B5:2 G5:1 B5:2 D6:3",
  // alpha.ogg — the Alphas and the giants (D minor): its head.
  alpha: "D5:4 A4:4 | Bb4:3 C5:1 D5:4 | E5:4 G5:4 | F5:2 E5:2 D5:4",
  // repos.ogg — rest at home (F major, music box).
  repos: "A5:2 C6:2 F6:2 E6:2 | G5:2 C6:2 E6:4 | F6:8",
  // The Cabinet of the Phaser version (G major / C lydian, music box): Hélène's house.
  cabinet: "E6:4 D6:2 B5:2 | A5:4 F#5:4 | G5:2 B5:2 E6:4 | F#6:8",
};
