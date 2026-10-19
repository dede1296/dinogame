// Intro, first half (story/cinematiques.gd: I-01 → I-05, ~40.8 s, then a 2 s cross-fade into
// cinematique_intro_b at I-06). D major, Chloé's theme (titre.ogg) as an "appel du large".
//   0.0  I-01 the open sea   6/8 barcarolle: the horn calls Chloé's theme over a rolling harp
//   8.4  I-02 amber cliffs   the flute answers, strings come in, a chime on each bar (the amber)
//  16.0  I-03 the Cabinet    music box (Hélène's motif, Cabinet of the Phaser version), cheeky pizzicati
//  24.0  I-04 the eggs       the music box slows down, the strings hold a note: tenderness
//  31.7  I-05 the map        4/4: pizzicati walk on and the head of the theme climbs a step a bar
//  38.5  (the volcano)       B♭ (♭VI), timpani roll, low horns and choir; then A sus4, left open
import { rep } from "./_lib.js";

export default {
  title: "cinematique_intro_a",
  reverb: 0.42,
  tail: 3.5,
  sections: [
    {
      name: "le large (I-01)", key: "D", bpm: 89.7, beats: 3, sub: 2, chords: "D Bm G A",
      layers: [
        { play: "pattern", inst: "harp", oct: 3, pat: "1 5 8 10 8 5", vol: 0.34, ring: true, dyn: [0.75, 1] },
        { play: "chords", inst: "cello", oct: 2, vol: 0.2 },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - -", vol: 0.32 },
        { play: "line", inst: "horn", lead: true, vol: 0.56, line: "F#4:3 E4:2 D4:1 | E4:2 F#4:1 B4:3 | D5:3 E5:1 D5:1 B4:1 | C#5:3 A4:3" },
        { play: "drums", inst: "taiko", pat: "x . . . . . | . . . . . . | . . . . . . | . . . o . .", vol: 0.22 },
      ],
    },
    {
      name: "les falaises d'ambre (I-02)", key: "D", bpm: 89.7, beats: 3, sub: 2, chords: "D F#m G A",
      layers: [
        { play: "pattern", inst: "harp", oct: 3, pat: "1 5 8 10 8 5", vol: 0.36, ring: true },
        { play: "chords", inst: "strings", oct: 3, vol: 0.17, dyn: [0.8, 1.1] },
        { play: "chords", inst: "cello", oct: 2, vol: 0.15 },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - L5 - -", vol: 0.34 },
        { play: "line", inst: "flute", lead: true, vol: 0.46, line: "F#5:3 E5:2 D5:1 | C#5:2 D5:1 A5:3 | G5:2 F#5:1 E5:2 D5:1 | E5:6" },
        { play: "line", inst: "horn", vol: 0.28, line: "A4:6 | A4:3 F#4:3 | G4:3 B4:3 | A4:6" },
        { play: "pattern", inst: "bell", oct: 4, pat: ". . . 10 . .", vol: 0.17 },
        { play: "drums", inst: "triangle", pat: "x . . . . . | . . . . . . | . . . . . . | . . . . . .", vol: 0.35 },
      ],
    },
    {
      name: "le Cabinet (I-03)", key: "G", bpm: 90, beats: 3, sub: 2, chords: "Cmaj7 D Cmaj7 D",
      layers: [
        { play: "line", inst: "musicbox", lead: true, vol: 0.56, line: "E6:3 D6:2 B5:1 | A5:3 F#5:3 | G5:1 A5:1 B5:1 E6:3 | F#6:3 D6:3" },
        { play: "pattern", inst: "pizz", oct: 2, pat: "1 . 8 5 . .", vol: 0.46 },
        { play: "chords", inst: "strings", oct: 3, vol: 0.12 },
        { play: "line", inst: "kalimba", vol: 0.22, line: "r:6 | r:3 D5:1 E5:1 F#5:1 | r:6 | r:3 A5:1 B5:1 C6:1" },
      ],
    },
    {
      name: "les trois œufs (I-04)", key: "G", bpm: 80.7, rit: 0.75, beats: 3, sub: 2, chords: "Am7 Em7 Dsus4",
      layers: [
        { play: "line", inst: "musicbox", lead: true, vol: 0.5, dyn: [1, 0.75], line: "E6:2 C6:1 A5:2 G5:1 | B5:3 G5:3 | D6:6" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.17 },
        { play: "line", inst: "strings", vol: 0.24, line: "r:6 | B4:3 G4:3 | A4:6" },
        { play: "line", inst: "cello", vol: 0.24, line: "A2:6 | G2:6 | D2:6" },
      ],
    },
    {
      name: "la carte (I-05)", key: "D", bpm: 105.9, beats: 4, sub: 2, chords: "D Em7 F#m7", dyn: [0.8, 1.1],
      layers: [
        { play: "line", inst: "pizz", vol: 0.5, line: "D3:1 F#3:1 A3:1 F#3:1 D3:1 E3:1 F#3:1 G3:1 | E3:1 G3:1 B3:1 G3:1 E3:1 F#3:1 G3:1 A3:1 | F#3:1 A3:1 C#4:1 A3:1 F#3:1 G3:1 A3:1 B3:1" },
        { play: "line", inst: "pizz", lead: true, vol: 0.44, line: "F#5:2 E5:1 D5:1 E5:1 F#5:1 A5:2 | G5:2 F#5:1 E5:1 F#5:1 G5:1 B5:2 | A5:2 G5:1 F#5:1 G5:1 A5:1 C#6:2" },
        { play: "line", inst: "kalimba", vol: 0.24, line: "F#5:2 E5:1 D5:1 E5:1 F#5:1 A5:2 | G5:2 F#5:1 E5:1 F#5:1 G5:1 B5:2 | A5:2 G5:1 F#5:1 G5:1 A5:1 C#6:2" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.18, dyn: [0.6, 1.1] },
        { play: "drums", inst: "shaker", pat: "o . x . o . x .", vol: 0.28 },
        { play: "drums", inst: "taiko", pat: "x . . . . . . .", vol: 0.2, dyn: [0.7, 1.2] },
      ],
    },
    {
      name: "le volcan", key: "D", bpm: 106, beats: 4, sub: 6, chords: "Bb",
      layers: [
        { play: "line", inst: "timpani", vol: 0.32, dyn: [0.25, 1], line: rep("Bb2:1", 24) },
        { play: "chords", inst: "choir", oct: 3, vol: 0.2, dyn: [0.5, 1] },
        { play: "line", inst: "horn", vol: 0.24, dyn: [0.4, 1], line: "Bb2+F3+Bb3:24" },
        { play: "line", inst: "cello", vol: 0.26, line: "Bb1:24" },
        { play: "drums", inst: "taiko", pat: "x . . . . . . . . . . . . . . . . . . . . . . .", vol: 0.26 },
      ],
    },
    {
      name: "suspendu", key: "D", bpm: 60, beats: 2, sub: 2, chords: "Asus4",
      layers: [
        { play: "chords", inst: "strings", oct: 3, vol: 0.26 },
        { play: "strum", inst: "harp", oct: 3, pat: "d . . .", strings: "1 5 8 10 12", spread: 0.05, vol: 0.4, ring: true },
        { play: "pattern", inst: "bass", oct: 1, pat: "1 - - -", vol: 0.34 },
        { play: "line", inst: "timpani", vol: 0.3, line: "A2:1 r:3" },
        { play: "line", inst: "strings", vol: 0.24, line: "D5:4" },
      ],
    },
  ],
};
