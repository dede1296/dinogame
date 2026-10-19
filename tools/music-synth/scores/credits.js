// The credits (story/cinematiques.gd: credits.ogg, looped under the roll of ~96 s; also from the
// menus). A gentle loop of 26 bars at 68 BPM (91.8 s): Chloé's theme (titre.ogg) told once more,
// harp and flute, nostalgic and serene, never climbing. D major.
//   intro (2)   the harp alone, the pad
//   A (8)       the flute sings the theme's A phrase (A1, A2); the cellos answer under A2
//   B (8)       the piano takes the B phrase an octave down, the flute holds a slow counter-line above
//   H (4)       Hélène's music-box motif (the intro's Cabinet), pizzicati
//   A' (4)      the horn, softly, the head once more; its A chord leads back to the harp's D
import { MOTIFS, bars } from "./_lib.js";

const harp = (vol, pat = "1 5 8 10 12 10 8 5") => ({ play: "pattern", inst: "harp", oct: 3, pat, vol, ring: true });

export default {
  title: "credits",
  loop: true,
  reverb: 0.48,
  sections: [
    {
      name: "intro", key: "D", bpm: 68, beats: 4, sub: 2, chords: "D G/D",
      layers: [
        harp(0.34),
        { play: "chords", inst: "pad", oct: 3, vol: 0.13 },
        { play: "pattern", inst: "bass", oct: 2, pat: "B - - - - - - -", vol: 0.28 },
      ],
    },
    {
      name: "A", key: "D", bpm: 68, beats: 4, sub: 2, chords: "D Bm G A D F#m G A",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.44, line: bars(MOTIFS.chloeA1, MOTIFS.chloeA2) },
        harp(0.3),
        { play: "chords", inst: "strings", oct: 3, vol: 0.14 },
        { play: "pattern", inst: "bass", oct: 2, pat: "B - - - 5 - - -", vol: 0.32 },
        { play: "line", inst: "cello", vol: 0.19, line: "r:8 | r:8 | r:8 | r:8 | A3:8 | A3:4 F#3:4 | G3:4 B3:4 | A3:4 C#4:4" },
        { play: "drums", inst: "triangle", pat: `x . . . . . . . ${". ".repeat(24)}x . . . . . . . ${". ".repeat(24)}`, vol: 0.16 },
      ],
    },
    {
      name: "B", key: "D", bpm: 68, beats: 4, sub: 2, chords: "Bm G D A Bm G Asus4 A",
      layers: [
        { play: "line", inst: "piano", lead: true, vol: 0.48, transpose: -12, line: bars(MOTIFS.chloeB1, MOTIFS.chloeB2) },
        { play: "line", inst: "flute", vol: 0.28, line: "F#5:8 | G5:4 B5:4 | A5:8 | A5:4 G5:2 E5:2 | F#5:8 | D5:4 B4:4 | A4:4 D5:4 | C#5:4 E5:4" },
        harp(0.22, "1 5 8 5 10 5 8 5"),
        { play: "chords", inst: "strings", oct: 3, vol: 0.14 },
        { play: "line", inst: "cello", vol: 0.18, line: "D3:4 F#3:4 | B2:4 D3:4 | A2:4 F#2:4 | C#3:4 E3:4 | D3:4 B2:4 | G2:4 B2:4 | D3:8 | C#3:8" },
        { play: "pattern", inst: "bass", oct: 2, pat: "B - - - 5 - - -", vol: 0.3 },
      ],
    },
    {
      name: "H (Hélène)", key: "G", bpm: 68, beats: 4, sub: 2, chords: "Cmaj7 D Cmaj7 D",
      layers: [
        { play: "line", inst: "musicbox", lead: true, vol: 0.62, line: MOTIFS.cabinet },
        { play: "pattern", inst: "pizz", oct: 2, pat: "1 . . . 5 . . .", vol: 0.42 },
        { play: "chords", inst: "pad", oct: 3, vol: 0.12 },
        { play: "chords", inst: "strings", oct: 3, vol: 0.12 },
        harp(0.18, "1 . 5 . 8 . 5 ."),
        { play: "line", inst: "kalimba", vol: 0.26, line: "r:8 | r:4 D5:1 E5:1 F#5:2 | r:8 | r:4 A5:1 G5:1 F#5:2" },
      ],
    },
    {
      name: "A'", key: "D", bpm: 68, beats: 4, sub: 2, chords: "D Bm G A",
      layers: [
        { play: "line", inst: "horn", lead: true, vol: 0.4, transpose: -12, line: MOTIFS.chloeA1 },
        harp(0.3),
        { play: "chords", inst: "strings", oct: 3, vol: 0.14 },
        { play: "pattern", inst: "bass", oct: 2, pat: "B - - - 5 - - -", vol: 0.3 },
        { play: "line", inst: "flute", vol: 0.2, line: "r:8 | r:8 | B5:8 | A5:8" },
      ],
    },
  ],
};
