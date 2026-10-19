// Le Souverain, the last battle (chapter 9; battle/apex_battles.gd souverain_rules: played in a loop for
// 8 to 25 turns). Tension, but tenderness: he is afraid, he must not be hated. The Alphas' motif
// (alpha.ogg: D–A, B♭–C–D, E–G, F–E–D) as a chorale that climbs; timpani, trembling strings; in the
// middle, Hélène's music box (the Cabinet's motif, as in the intro) — the words he has always had; then
// the same chorale in D MAJOR (as in the end film, F-08). Energy without cruelty: no war drums, no
// synth bass, no snare; low strings in detached eighths, pizzicati on the off-beats.
// ≈ 94 s, seamless loop; D minor → E minor → (F major) → D major → D minor.
//   intro (2)  he trembles: tremolo strings, a racing heart (timpani, da-dum twice a bar), low strings
//   A (8)      the chorale: two horns, the Alphas' tune (Dm B♭ C Dm Dm B♭ Gm A), detached cellos and
//              basses in eighths, pizzicati, timpani on 1 and 3
//   A' (8)     it climbs: a tone higher (E minor), the violins on top an octave above the horns, the
//              tremolo swelling, a soft taiko every four bars
//   B (6)      fear: the cellos alone, the head bent (C–G, A–B–C; B♭m6), and the flute answers with the
//              head of Chloé's theme (D–C–B♭, C–D–G): she talks to him; the heart slows, the tremolo dies
//              down; slowing into…
//   H (8)      Hélène, at 90: the music box sings the Cabinet's motif in F major (B♭maj7 C, Gm7 Dm7
//              E♭maj7 F), harp, a soft pulse, a cello answering; no heartbeat
//   C (8)      the chorale in D major, broad (104): horns and violins, the B♭ of the Alphas' tune become
//              B♮; D/A – A7 leads back to the trembling D minor
import { bars } from "./_lib.js";

const alphaHorn = "D4:4 A3:4 | Bb3:3 C4:1 D4:4 | E4:4 G4:4 | F4:2 E4:2 D4:4 | A4:4 F4:2 D4:2 | D4:2 F4:2 Bb4:4 | A4:2 G4:2 F4:2 D4:2 | C#4:4 E4:2 A3:2";
const alphaSecond = "F3:4 F3:4 | F3:3 A3:1 Bb3:4 | C4:4 E4:4 | D4:2 C#4:2 A3:4 | F4:4 D4:2 A3:2 | Bb3:2 D4:2 F4:4 | F4:2 D4:2 D4:2 Bb3:2 | A3:4 C#4:2 E3:2";
const majorHorn = "D4:4 A3:4 | B3:3 C#4:1 D4:4 | E4:4 G4:4 | F#4:2 E4:2 D4:4 | A4:4 F#4:2 D4:2 | D4:2 F#4:2 B4:4 | A4:2 G4:2 F#4:2 D4:2 | C#4:4 E4:2 A3:2";
const majorSecond = "F#3:4 F#3:4 | G3:3 A3:1 B3:4 | B3:4 E4:4 | D4:2 C#4:2 A3:4 | F#4:4 D4:2 B3:2 | B3:2 D4:2 G4:4 | F#4:2 E4:2 D4:2 A3:2 | A3:4 C#4:2 E3:2";
// Low strings, detached eighths (the tremolo voice speaks at once); pizzicati on the off-beats.
const spic = (vol) => ({ play: "pattern", inst: "tremolo", oct: 2, pat: "1 1 5 1 1 1 5 1", legato: 0.5, vol });
const offbeats = (vol) => ({ play: "pattern", inst: "pizz", oct: 3, pat: ". 8 . 5 . 8 . 5", vol });
const trem = (vol, dyn) => ({ play: "chords", inst: "tremolo", oct: 3, trem: 10, vol, ...(dyn ? { dyn } : {}) });
const timp = (vol, roots) => ({ play: "line", inst: "timpani", vol, line: bars(...roots.map((r) => `${r}:2 r:2 ${r}_:2 r:2`)) });
const heart = (vol, roots, twice = true) => ({ play: "line", inst: "timpani", vol, line: bars(...roots.map((r) => (twice ? `${r}:1 ${r}_:1 r:2 ${r}:1 ${r}_:1 r:2` : `${r}:1 ${r}_:1 r:6`))) });
const bass = (vol, pat = "B - - - B - - -") => ({ play: "pattern", inst: "bass", oct: 2, pat, vol });

export default {
  title: "souverain",
  loop: true,
  reverb: 0.42,
  reverbSeconds: 3.0,
  sections: [
    {
      name: "intro (il tremble)", key: "Dm", bpm: 108, beats: 4, sub: 2, chords: "Dm Dm",
      layers: [
        trem(0.04, [0.5, 1.2]), heart(0.2, ["D2", "D2"]), spic(0.1), bass(0.24, "1 - - - - - - -"),
        { play: "line", inst: "horn", vol: 0.28, line: "r:8 | r:4 A3:4" },
      ],
    },
    {
      name: "A (le choral)", key: "Dm", bpm: 108, beats: 4, sub: 2, chords: "Dm Bb C Dm Dm Bb Gm A",
      layers: [
        { play: "line", inst: "horn", lead: true, vol: 0.55, line: alphaHorn },
        { play: "line", inst: "horn", vol: 0.36, line: alphaSecond },
        spic(0.14), offbeats(0.24), trem(0.03),
        timp(0.18, ["D2", "Bb2", "C2", "D2", "D2", "Bb2", "G2", "A2"]),
        bass(0.26),
      ],
    },
    {
      name: "A' (il monte)", key: "Em", bpm: 108, beats: 4, sub: 2, chords: "Em C D Em Em C Am B",
      layers: [
        { play: "line", inst: "strings", lead: true, vol: 0.85, transpose: 14, line: alphaHorn },
        { play: "line", inst: "horn", vol: 0.5, transpose: 2, line: alphaHorn },
        { play: "line", inst: "horn", vol: 0.34, transpose: 2, line: alphaSecond },
        spic(0.15), offbeats(0.26), trem(0.045, [0.8, 1.5]),
        timp(0.2, ["E2", "C2", "D2", "E2", "E2", "C2", "A2", "B2"]),
        { play: "drums", inst: "taiko", pat: `x . . . . . . . ${". ".repeat(24)}x . . . . . . . ${". ".repeat(24)}`, vol: 0.2 },
        bass(0.28),
      ],
    },
    {
      name: "B (il a peur)", key: "Dm", bpm: 108, rit: 0.85, beats: 4, sub: 2, chords: "C Am7 Bb Gm7 Bbm6 C7",
      layers: [
        { play: "line", inst: "cello", lead: true, vol: 0.5, line: "C3:4 G2:4 | A2:3 B2:1 C3:4 | r:8 | r:8 | Db3:4 Bb2:4 | C3:8" },
        { play: "line", inst: "flute", lead: true, vol: 0.3, line: "r:8 | r:8 | D5:4 C5:2 Bb4:2 | C5:2 D5:2 G4:4 | F5:8 | E5:4 G5:4" },
        trem(0.05, [1.4, 0.4]),
        heart(0.18, ["C2", "A2", "Bb2", "G2", "Bb2", "C2"], false),
        { play: "pattern", inst: "harp", oct: 3, pat: "1 . 5 . 8 . 10 .", vol: 0.12, ring: true },
        bass(0.22, "B - - - - - - -"),
      ],
    },
    {
      name: "H (Hélène)", key: "F", bpm: 90, beats: 4, sub: 2, chords: "Bbmaj7 C Bbmaj7 C Gm7 Dm7 Ebmaj7 F",
      layers: [
        { play: "line", inst: "musicbox", lead: true, vol: 0.55, line: "D6:4 C6:2 A5:2 | G5:4 E5:4 | F5:2 A5:2 D6:4 | E6:8 | D6:2 Bb5:2 G5:2 F5:2 | A5:4 F5:4 | G5:2 Bb5:2 D6:2 Eb6:2 | C6:4 A5:4" },
        { play: "pattern", inst: "harp", oct: 3, pat: "1 5 8 10 12 10 8 5", vol: 0.18, ring: true },
        { play: "pattern", inst: "pizz", oct: 2, pat: "1 . . . 5 . . .", vol: 0.3 },
        { play: "chords", inst: "strings", oct: 3, vol: 0.1 },
        { play: "line", inst: "horn", vol: 0.18, line: "F3:8 | E3:8 | F3:8 | G3:8 | r:8 | r:8 | r:8 | r:8" },
        { play: "line", inst: "cello", vol: 0.22, line: "r:8 | r:8 | r:8 | r:8 | Bb2:4 D3:4 | F3:4 A3:4 | G3:4 Bb3:4 | A3:8" },
        bass(0.2, "B - - - - - - -"),
      ],
    },
    {
      name: "C (en majeur)", key: "D", bpm: 104, beats: 4, sub: 2, chords: "D G Em7 D Bm7 Gmaj7 D/A A7",
      layers: [
        { play: "line", inst: "horn", lead: true, vol: 0.55, line: majorHorn },
        { play: "line", inst: "strings", vol: 0.7, transpose: 12, line: majorHorn },
        { play: "line", inst: "horn", vol: 0.34, line: majorSecond },
        { play: "line", inst: "cello", vol: 0.26, line: "D3:4 F#3:4 | G2:4 B2:4 | E3:8 | D3:4 A2:4 | B2:8 | G2:8 | A2:8 | A2:4 G2:4" },
        { play: "pattern", inst: "harp", oct: 3, pat: "1 5 8 10 12 10 8 5", vol: 0.2, ring: true },
        { play: "chords", inst: "strings", oct: 3, vol: 0.12 },
        timp(0.16, ["D2", "G2", "E2", "D2", "B2", "G2", "A2", "A2"]),
        { play: "drums", inst: "taiko", pat: `x . . . . . . . ${". ".repeat(56)}`, vol: 0.16 },
        bass(0.26),
      ],
    },
  ],
};
