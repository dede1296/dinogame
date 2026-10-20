// Partition de tools/music-synth/scores → fichier MIDI (un canal par instrument).
// Usage : node export_midi.mjs <piste> [out.mid]
import { writeFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
import path from "node:path";
import { compileScore, compileTheme } from "../music-synth/engine/compile.js";
import { THEMES } from "../music-synth/synth/data/musicThemes.js";
import { THEME_PASSES } from "../music-synth/engine/stats.js";

const PPQ = 960;
// instrument du synthétiseur → programme General MIDI (0-indexé). Percussions : note du canal 10.
const PROG = {
  strings: 48, swell: 49, tremolo: 44, cello: 42, horn: 60, brass: 61, tuba: 58, flute: 73, reed: 68, bassoon: 70,
  bass: 32, harp: 46, pizz: 45, guitar: 24, piano: 0, kalimba: 108, musicbox: 10, bell: 14, marimba: 12,
  lead: 73, synthbass: 38, choir: 52, pad: 89, accordion: 21, fiddle: 40, wind: 75, anvil: 14, timpani: 47, taiko: 116,
};
const PERC = { kick: 36, snare: 38, hat: 42, shaker: 70, tom: 47, block: 76, triangle: 81 };
const MAX_HOLD = 6;

const vlq = (n) => { const b = [n & 0x7f]; while ((n >>= 7)) b.unshift((n & 0x7f) | 0x80); return b; };

export function scoreToMidi(score, { passes = 1, part = 0, compiled = null, program = {} } = {}) {
  const comp = compiled ?? compileScore(score, { reverb: score.reverb });
  const { length, sections } = comp;
  const events = [];
  for (let p = 0; p < passes; p++) for (const e of comp.events) events.push({ ...e, t: e.t + p * length });
  const all = [...new Set(events.map((e) => e.inst))];
  // Plus de 15 instruments mélodiques : plusieurs MIDI (rendus puis additionnés), les percussions dans le premier.
  const melodic = all.filter((i) => !(i in PERC)), PER = 15;
  const parts = Math.max(1, Math.ceil(melodic.length / PER));
  const insts = [...melodic.slice(part * PER, (part + 1) * PER), ...(part === 0 ? all.filter((i) => i in PERC) : [])];
  const chan = new Map(); let next = 0;
  for (const i of insts) {
    if (i in PERC) { chan.set(i, 9); continue; }
    if (next === 9) next++;
    chan.set(i, next++);
  }
  if (next > 16) throw new Error("trop d'instruments");
  const sec = (t) => sections.find((s) => t >= s.start && t < s.end) || sections[sections.length - 1];
  const tick = (t) => Math.round(t * PPQ * 2); // 120 bpm fixes : 1 s = 2 temps = 1920 ticks
  const list = [];
  for (const [inst, ch] of chan) {
    if (ch !== 9) list.push({ t: 0, d: [0xc0 | ch, program[inst] ?? PROG[inst] ?? 0] });
    const ex = events.find((e) => e.inst === inst);
    list.push({ t: 0, d: [0xb0 | ch, 10, Math.round(64 + (ex.pan || 0) * 63)] });
    list.push({ t: 0, d: [0xb0 | ch, 91, Math.round(Math.min(1, (ex.send ?? 0.3) * 1.2 + 0.15) * 127)] });
  }
  for (const e of events) {
    if (!chan.has(e.inst)) continue;
    const ch = chan.get(e.inst);
    const note = e.inst in PERC ? PERC[e.inst] : e.inst === "taiko" ? 45 : Math.max(0, Math.min(127, e.midi));
    const vel = Math.max(1, Math.min(127, Math.round(28 + Math.min(1, e.vel / 0.55) * 99)));
    const dur = Math.min(e.dur, MAX_HOLD, e.inst in PERC ? 0.2 : 99);
    list.push({ t: tick(e.t), d: [0x90 | ch, note, vel], on: 1 });
    list.push({ t: tick(e.t + Math.max(0.05, dur)), d: [0x80 | ch, note, 0] });
  }
  list.sort((a, b) => a.t - b.t || (a.on ? 1 : 0) - (b.on ? 1 : 0));
  const body = []; let last = 0;
  for (const ev of list) { body.push(...vlq(ev.t - last), ...ev.d); last = ev.t; }
  const end = Math.max(last, tick(length * passes) + tick(compiled ? 3 : 1));
  body.push(...vlq(end - last), 0xff, 0x2f, 0);
  const tempo = [0x00, 0xff, 0x51, 3, 0x07, 0xa1, 0x20]; // 500000 µs = 120 bpm
  const trk = [...tempo, ...body];
  const head = [0x4d, 0x54, 0x68, 0x64, 0, 0, 0, 6, 0, 0, 0, 1, (PPQ >> 8) & 255, PPQ & 255];
  const len = trk.length;
  return { bytes: Buffer.from([...head, 0x4d, 0x54, 0x72, 0x6b, len >>> 24, (len >> 16) & 255, (len >> 8) & 255, len & 255, ...trk]), length, loop: !!score?.loop, insts, parts };
}

// Thèmes d'origine (musicThemes.js) : une boucle = N passes (THEME_PASSES), jouée deux fois (on garde la seconde) ;
// un jingle (victoire, capture) = la passe 0 une fois, avec sa queue.
export const JINGLES = ["victoire", "capture"];
const BATTLE = ["sauvage", "rivale", "alpha", "ombre"];
export function themeMidis(id) {
  const def = THEMES[id], once = JINGLES.includes(id), n = once ? 1 : (THEME_PASSES[id] ?? 1);
  const program = BATTLE.includes(id) ? { lead: 56 } : {};
  const compiled = compileTheme(id, def, once ? 0 : 1, once ? 1 : 2 * n);
  const out = [];
  const first = scoreToMidi(null, { compiled, part: 0, program });
  for (let part = 0; part < first.parts; part++) out.push(scoreToMidi(null, { compiled, part, program }));
  return { out, once, n, passLength: compileTheme(id, def, 1, 1).length };
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  const name = process.argv[2];
  if (name.startsWith("theme:")) {
    const id = name.slice(6), t = themeMidis(id);
    t.out.forEach((m, part) => {
      const out = `out/${id}${part ? "_" + (part + 1) : ""}.mid`;
      writeFileSync(out, m.bytes);
      console.log(id, m.length.toFixed(1) + " s", m.insts.join(","), "→", out);
    });
    process.exit(0);
  }
  const score = (await import(pathToFileURL(path.resolve("../music-synth/scores", name + ".js")).href)).default;
  const passes = score.loop ? 2 : 1;
  const { parts } = scoreToMidi(score, { passes });
  for (let part = 0; part < parts; part++) {
    const { bytes, length, insts } = scoreToMidi(score, { passes, part });
    const out = `out/${name}${part ? "_" + (part + 1) : ""}.mid`;
    writeFileSync(out, bytes);
    console.log(name, length.toFixed(1) + " s", insts.join(","), "→", out);
  }
}
