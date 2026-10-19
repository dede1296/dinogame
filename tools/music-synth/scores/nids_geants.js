// Les Nids géants, the sanctuary of the Quetzalcoatlus Roi (chapter 7; tools/zones/nids_geants.gd).
// Majestic and warm: immense wings, the wind, a chorale of soft horns. A cousin of cieux.ogg (whose B
// section, the horn tune of the King of the Skies, gives this one its head: D–F, C–F–A, B♭–A–G), but
// lower and more solemn: B♭ major (with the lydian A♮ of the sky over E♭ in B), 3/4 at 72 BPM, the slow
// sway of the wings. 28 bars = 70 s, seamless loop.
//   intro (2)  the wind: harp sweeps upwards, a pitched gust, a distant horn call (G minor → F/A, the
//              bass climbing G–A to the B♭ of the chorale)
//   A (8)      the chorale: the King's tune in two horns (thirds and sixths), cellos walking down, the
//              harp rolling like wings, a timpani stroke on bars 1 and 5 (a wing beat); half cadence on F
//   B (8)      the flight: G minor, the flute rises and glides (a new tune, D–G–B♭, the lydian A over
//              E♭maj7, up to E♭6), the horns hold a soft chorale under it, strings trembling like
//              feathers, pizzicato bass; a timpani roll on F7sus4 lifts into A'
//   A' (10)    the tune in full: violins an octave above the horns, the climax on E♭6 (bar 6), then a
//              plagal "amen" (E♭6 → B♭) held on the third, D: the loop breathes back into the wind
const harp = (vol, pat) => ({ play: "pattern", inst: "harp", oct: 3, pat, vol, ring: true });
const bass = (vol) => ({ play: "pattern", inst: "bass", oct: 2, pat: "B - - - - -", vol });
const wind = (vol, line) => ({ play: "line", inst: "wind", vol, ring: true, line });
// The King's chorale (A), written for the first horn; A' gives it to the violins an octave up.
const chorale = "D4:3 F4:3 | C4:2 F4:1 A4:3 | Bb4:3 A4:2 G4:1 | G4:4 F4:1 Eb4:1 | D4:3 F4:3 | Bb4:2 Eb5:1 D5:3 | Eb5:2 D5:1 C5:3";
const choraleEnd = "Bb4:2 A4:1 C5:3";                                          // (A: half cadence on F)
const choraleWide = "C5:2 Bb4:1 A4:3 | Eb5:3 C5:2 Bb4:1 | D5:6";                 // (A': F7, E♭6, B♭)
const second = "Bb3:3 D4:3 | A3:2 C4:1 F4:3 | D4:3 F4:2 Eb4:1 | Eb4:4 D4:1 C4:1 | Bb3:3 D4:3 | G4:3 Bb4:3 | G4:2 F4:1 Eb4:3";

export default {
  title: "nids_geants",
  loop: true,
  reverb: 0.5,
  reverbSeconds: 3.4,
  sections: [
    {
      name: "intro (le vent)", key: "Bb", bpm: 72, beats: 3, sub: 2, chords: "Gm7 F/A",
      layers: [
        wind(0.1, "D5:6 | C5:6"),
        harp(0.26, "1 5 8 10 12 15"),
        { play: "line", inst: "horn", vol: 0.34, send: 0.7, line: "r:3 D4:1 G4:2 | F4:4 C4:2" },
        { play: "line", inst: "cello", vol: 0.24, line: "G2:6 | A2:6" },
        bass(0.24),
        { play: "chords", inst: "strings", oct: 3, vol: 0.08 },
      ],
    },
    {
      name: "A (le choral)", key: "Bb", bpm: 72, beats: 3, sub: 2, chords: "Bb F/A Gm7 Eb Bb/D Ebmaj7 Cm7 F",
      layers: [
        { play: "line", inst: "horn", lead: true, vol: 0.6, line: `${chorale} | ${choraleEnd}` },
        { play: "line", inst: "horn", vol: 0.36, line: `${second} | D4:2 C4:1 F4:3` },
        { play: "line", inst: "cello", vol: 0.26, line: "Bb2:6 | A2:6 | G2:3 F2:3 | Eb2:6 | D2:6 | Eb2:3 G2:3 | C3:3 Bb2:3 | A2:3 F2:3" },
        bass(0.26),
        harp(0.22, "1 5 8 10 8 5"),
        { play: "chords", inst: "strings", oct: 3, vol: 0.1 },
        { play: "line", inst: "timpani", vol: 0.2, line: "Bb2:6 | r:6 | r:6 | r:6 | F2:6 | r:6 | r:6 | r:6" },
        wind(0.07, "r:6 | r:6 | r:6 | Bb4:6 | r:6 | r:6 | r:6 | C5:6"),
      ],
    },
    {
      name: "B (l'envol)", key: "Bb", bpm: 72, beats: 3, sub: 2, chords: "Gm Ebmaj7 Cm7 D7 Gm Ebmaj7 Cm7 F7sus4",
      layers: [
        { play: "line", inst: "flute", lead: true, vol: 0.3, line: "D5:1 G5:1 Bb5:4 | A5:1 Bb5:1 G5:4 | C6:2 Eb6:2 D6:1 C6:1 | Bb5:2 A5:4 | D5:1 G5:1 D6:4 | C6:1 D6:1 Bb5:4 | Eb6:3 C6:2 G5:1 | F5:3 Eb5:2 C5:1" },
        { play: "line", inst: "horn", vol: 0.3, line: "D4:6 | Eb4:3 D4:3 | C4:3 Eb4:3 | D4:3 C4:3 | Bb3:6 | Bb3:3 G3:3 | G3:3 C4:3 | Eb4:3 C4:3" },
        { play: "line", inst: "horn", vol: 0.22, line: "Bb3:6 | G3:6 | G3:6 | F#3:6 | G3:6 | G3:6 | Eb3:6 | F3:6" },
        { play: "chords", inst: "tremolo", oct: 3, trem: 9, vol: 0.028, dyn: [0.5, 1.3] },
        harp(0.17, "1 5 8 10 12 15"),
        { play: "pattern", inst: "pizz", oct: 2, pat: "1 . . . 5 .", vol: 0.36 },
        bass(0.22),
        wind(0.07, "r:6 | G5:6 | r:6 | r:6 | r:6 | Bb4:6 | r:6 | r:6"),
        { play: "line", inst: "bell", vol: 0.07, line: "r:6 | r:6 | r:6 | r:6 | D6:6 | r:6 | r:6 | r:6" },
        { play: "line", inst: "timpani", vol: 0.15, line: "r:6 | r:6 | r:6 | r:6 | r:6 | r:6 | r:6 | F2_:1 F2_:1 F2:1 F2:1 F2:1 F2!:1" },
      ],
    },
    {
      name: "A' (le Roi)", key: "Bb", bpm: 72, beats: 3, sub: 2, chords: "Bb F/A Gm7 Eb Bb/D Ebmaj7 Cm7 F7 Eb6 Bb",
      layers: [
        { play: "line", inst: "strings", lead: true, vol: 0.8, transpose: 12, line: `${chorale} | ${choraleWide}` },
        { play: "line", inst: "horn", vol: 0.54, line: `${chorale} | ${choraleWide}` },
        { play: "line", inst: "horn", vol: 0.34, line: `${second} | F4:3 Eb4:3 | G4:6 | F4:6` },
        { play: "line", inst: "cello", vol: 0.28, line: "Bb2:6 | A2:6 | G2:3 F2:3 | Eb2:6 | D2:6 | Eb2:3 G2:3 | C3:3 Bb2:3 | F2:3 A2:3 | G2:3 C3:3 | Bb2:6" },
        bass(0.28),
        harp(0.24, "1 5 8 10 12 10"),
        { play: "chords", inst: "strings", oct: 3, vol: 0.12 },
        { play: "line", inst: "timpani", vol: 0.22, line: "Bb2:6 | r:6 | r:6 | r:6 | F2:3 F2:3 | Bb2:6 | r:6 | F2:6 | r:6 | Bb2_:6" },
        wind(0.08, "r:6 | r:6 | r:6 | r:6 | r:6 | Eb5:6 | r:6 | r:6 | r:6 | F5:6"),
        { play: "drums", inst: "triangle", pat: `x . . . . . ${". ".repeat(24)}x . . . . . ${". ".repeat(24)}`, vol: 0.14 },
      ],
    },
  ],
};
