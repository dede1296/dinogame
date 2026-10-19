// L'Arche du Vent, the summit and its stone arch (chapter 7; tools/zones/arche_du_vent.gd): where the
// mask falls (Isaure, Maïa). Suspended and windy: solitude, a tender gravity. D (sus2, mixolydian C,
// phrygian E♭ when the Ombre passes), 4/4 at 60 BPM, 18 bars = 72 s, seamless loop. No tune is ever
// finished: a three-note sketch, A–D–E (a fourth up, a step, left on the ninth), comes back three
// times, longer each time, and never resolves; Maïa's motif (rivale.ogg) and the Ombre's (ombre.ogg)
// pass through it like the wind.
//   I   le vent (4)     an aeolian harp (high harmonics of D, out of time), a pitched gust, a bell; far
//                       off, a horn says the sketch once: A–D–E
//   II  la petite (5)   D – Bm7 – Gmaj7 – Em7 – A sus4: the kalimba plays Maïa's motif at half speed
//                       (A–F#–A–F#–D) and stops; the flute takes the sketch, A–D–E, and falls back to D
//   III l'Ombre (5)     D minor, E♭/F, B♭maj7: the cellos sing the Ombre's head slowly in D phrygian
//                       (D–A–D–E♭, F–E♭–D–B♭); the flute's sketch bends to it (A–D–E♭); Maïa's motif
//                       comes back in minor over B♭maj7 (F♮): mother and daughter, one bar each
//   IV  l'esquisse (4)  a solo fiddle, the sketch at last a phrase: A–D–E–F#, A… G, F#–E, and E again,
//                       held on A sus4 — the wind takes it back
const harp = (vol, pat) => ({ play: "pattern", inst: "harp", oct: 3, pat, vol, ring: true });
const wind = (vol, line) => ({ play: "line", inst: "wind", vol, ring: true, line });

export default {
  title: "arche_du_vent",
  loop: true,
  reverb: 0.6,
  reverbSeconds: 4.0,
  sections: [
    {
      name: "I (le vent)", key: "D", bpm: 60, beats: 4, sub: 2, chords: "Dsus2 C/D Dsus2 Dsus2",
      layers: [
        wind(0.34, "A4:8 | G4:8 | E5:8 | D5:8"),
        { play: "line", inst: "harp", vol: 0.38, ring: true, line: "r:3 A5:1 r:2 D6:2 | r:5 E6:1 G6:2 | r:2 E6:1 r:3 A5:2 | r:4 D6:1 r:1 E6:2" },
        { play: "line", inst: "cello", vol: 0.26, line: "D2:8 | -:8 | D2:8 | -:6 r:2" },
        { play: "line", inst: "bell", vol: 0.1, line: "r:8 | r:4 G5:4 | r:8 | r:8" },
        { play: "line", inst: "horn", lead: true, vol: 0.44, send: 0.75, line: "r:8 | r:8 | A3:4 D4:4 | E4:8" },
      ],
    },
    {
      name: "II (la petite)", key: "D", bpm: 60, beats: 4, sub: 2, chords: "D Bm7 Gmaj7 Em7 Asus4",
      layers: [
        { play: "line", inst: "kalimba", vol: 0.34, line: "A5:4 F#5:2 A5:2 | -:2 F#5:2 D5:4 | r:8 | r:8 | r:8" },
        { play: "line", inst: "flute", lead: true, vol: 0.22, line: "r:8 | r:8 | r:4 A4:2 D5:2 | E5:6 D5:2 | D5:4 r:4" },
        { play: "line", inst: "cello", vol: 0.18, line: "D3:8 | B2:8 | G2:8 | E2:8 | A2:8" },
        harp(0.19, "1 . . 5 . . 8 ."),
        { play: "chords", inst: "strings", oct: 3, vol: 0.09 },
        wind(0.07, "F#5:8 | r:8 | r:8 | r:8 | E5:8"),
      ],
    },
    {
      name: "III (l'Ombre)", key: "Dm", bpm: 60, beats: 4, sub: 2, chords: "Dm Dm Eb/F Bbmaj7 A7sus4",
      layers: [
        { play: "line", inst: "cello", lead: true, vol: 0.22, line: "D3:6 A2:2 | -:4 D3:2 Eb3:2 | F3:4 Eb3:4 | D3:4 Bb2:4 | A2:8" },
        { play: "line", inst: "flute", vol: 0.16, line: "r:8 | r:4 A4:2 D5:2 | Eb5:6 D5:2 | r:8 | E5:8" },
        { play: "line", inst: "kalimba", vol: 0.2, line: "r:8 | r:8 | r:8 | A5:2 F5:1 A5:2 F5:1 D5:2 | r:8" },
        { play: "chords", inst: "tremolo", oct: 3, trem: 8, vol: 0.018, dyn: [0.4, 1] },
        { play: "line", inst: "horn", vol: 0.18, send: 0.7, line: "r:8 | r:8 | G3:8 | F3:8 | r:8" },
        { play: "line", inst: "timpani", vol: 0.12, line: "D2:8 | r:8 | r:8 | r:8 | A2:8" },
        { play: "pattern", inst: "bass", oct: 2, pat: "B - - - - - - -", vol: 0.18 },
        wind(0.06, "r:8 | r:8 | Bb4:8 | r:8 | r:8"),
      ],
    },
    {
      name: "IV (l'esquisse)", key: "D", bpm: 60, beats: 4, sub: 2, chords: "D Bm7 Em9 A7sus4",
      layers: [
        { play: "line", inst: "fiddle", lead: true, vol: 0.6, line: "A4:2 D5:2 E5:2 F#5:2 | A5:6 G5:2 | F#5:4 E5:4 | E5:3 D5:1 E5:4" },
        harp(0.13, "1 5 8 10 12 10 8 5"),
        { play: "line", inst: "cello", vol: 0.18, line: "D3:8 | B2:8 | E2:8 | A2:8" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.08 },
        { play: "line", inst: "bell", vol: 0.05, line: "r:8 | r:8 | B5:8 | r:8" },
        wind(0.08, "r:8 | r:8 | r:8 | A5:8"),
      ],
    },
  ],
};
