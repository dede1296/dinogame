// Le Cœur des Apex, the Souverain (chapter 9; tools/zones/apex_coeur.gd). Grave, tender,
// trembling. D minor at 60 BPM in sixteenths (the strings' tremolo), 18 bars = 72 s, seamless loop.
// A heartbeat (two soft timpani strokes a bar) under the tremolo.
//   A (6)   grave: the cellos sing the Alphas' motif (alpha.ogg), D – A – B♭ C – D – E G – F E D
//   B (6)   tender: D major, the flute sings the head of Chloé's theme (titre.ogg) over a slow harp,
//           the heartbeat stops
//   C (6)   grave and trembling: the horn and the cellos in octaves, the motif with a Neapolitan E♭,
//           the tremolo grows, then A (V) leads back to the cellos' D minor
// The strings' tremolo: each chord tone re-bowed 11 times a second.
const trem = (vol, dyn) => ({ play: "chords", inst: "tremolo", oct: 3, trem: 11, vol, ...(dyn ? { dyn } : {}) });
const heart = (roots) => ({ play: "line", inst: "timpani", vol: 0.2, line: roots.map((r) => `${r}:1 ${r}_:15`).join(" | ") });
const alphaLow = "D3:8 A2:8 | Bb2:12 C3:4 | D3:16 | E3:8 G3:8 | F3:4 E3:4 D3:8 | C#3:16";

export default {
  title: "coeur_apex",
  loop: true,
  reverb: 0.55,
  reverbSeconds: 3.5,
  sections: [
    {
      name: "A (grave)", key: "Dm", bpm: 60, beats: 4, sub: 4, chords: "Dm Bb Gm A7 Dm A7",
      layers: [
        trem(0.042),
        { play: "line", inst: "cello", lead: true, vol: 0.38, line: alphaLow },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - - - - - - - - - - - -", vol: 0.26 },
        heart(["D2", "D2", "D2", "A2", "D2", "A2"]),
        { play: "chords", inst: "choir", oct: 3, vol: 0.08 },
      ],
    },
    {
      name: "B (tendre)", key: "D", bpm: 60, beats: 4, sub: 4, chords: "D Bm G A G A",
      layers: [
        trem(0.028),
        { play: "line", inst: "flute", lead: true, vol: 0.31, line: "F#5:8 E5:4 D5:4 | E5:4 F#5:4 B4:8 | D5:8 E5:4 D5:2 B4:2 | C#5:8 A4:8 | B4:4 D5:4 G5:8 | E5:16" },
        { play: "pattern", inst: "harp", oct: 3, pat: "1 . 5 . 8 . 10 . 12 . 10 . 8 . 5 .", vol: 0.16, ring: true },
        { play: "line", inst: "cello", vol: 0.2, line: "D3:16 | D3:16 | B2:16 | C#3:16 | D3:8 B2:8 | C#3:16" },
        { play: "pattern", inst: "bass", oct: 2, pat: "1 - - - - - - - - - - - - - - -", vol: 0.22 },
      ],
    },
    {
      name: "C (tremblant)", key: "Dm", bpm: 60, beats: 4, sub: 4, chords: "Dm Bb Gm Eb Dm/A A", dyn: [0.9, 1.1],
      layers: [
        trem(0.046, [0.8, 1.4]),
        { play: "line", inst: "horn", lead: true, vol: 0.5, line: "D4:8 A3:8 | Bb3:12 C4:4 | D4:16 | Eb4:8 G4:8 | F4:4 E4:4 D4:8 | C#4:16" },
        { play: "line", inst: "cello", vol: 0.3, line: "D3:8 A2:8 | Bb2:12 C3:4 | D3:16 | Eb3:8 G3:8 | F3:4 E3:4 D3:8 | C#3:16" },
        { play: "pattern", inst: "bass", oct: 2, pat: "B - - - - - - - - - - - - - - -", vol: 0.26 },
        heart(["D2", "D2", "D2", "Eb2", "A2", "A2"]),
        { play: "chords", inst: "choir", oct: 3, vol: 0.12 },
      ],
    },
  ],
};
