// The end (story/cinematiques.gd: F-01 → F-09, ~89 s; credits.ogg takes over at F-10 with a 2.5 s
// cross-fade, while this one holds its last chord). The intro's call, answered: D major, then a
// journey of keys (E minor, G, D, E minor, C, G) back home to D.
//   0   F-01 the jetty      Chloé's theme (titre.ogg) at 72 BPM, violins over a picked guitar: calm
//  10   F-02 the boat       the flute goes on with the theme, a little more flowing (80 BPM)
//  19   F-03 the forges     comic: the bassoon plays the Ombre Noire's motif (ombre.ogg) staccato over
//                           pizzicati; the flute answers with the theme's head; strings tremble (Roc);
//                           the bassoon tumbles down the ladder
//  28   F-04 the blue cup   piano alone: the rest tune (repos.ogg) in G, then the strings, very soft
//  39   F-05 the keepers    the theme regains breadth (flute, strings, harp); Maïa's motif (rivale.ogg)
//                           answers it on the kalimba, cheeky
//  48   F-06 the dinos      a tender, funny variation (flute hiccups an octave, pizzicati); a gap left
//                           for the starter's cry and Écho's wrong notes (1.8–3.3 s)
//  58   F-07 Brac at night  double-bass pizzicati, a marimba snoring, the bassoon sings the Ombre's
//                           motif as a lullaby: its F♮ has become F♯
//  67   F-08 the Souverain  B7 → C: a wide held chord, soft horns play the Alphas' motif (alpha.ogg)
//                           in C major as a chorale, choir and strings, no percussion
//  78   F-09 the journal    piano alone: Hélène's music-box motif from the intro (I-03)…
//  85.5 (F-09 → F-10)       … that flows into the head of Chloé's theme, F#–E–D, and a full warm D
//                           major chord held (the point d'orgue under the credits' cross-fade)

export default {
  title: "cinematique_fin",
  reverb: 0.42,
  tail: 3.5,
  sections: [
    {
      name: "la jetée (F-01)", key: "D", bpm: 72, beats: 4, sub: 2, chords: "D Bm G",
      layers: [
        { play: "pattern", inst: "guitar", oct: 3, pat: "1 5 8 5 10 5 8 5", vol: 0.34, ring: true },
        { play: "chords", inst: "strings", oct: 3, vol: 0.16, dyn: [0.6, 1] },
        { play: "line", inst: "strings", lead: true, vol: 0.5, line: "F#5:4 E5:2 D5:2 | E5:2 F#5:2 B4:4 | D5:4 E5:4" },
        { play: "line", inst: "cello", vol: 0.24, line: "A3:4 F#3:4 | F#3:4 D3:4 | B2:4 D3:4" },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - - - -", vol: 0.34 },
      ],
    },
    {
      name: "la barque (F-02)", key: "D", bpm: 80, beats: 4, sub: 2, chords: "A D F#m",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.48, line: "C#5:4 A4:4 | F#5:4 E5:2 D5:2 | C#5:2 D5:2 A5:4" },
        { play: "strum", inst: "guitar", oct: 3, pat: "d . . u . u d .", vol: 0.24 },
        { play: "chords", inst: "strings", oct: 3, vol: 0.18 },
        { play: "line", inst: "cello", vol: 0.2, line: "E3:8 | D3:4 F#3:4 | A3:8" },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - . 1 5 - . .", vol: 0.36 },
        { play: "drums", inst: "shaker", pat: "o . o . o . o .", vol: 0.2 },
        { play: "pattern", inst: "kalimba", oct: 5, pat: ". . . . . . 10 .", vol: 0.14 },
      ],
    },
    {
      name: "les forges (F-03)", key: "Em", bpm: 106.67, beats: 4, sub: 4, chords: "Em C Am B7",
      layers: [
        { play: "pattern", inst: "pizz", oct: 2, pat: "1 . . . 10 . . . 5 . . . 10 . . .", vol: 0.66 },
        { play: "line", inst: "bassoon", lead: true, vol: 0.8, line: "E3':6 B2':6 E3':2 F3':2 | G3':4 F3':4 E3':4 C3':4 | r:16 | B2:4 A#2:2 B2:2 F#2':4 B1':4" },
        { play: "line", inst: "flute", lead: true, vol: 0.55, line: "r:16 | r:16 | C6':2 B5':2 A5':4 r:8 | r:16" },
        { play: "line", inst: "tremolo", trem: 11, vol: 0.11, line: "r:16 | r:16 | E4+A4+C5:16 | r:16" },
        { play: "drums", inst: "block", pat: "x . . . . . . . x . . . . . . .", vol: 0.28 },
      ],
    },
    {
      name: "la tasse bleue (F-04)", key: "G", bpm: 87.27, beats: 4, sub: 2, chords: "G D/F# Em7 Cmaj7",
      layers: [
        { play: "line", inst: "piano", lead: true, vol: 0.52, line: "B4:2 D5:2 G5:2 F#5:2 | A4:2 D5:2 F#5:4 | G5:4 F#5:2 E5:2 | E5:4 D5:4" },
        { play: "line", inst: "piano", vol: 0.28, line: "G2:2 D3:2 B3:4 | F#2:2 D3:2 A3:4 | E2:2 B2:2 G3:4 | C3:2 G3:2 E4:4" },
        { play: "line", inst: "strings", vol: 0.1, line: "r:8 | r:8 | E3+G3+B3+D4:8 | C3+E3+G3+B3:8" },
        { play: "line", inst: "strings", vol: 0.17, line: "r:8 | r:8 | B4:8 | G4:4 A4:4" },
      ],
    },
    {
      name: "les gardiennes (F-05)", key: "D", bpm: 80, beats: 4, sub: 2, chords: "D G A",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.38, line: "F#5:4 E5:2 D5:2 | D5:8 | E5:2 F#5:2 A5:4" },
        { play: "line", inst: "strings", vol: 0.15, line: "F#4:4 E4:2 D4:2 | B3:8 | C#4:2 D4:2 E4:4" },
        { play: "line", inst: "kalimba", lead: true, vol: 0.32, line: "r:8 | B5:2 G5:1 B5:2 D6:3 | r:8" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.15 },
        { play: "pattern", inst: "harp", oct: 3, pat: "1 5 8 10 12 10 8 5", vol: 0.22, ring: true },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - 5 - - -", vol: 0.4 },
        { play: "drums", inst: "taiko", pat: "x . . . . . . .", vol: 0.18 },
        { play: "drums", inst: "triangle", pat: "x . . . . . . . | . . . . . . . . | . . . . . . . .", vol: 0.26 },
      ],
    },
    {
      name: "les dinos de Chloé (F-06)", key: "D", bpm: 72, beats: 4, sub: 2, chords: "D G Em7",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.46, line: "F#5:2 E5:1 D5:1 r:4 | E5:1 F#5:1 B5:2 B4':1 r:1 D5:2 | D5:2 E5:2 B4:4" },
        { play: "pattern", inst: "pizz", oct: 3, pat: "1 . 5 . 8 . 5 .", vol: 0.34 },
        { play: "chords", inst: "strings", oct: 3, vol: 0.15 },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - - - -", vol: 0.3 },
        { play: "line", inst: "harp", vol: 0.2, ring: true, line: "r:8 | r:4 D6:1 B5:1 G5:2 | r:8" },
      ],
    },
    {
      name: "Brac (F-07)", key: "Em", bpm: 80, beats: 4, sub: 2, chords: "Em C B7",
      layers: [
        { play: "line", inst: "pizz", vol: 0.68, line: "E2:2 r:2 B1:2 r:2 | C2:2 r:2 G1:2 r:2 | B1:2 r:2 F#2:2 r:2" },
        { play: "line", inst: "marimba", vol: 0.42, line: "r:4 B4:1 C5:1 D5:2 | D5:1 C5:1 B4:2 r:4 | r:4 B4:1 C5:1 D#5:2" },
        { play: "line", inst: "bassoon", lead: true, vol: 0.6, line: "E3:3 B2:3 E3:1 F#3:1 | G3:2 F#3:2 E3:4 | D#3:4 F#3:4" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.15 },
      ],
    },
    {
      name: "le Souverain (F-08)", key: "C", bpm: 65.45, beats: 4, sub: 2, chords: "Cadd9 Cadd9 G/B",
      layers: [
        { play: "line", inst: "horn", lead: true, vol: 0.74, line: "C4:4 G3:4 | A3:3 B3:1 C4:4 | D4:4 B3:4" },
        { play: "line", inst: "horn", vol: 0.44, line: "E4:8 | C4:4 E4:4 | D4:8" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.37 },
        { play: "chords", inst: "strings", oct: 4, vol: 0.25 },
        { play: "chords", inst: "cello", oct: 2, vol: 0.27 },
        { play: "chords", inst: "choir", oct: 3, vol: 0.25 },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - - - - - - - - - - - - LB - - - - - - -", vol: 0.38 },
        { play: "line", inst: "flute", vol: 0.2, line: "r:8 | E6:8 | D6:8" },
        { play: "strum", inst: "harp", oct: 3, pat: "d . . . . . . . | . . . . . . . . | d . . . . . . .", strings: "1 5 8 10 12 15", spread: 0.07, vol: 0.3, ring: true },
      ],
    },
    {
      name: "le journal (F-09)", key: "G", bpm: 72, beats: 3, sub: 2, chords: "Cmaj7 D Cmaj7",
      layers: [
        { play: "line", inst: "piano", lead: true, vol: 0.5, line: "E5:3 D5:2 B4:1 | A4:3 F#4:3 | G4:1 A4:1 B4:1 E5:3" },
        { play: "line", inst: "piano", vol: 0.26, line: "C3:3 G3:3 | D3:3 A3:3 | C3:3 G3:3" },
        { play: "line", inst: "musicbox", vol: 0.32, line: "r:6 | r:6 | G5:1 A5:1 B5:1 E6:3" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.09, dyn: [0.5, 1] },
      ],
    },
    {
      name: "point d'orgue (F-09 → F-10)", key: "D", bpm: 66, rit: 0.6, beats: 4, sub: 2, chords: "D D", dyn: [1, 0.9],
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.5, line: "F#5:2 E5:2 D5:4 | r:8" },
        { play: "line", inst: "strings", vol: 0.26, line: "A4:4 F#4:4 | F#4:8" },
        { play: "line", inst: "horn", vol: 0.32, line: "A3:4 A3:4 | A3+D4:8" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.28 },
        { play: "chords", inst: "strings", oct: 4, vol: 0.18 },
        { play: "strum", inst: "harp", oct: 3, pat: "d . . . . . . . | d . . . . . . .", strings: "1 5 8 10 12 15", spread: 0.06, vol: 0.38, ring: true },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - - - -", vol: 0.4 },
        { play: "line", inst: "cello", vol: 0.25, line: "D2:8 | -:8" },
        { play: "drums", inst: "triangle", pat: ". . . . . . . . | x . . . . . . .", vol: 0.24 },
        { play: "line", inst: "bell", vol: 0.14, line: "r:8 | A5:8" },
      ],
    },
  ],
};
