// Les Forges de l'Ombre Noire (chapter 8; tools/zones/volcan_forges.gd). Machines and anvils, but not
// frightening: a heavy, slightly comic march on the Ombre Noire's motif (ombre.ogg: E–B–E–F, G–F–E–C,
// E phrygian), then a clearing when the forges go out. A cousin of ombre.ogg and volcan.ogg (the anvil
// in 3+3+2). 4/4 at 96 BPM in sixteenths, 28 bars ≈ 70.9 s, seamless loop.
//   PART 1, the forges lit (14 bars, 35.9 s)
//   intro (2)      the machine: anvils in 3+2+3 (E–B–E), wooden gears ticking, a tuba "oom", pizzicato
//                  "pah", steam on the off-beats, a big soft foot (taiko) on each bar
//   A (8)          the march: the bassoon tiptoes the Ombre's whole tune, staccato (Em F Em F C B7 Em
//                  B7); the oboe giggles in its long notes; a snare roll at each half
//   A' (3)         the hammer: two horns in octaves take the head, heavy; the bassoon runs under them in
//                  eighths, the anvils hammer every beat, a kettle whistles (E–F–E–F)
//   point d'orgue  B7 held, slowing to half speed: the last blow, then steam escaping (a long hiss)
//   PART 2, the forges out (14 bars, 35 s)
//   C (8)          the clearing: E MAJOR, the flute sings the same tune with its F♮ turned to F♯ (as Brac's
//                  lullaby in the end film), harp, pizzicato bass, a soft horn, the metal ticking as it cools
//   D (4)          rest: the horn sings A – B – E; the bassoon, out of habit, starts the old minor head
//                  (E–B–E–F♮)… and the flute corrects it: F♯–G♯–E
//   link (2)       C – B7: the tuba and the gears wake up, back to the machine
// Each half loops on its own too (part 1 ends on B7 → Em; part 2 on B7 → E): to split it into two
// moods, render sections 1–4 and 5–7 separately (see docs/musiques-composees.md).
const tuba = (vol) => ({ play: "pattern", inst: "tuba", oct: 2, pat: "1 . . . . . . . L5 . . . . . . .", vol });
const pah = (vol) => ({ play: "strum", inst: "pizz", oct: 3, pat: ". . . . d . . . . . . . d . . .", strings: "3 5 8", vol });
const anvil = (vol, pat = "8 . . . . . 12 . . . 8 . . . . .") => ({ play: "pattern", inst: "anvil", oct: 4, pat, vol });
const gears = (vol) => ({ play: "drums", inst: "block", pat: "x . . . o . . . x . . . o . . .", vol });
const steam = (vol) => ({ play: "drums", inst: "shaker", pat: ". . x . . . x . . . x . . . x .", vol });
const foot = (vol, pat = "x . . . . . . . . . . . . . . .") => ({ play: "drums", inst: "taiko", pat, vol });
const bars = (n) => Array.from({ length: n }, () => ". ".repeat(16).trim()).join(" | ");
// The Ombre's tune (ombre.ogg), two octaves down, in sixteenths, staccato: the bassoon's march.
const march = "E3':6 B2':6 E3':2 F3':2 | G3':4 F3':4 E3':4 C3':4 | E3':6 B2':6 E3':2 G3':2 | A3':4 G3':4 F3:8 | G3':6 E3':6 C3':2 E3':2 | F#3':6 D#3':6 B2':4 | E3':4 G3':4 B3':4 A3':2 G3':2 | F#3:8 D#3':4 B2':4";
const roll = ". . . . . . . . . . . . r r x .";

export default {
  title: "forges_ombre",
  loop: true,
  reverb: 0.3,
  sections: [
    {
      name: "intro (la machine)", key: "Em", bpm: 96, beats: 4, sub: 4, chords: "Em Em",
      layers: [anvil(0.15), gears(0.2), tuba(0.44), pah(0.4), foot(0.16), steam(0.22), { play: "chords", inst: "strings", oct: 3, vol: 0.12 }],
    },
    {
      name: "A (la marche)", key: "Em", bpm: 96, beats: 4, sub: 4, chords: "Em F Em F C B7 Em B7",
      layers: [
        { play: "line", inst: "bassoon", lead: true, vol: 0.9, line: march },
        { play: "line", inst: "reed", vol: 0.4, line: "r:16 | r:16 | r:16 | r:8 A5':1 G5':1 F5':2 r:4 | r:16 | r:16 | r:16 | r:2 D#6':1 E6':1 F#6':2 r:10" },
        tuba(0.36), pah(0.27), anvil(0.1), gears(0.14), foot(0.16), steam(0.14),
        { play: "drums", inst: "snare", pat: `${bars(3)} | ${roll} | ${bars(3)} | ${roll}`, vol: 0.14 },
        { play: "chords", inst: "strings", oct: 3, vol: 0.13 },
      ],
    },
    {
      name: "A' (le marteau)", key: "Em", bpm: 96, beats: 4, sub: 4, chords: "Em F Em",
      layers: [
        { play: "line", inst: "horn", lead: true, vol: 0.46, line: "E4:6 B3:6 E4:2 F4:2 | G4:4 F4:4 E4:4 C4:4 | E4:6 B3:6 E4:2 G4:2" },
        { play: "line", inst: "horn", vol: 0.26, transpose: -12, line: "E4:6 B3:6 E4:2 F4:2 | G4:4 F4:4 E4:4 C4:4 | E4:6 B3:6 E4:2 G4:2" },
        { play: "line", inst: "bassoon", vol: 0.5, line: "E3':2 G3':2 B3':2 G3':2 E3':2 G3':2 B3':2 C4':2 | A3':2 C4':2 F3':2 A3':2 C4':2 A3':2 F3':2 E3':2 | G3':2 B3':2 E4':2 B3':2 G3':2 E3':2 B2':2 D#3':2" },
        { play: "line", inst: "reed", vol: 0.3, line: "r:16 | r:16 | r:8 E5':1 F5':1 E5':1 F5':1 E5':1 F5':1 E5':1 F5':1" },
        tuba(0.27), pah(0.3), anvil(0.08, "8 . . . 12 . . . 8 . . . 12 . . ."), gears(0.12),
        foot(0.15, "x . . . . . . . x . . . . . . ."),
        { play: "drums", inst: "snare", pat: "x . . . . . x . x . . . . . . .", vol: 0.12 },
      ],
    },
    {
      name: "point d'orgue", key: "Em", bpm: 96, rit: 0.5, beats: 4, sub: 4, chords: "B7",
      layers: [
        { play: "line", inst: "horn", vol: 0.42, line: "F#4!:16" },
        { play: "line", inst: "horn", vol: 0.32, line: "D#4:16" },
        { play: "line", inst: "bassoon", vol: 0.5, line: "A3:16" },
        { play: "line", inst: "tuba", vol: 0.3, line: "B1:16" },
        { play: "line", inst: "anvil", vol: 0.14, line: "B5!:16" },
        foot(0.12),
        { play: "drums", inst: "snare", pat: "R R R R x . . . . . . . . . . .", vol: 0.12 },
        { play: "line", inst: "wind", vol: 0.16, ring: true, line: "r:4 B4:12" },
      ],
    },
    {
      name: "C (l'éclaircie)", key: "E", bpm: 96, beats: 4, sub: 4, chords: "E Amaj7 E B7/D# C#m G#m7 E/G# B7",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.2, line: "E5:6 B4:6 E5:2 F#5:2 | G#5:4 F#5:4 E5:4 C#5:4 | E5:6 B4:6 E5:2 G#5:2 | A5:4 G#5:4 F#5:8 | G#5:6 E5:6 C#5:2 E5:2 | F#5:6 D#5:6 B4:4 | E5:4 G#5:4 B5:4 A5:2 G#5:2 | F#5:8 D#5:4 B4:4" },
        { play: "pattern", inst: "harp", oct: 3, pat: "1 . 5 . 8 . 10 . 12 . 10 . 8 . 5 .", vol: 0.18, ring: true },
        { play: "pattern", inst: "pizz", oct: 2, pat: "B . . . . . . . 5 . . . . . . .", vol: 0.42 },
        { play: "line", inst: "horn", vol: 0.2, line: "B3:16 | C#4:16 | B3:16 | A3:16 | G#3:16 | B3:16 | B3:16 | A3:16" },
        { play: "chords", inst: "strings", oct: 3, vol: 0.08 },
        { play: "line", inst: "anvil", vol: 0.05, line: "r:12 E6:4 | r:16 | r:6 B6:2 r:8 | r:16 | r:10 E6:2 r:4 | r:16 | r:4 G#6:2 r:10 | r:16" },
        { play: "drums", inst: "shaker", pat: ". . . . o . . . . . . . o . . .", vol: 0.1 },
        { play: "drums", inst: "triangle", pat: `x . . . . . . . . . . . . . . . | ${bars(7)}`, vol: 0.12 },
      ],
    },
    {
      name: "D (le repos)", key: "E", bpm: 96, beats: 4, sub: 4, chords: "A B E E",
      layers: [
        { play: "line", inst: "horn", lead: true, vol: 0.42, line: "C#4:4 E4:4 A4:8 | F#4:4 D#4:4 B3:8 | r:16 | r:16" },
        { play: "line", inst: "bassoon", vol: 0.85, line: "r:16 | r:16 | E3':6 B2':6 E3':2 F3':2 | r:16" },
        { play: "line", inst: "flute", lead: true, vol: 0.24, line: "r:16 | r:16 | r:16 | F#5!:2 r:2 G#5:4 E5:8" },
        { play: "pattern", inst: "harp", oct: 3, pat: "1 . 5 . 8 . 10 . 12 . 10 . 8 . 5 .", vol: 0.16, ring: true },
        { play: "pattern", inst: "pizz", oct: 2, pat: "B . . . . . . . 5 . . . . . . .", vol: 0.4 },
        { play: "chords", inst: "strings", oct: 3, vol: 0.08 },
        { play: "line", inst: "anvil", vol: 0.05, line: "r:16 | r:8 F#6:2 r:6 | r:16 | r:12 B6:4" },
      ],
    },
    {
      name: "link (les machines)", key: "Em", bpm: 96, beats: 4, sub: 4, chords: "C B7",
      layers: [
        { play: "line", inst: "bassoon", vol: 0.8, line: "C3':4 E3':4 G3':4 E3':4 | D#3':4 F#3':4 A3':4 F#3':4" },
        { play: "line", inst: "tuba", vol: 0.36, line: "C2':4 r:4 G1':4 r:4 | B1':4 r:4 F#2':4 r:4" },
        pah(0.32), gears(0.14), anvil(0.09),
        { play: "drums", inst: "snare", pat: `${". ".repeat(16).trim()} | ${roll}`, vol: 0.12 },
        foot(0.18),
      ],
    },
  ],
};
