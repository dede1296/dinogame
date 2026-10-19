// Intro, second half (story/cinematiques.gd: from I-06 to the « Ambrelune » card, ~38 s; it comes
// in over the A sus4 that ends cinematique_intro_a, and resolves it). D major.
//   0.0  I-06 the bedroom    100 BPM: strummed guitar, light snare, the head of Chloé's theme, bouncing
//   8.4  I-07 the pontoon    the jump: a brass hit on beat 3 (9.6 s); flute and horn climb in arpeggios
//                            (IV, V) — the heroic call rising with the boat
//  15.6  I-08 the mist       V → vi: the music holds back; tremolo strings, a low flute (the theme's head
//                            in B minor), slow cellos (the shadow under the boat), a pulse very low
//  21.0  the mist tears      a timpani roll and a harp run into…
//  23.7  I-09 the island     Chloé's theme in full (titre.ogg's harp, strings, flute, horn an octave
//                            below), broader at 80 BPM, the B leaping up instead of down
//  32.7  card « Ambrelune »  the theme sets down on D: F#–E–D, a rolled harp chord, held
import { rep } from "./_lib.js";

// The strings' tremolo in the mist: each chord tone re-bowed 10 times a second, very soft.
const tremolo = { play: "chords", inst: "tremolo", oct: 3, trem: 10, vol: 0.045, dyn: [0.7, 1] };

export default {
  title: "cinematique_intro_b",
  reverb: 0.4,
  tail: 3.5,
  sections: [
    {
      name: "la chambre (I-06)", key: "D", bpm: 100, beats: 4, sub: 2, chords: "D D G",
      layers: [
        { play: "strum", inst: "guitar", oct: 3, pat: "d . d u . u d u", vol: 0.3 },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - . 1 5 - 5 .", vol: 0.4 },
        { play: "drums", inst: "shaker", pat: "o . x . o . x .", vol: 0.28 },
        { play: "drums", inst: "snare", pat: ". . . . . . . . | . . o . . . o . | . . o . . . o .", vol: 0.32 },
        { play: "drums", inst: "kick", pat: "x . . . . . . . | x . . . x . . . | x . . . x . . .", vol: 0.24 },
        { play: "line", inst: "flute", lead: true, vol: 0.46, line: "r:8 | F#5:2 E5:1 D5:1 E5:1 F#5:1 A5:2 | B5:2 A5:1 G5:1 E5:2 D5:1 E5:1" },
      ],
    },
    {
      name: "l'élan", key: "D", bpm: 100, beats: 2, sub: 2, chords: "A",
      layers: [
        { play: "strum", inst: "guitar", oct: 3, pat: "d u d u", vol: 0.3 },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 . 5 .", vol: 0.4 },
        { play: "drums", inst: "snare", pat: "o o x x", vol: 0.3 },
        { play: "drums", inst: "shaker", pat: "o x o x", vol: 0.26 },
        { play: "line", inst: "flute", lead: true, vol: 0.46, line: "A4:1 B4:1 C#5:1 E5:1" },
      ],
    },
    {
      name: "le ponton (I-07)", key: "D", bpm: 100, beats: 4, sub: 2, chords: "D G A",
      layers: [
        { play: "strum", inst: "guitar", oct: 3, pat: "d . d u . u d u", vol: 0.28 },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - . 1 5 - 5 .", vol: 0.42 },
        { play: "chords", inst: "strings", oct: 3, vol: 0.2, dyn: [0.7, 1.1] },
        { play: "line", inst: "brass", vol: 0.42, line: "r:4 D4+F#4+A4+D5!:2 r:2 | r:8 | r:8" },
        { play: "drums", inst: "taiko", pat: ". . . . x . . . | x . . . . . . . | x . . . . . . .", vol: 0.38 },
        { play: "drums", inst: "snare", pat: ". . o r x . o . | . . o . . . o . | . . o . x . . .", vol: 0.3 },
        { play: "drums", inst: "shaker", pat: "o . x . o . x .", vol: 0.24 },
        { play: "drums", inst: "kick", pat: "x . . . x . . .", vol: 0.26 },
        { play: "line", inst: "flute", lead: true, vol: 0.48, line: "r:6 A4:1 D5:1 | D5:2 G5:2 B5:3 A5:1 | A5:2 C#6:2 E6:4" },
        { play: "line", inst: "horn", vol: 0.36, line: "r:8 | D4:2 G4:2 B4:3 A4:1 | A4:2 C#5:2 E5:4" },
      ],
    },
    {
      name: "la brume (I-08)", key: "Bm", bpm: 90, beats: 4, sub: 4, chords: "Bm Gmaj7",
      layers: [
        tremolo,
        { play: "chords", inst: "choir", oct: 3, vol: 0.07 },
        { play: "pattern", inst: "pizz", oct: 2, pat: "1 . . . . . . . 5 . . . . . . .", vol: 0.24 },
        { play: "drums", inst: "shaker", pat: "o . . . o . . . o . . . o . . .", vol: 0.14 },
        { play: "line", inst: "flute", lead: true, vol: 0.34, line: "D5:8 C#5:4 B4:4 | C#5:4 D5:4 F#4:8" },
        { play: "line", inst: "cello", vol: 0.2, line: "B2:16 | G2:16" },
        { play: "line", inst: "harp", vol: 0.2, ring: true, line: "r:6 F#5:2 r:8 | r:10 D5:2 r:4" },
      ],
    },
    {
      name: "la brume se déchire", key: "D", bpm: 90, beats: 4, sub: 8, chords: "A7sus4", dyn: [0.8, 1.2],
      layers: [
        { play: "chords", inst: "tremolo", oct: 3, trem: 12, vol: 0.055, dyn: [0.7, 1.6] },
        { play: "chords", inst: "strings", oct: 3, vol: 0.16, dyn: [0.4, 1.2] },
        { play: "line", inst: "flute", lead: true, vol: 0.4, line: "E5:16 D5:8 r:8" },
        { play: "line", inst: "harp", vol: 0.4, ring: true, line: "r:24 D4:1 E4:1 F#4:1 G4:1 A4:1 B4:1 C#5:1 D5:1" },
        { play: "line", inst: "timpani", vol: 0.34, dyn: [0.1, 1], line: `r:16 ${rep("A2:1", 16)}` },
        { play: "line", inst: "cello", vol: 0.24, line: "A2:32" },
      ],
    },
    {
      name: "l'île (I-09)", key: "D", bpm: 80, beats: 4, sub: 2, chords: "D Bm A",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.55, line: "F#5:4 E5:2 D5:2 | E5:2 F#5:2 B5:4 | A5:3 G5:1 E5:2 C#5:2" },
        { play: "line", inst: "horn", vol: 0.34, line: "F#4:4 E4:2 D4:2 | E4:2 F#4:2 B4:4 | A4:3 G4:1 E4:2 C#4:2" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.28 },
        { play: "chords", inst: "strings", oct: 4, vol: 0.16 },
        { play: "pattern", inst: "harp", oct: 3, pat: "1 5 8 10 12 10 8 5", vol: 0.4, ring: true },
        { play: "line", inst: "cello", vol: 0.26, line: "D3:4 C#3:4 | B2:4 D3:4 | A2:4 E3:2 G3:2" },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - 5 - - -", vol: 0.42 },
        { play: "line", inst: "timpani", vol: 0.28, line: "D2!:8 | r:8 | A2:4 A2:2 A2:2" },
        { play: "drums", inst: "taiko", pat: "x . . . . . . . | . . . . . . . . | . . . . x . . .", vol: 0.24 },
        { play: "drums", inst: "triangle", pat: "x . . . . . . . | . . . . . . . . | x . . . . . . .", vol: 0.3 },
      ],
    },
    {
      name: "« Ambrelune »", key: "D", bpm: 72, rit: 0.6, beats: 4, sub: 2, chords: "D",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.5, line: "F#5:2 E5:2 D5:4" },
        { play: "line", inst: "horn", vol: 0.3, line: "D4+A4:8" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.28 },
        { play: "chords", inst: "strings", oct: 4, vol: 0.15 },
        { play: "strum", inst: "harp", oct: 3, pat: "d . . . . . . .", strings: "1 5 8 10 12 15", spread: 0.06, vol: 0.42, ring: true },
        { play: "line", inst: "cello", vol: 0.26, line: "D2:8" },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - - - -", vol: 0.4 },
        { play: "line", inst: "timpani", vol: 0.24, line: "D2:8" },
        { play: "drums", inst: "triangle", pat: "x . . . . . . .", vol: 0.3 },
      ],
    },
  ],
};
