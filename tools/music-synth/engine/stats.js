// Statistics of a piece, from its notes (not from the audio): harmony (chords and degrees), melody
// (motifs, range), texture. Used to compare the new scores with the original themes
// (docs/musiques-composees.md § Mesures). Node only.
import { compileScore, compileTheme, parseChord, tokens } from "./compile.js";

// The keys of the original themes (their chords show them; only the "gen" ones carry a `key`).
const THEME_KEYS = {
  titre: "D", village: "F", plaines: "G", boutique: "C", sauvage: "Am", ombre: "Em", rivale: "D", alpha: "Dm",
  victoire: "C", capture: "C", repos: "F", foret: "Em", marais: "Am", desert: "E", monts: "Bm", cieux: "F",
  volcan: "Cm", apex: "Dm", grotte: "Dm", cote: "D", cabinet: "C", maison: "Am", defaite: "Am",
};
// The passes of one full cycle, as rendered into the game (render-phaser-music.mjs).
export const THEME_PASSES = { titre: 1, village: 3, plaines: 6, boutique: 1, sauvage: 1, ombre: 1, rivale: 1, alpha: 1, foret: 6, marais: 1, desert: 1, monts: 2, cieux: 2, volcan: 2, apex: 2 };

const ROMAN = ["I", "bII", "II", "bIII", "III", "IV", "#IV", "V", "bVI", "VI", "bVII", "VII"];

function degreeOf(sym, key) {
  const k = parseChord(key.replace(/m$/, ""));
  const c = parseChord(sym);
  const step = (c.root - k.root + 12) % 12;
  const minor = c.tones[1] === 3;
  const r = ROMAN[step];
  return (minor ? r.toLowerCase() : r) + (c.tones[2] === 6 ? "°" : "");
}

/** Motif of a bar: its rhythm (steps) and its intervals, whatever the starting pitch. */
function motifs(events) {
  const bars = new Map();
  for (const e of events) {
    if (!bars.has(e.bar)) bars.set(e.bar, []);
    const b = bars.get(e.bar);
    if (!b.some((x) => x.pos === e.pos)) b.push(e); // (the top note of a chord only)
    else { const x = b.find((y) => y.pos === e.pos); if (e.midi > x.midi) Object.assign(x, { midi: e.midi }); }
  }
  const sigs = [];
  for (const [, b] of [...bars].sort((a, c) => a[0] - c[0])) {
    if (b.length < 2) continue;
    b.sort((x, y) => x.pos - y.pos);
    sigs.push(b.map((x, i) => `${x.pos}:${Math.min(x.steps, 8)}:${i ? x.midi - b[i - 1].midi : 0}`).join(" "));
  }
  return { bars: sigs.length, distinct: new Set(sigs).size };
}

function summarize(comp, keyOf) {
  const chords = [], degrees = new Set(), symbols = new Set();
  let changes = 0, prev = null, bars = 0;
  comp.sections.forEach((s) => {
    const key = keyOf(s);
    for (const sym of s.chords) {
      bars++;
      symbols.add(sym);
      if (key) degrees.add(degreeOf(sym, key));
      if (sym !== prev) changes++;
      prev = sym;
      chords.push(sym);
    }
  });
  const lead = comp.events.filter((e) => e.lead);
  const midis = lead.map((e) => e.midi);
  const m = motifs(lead);
  const insts = new Set(comp.events.map((e) => e.inst));
  return {
    seconds: +comp.length.toFixed(2), sections: comp.sections.length, tempi: [...new Set(comp.sections.map((s) => s.bpm))],
    bars, chordSymbols: symbols.size, chordChanges: changes, degrees: [...degrees],
    leadNotes: lead.length, leadRangeSemitones: midis.length ? Math.max(...midis) - Math.min(...midis) : 0,
    leadPitchClasses: new Set(midis.map((x) => x % 12)).size, motifBars: m.bars, distinctMotifs: m.distinct,
    instruments: [...insts], notes: comp.events.length, notesPerSecond: +(comp.events.length / comp.length).toFixed(1),
  };
}

export async function scoreStats(name) {
  const score = (await import(`../scores/${name}.js`)).default;
  const comp = compileScore(score);
  return { name, ...summarize(comp, (s) => s.key || score.key) };
}

export async function themeStats(id) {
  const { THEMES } = await import("../synth/data/musicThemes.js");
  const comp = compileTheme(id, THEMES[id], 1, THEME_PASSES[id] ?? 1);
  // (a cycle repeats its chords: count the bars of one pass, the motifs of the whole cycle)
  const one = tokens(THEMES[id].chords);
  const s = summarize(comp, () => THEME_KEYS[id]);
  return { name: id, ...s, bars: one.length, chordChanges: one.filter((c, i) => c !== one[(i + one.length - 1) % one.length]).length };
}

/**
 * Notes held a beat or more that are not in their bar's chord (a check of the writing: a written
 * appoggiatura is fine, a wrong note is not). Returns [{ section, bar, note, chord, beats }].
 */
export async function clashes(name) {
  const score = (await import(`../scores/${name}.js`)).default;
  const comp = compileScore(score);
  const NAMES = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];
  const chordsByBar = [];
  comp.sections.forEach((s) => s.chords.forEach((c) => chordsByBar.push({ sym: c, section: s.name, sub: s.sub })));
  const out = [];
  for (const e of comp.events) {
    if (e.inst && ["taiko", "kick", "snare", "hat", "shaker", "tom", "block", "triangle"].includes(e.inst)) continue;
    const bar = chordsByBar[e.bar];
    if (!bar || e.steps < bar.sub) continue;
    const c = parseChord(bar.sym);
    const pcs = c.tones.map((t) => (c.root + t) % 12).concat(c.bass ?? []);
    const pc = ((Math.round(e.midi) % 12) + 12) % 12;
    if (!pcs.includes(pc)) out.push({ section: bar.section, bar: e.bar + 1, note: NAMES[pc], chord: bar.sym, beats: e.steps / bar.sub, inst: e.inst });
  }
  return out;
}
