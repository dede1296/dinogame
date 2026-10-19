// La Terre des Apex, the crater (chapter 9; tools/zones/apex_terre.gd). Solemn, a slow breath,
// minimal. D minor at 56 BPM, 16 bars = 68.6 s, seamless loop. The chords breathe every two bars
// (a pad that swells in over 2 s and fades over 2.5 s) over a low D; the Alphas' motif (alpha.ogg)
// becomes a slow horn chorale. Recipe of the Phaser version kept: D minor, choir, horns.
//   souffle (4)  D minor, B♭maj7 over D: the breath alone, a bell, a soft timpani
//   choral (4)   the horns: D – A – B♭ C – D, the Alphas' head, very slow
//   lumière (4)  B♭, F/A: the violins, a little light from the amber
//   retour (4)   the horns again; A sus4 → A leads back to D minor
const breath = { play: "chords", inst: "swell", oct: 3, vol: 0.24 };
const choir = { play: "chords", inst: "choir", oct: 3, vol: 0.09 };
const bass = { play: "pattern", inst: "bass", oct: 2, pat: "B - - - - - - -", vol: 0.24 };

export default {
  title: "terre_apex",
  loop: true,
  reverb: 0.6,
  reverbSeconds: 3.8,
  reverbDamp: 0.6,
  sections: [
    {
      name: "souffle", key: "Dm", bpm: 56, beats: 4, sub: 2, chords: "Dm Dm Bbmaj7/D Bbmaj7/D",
      layers: [
        breath, choir, bass,
        { play: "line", inst: "cello", vol: 0.2, line: "D2:8 | -:8 | D2:8 | -:8" },
        { play: "line", inst: "bell", vol: 0.12, line: "r:8 | r:4 A5:4 | r:8 | r:6 F5:2" },
        { play: "line", inst: "timpani", vol: 0.16, line: "D2:8 | r:8 | r:8 | r:8" },
      ],
    },
    {
      name: "choral", key: "Dm", bpm: 56, beats: 4, sub: 2, chords: "Dm Dm Gm/D Dm",
      layers: [
        breath, choir, bass,
        { play: "line", inst: "horn", lead: true, vol: 0.42, line: "D4:8 | A3:8 | Bb3:6 C4:2 | D4:8" },
        { play: "line", inst: "horn", vol: 0.26, line: "F3:8 | F3:8 | G3:6 A3:2 | F3:8" },
        { play: "line", inst: "cello", vol: 0.2, line: "D2:8 | -:8 | D2:8 | -:8" },
        { play: "line", inst: "timpani", vol: 0.14, line: "D2:8 | r:8 | r:8 | r:8" },
      ],
    },
    {
      name: "lumière", key: "Dm", bpm: 56, beats: 4, sub: 2, chords: "Bb Bb F/A F/A",
      layers: [
        breath, choir, bass,
        { play: "line", inst: "strings", lead: true, vol: 0.2, line: "F5:8 | D5:4 F5:4 | C5:8 | A4:8" },
        { play: "line", inst: "harp", vol: 0.16, ring: true, line: "r:4 Bb4:2 D5:2 | r:8 | r:4 F4:2 A4:2 | r:8" },
        { play: "line", inst: "cello", vol: 0.18, line: "Bb2:8 | -:8 | A2:8 | -:8" },
      ],
    },
    {
      name: "retour", key: "Dm", bpm: 56, beats: 4, sub: 2, chords: "Gm7 Gm7 Asus4 A",
      layers: [
        breath, choir, bass,
        { play: "line", inst: "horn", lead: true, vol: 0.4, line: "Bb3:8 | D4:8 | D4:4 E4:4 | C#4:8" },
        { play: "line", inst: "horn", vol: 0.24, line: "G3:8 | F3:8 | A3:8 | A3:8" },
        { play: "line", inst: "cello", vol: 0.2, line: "G2:8 | -:8 | A2:8 | -:8" },
        { play: "line", inst: "timpani", vol: 0.14, line: "r:8 | r:8 | A2:8 | r:8" },
        { play: "line", inst: "bell", vol: 0.1, line: "r:8 | r:8 | r:8 | r:4 E5:4" },
      ],
    },
  ],
};
