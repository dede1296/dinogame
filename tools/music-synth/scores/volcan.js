// Le volcan: Champs de Cendres and Coulées de Lave (chapter 8; tools/zones/volcan_champs.gd,
// volcan_coulees.gd). Ashes and forges: dark but not frightening. C minor with the dorian ♮A (and
// major chords: F, B♭, E♭, A♭) at 92 BPM, 30 bars = 78.3 s, seamless loop. Recipe of the Phaser
// version kept: C minor, taiko, brass; a low marimba ostinato and an anvil ping make the forge.
//   intro (2)  the forge: low marimba in 3+3+2, taiko, anvil
//   A (8)      the reed (oboe) sings a work song in C minor, the ♮A of F major lifting it
//   B (8)      E♭ major, warmer: the horn takes the song, the reed holds a counter-line
//   C (4)      a memory of the Ombre Noire's forges: its motif (ombre.ogg) in the low horns, softly,
//              C phrygian (D♭), never loud
//   A' (8)     the reed and the flute an octave apart; G (V) leads back to the intro's C minor
const forge = (vol = 0.3) => ({ play: "pattern", inst: "marimba", oct: 2, pat: "1 . . 5 . . 8 .", vol });
const anvil = (vol = 0.14) => ({ play: "drums", inst: "triangle", pat: ". . . x . . . . | . . . x . . o .", vol });
const taiko = (vol = 0.3) => ({ play: "drums", inst: "taiko", pat: "x . . . . . o . | x . . . . . . .", vol });
const bass = (vol = 0.38) => ({ play: "pattern", inst: "bass", oct: 2, pat: "1 - . 1 - . 5 .", vol });
const songA = "G4:3 C5:1 Eb5:2 D5:2 | C5:3 A4:1 F4:4 | G4:2 C5:2 Eb5:2 G5:2 | F5:4 D5:2 Bb4:2 | C5:3 Eb5:1 Ab5:4 | G5:2 F5:2 Eb5:2 Bb4:2 | C5:2 D5:2 Eb5:2 F5:2 | D5:6 B4:2";

export default {
  title: "volcan",
  loop: true,
  reverb: 0.36,
  sections: [
    {
      name: "intro (la forge)", key: "Cm", bpm: 92, beats: 4, sub: 2, chords: "Cm Cm",
      layers: [forge(0.32), anvil(), taiko(), bass(0.34), { play: "chords", inst: "cello", oct: 2, vol: 0.14 }],
    },
    {
      name: "A", key: "Cm", bpm: 92, beats: 4, sub: 2, chords: "Cm F Cm Bb Ab Eb F G",
      layers: [
        { play: "line", inst: "reed", lead: true, vol: 0.44, line: songA },
        forge(), anvil(0.12), taiko(0.28), bass(),
        { play: "chords", inst: "strings", oct: 3, vol: 0.13 },
      ],
    },
    {
      name: "B", key: "Eb", bpm: 92, beats: 4, sub: 2, chords: "Eb Bb/D Cm Ab Eb/Bb Bb Ab G",
      layers: [
        { play: "line", inst: "horn", lead: true, vol: 0.5, line: "Eb4:3 F4:1 G4:4 | F4:2 D4:2 Bb3:4 | C4:3 D4:1 Eb4:2 G4:2 | Ab4:6 G4:2 | G4:3 F4:1 Eb4:4 | D4:2 F4:2 Bb4:4 | C5:3 Bb4:1 Ab4:2 F4:2 | G4:8" },
        { play: "line", inst: "reed", vol: 0.24, line: "G5:8 | F5:8 | Eb5:8 | C5:8 | Bb4:8 | D5:8 | Eb5:4 C5:4 | B4:8" },
        forge(0.28), taiko(0.26), { play: "pattern", inst: "bass", oct: 2, pat: "B - . B - . 5 .", vol: 0.38 },
        { play: "chords", inst: "choir", oct: 3, vol: 0.14 },
      ],
    },
    {
      name: "C (les forges de l'Ombre)", key: "Cm", bpm: 92, beats: 4, sub: 2, chords: "Cm Db Cm Db",
      layers: [
        { play: "line", inst: "horn", lead: true, vol: 0.36, line: "C3:3 G2:3 C3:1 Db3:1 | Eb3:2 Db3:2 C3:2 Ab2:2 | C3:3 G2:3 C3:1 Db3:1 | F3:2 Eb3:2 Db3:4" },
        forge(0.3), anvil(0.16), taiko(0.24), bass(0.34),
        { play: "chords", inst: "choir", oct: 3, vol: 0.12 },
      ],
    },
    {
      name: "A'", key: "Cm", bpm: 92, beats: 4, sub: 2, chords: "Cm F Cm Bb Ab Eb F G",
      layers: [
        { play: "line", inst: "reed", lead: true, vol: 0.4, line: songA },
        { play: "line", inst: "flute", vol: 0.26, transpose: 12, line: songA },
        forge(), anvil(0.12), taiko(0.28), bass(),
        { play: "chords", inst: "strings", oct: 3, vol: 0.15 },
      ],
    },
  ],
};
