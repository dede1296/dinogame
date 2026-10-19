// The music of Ambrelune, played by nouveau/src/audio/music.js.
//
// A theme: `bpm`, `beats` per bar, `sub` steps per beat (2 = eighth notes), `chords`
// (one per bar, the whole loop), and layers:
//   { play: "chords",  inst, oct }                 held chord of each bar
//   { play: "pattern", inst, oct, pat }            chord degrees each step: 1 3 5 7 8 10 12, L5 = fifth below
//   { play: "notes",   inst, notes }               a written tune over the whole loop ("A4", "-" hold, "." rest)
//   { play: "drums",   inst, pat }                 "x" hit, "o" soft hit, "." nothing (pattern repeats)
//   { play: "gen",     inst, oct, density, seed }  a tune generated from the chords (same one every loop)
// Layer options: vol, pan, ring (let plucks ring), legato, every: [1,0] (on which loop
// passes it plays), from (first pass), ride (only while riding a dino), prob.
// Instruments: nouveau/src/audio/instruments.js.
// Theme options: swing (0..0.3), reverb (send level), gain, key + scale (for "gen").

const MAJOR = [0, 2, 4, 5, 7, 9, 11];
const MINOR = [0, 2, 3, 5, 7, 8, 10];
const DORIAN = [0, 2, 3, 5, 7, 9, 10];
const LYDIAN = [0, 2, 4, 6, 7, 9, 11];
const PHRYGIAN_DOM = [0, 1, 4, 5, 7, 8, 10];

export const THEMES = {
  // ------------------------------------------------------------------ title screen
  // "Ambrelune": wistful and adventurous, harp and flute.
  titre: {
    bpm: 84, beats: 4, sub: 2, reverb: 0.45,
    chords: "D Bm G A D F#m G A Bm G D A Bm G Asus4 A",
    layers: [
      { play: "chords", inst: "strings", oct: 3, vol: 0.32 },
      { play: "pattern", inst: "harp", oct: 3, pat: "1 5 8 10 12 10 8 5", vol: 0.42, ring: true },
      { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - 5 - - -", vol: 0.45 },
      { play: "notes", inst: "flute", vol: 0.5, notes: `
        F#5 - - - E5 - D5 - | E5 - F#5 - B4 - - - | D5 - - - E5 - D5 B4 | C#5 - - - A4 - - - |
        F#5 - - - E5 - D5 - | C#5 - D5 - A5 - - - | G5 - F#5 - E5 - D5 - | E5 - - - - - . . |
        D5 - B4 - F#5 - - - | G5 - F#5 - D5 - B4 - | A4 - - D5 - - F#5 - | E5 - - - C#5 - A4 - |
        B4 - D5 - F#5 - B5 - | A5 - G5 - F#5 - D5 - | E5 - - - D5 - E5 - | C#5 - - - - - . . |` },
      { play: "drums", inst: "taiko", pat: "x . . . . . . . | . . . . . . o .", vol: 0.25, from: 1 },
      { play: "drums", inst: "triangle", pat: ". . . . . . . . | . . . . x . . .", vol: 0.5, from: 1 },
    ],
  },

  // ------------------------------------------------------------------ places
  // Port-Ambre: a cheerful little sea shanty in 3/4 (accordion, guitar, kalimba).
  village: {
    bpm: 104, beats: 3, sub: 2, reverb: 0.3,
    chords: "F F C C Bb F C F Dm Am Bb F Gm C F F",
    layers: [
      { play: "pattern", inst: "guitar", oct: 3, pat: "1 . 5 8 10 8", vol: 0.4 },
      { play: "pattern", inst: "bass", oct: 2, pat: "1 - . 5 - .", vol: 0.5 },
      { play: "drums", inst: "shaker", pat: "x . o . o .", vol: 0.5 },
      { play: "notes", inst: "reed", vol: 0.5, every: [1, 1, 0], notes: `
        C5 - - A4 - C5 | F5 - - E5 - D5 | E5 - - G4 - C5 | E5 - - - - - |
        D5 - - F5 - D5 | C5 - - A4 - F4 | G4 - A4 - Bb4 - | A4 - - - - - |
        D5 - E5 - F5 - | E5 - - C5 - - | D5 - C5 - Bb4 - | A4 - - C5 - - |
        Bb4 - A4 - G4 - | C5 - - E5 - G5 | F5 - - C5 - A4 | F4 - - - - - |` },
      { play: "notes", inst: "kalimba", vol: 0.4, every: [0, 0, 1], transpose: 12, notes: `
        C5 - - A4 - C5 | F5 - - E5 - D5 | E5 - - G4 - C5 | E5 - - - - - |
        D5 - - F5 - D5 | C5 - - A4 - F4 | G4 - A4 - Bb4 - | A4 - - - - - |
        D5 - E5 - F5 - | E5 - - C5 - - | D5 - C5 - Bb4 - | A4 - - C5 - - |
        Bb4 - A4 - G4 - | C5 - - E5 - G5 | F5 - - C5 - A4 | F4 - - - - - |` },
    ],
  },

  // Plaines des Fougères: an open, carefree walk. Faster with drums while riding.
  plaines: {
    bpm: 108, beats: 4, sub: 2, reverb: 0.3, key: 7, scale: MAJOR,
    chords: "G D Em C G D C D Em C G D Em C Am D",
    layers: [
      { play: "pattern", inst: "guitar", oct: 3, pat: "1 5 8 5 10 5 8 5", vol: 0.36 },
      { play: "chords", inst: "pad", oct: 3, vol: 0.22 },
      { play: "pattern", inst: "bass", oct: 2, pat: "1 - . 1 5 - 5 .", vol: 0.5 },
      { play: "drums", inst: "shaker", pat: "o . x . o . x .", vol: 0.5 },
      { play: "drums", inst: "kick", pat: "x . . . x . . .", vol: 0.45, ride: true },
      { play: "drums", inst: "snare", pat: ". . x . . . x .", vol: 0.35, ride: true },
      { play: "notes", inst: "flute", vol: 0.5, every: [1, 1, 0], notes: `
        D5 - - B4 D5 - G5 - | F#5 - - E5 D5 - A4 - | B4 - - C5 D5 - E5 - | G5 - - - E5 - - - |
        D5 - - B4 D5 - G5 - | A5 - - G5 F#5 - D5 - | E5 - D5 - C5 - B4 - | A4 - - - - - . . |
        G5 - - F#5 E5 - B4 - | C5 - E5 - G5 - - - | D5 - - B4 G4 - B4 - | A4 - - - F#4 - - - |
        E5 - - F#5 G5 - B5 - | A5 - G5 - E5 - C5 - | C5 - B4 - A4 - C5 - | D5 - - - F#5 - A5 - |` },
      { play: "gen", inst: "kalimba", oct: 5, density: 0.7, seed: 3, vol: 0.38, every: [0, 0, 1] },
    ],
  },

  // The Cabinet: curious and a little mysterious (lydian music box, clockwork ticks).
  cabinet: {
    bpm: 76, beats: 4, sub: 2, reverb: 0.5,
    chords: "Cmaj7 D Cmaj7 D Am7 Em7 Fmaj7 G",
    layers: [
      { play: "chords", inst: "pad", oct: 3, vol: 0.28 },
      { play: "pattern", inst: "harp", oct: 4, pat: "1 . 5 . 8 . 5 .", vol: 0.25, ring: true },
      { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - - - -", vol: 0.35 },
      { play: "drums", inst: "block", pat: "x . . . o . . .", vol: 0.35 },
      { play: "notes", inst: "musicbox", vol: 0.55, notes: `
        E6 - - - D6 - B5 - | A5 - - - F#5 - - - | G5 - B5 - E6 - - - | F#6 - - - - - - - |
        E6 - C6 - A5 - G5 - | B5 - - - G5 - - - | A5 - C6 - E6 - F6 - | D6 - - - B5 - - - |` },
    ],
  },

  // Hélène's house: tender and nostalgic, piano and strings.
  maison: {
    bpm: 70, beats: 4, sub: 2, reverb: 0.45,
    chords: "Am F C G Am F Dm E",
    layers: [
      { play: "chords", inst: "strings", oct: 3, vol: 0.2 },
      { play: "pattern", inst: "piano", oct: 3, pat: "1 5 8 10 8 5 . .", vol: 0.34, ring: true },
      { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - - - -", vol: 0.3 },
      { play: "notes", inst: "piano", vol: 0.55, every: [1, 1, 0], notes: `
        E5 - - - A5 - - G5 | F5 - E5 - C5 - - - | G5 - - - E5 - D5 C5 | D5 - - - B4 - - - |
        C5 - B4 - A4 - E5 - | A5 - - - G5 - F5 - | F5 - E5 - D5 - - A4 | G#4 - - - B4 - - - |` },
    ],
  },

  // Port-Ambre's shop: jaunty and bouncy, marimba and pizzicato.
  boutique: {
    bpm: 116, beats: 4, sub: 2, swing: 0.18, reverb: 0.25,
    chords: "C Am Dm G7 C A7 Dm7 G7",
    layers: [
      { play: "pattern", inst: "pizz", oct: 2, pat: "1 . 5 . 8 . 5 .", vol: 0.6 },
      { play: "chords", inst: "pad", oct: 4, vol: 0.14 },
      { play: "drums", inst: "block", pat: "x . . x . . x .", vol: 0.3 },
      { play: "drums", inst: "shaker", pat: ". . x . . . x .", vol: 0.45 },
      { play: "notes", inst: "marimba", vol: 0.6, notes: `
        E5 . G5 . C6 - G5 . | A5 . G5 . E5 - . . | F5 . A5 . D6 - A5 . | B5 - A5 . G5 - . . |
        E5 . G5 . C6 . E6 . | D6 - C#6 . A5 - . . | F5 . E5 . D5 . F5 . | G5 - - - . . . . |` },
    ],
  },

  // Grotte des Échos: dark and hushed, a choir, a drone and distant bells.
  grotte: {
    bpm: 60, beats: 4, sub: 2, reverb: 0.7, key: 2, scale: MINOR,
    chords: "Dm Dm Bb Bb Gm Gm A A",
    layers: [
      { play: "chords", inst: "choir", oct: 3, vol: 0.3 },
      { play: "pattern", inst: "bass", oct: 1, pat: "1 - - - - - - -", vol: 0.4 },
      { play: "gen", inst: "bell", oct: 5, density: 0.25, seed: 11, vol: 0.3 },
      { play: "drums", inst: "taiko", pat: "x . . . . . . . | . . . . . . . . | . . . . o . . . | . . . . . . . .", vol: 0.18 },
    ],
  },

  // ------------------------------------------------------------------ battles
  // A wild dino: urgent and bright.
  sauvage: {
    bpm: 144, beats: 4, sub: 2, reverb: 0.2,
    chords: "Am F G E Am F Dm E",
    layers: [
      { play: "pattern", inst: "synthbass", oct: 2, pat: "1 1 8 1 1 8 1 5", vol: 0.55 },
      { play: "chords", inst: "strings", oct: 3, vol: 0.2 },
      { play: "pattern", inst: "pizz", oct: 4, pat: "1 5 8 5 1 5 8 5", vol: 0.25 },
      { play: "drums", inst: "kick", pat: "x . . x x . . .", vol: 0.6 },
      { play: "drums", inst: "snare", pat: ". . x . . . x .", vol: 0.5 },
      { play: "drums", inst: "hat", pat: "o o x o o o x o", vol: 0.5 },
      { play: "notes", inst: "lead", vol: 0.45, notes: `
        A5 - - E5 - - A5 B5 | C6 - B5 - A5 - F5 - | G5 - - D5 - - G5 A5 | B5 - - - G#5 - E5 - |
        A5 - - E5 - - A5 B5 | C6 - B5 - C6 - D6 - | E6 - D6 - C6 - A5 - | B5 - - - - - E5 G#5 |` },
    ],
  },

  // The Ombre Noire's masked grunts: sly and menacing.
  ombre: {
    bpm: 132, beats: 4, sub: 2, reverb: 0.25,
    chords: "Em F Em F C B Em B",
    layers: [
      { play: "pattern", inst: "synthbass", oct: 2, pat: "1 . 1 . 1 1 . 1", vol: 0.55 },
      { play: "chords", inst: "brass", oct: 3, vol: 0.2, restrike: true },
      { play: "drums", inst: "kick", pat: "x . . . x . x .", vol: 0.6 },
      { play: "drums", inst: "snare", pat: ". . x . . . x x", vol: 0.45 },
      { play: "drums", inst: "hat", pat: "x o x o x o x o", vol: 0.4 },
      { play: "notes", inst: "lead", vol: 0.42, notes: `
        E5 - - B4 - - E5 F5 | G5 - F5 - E5 - C5 - | E5 - - B4 - - E5 G5 | A5 - G5 - F5 - - - |
        G5 - - E5 - - C5 E5 | F#5 - - D#5 - - B4 - | E5 - G5 - B5 - A5 G5 | F#5 - - - D#5 - B4 - |` },
    ],
  },

  // Maïa, the rival: bouncy, cheeky, full of energy.
  rivale: {
    bpm: 150, beats: 4, sub: 2, reverb: 0.2,
    chords: "D G A D Bm G E A",
    layers: [
      { play: "pattern", inst: "synthbass", oct: 2, pat: "1 . 8 . 1 . 8 5", vol: 0.5 },
      { play: "pattern", inst: "guitar", oct: 3, pat: ". 5 . 8 . 5 . 10", vol: 0.35 },
      { play: "drums", inst: "kick", pat: "x . . . x . . x", vol: 0.6 },
      { play: "drums", inst: "snare", pat: ". . x . . . x .", vol: 0.5 },
      { play: "drums", inst: "hat", pat: "x x x x x x x x", vol: 0.35 },
      { play: "notes", inst: "lead", vol: 0.42, notes: `
        A5 - F#5 A5 - F#5 D5 - | B5 - G5 B5 - D6 - - | C#6 - B5 A5 - E5 - - | F#5 - - - A5 - - - |
        B5 - A5 F#5 - D5 - F#5 | G5 - A5 B5 - D6 - - | E6 - D6 G#5 - B5 - - | A5 - - - C#6 - E6 - |` },
    ],
  },

  // An Alpha or a boss: heavy war drums, brass and choir.
  alpha: {
    bpm: 112, beats: 4, sub: 2, reverb: 0.35, gain: 0.75,
    chords: "Dm Bb C Dm Dm Bb Gm A",
    layers: [
      { play: "chords", inst: "choir", oct: 3, vol: 0.3 },
      { play: "pattern", inst: "bass", oct: 1, pat: "1 - - 1 - - 1 -", vol: 0.55 },
      { play: "pattern", inst: "strings", oct: 3, pat: "1 1 1 1 1 1 1 1", vol: 0.18, legato: 0.5 },
      { play: "drums", inst: "taiko", pat: "x . . x . . x . | x . x . x x x .", vol: 0.6 },
      { play: "drums", inst: "tom", pat: ". . . . . . . . | . . . . . . o x", vol: 0.5 },
      { play: "notes", inst: "brass", vol: 0.5, notes: `
        D5 - - - A4 - - - | Bb4 - - C5 D5 - - - | E5 - - - G5 - - - | F5 - E5 - D5 - - - |
        A5 - - - F5 - D5 - | D5 - F5 - Bb5 - - - | A5 - G5 - F5 - D5 - | C#5 - - - E5 - A4 - |` },
    ],
  },

  // ------------------------------------------------------------------ jingles (played once)
  victoire: {
    bpm: 132, beats: 4, sub: 2, reverb: 0.3,
    chords: "C F G C",
    layers: [
      { play: "chords", inst: "brass", oct: 3, vol: 0.3 },
      { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - 1 - - -", vol: 0.5 },
      { play: "drums", inst: "snare", pat: "x x x x . . . . | . . . . . . . . | . . x x x x x x | x . . . . . . .", vol: 0.4 },
      { play: "notes", inst: "lead", vol: 0.45, notes: `G5 - C6 - E6 - G6 - | F6 - - - A6 - - - | G6 - F6 - D6 - B5 - | C6 - - - - - - - |` },
    ],
  },
  capture: {
    bpm: 120, beats: 4, sub: 2, reverb: 0.4,
    chords: "C G C",
    layers: [
      { play: "chords", inst: "strings", oct: 3, vol: 0.3 },
      { play: "notes", inst: "musicbox", vol: 0.6, notes: `C6 - E6 - G6 - C7 - | B6 - - - D7 - - - | C7 - - - - - - - |` },
      { play: "notes", inst: "harp", vol: 0.4, notes: `C5 E5 G5 C6 E6 G6 C6 G5 | D5 G5 B5 D6 G6 B6 G6 D6 | C5 - - - - - - - |`, ring: true },
    ],
  },
  defaite: {
    bpm: 72, beats: 4, sub: 2, reverb: 0.5,
    chords: "Am Fm Am",
    layers: [
      { play: "chords", inst: "strings", oct: 3, vol: 0.3 },
      { play: "notes", inst: "piano", vol: 0.5, notes: `E5 - D5 - C5 - B4 - | Ab4 - - - C5 - - - | A4 - - - - - - - |` },
    ],
  },
  // Resting at a campfire or in bed: the little "healing" tune.
  repos: {
    bpm: 100, beats: 4, sub: 2, reverb: 0.45,
    chords: "F C F",
    layers: [
      { play: "chords", inst: "pad", oct: 3, vol: 0.25 },
      { play: "notes", inst: "musicbox", vol: 0.6, notes: `A5 - C6 - F6 - E6 - | G5 - C6 - E6 - - - | F6 - - - - - - - |` },
    ],
  },

  // ------------------------------------------------------------------ later chapters
  // Recipes: a tune generated from the chords (the same one every time), ready for the
  // regions of HISTOIRE.md. Written tunes can replace them when those chapters are made.
  foret: {
    bpm: 96, beats: 4, sub: 2, reverb: 0.35, key: 4, scale: DORIAN,
    chords: "Em A Em A G D C B7",
    layers: [
      { play: "pattern", inst: "marimba", oct: 3, pat: "1 5 8 5 10 8 5 8", vol: 0.4 },
      { play: "pattern", inst: "bass", oct: 2, pat: "1 - . 1 . 5 . .", vol: 0.45 },
      { play: "drums", inst: "tom", pat: "x . o . . x o .", vol: 0.35 },
      { play: "drums", inst: "shaker", pat: "o x o x o x o x", vol: 0.35 },
      { play: "gen", inst: "flute", oct: 5, density: 0.8, seed: 21, vol: 0.45, every: [1, 1, 0] },
      { play: "drums", inst: "kick", pat: "x . . . x . . .", vol: 0.4, ride: true },
    ],
  },
  marais: {
    bpm: 66, beats: 4, sub: 2, reverb: 0.6, key: 9, scale: MINOR,
    chords: "Am Am F F Dm Dm E E",
    layers: [
      { play: "chords", inst: "choir", oct: 3, vol: 0.25 },
      { play: "pattern", inst: "harp", oct: 3, pat: "1 . 5 . 3 . 5 .", vol: 0.3, ring: true },
      { play: "pattern", inst: "bass", oct: 1, pat: "1 - - - - - - -", vol: 0.35 },
      { play: "gen", inst: "flute", oct: 4, density: 0.5, seed: 31, vol: 0.4 },
    ],
  },
  desert: {
    bpm: 92, beats: 4, sub: 2, reverb: 0.35, key: 4, scale: PHRYGIAN_DOM,
    chords: "E E F E E Dm F E",
    layers: [
      { play: "pattern", inst: "guitar", oct: 3, pat: "1 1 5 1 8 1 5 3", vol: 0.38 },
      { play: "pattern", inst: "bass", oct: 1, pat: "1 - - 1 - - 1 -", vol: 0.45 },
      { play: "drums", inst: "taiko", pat: "x . . x . . x .", vol: 0.35 },
      { play: "drums", inst: "shaker", pat: ". x . x . x . x", vol: 0.35 },
      { play: "gen", inst: "reed", oct: 4, density: 0.8, seed: 41, vol: 0.45 },
    ],
  },
  cote: {
    bpm: 88, beats: 3, sub: 2, reverb: 0.45, key: 2, scale: MAJOR,
    chords: "D A Bm G D A G A",
    layers: [
      { play: "chords", inst: "strings", oct: 3, vol: 0.25 },
      { play: "pattern", inst: "harp", oct: 3, pat: "1 5 8 10 8 5", vol: 0.38, ring: true },
      { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - -", vol: 0.4 },
      { play: "gen", inst: "flute", oct: 5, density: 0.75, seed: 51, vol: 0.45 },
    ],
  },
  monts: {
    bpm: 70, beats: 4, sub: 2, reverb: 0.65, key: 11, scale: MINOR,
    chords: "Bm G D A Bm G Em F#",
    layers: [
      { play: "chords", inst: "strings", oct: 3, vol: 0.28 },
      { play: "pattern", inst: "musicbox", oct: 5, pat: "1 . 5 . 8 . 5 .", vol: 0.3 },
      { play: "pattern", inst: "bass", oct: 1, pat: "1 - - - - - - -", vol: 0.35 },
      { play: "gen", inst: "bell", oct: 5, density: 0.45, seed: 61, vol: 0.35 },
    ],
  },
  cieux: {
    bpm: 84, beats: 4, sub: 2, reverb: 0.55, key: 5, scale: LYDIAN,
    chords: "F G F G Dm C Bb C",
    layers: [
      { play: "chords", inst: "pad", oct: 3, vol: 0.28 },
      { play: "pattern", inst: "harp", oct: 4, pat: "1 5 8 10 12 10 8 5", vol: 0.35, ring: true },
      { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - 5 - - -", vol: 0.35 },
      { play: "gen", inst: "flute", oct: 5, density: 0.7, seed: 71, vol: 0.45 },
    ],
  },
  volcan: {
    bpm: 100, beats: 4, sub: 2, reverb: 0.35, key: 0, scale: MINOR,
    chords: "Cm Ab Bb Cm Cm Ab Fm G",
    layers: [
      { play: "chords", inst: "choir", oct: 3, vol: 0.3 },
      { play: "pattern", inst: "synthbass", oct: 1, pat: "1 . 1 . 1 1 . 1", vol: 0.5 },
      { play: "drums", inst: "taiko", pat: "x . . x . . x . | x . x . x . x x", vol: 0.55 },
      { play: "gen", inst: "brass", oct: 4, density: 0.6, seed: 81, vol: 0.45 },
    ],
  },
  apex: {
    bpm: 104, beats: 4, sub: 2, reverb: 0.45, key: 2, scale: MINOR, gain: 0.8,
    chords: "Dm Bb F C Dm Bb Gm A",
    layers: [
      { play: "chords", inst: "choir", oct: 3, vol: 0.3 },
      { play: "chords", inst: "strings", oct: 4, vol: 0.2 },
      { play: "pattern", inst: "bass", oct: 1, pat: "1 - 1 - 1 - 1 -", vol: 0.5 },
      { play: "drums", inst: "taiko", pat: "x . . x . . x . | x . x . x x x x", vol: 0.55 },
      { play: "gen", inst: "brass", oct: 4, density: 0.7, seed: 91, vol: 0.5 },
    ],
  },
};
