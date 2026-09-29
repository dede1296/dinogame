// The atlas of Ambrelune: the whole island, drawn like an explorer's map, and the source of
// its geography (which region lies where, what they share at their borders):
//   Godot/assets/art/ui/atlas_ile.png      the painted map (coasts, relief, biomes, rivers, villages)
//   Godot/assets/art/ui/atlas_regions.png  one grey level per region (index * 16; sea = 255):
//                                           what a tap on the map hits, where the mist stays
//   Godot/data/atlas_db.gd                 the regions (names, zones, levels, where names go)
// The regions ring the volcano, clockwise from the south (docs/histoire.md, « Géographie ») :
// Port-Ambre and the Plaines (south), Havre-Doré (south-east bay), the Forêt (south-west), the
// Marais (west), the Désert (north-west), the Côte (north), the Monts Gelés (north-east down to
// the east of the Plaines); inside: the Cieux above the Monts, the Plaine Volcanique, the crater.
// Regions are cells around seeds, in warped space (organic borders); their colours blend over
// a wide band (the Plaines' woods thicken into the Forêt, the Forêt sinks into the Marais…).
// Usage (repository root): node Godot/tools/maps/gen-atlas.mjs
import sharp from "sharp";
import fs from "node:fs";

const N = 1024;
const OUT_ART = "Godot/assets/art/ui";
const OUT_DB = "Godot/data/atlas_db.gd";
const C = [0.5, 0.5];   // the volcano
// The map is drawn a little zoomed out, so the whole island and a rim of sea fit in the image:
// U() turns an image coordinate (0–1) into island space (where everything below is placed),
// I() the other way round (what the game gets).
const Z = 1.3;
const U = (v) => 0.5 + (v - 0.5) * Z;
const I = (v) => 0.5 + (v - 0.5) / Z;
const toImage = (p) => [I(p[0]), I(p[1])];

// ---------------------------------------------------------------- noise
function hash(x, y) {
  let h = (x * 374761393 + y * 668265263) | 0;
  h = (h ^ (h >>> 13)) * 1274126177 | 0;
  return ((h ^ (h >>> 16)) >>> 0) / 4294967295;
}
function noise(x, y) {
  const xi = Math.floor(x), yi = Math.floor(y), fx = x - xi, fy = y - yi;
  const s = (t) => t * t * (3 - 2 * t);
  const a = hash(xi, yi), b = hash(xi + 1, yi), c = hash(xi, yi + 1), d = hash(xi + 1, yi + 1);
  return a + (b - a) * s(fx) + (c - a) * s(fy) + (a - b - c + d) * s(fx) * s(fy);
}
const fbm = (x, y, o = 5) => { let v = 0, a = 0.5, f = 1, t = 0; for (let i = 0; i < o; i++) { v += a * noise(x * f + i * 17.3, y * f + i * 9.1); t += a; f *= 2.03; a *= 0.5; } return v / t; };
const ridge = (x, y) => 1 - Math.abs(fbm(x, y, 4) * 2 - 1);
const smooth = (a, b, t) => { const k = Math.max(0, Math.min(1, (t - a) / (b - a))); return k * k * (3 - 2 * k); };
const mix = (a, b, t) => a.map((v, i) => v + (b[i] - v) * t);
const hex = (h) => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
const gauss = (x, y, cx, cy, r) => Math.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (r * r));

// ---------------------------------------------------------------- regions
// seeds: where the region lies (0–1); w: extra reach (bigger = wider region).
const REGIONS = [
  { id: "plaines", name: "Plaines des Fougères", zones: ["plaines", "grotte_echos", "antre_crane"], levels: [2, 8], seeds: [[0.5, 0.72]], w: 0.02, c: "#93bb68" },
  { id: "port", name: "Port-Ambre", zones: ["port_ambre", "cabinet"], levels: [1, 1], seeds: [[0.49, 0.875]], w: -0.075, c: "#cdb98e" },
  { id: "havre", name: "Havre-Doré", zones: ["havre_dore"], levels: [1, 1], seeds: [[0.76, 0.755]], w: -0.06, c: "#d8bb78" },
  { id: "foret", name: "Forêt Jurassique", zones: ["foret", "camp_ombre"], levels: [10, 18], seeds: [[0.27, 0.7], [0.36, 0.83]], w: 0.0, c: "#3f6d38" },
  { id: "marais", name: "Marais Brumeux", zones: ["marais", "temple_englouti"], levels: [15, 21], seeds: [[0.15, 0.47]], w: 0.0, c: "#6d7f55" },
  { id: "desert", name: "Désert Aride", zones: ["desert", "sanctuaire_vents"], levels: [21, 27], seeds: [[0.28, 0.2], [0.2, 0.3]], w: 0.0, c: "#e2b56c" },
  { id: "cote", name: "Côte Préhistorique", zones: ["cote", "grottes_marines", "recif_sanctuaire"], levels: [28, 35], seeds: [[0.55, 0.1], [0.7, 0.14]], w: -0.01, c: "#a7c98a" },
  { id: "monts", name: "Monts Gelés", zones: ["monts"], levels: [33, 40], seeds: [[0.84, 0.36], [0.76, 0.6]], w: 0.02, c: "#9ea08c" },
  { id: "cieux", name: "Cieux Éternels", zones: ["cieux"], levels: [38, 44], seeds: [[0.63, 0.3]], w: -0.035, c: "#dfe8f2" },
  { id: "volcan", name: "Plaine Volcanique", zones: ["volcan"], levels: [42, 48], seeds: [], w: 0, c: "#5f4a42" },
  { id: "apex", name: "Terre des Apex", zones: ["apex"], levels: [50, 50], seeds: [], w: 0, c: "#3a2622" },
];
const G = Object.fromEntries(REGIONS.map((r, i) => [r.id, i]));

// Warped coordinates: every border wanders.
const warp = (x, y, amp = 0.07, f = 3.2) => [x + (fbm(x * f + 3.1, y * f + 7.7, 4) - 0.5) * amp * 2, y + (fbm(x * f + 11.4, y * f + 1.9, 4) - 0.5) * amp * 2];

// ---------------------------------------------------------------- land and height
const land = new Uint8Array(N * N), height = new Float32Array(N * N), region = new Int16Array(N * N).fill(-1);
for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) {
  const x = U(i / N), y = U(j / N), k = j * N + i;
  const [wx, wy] = warp(x, y, 0.09, 2.2);
  // Base: a rounded mass, stretched a little east–west, with capes and bays from noise.
  const d = Math.hypot((wx - C[0]) / 1.06, (wy - C[1]) / 0.97);
  let e = 1 - d / 0.42 + (fbm(x * 3.5, y * 3.5) - 0.5) * 0.55;
  e -= 0.5 * gauss(x, y, 0.49, 0.965, 0.07);     // Port-Ambre's cove
  e -= 0.55 * gauss(x, y, 0.8, 0.84, 0.075);     // Havre-Doré's bay
  e -= 0.35 * gauss(x, y, 0.56, 0.02, 0.06);     // the Côte's lagoon
  e += 0.25 * gauss(x, y, 0.1, 0.52, 0.09);      // the Marais' delta, pushing out
  e += 0.2 * gauss(x, y, 0.9, 0.3, 0.07);        // a cape north-east
  e += (fbm(x * 13, y * 13, 3) - 0.5) * 0.2;       // small inlets and points along the coast
  for (const [ix, iy, ir] of [[0.2, 0.12, 0.022], [0.06, 0.66, 0.018], [0.93, 0.62, 0.02], [0.62, 0.95, 0.014], [0.97, 0.2, 0.016]])
    e = Math.max(e, 0.25 * (1 - Math.hypot(x - ix, y - iy) / ir) + (fbm(x * 25, y * 25, 2) - 0.5) * 0.2);   // islets
  const isLand = e > 0;
  land[k] = isLand ? 1 : 0;
  const dv = Math.hypot(x - C[0], y - C[1]);
  let h = Math.max(0, e) * 0.9 + fbm(x * 6, y * 6, 4) * 0.12;
  h += 0.7 * gauss(x, y, C[0], C[1], 0.12) - 0.45 * gauss(x, y, C[0], C[1], 0.025);   // volcano, crater
  height[k] = isLand ? h : 0;
}
// Mountains where the Monts and the Cieux are (ridges), after regions are known.

// Regions: nearest seed in warped space, minus its reach; the volcano's rings by distance.
for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) {
  const k = j * N + i;
  if (!land[k]) continue;
  const x = U(i / N), y = U(j / N);
  const [ux, uy] = warp(x, y, 0.15, 2.0);
  const [vx, vy] = warp(ux, uy, 0.05, 6.0);
  const [wx, wy] = warp(vx, vy, 0.015, 16.0);
  const dv = Math.hypot(wx - C[0], wy - C[1]);
  if (dv < 0.055) { region[k] = G.apex; continue; }
  let best = -1, bestD = 9;
  for (let g = 0; g < REGIONS.length; g++) {
    for (const [sx, sy] of REGIONS[g].seeds) {
      const dd = Math.hypot(wx - sx, wy - sy) - REGIONS[g].w;
      if (dd < bestD) { bestD = dd; best = g; }
    }
  }
  // The volcanic plain rings the crater, except where the Cieux rise above it.
  if (dv < 0.17 && best !== G.cieux) best = G.volcan;
  region[k] = best;
}


// ---------------------------------------------------------------- rivers (downhill to the sea)
const water = new Uint8Array(N * N);
const trace = (sx, sy, widthEnd) => {
  let i = Math.round(I(sx) * N), j = Math.round(I(sy) * N);
  const path = [];
  for (let step = 0; step < 1500; step++) {
    const k = j * N + i;
    if (!land[k]) break;
    path.push([i, j]);
    // Down and away from the volcano (so it always reaches the sea), meandering.
    const F = (ii, jj) => height[jj * N + ii] * 0.8 - Math.hypot(U(ii / N) - C[0], U(jj / N) - C[1]) * 0.9
      + (fbm(U(ii / N) * 7 + sx * 13, U(jj / N) * 7, 3) - 0.5) * 0.3;
    let bi = i, bj = j, bf = 1e9;
    for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) {
      if (!dx && !dy) continue;
      const ii = i + dx, jj = j + dy;
      if (ii < 0 || jj < 0 || ii >= N || jj >= N || path.some(([pi, pj]) => pi === ii && pj === jj)) continue;
      const f = F(ii, jj);
      if (f < bf) { bf = f; bi = ii; bj = jj; }
    }
    if (bf === 1e9) break;
    i = bi; j = bj;
  }
  path.forEach(([pi, pj], n) => {
    const w = 0.8 + (n / path.length) * widthEnd;
    for (let dy = -4; dy <= 4; dy++) for (let dx = -4; dx <= 4; dx++) {
      if (dx * dx + dy * dy > w * w) continue;
      const ii = pi + dx, jj = pj + dy;
      if (ii >= 0 && jj >= 0 && ii < N && jj < N) water[jj * N + ii] = 1;
    }
  });
};

// ---------------------------------------------------------------- paint
const SEA_DEEP = hex("#5d8ea5"), SEA_SHALLOW = hex("#93c3ce"), SAND = hex("#e8d6a4"), INK = hex("#3b2a1c");
const PAPER = hex("#ecdfbf");
// Base colour per pixel, then blurred for wide soft transitions between biomes.
const base = new Float32Array(N * N * 3);
for (let k = 0; k < N * N; k++) {
  const c = land[k] ? hex(REGIONS[region[k]].c) : [0, 0, 0];
  base[k * 3] = c[0]; base[k * 3 + 1] = c[1]; base[k * 3 + 2] = c[2];
}
const blur = (src, radius) => {
  const tmp = new Float32Array(src.length), out = new Float32Array(src.length);
  for (const [from, to, horizontal] of [[src, tmp, true], [tmp, out, false]]) {
    for (let a = 0; a < N; a++) {
      const acc = [0, 0, 0]; let n = 0;
      const at = (b) => (horizontal ? a * N + b : b * N + a);
      for (let b = -radius; b < N + radius; b++) {
        const add = b + radius, rem = b - radius - 1;
        if (add >= 0 && add < N && land[at(add)]) { const k = at(add); for (let m = 0; m < 3; m++) acc[m] += from[k * 3 + m]; n++; }
        if (rem >= 0 && rem < N && land[at(rem)]) { const k = at(rem); for (let m = 0; m < 3; m++) acc[m] -= from[k * 3 + m]; n--; }
        if (b >= 0 && b < N && n > 0) { const k = at(b); for (let m = 0; m < 3; m++) to[k * 3 + m] = acc[m] / n; }
      }
    }
  }
  return out;
};
const soft = blur(base, 26);
// How much each biome is present around a pixel (soft), to fade its details at the borders.
const weights = {};
for (const group of [["foret", "marais", "desert"], ["cieux", "monts", "volcan"], ["plaines", "cote", "apex"]]) {
  const m = new Float32Array(N * N * 3);
  for (let k = 0; k < N * N; k++) group.forEach((id, n) => { m[k * 3 + n] = region[k] === G[id] ? 255 : 0; });
  const b = blur(m, 11);
  group.forEach((id, n) => { const w = new Float32Array(N * N); for (let k = 0; k < N * N; k++) w[k] = b[k * 3 + n] / 255; weights[id] = w; });
}
// Ridges on the Monts and the Cieux, fading out at their edges (no step in the relief).
for (let k = 0; k < N * N; k++) {
  if (!land[k]) continue;
  const x = U((k % N) / N), y = U(Math.floor(k / N) / N);
  height[k] += 0.45 * ridge(x * 7, y * 7) * weights.monts[k] + 0.6 * ridge(x * 9, y * 9) * weights.cieux[k];
  height[k] += 0.015 * Math.sin(x * 110 + y * 30 + fbm(x * 7, y * 7) * 10) * weights.desert[k];
}
// Rivers, now that the relief is final.
trace(0.36, 0.4, 3.5);    // through the Marais
trace(0.7, 0.5, 3.0);     // down the Monts towards Havre-Doré
trace(0.57, 0.3, 2.5);    // to the Côte
trace(0.36, 0.62, 2.2);   // through the Forêt
const coastDist = new Float32Array(N * N).fill(99);
{
  const q = [];
  for (let k = 0; k < N * N; k++) if (land[k]) { coastDist[k] = 0; q.push(k); }
  for (let h = 0; h < q.length; h++) {
    const k = q[h], i = k % N, j = (k - i) / N;
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const ii = i + dx, jj = j + dy;
      if (ii < 0 || jj < 0 || ii >= N || jj >= N) continue;
      const n = jj * N + ii;
      if (coastDist[n] > coastDist[k] + 1 && coastDist[k] < 60) { coastDist[n] = coastDist[k] + 1; q.push(n); }
    }
  }
}
const isCoast = (i, j) => [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dx, dy]) => { const ii = i + dx, jj = j + dy; return ii >= 0 && jj >= 0 && ii < N && jj < N && !land[jj * N + ii]; });
const nearSea = (i, j, r) => { for (let dy = -r; dy <= r; dy += 2) for (let dx = -r; dx <= r; dx += 2) { const ii = i + dx, jj = j + dy; if (ii >= 0 && jj >= 0 && ii < N && jj < N && !land[jj * N + ii]) return true; } return false; };

const img = Buffer.alloc(N * N * 3), ids = Buffer.alloc(N * N);
for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) {
  const k = j * N + i, x = U(i / N), y = U(j / N);
  const grain = (hash(i, j) - 0.5) * 8;
  let c;
  if (!land[k]) {
    const d = coastDist[k];
    c = mix(SEA_SHALLOW, SEA_DEEP, smooth(2, 50, d));
    if (d > 4 && d < 6.5) c = mix(c, [255, 255, 255], 0.3);
    if (d > 14 && d < 60 && Math.abs(Math.sin(d * 0.3)) < 0.04) c = mix(c, [255, 255, 255], 0.12);   // swell lines
    ids[k] = 255;
  } else {
    const reg = REGIONS[region[k]].id;
    ids[k] = region[k] * 16;
    c = [soft[k * 3], soft[k * 3 + 1], soft[k * 3 + 2]];
    const f = fbm(x * 38, y * 38, 3), f2 = fbm(x * 70, y * 70, 2);
    // Biome details, faded at the region's edges by the blur itself.
    const W = (id) => weights[id][k];
    c = mix(c, hex("#2a5226"), smooth(0.42, 0.7, f) * 0.85 * W("foret"));                       // crowns
    c = mix(c, hex("#4d7a3a"), smooth(0.64, 0.7, f) * 0.6 * W("plaines"));                      // copses
    c = mix(c, hex("#7ba3a6"), smooth(0.58, 0.64, f2) * 0.75 * W("marais"));                    // pools
    c = mix(c, hex("#cf904e"), 0.16 * (0.5 + 0.5 * Math.sin(x * 110 + y * 30 + fbm(x * 7, y * 7) * 10)) * W("desert"));   // dunes
    c = mix(c, [247, 249, 253], smooth(0.8, 1.05, height[k]) * Math.max(W("monts"), W("cieux")));   // snow
    c = mix(c, [255, 255, 255], 0.45 * smooth(0.5, 0.72, fbm(x * 10, y * 10, 3)) * W("cieux"));      // clouds
    if (Math.abs(fbm(x * 18, y * 18, 4) - 0.5) < 0.014) c = mix(c, hex("#e25a2a"), 0.9 * W("volcan"));
    if (reg === "apex") c = mix(c, hex("#e0662c"), 0.55 * smooth(0.035, 0.0, Math.hypot(x - C[0], y - C[1])));
    if (nearSea(i, j, 4) && reg !== "monts" && reg !== "cieux") c = mix(c, SAND, 0.75);             // beaches
    if (water[k]) c = hex("#5b9cc0");
    // Relief, lit from the north-west, soft.
    const hx = (height[k + (i < N - 1 ? 1 : 0)] - height[k - (i > 0 ? 1 : 0)]) * N * 0.5;
    const hy = (height[k + (j < N - 1 ? N : 0)] - height[k - (j > 0 ? N : 0)]) * N * 0.5;
    const light = Math.max(-1, Math.min(1, (-hx - hy) * 0.35));
    c = c.map((v) => v * (1 + 0.28 * light));
    if (isCoast(i, j)) c = INK;
  }
  c = mix(c, PAPER, 0.1).map((v) => Math.max(0, Math.min(255, v + grain)));
  img.set(c.map(Math.round), k * 3);
}

// Villages: little houses with red roofs, on land by the water.
const onCoast = (ux, uy) => {
  const tx = I(ux), ty = I(uy);
  let best = null, bestD = 1e9;
  for (let j = Math.round((ty - 0.08) * N); j < (ty + 0.08) * N; j++) for (let i = Math.round((tx - 0.08) * N); i < (tx + 0.08) * N; i++) {
    if (i < 0 || j < 0 || i >= N || j >= N || !land[j * N + i] || !nearSea(i, j, 8)) continue;
    const d = (i / N - tx) ** 2 + (j / N - ty) ** 2;
    if (d < bestD) { bestD = d; best = [i / N, j / N]; }
  }
  return best ?? [tx, ty];
};
const houses = ([cx, cy], n, spread) => {
  let placed = 0;
  for (let h = 0; placed < n && h < n * 12; h++) {
    const hx = Math.round((cx + (hash(h, 7) - 0.5) * spread) * N), hy = Math.round((cy + (hash(h, 13) - 0.5) * spread) * N);
    if (hx < 5 || hy < 5 || hx > N - 5 || hy > N - 5 || !land[hy * N + hx] || water[hy * N + hx]) continue;
    placed++;
    for (let dy = -3; dy <= 3; dy++) for (let dx = -4; dx <= 4; dx++) {
      const k = (hy + dy) * N + hx + dx;
      img.set(Math.abs(dx) === 4 || Math.abs(dy) === 3 ? INK : dy < 0 ? hex("#b5463a") : hex("#f1e6cf"), k * 3);
    }
  }
};
const portAt = onCoast(0.49, 0.9), havreAt = onCoast(0.78, 0.8);
houses(portAt, 7, 0.035);
houses(havreAt, 16, 0.055);

// ---------------------------------------------------------------- where things are
const centroid = (g) => {
  let sx = 0, sy = 0, n = 0;
  for (let k = 0; k < N * N; k++) if (region[k] === g) { sx += k % N; sy += Math.floor(k / N); n++; }
  return n ? [sx / n / N, sy / n / N] : [0.5, 0.5];
};
const labels = REGIONS.map((r, g) => centroid(g));
// Each region's bounding box (0–1): a zone's detailed map is laid over it (Chloé on the atlas).
const bounds = REGIONS.map((r, g) => {
  let x0 = N, y0 = N, x1 = 0, y1 = 0;
  for (let k = 0; k < N * N; k++) if (region[k] === g) { const i = k % N, j = Math.floor(k / N); x0 = Math.min(x0, i); y0 = Math.min(y0, j); x1 = Math.max(x1, i); y1 = Math.max(y1, j); }
  return [x0 / N, y0 / N, (x1 - x0 + 1) / N, (y1 - y0 + 1) / N];
});
labels[G.volcan] = toImage([0.5, 0.41]);
labels[G.apex] = toImage([0.5, 0.535]);
labels[G.port] = [portAt[0], portAt[1] + 0.03];
labels[G.havre] = [havreAt[0] + 0.015, havreAt[1] + 0.035];
/** A point of region `id` at shares (fx, fy) of its box. */
const inRegion = (id, fx, fy) => {
  const g = G[id], b = bounds[g];
  const i0 = Math.min(N - 1, Math.floor((b[0] + fx * b[2]) * N)), j0 = Math.min(N - 1, Math.floor((b[1] + fy * b[3]) * N));
  // A region is not a box: when the point falls in a neighbour, the nearest cell of the region.
  for (let r = 0; r < N; r++) {
    let best = null;
    for (let j = j0 - r; j <= j0 + r; j++) for (let i = i0 - r; i <= i0 + r; i++) {
      if (Math.max(Math.abs(i - i0), Math.abs(j - j0)) !== r || i < 0 || j < 0 || i >= N || j >= N || region[j * N + i] !== g) continue;
      const d = (i - i0) ** 2 + (j - j0) ** 2;
      if (!best || d < best[2]) best = [i, j, d];
    }
    if (best) return [(best[0] + 0.5) / N, (best[1] + 0.5) / N];
  }
  return [b[0] + fx * b[2], b[1] + fy * b[3]];
};
const places = [
  ["grotte_echos", "Grotte des Échos", toImage([0.49, 0.64])], ["antre_crane", "Grand Crâne", toImage([0.58, 0.74])],
  ["cabinet", "Cabinet", [portAt[0] + 0.015, portAt[1] - 0.006]],
  // The doors of the zones inside a region: where Chloé stands on the atlas at their entrance (the
  // zone's map laid over its region's box, as for her marker): tile / map size of that zone.
  ["camp_ombre", "Camp de l'Ombre Noire", inRegion("foret", 12 / 130, 39 / 100)],
  ["temple_englouti", "Temple englouti", inRegion("marais", 30 / 120, 11.5 / 96)],
  ["sanctuaire_vents", "Sanctuaire des Vents", inRegion("desert", 60.5 / 120, 3 / 100)],
  ["grottes_marines", "Grottes marines", inRegion("cote", 93 / 128, 25 / 100)],
  ["recif_sanctuaire", "Récif du Sanctuaire", inRegion("cote", 68.5 / 128, 20.5 / 100)],
];

await sharp(img, { raw: { width: N, height: N, channels: 3 } }).png().toFile(`${OUT_ART}/atlas_ile.png`);
await sharp(ids, { raw: { width: N, height: N, channels: 1 } }).png().toFile(`${OUT_ART}/atlas_regions.png`);

const v = (p) => `Vector2(${p[0].toFixed(3)}, ${p[1].toFixed(3)})`;
const gd = `class_name AtlasDB
## Generated by tools/maps/gen-atlas.mjs (do not edit: run it again). The regions of Ambrelune
## on its atlas (assets/art/ui/atlas_ile.png): name, zones of the game in it (the first one has
## the detailed map), levels of its wild dinos, where its name goes (0–1), its bounding box
## (0–1: the first zone's detailed map is laid over it, to place Chloé).
## atlas_regions.png holds each region's index * 16 (the sea: 255).

const REGIONS := [
${REGIONS.map((r, g) => `\t{"id": &"${r.id}", "name": "${r.name}", "zones": [${r.zones.map((z) => `&"${z}"`).join(", ")}], "levels": Vector2i(${r.levels[0]}, ${r.levels[1]}), "label": ${v(labels[g])}, "bounds": Rect2(${bounds[g].map((b) => b.toFixed(3)).join(", ")})},`).join("\n")}
]
## Places inside the regions, marked once visited: [zone, name, where (0–1)].
const PLACES := [
${places.map(([z, n, p]) => `\t[&"${z}", "${n}", ${v(p)}],`).join("\n")}
]
`;
fs.writeFileSync(OUT_DB, gd);
console.log(`${OUT_ART}/atlas_ile.png, atlas_regions.png, ${OUT_DB}`);
