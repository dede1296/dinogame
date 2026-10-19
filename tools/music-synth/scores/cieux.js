// Cieux Éternels (chapter 7; tools/zones/cieux.gd, and arche_du_vent / nids_geants as a fallback).
// The heights, the wind: majestic and airy. F lydian (the ♮B of the sky) turning to F major (♭B)
// for the majestic part; 3/4 at 80 BPM, 32 bars = 72 s, seamless loop. Recipe of the Phaser
// version kept: F lydian, pad, harp arpeggios, flute.
//   A (8)   the flute: the head of Chloé's theme in F (A–G–F) and a lydian leap up (A–D, B♮)
//   B (8)   the horn: a broad tune for the King of the Skies (B♭ F/A Gm C), the violins above it,
//           a soft taiko on the strong bars
//   A' (8)  the flute and the violins an octave apart, the same start, a higher ending
//   C (8)   the wind: echoes of the head, bells, the harp alone; C sus4 → C leads back to F
const harp = (vol) => ({ play: "pattern", inst: "harp", oct: 4, pat: "1 5 8 10 12 10", vol, ring: true });
// (the pad lighter than in the recipe, the strings with it: less organ, more air)
const pad = (vol) => [{ play: "chords", inst: "pad", oct: 3, vol: vol * 0.55 }, { play: "chords", inst: "strings", oct: 3, vol: vol * 0.5 }];
const bass = (vol, pat = "B - - - - -") => ({ play: "pattern", inst: "bass", oct: 2, pat, vol });
const headA = "A5:3 G5:2 F5:1 | G5:2 A5:1 D6:3 | C6:3 A5:2 F5:1 | B5:4 A5:1 G5:1";

export default {
  title: "cieux",
  loop: true,
  reverb: 0.55,
  reverbSeconds: 3.2,
  sections: [
    {
      name: "A", key: "F", bpm: 80, beats: 3, sub: 2, chords: "F G/F F G/F Am G Dm7 C",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.46, line: `${headA} | A5:3 E5:3 | D5:2 E5:1 G5:3 | F5:2 E5:1 D5:2 C5:1 | E5:6` },
        harp(0.28), ...pad(0.2), bass(0.3),
        { play: "pattern", inst: "bell", oct: 5, pat: ". . . . . . | . . . 10 . .", vol: 0.1 },
      ],
    },
    {
      name: "B", key: "F", bpm: 80, beats: 3, sub: 2, chords: "Bb F/A Gm7 C Bb Dm7 Bbmaj7 C",
      layers: [
        { play: "line", inst: "horn", lead: true, vol: 0.64, line: "D4:3 F4:3 | C4:2 F4:1 A4:3 | Bb4:3 A4:2 G4:1 | G4:6 | D4:3 F4:3 | A4:2 D5:1 C5:3 | Bb4:2 A4:1 F4:3 | G4:3 E4:3" },
        { play: "line", inst: "strings", vol: 0.27, line: "F5:6 | A5:6 | Bb5:6 | G5:6 | F5:6 | A5:3 F5:3 | D5:6 | E5:6" },
        harp(0.24), ...pad(0.24), bass(0.34, "B - - 5 - -"),
        { play: "drums", inst: "taiko", pat: "x . . . . . | . . . . . . | . . . . . . | . . . . . . | x . . . . . | . . . . . . | . . . . . . | . . . o . .", vol: 0.25 },
      ],
    },
    {
      name: "A'", key: "F", bpm: 80, beats: 3, sub: 2, chords: "F G/F F G/F Dm Bb Gm7 C",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.44, line: `${headA} | F5:2 A5:1 D6:3 | F6:3 D6:2 Bb5:1 | A5:2 Bb5:1 G5:3 | C6:6` },
        { play: "line", inst: "strings", vol: 0.2, transpose: -12, line: `${headA} | F5:2 A5:1 D6:3 | F6:3 D6:2 Bb5:1 | A5:2 Bb5:1 G5:3 | C6:6` },
        harp(0.26), ...pad(0.2), bass(0.32, "B - - 5 - -"),
        { play: "drums", inst: "triangle", pat: "x . . . . . | . . . . . . | . . . . . . | . . . . . . | . . . . . . | . . . . . . | . . . . . . | . . . . . .", vol: 0.18 },
      ],
    },
    {
      name: "C (le vent)", key: "F", bpm: 80, beats: 3, sub: 2, chords: "Dm Am Bb F/A Gm7 Am7 Bbmaj7 Csus4",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.4, line: "r:3 F5:1 E5:1 D5:1 | E5:6 | r:3 D6:1 C6:1 Bb5:1 | C6:6 | r:3 Bb5:1 A5:1 G5:1 | A5:3 C6:3 | D6:3 A5:3 | G5:6" },
        { play: "pattern", inst: "harp", oct: 3, pat: "1 5 8 10 8 5", vol: 0.26, ring: true },
        ...pad(0.22), bass(0.28),
        { play: "pattern", inst: "bell", oct: 5, pat: "8 . . . . . | . . . . . . | . . . . . . | . . . 10 . .", vol: 0.12 },
        { play: "line", inst: "cello", vol: 0.16, line: "D3:6 | E3:6 | F3:6 | F3:6 | G3:6 | E3:6 | F3:6 | G3:6" },
      ],
    },
  ],
};
