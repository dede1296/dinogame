// La jetée de Port-Ambre, the epilogue (story/apex_jetee.gd: the whole village on the jetty, then the
// end). A quiet party, a gentle village band: musette accordion, a fiddle, a guitar "pompe", a tuba,
// soft horns. Chloé's theme (titre.ogg) turned into a waltz, in joy; and a wink at Brac: his name
// spelled in notes the way B-A-C-H is (German names: B = B♭), B♭ – A – (R: a rest) – C, the gruff tuba
// alone, and the band answers by landing B♭ – C – D (♭VI – ♭VII – I, the happiest of cadences).
// D major, 3/4 at 108 BPM, 48 bars = 80 s, seamless loop. Port-Ambre's own tune (village.ogg) is a
// 3/4 shanty in F: this is its cousin, in Chloé's key.
//   intro (4)   the band starts: guitar pah-pah, tuba oom, a triangle; the accordion runs up into…
//   A (16)      Chloé's whole theme as a waltz: the accordion sings A1–A2 (D Bm G A D F#m G A); the
//               fiddle sings B1–B2 (Bm G D A Bm G Asus4 A), the accordion goes back to pah-pah under it
//   B (12)      the party: a new tune in G (B–D–G, the head of Chloé's theme in passing, E–G–B…), the
//               accordion asks, the fiddle answers, then both in thirds with soft horns; it climbs to
//               A7 and… everybody stops
//   BARC (4)    the tuba, alone: B♭! … A … (a whole bar of silence) … C! — the band bursts out laughing
//               on C (the accordion tumbles down G–E–C–G)
//   A' (8)      the theme again, tutti: the fiddle sings, the accordion in thirds under it, the horns'
//               fanfare, little music-box sparkles
//   coda (4)    the accordion winks once more, softly: B♭–A–(r)–C… D–F#–A–D; the fiddle giggles down
import { bars } from "./_lib.js";

const pompe = (vol, inst = "guitar", oct = 3, strings = "5 8 10") => ({ play: "strum", inst, oct, pat: ". . d . d .", strings, spread: 0.03, vol });
const oom = (vol) => ({ play: "pattern", inst: "tuba", oct: 2, pat: "1 . . . . . | L5 . . . . .", vol });
const shaker = (vol) => ({ play: "drums", inst: "shaker", pat: ". . o . o .", vol });
const triangle = (vol) => ({ play: "drums", inst: "triangle", pat: "x . . . . . | . . . . . .", vol });
const rests = (n) => bars(...Array.from({ length: n }, () => "r:6"));
// Chloé's theme (titre.ogg), as a waltz: A1–A2, then B1–B2.
const themeA = "F#5:3 E5:1 D5:2 | E5:2 F#5:2 B4:2 | D5:3 E5:1 D5:1 B4:1 | C#5:4 A4:2 | F#5:3 E5:1 D5:2 | C#5:2 D5:2 A5:2 | G5:2 F#5:2 E5:1 D5:1 | E5:4 r:2";
const themeB = "D5:2 B4:1 F#5:3 | G5:1 F#5:1 D5:2 B4:2 | A4:2 D5:2 F#5:2 | E5:3 C#5:2 A4:1 | B4:1 D5:1 F#5:2 B5:2 | A5:1 G5:1 F#5:2 D5:2 | E5:3 D5:1 E5:2 | C#5:4 r:2";

export default {
  title: "jetee",
  loop: true,
  reverb: 0.3,
  reverbSeconds: 2.4,
  sections: [
    {
      name: "intro", key: "D", bpm: 108, beats: 3, sub: 2, chords: "D A7 D D",
      layers: [
        pompe(0.36), oom(0.4), triangle(0.1), shaker(0.1),
        { play: "line", inst: "accordion", vol: 0.6, line: `${rests(3)} | r:2 A4:1 B4:1 C#5:1 E5:1` },
      ],
    },
    {
      name: "A (le thème de Chloé)", key: "D", bpm: 108, beats: 3, sub: 2, chords: "D Bm G A D F#m G A Bm G D A Bm G Asus4 A",
      layers: [
        { play: "line", inst: "accordion", lead: true, vol: 0.75, line: `${themeA} | ${rests(8)}` },
        { play: "line", inst: "fiddle", lead: true, vol: 0.42, line: `${rests(8)} | ${themeB}` },
        { play: "strum", inst: "accordion", oct: 4, pat: `${". ".repeat(48)}${". . d . d . ".repeat(8)}`.trim(), strings: "3 5 8", vol: 0.16 },
        pompe(0.36), oom(0.4), triangle(0.1), shaker(0.1),
      ],
    },
    {
      name: "B (la fête)", key: "G", bpm: 108, beats: 3, sub: 2, chords: "G D/F# Em Bm7/D C G/B Am7 D7 G Em C A7",
      layers: [
        { play: "line", inst: "accordion", lead: true, vol: 0.72, line: `B4:2 D5:2 G5:2 | F#5:3 E5:1 D5:2 | E5:2 G5:2 B5:2 | A5:3 G5:1 F#5:2 | ${rests(4)} | B5:3 A5:1 G5:2 | G5:2 F#5:1 E5:1 B4:2 | E5:2 G5:2 C6:2 | C#6:4 r:2` },
        { play: "line", inst: "fiddle", lead: true, vol: 0.4, line: `${rests(4)} | G5:2 E5:2 C5:2 | D5:3 C5:1 B4:2 | C5:2 E5:2 A5:2 | F#5:2 A5:2 C6:2 | G5:3 F#5:1 E5:2 | E5:2 D5:1 C5:1 G4:2 | C5:2 E5:2 G5:2 | A5:4 r:2` },
        { play: "line", inst: "horn", vol: 0.2, line: `${rests(8)} | G4:3 B4:3 | B4:3 G4:3 | G4:6 | G4:3 E4:3` },
        pompe(0.36), oom(0.4), triangle(0.1), shaker(0.1),
      ],
    },
    {
      name: "BARC", key: "D", bpm: 108, beats: 3, sub: 2, chords: "Bb A A C",
      layers: [
        { play: "line", inst: "tuba", lead: true, vol: 0.6, line: "Bb2!:3 r:3 | A2:3 r:3 | r:6 | C3!:2 r:4" },
        { play: "line", inst: "accordion", vol: 0.6, line: "r:6 | r:6 | r:6 | r:2 G5':1 E5':1 C5':1 G4':1" },
        { play: "line", inst: "horn", vol: 0.24, line: "r:6 | r:6 | r:6 | r:2 E4+G4:4" },
        { play: "strum", inst: "guitar", oct: 3, pat: ". . . . . . | . . . . . . | . . . . . . | . . d . d .", strings: "5 8 10", spread: 0.03, vol: 0.4 },
        { play: "drums", inst: "snare", pat: ". . . . . . | . . . . . . | . . . . . . | . . . . r r", vol: 0.1 },
      ],
    },
    {
      name: "A' (tous ensemble)", key: "D", bpm: 108, beats: 3, sub: 2, chords: "D Bm G A D F#m G A",
      layers: [
        { play: "line", inst: "fiddle", lead: true, vol: 0.46, line: themeA },
        { play: "line", inst: "accordion", vol: 0.5, line: "D5:3 C#5:1 A4:2 | B4:2 D5:2 F#4:2 | B4:5 G4:1 | A4:4 E4:2 | D5:3 C#5:1 A4:2 | A4:2 B4:2 F#5:2 | E5:2 D5:2 C#5:1 B4:1 | C#5:4 r:2" },
        { play: "line", inst: "horn", vol: 0.21, line: "A3:3 D4:3 | D4:6 | D4:3 B3:3 | C#4:3 E4:3 | A3:3 D4:3 | C#4:6 | B3:3 D4:3 | C#4:6" },
        { play: "line", inst: "musicbox", vol: 0.2, line: "r:6 | r:6 | r:6 | A6:2 r:4 | r:6 | r:6 | r:6 | E6:2 r:4" },
        pompe(0.38), oom(0.42), triangle(0.12), shaker(0.12),
      ],
    },
    {
      name: "coda (le clin d'œil)", key: "D", bpm: 108, beats: 3, sub: 2, chords: "Bb C D D",
      layers: [
        { play: "line", inst: "accordion", lead: true, vol: 0.6, line: "Bb4':2 A4':2 r:2 | C5:4 r:2 | D5:1 F#5:1 A5:1 D6:3 | r:6" },
        { play: "line", inst: "tuba", vol: 0.36, line: "Bb1:3 r:3 | C2:3 r:3 | D2:3 A1:3 | D2:3 r:3" },
        { play: "line", inst: "fiddle", vol: 0.45, line: "r:6 | r:6 | r:6 | r:3 F#5':1 E5':1 D5':1" },
        pompe(0.32), shaker(0.08),
      ],
    },
  ],
};
