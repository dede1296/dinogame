// Draws the two map images of the Monts Gelés (1 pixel = 1 tile, 130 x 110):
//   monts_sols.png   — the ground, by colour (see SOLS below; any other colour = grass)
//   monts_relief.png — the height, in grey levels (1 level = 5 cm; black = 0 m)
//   monts_neige.png  — the snow over the ground (black none, white all covered; see « the snow »),
//                      and cote_neige.png, the few patches on the Côte's side of the join
// They are the source of the region: retouch them in any paint program (keep the exact
// colours of SOLS, and 1 pixel = 1 tile), then rebuild the region:
//   godot --headless --path Godot --script res://tools/build_zone.gd -- monts --force
// Running this script again overwrites them (from the layout below), and prints the checks:
// the places reachable on foot from the way in (with the ice walls shut, then broken), open
// ground nobody reaches, steps on the trails, the junction with the Côte.
// Usage (from the repository root): node Godot/tools/maps/gen-monts.mjs
//
// In the Monts, the zone's own pictures turn the grounds into snow (grass), packed snow (path),
// tundra tufts (tall grass), ice (sand: the frozen lake, the glacier), snowy conifers (forest);
// no water, no mud, no bare rock (the rock faces are the relief).
// The land climbs from the south to the north and the east; the camera looks north, so the faces
// look south, and nothing tall stands south of where Chloé walks.
// Layout (tiles; the places are the ones tools/zones/monts.gd fills, story/monts_places.gd names):
//   west        the way in from the Côte (x 0, rows 28-32; 4.8 m, the Côte's clifftops: its last
//               column is copied here, Côte row = Monts row + 28), snowy conifers either side,
//               north of the trail the woods up to the north edge (x < 34);
//   south-west  the Vallée des Troupeaux (3.6 m), down a gentle slope: Bertille's rock shelter at
//               the foot of a knoll (22, 57), the herds' meadow, the frozen lake (40, 86), a low
//               rise at its south-west (page 30);
//   centre-north the glacier (x 36-93, 6 m, ice with snowy margins), up a slope from the way in:
//               two crevasses across it (2.4 m deep), each crossed only at one bridge its ice wall
//               plugs (Charge); in its north band, the caves' mouth at the back of a notch in the
//               peaks' face (66, 6);
//   east        the Col des Tempêtes: a ramp from the glacier's south-east to its terrace (7.2 m),
//               a second one to its top (8.4 m); the frost door at the back of a notch in the north
//               face (114.5, 7); north-west of the top, a gully climbs to the north edge (10.8 m:
//               the way to the Cieux, closed);
//   south-east  the tundra (4.8 m), the herds' pastures under the col's south face;
//   around      the peaks (12.6 m) along the north (x >= 34) and east edges; conifers along the
//               south and west edges.
import sharp from "sharp";

export const SOLS = {
  grass: [90, 158, 58], path: [200, 160, 96], tall_grass: [47, 107, 31],
  water: [46, 111, 181], forest: [31, 64, 32], sand: [232, 212, 154], mud: [107, 90, 54], rock: [176, 96, 60],
};
const W = 130, H = 110;
const OUT = "Godot/tools/maps";
/** The Côte (tools/zones/cote.gd: its exit x 127.45, rows 56-60) joins the Monts' way in (x 0,
 *  rows 28-32): Côte row = Monts row + COTE_SHIFT; its last column is copied on the first ones. */
const COTE_SHIFT = 28;
const JUNCTION_COLS = 3;
/** Heights (m). */
const ENTRY = 4.8, VALLEY = 3.6, TUNDRA = 4.8, GLACIER = 6.0, CREVASSE = 3.6, TERRACE = 7.2, TOP = 8.4;
const PEAK = 12.6, CIEUX = 10.8, KNOLL = 6.0;
/** Places to check: [x, y, how] — "pied": on foot from the way in, the ice walls shut; "murs": only
 *  once the ice walls are broken. */
const PLACES = {
  "entrée (depuis la Côte)": [1, 30, "pied"], "arrivée": [4, 30, "pied"], "feu de l'entrée": [14, 36, "pied"],
  "abri de Bertille (encoche)": [20, 55, "pied"], "devant l'abri": [20, 57, "pied"], "Bertille": [22, 58, "pied"], "feu de Bertille": [20, 59, "pied"],
  "vallée": [32, 72, "pied"], "troupeau": [40, 66, "pied"], "lac gelé": [40, 86, "pied"], "page 30": [10, 95, "pied"],
  "toundra": [86, 72, "pied"], "feu de la toundra": [88, 70, "pied"],
  "glacier (arrivée)": [46, 34, "pied"], "mur 1 (devant)": [57, 30, "pied"], "bande du milieu": [60, 21, "murs"],
  "page 29": [84, 20, "murs"], "mur 2 (devant)": [67, 20, "murs"], "bande nord": [66, 10, "murs"],
  "bouche des grottes (encoche)": [66, 6, "murs"],
  "rampe du col": [91, 37, "pied"], "terrasse du col": [100, 38, "pied"], "rampe du sommet": [105, 33, "pied"],
  "sommet du col": [110, 20, "pied"], "Roc au col": [106, 24, "pied"], "page 28": [121, 14, "pied"],
  "porte de givre (encoche)": [114, 7, "pied"], "Maïa (retour)": [111, 12, "pied"], "feu du col": [118, 24, "pied"],
  "couloir des Cieux": [100, 3, "pied"], "sortie des Cieux": [100, 0, "pied"],
};

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
const fbm = (x, y) => noise(x, y) * 0.6 + noise(x * 2.1 + 17, y * 2.1 + 5) * 0.3 + noise(x * 4.3 + 3, y * 4.3 + 29) * 0.1;
const smooth = (a, b, t) => { const k = Math.max(0, Math.min(1, (t - a) / (b - a))); return k * k * (3 - 2 * k); };
const q = (h) => Math.round(h / 0.05) * 0.05;

// ---------------------------------------------------------------- layers
const grid = (v) => Array.from({ length: H }, () => Array(W).fill(v));
const sol = grid("grass");
const height = grid(ENTRY);
const flat = grid(false);      // kept level: the places, the ramps, the ice (no rolling)
const inside = (x, y) => x >= 0 && y >= 0 && x < W && y < H;
const inEllipse = (x, y, cx, cy, rx, ry, wobble = 0) =>
  ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 < 1 + wobble * (fbm(x * 0.35, y * 0.35) - 0.5);
const each = (f) => { for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) f(x, y); };
const DIRS = [[1, 0], [-1, 0], [0, 1], [0, -1]];
const inRect = (x, y, [rx, ry, rw, rh]) => x >= rx && y >= ry && x < rx + rw && y < ry + rh;
/** Distance (tiles) from the middle of tile (x, y) to a polyline. */
function toPolyline(x, y, pts) {
  let best = 1e9;
  for (let i = 0; i < pts.length - 1; i++) {
    const [ax, ay] = pts[i], [bx, by] = pts[i + 1];
    const px = x + 0.5, py = y + 0.5, dx = bx - ax, dy = by - ay;
    const t = Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)));
    best = Math.min(best, Math.hypot(px - ax - t * dx, py - ay - t * dy));
  }
  return best;
}
/** Distance (tiles, by steps) to the nearest tile passing `test`. */
function distanceTo(test) {
  const d = grid(99), queue = [];
  each((x, y) => { if (test(x, y)) { d[y][x] = 0; queue.push([x, y]); } });
  for (let i = 0; i < queue.length; i++) {
    const [x, y] = queue[i];
    for (const [dx, dy] of DIRS) {
      const xx = x + dx, yy = y + dy;
      if (inside(xx, yy) && d[yy][xx] > d[y][x] + 1) { d[yy][xx] = d[y][x] + 1; queue.push([xx, yy]); }
    }
  }
  return d;
}
const edgeDistance = (x, y) => Math.min(x, y, W - 1 - x, H - 1 - y);

// ---------------------------------------------------------------- the peaks' edges
// The north face (tiles y <= northFace(x) are the peaks, from x 34), straight where a notch cuts
// it (the caves' mouth, the frost door) and where the gully to the Cieux climbs; the east face
// (x >= eastFace(y)).
const PEAKS_WEST = 34;
const northFace = (x) => {
  if (x >= 62 && x <= 70) return 7;                 // the caves' notch (x 65-66)
  if (x >= 96 && x <= 119) return 8;                // the gully (x 99-101), the door's notch (x 113-115)
  return 7 + Math.round((fbm(x * 0.15, 2.2) - 0.5) * 3);
};
const eastFace = (y) => 126 + Math.round((fbm(4.4, y * 0.12) - 0.5) * 3);
const inPeaks = (x, y) => (x >= PEAKS_WEST && y <= northFace(x)) || x >= eastFace(y);
/** The notches: the caves' mouth at the back (y 6), the frost door at the back (y 7). */
const CAVE_NOTCH = [65, 6, 2, 2];
const DOOR_NOTCH = [113, 7, 3, 2];
/** The gully up to the Cieux (x 99-101): its ramp (rows 5-8, 0.6 m a step) from the col's top,
 *  then level to the north edge. */
const GULLY = [99, 0, 3, 9];

// ---------------------------------------------------------------- the glacier and the col
// The glacier's west face (straight from the slope up from the way in, row 28, down), its tongue
// reaching down into the lowland (x 50-78), the col's west face (straight by its ramp).
const glacierWest = (y) => (y >= 28 ? 36 : 36 + Math.round((fbm(3.3, y * 0.13) - 0.5) * 4));
const colWest = (y) => (y >= 34 && y <= 40 ? 94 : 94 + Math.round((fbm(6.6, y * 0.15) - 0.5) * 3));
const snout = (x) => 43 + Math.round(5 * Math.exp(-(((x - 64) / 13) ** 2)) + (fbm(x * 0.12, 7.7) - 0.5) * 3);
const colSouth = (x) => 45 + Math.round((fbm(x * 0.14, 3.9) - 0.5) * 3);
/** The col's top: rows up to topSouth(x) (straight by its ramp, x 101-109); its terrace below. */
const topSouth = (x) => (x >= 101 && x <= 109 ? 31 : 31 + Math.round((fbm(x * 0.2, 1.9) - 0.5) * 3));
const inGlacier = (x, y) => x >= glacierWest(y) && x < colWest(y) && y > northFace(x) && y <= snout(x);
const inCol = (x, y) => x >= colWest(y) && x < eastFace(y) && y > northFace(x) && y <= colSouth(x);
/** The crevasses (2.4 m deep, two tiles wide), west face to col, each crossed only at its bridge
 *  (the gap: x range), where the ice wall stands (MURS_GLACE). */
const CREVASSES = [
  { line: [[30, 22.2], [35.5, 23.5], [42, 25], [50, 26.5], [55, 27], [60, 27], [66, 28], [72, 28.6], [80, 27.6], [88, 28], [94.5, 27.4], [99, 27.2]], gap: [56, 57] },
  { line: [[30, 12], [35.5, 13.2], [44, 15], [52, 16.4], [62, 17], [71, 17], [78, 16.2], [86, 15.4], [94.5, 16.2], [99, 16.4]], gap: [66, 67] },
];
const CREVASSE_HALF = 0.95;
const nearCrevasse = (x, y, c) => toPolyline(x, y, c.line) < CREVASSE_HALF;
const isCrevasse = (x, y) => inGlacier(x, y) && CREVASSES.some((c) => nearCrevasse(x, y, c) && !(x >= c.gap[0] && x <= c.gap[1]));
/** The bridges (where the walls stand): the gap's tiles the crevasse would take. */
const isBridge = (x, y) => inGlacier(x, y) && CREVASSES.some((c) => nearCrevasse(x, y, c) && x >= c.gap[0] && x <= c.gap[1]);
/** The ramps: [x, y, w, h, heights along the climb, axis]. Up the glacier from the way in (east),
 *  the glacier to the col's terrace (east), the terrace to the top (north). */
const RAMPS = [
  { rect: [31, 30, 5, 5], axis: "x", from: ENTRY, to: GLACIER },
  { rect: [90, 36, 4, 3], axis: "x", from: GLACIER, to: TERRACE },
  { rect: [104, 32, 3, 4], axis: "-y", from: TERRACE, to: TOP },
];

// ---------------------------------------------------------------- the valley and the tundra
// The land south of the way in and of the glacier: 4.8 m by the west edge, along the way in and
// in the tundra (east), down gentle slopes (0.2 m a tile at most) to the valley's 3.6 m.
const lowland = (x, y) => {
  const west = smooth(9, 3, x);
  const north = x < 38 ? smooth(47, 41, y) : 0;
  const east = smooth(55, 64, x);
  return VALLEY + (ENTRY - VALLEY) * Math.max(west, north, east);
};
/** Bertille's knoll: a rock 2.4 m above the valley, rounded, its south face straight (x 18-23, the
 *  face at y 57) where her shelter is dug into it: a notch at the valley's level (SHELTER, x 19-21,
 *  rows 55-56), the dark hollow at its back (y 55). */
const SHELTER = [19, 55, 3, 2];
const inKnoll = (x, y) => {
  if (y > 56 || y < 49 || inRect(x, y, SHELTER)) return false;
  if (y >= 54 && x >= 18 && x <= 23) return true;
  return inEllipse(x, y, 21, 53.2, 6.2, 3.9, 0.5);
};
const LAKE = [40, 86, 9, 5];
/** Low rises (the rise of page 30 at the valley's south-west, broad swells in the tundra):
 *  [x, y, radius, height above the ground], never steeper than 0.3 m a tile. */
const RISES = [[10.5, 95, 5, 0.6], [100, 88, 7, 1.2], [66, 93, 5, 0.6], [112, 66, 5, 0.6]];
/** Rocky outcrops in the valley and the tundra (their snowy tops out of reach), well away south of
 *  the trails: [x, y, rx, ry, height above the ground]. */
const OUTCROPS = [[48, 77, 2.4, 1.7, 1.8], [14, 75, 2, 1.4, 1.2], [79, 63, 3, 2, 2.4], [101, 72, 2.4, 1.7, 1.8],
  [112, 95, 3, 2, 2.4], [86, 98, 2.2, 1.5, 1.2], [71, 79, 2, 1.5, 1.2], [121, 59, 2.4, 3, 2.4], [57, 89, 1.8, 1.3, 1.2]];
const inOutcrop = (x, y) => OUTCROPS.some(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, 0.4));

each((x, y) => {
  if (inPeaks(x, y)) { height[y][x] = PEAK; sol[y][x] = "grass"; return; }
  if (inGlacier(x, y)) { height[y][x] = GLACIER; sol[y][x] = "sand"; flat[y][x] = true; return; }
  if (inCol(x, y)) { height[y][x] = y <= topSouth(x) ? TOP : TERRACE; sol[y][x] = "grass"; return; }
  if (x < PEAKS_WEST && y <= 25) { height[y][x] = ENTRY; return; }       // the woods north of the way in
  if (y <= 41 && x < glacierWest(y) + 2) { height[y][x] = ENTRY; return; }   // the way in, by the glacier's face
  height[y][x] = q(lowland(x, y));
});
// Bertille's knoll, the frozen lake, the rises, the outcrops.
each((x, y) => {
  if (inKnoll(x, y)) { height[y][x] = q(lowland(x, y)) + (KNOLL - VALLEY); sol[y][x] = "grass"; }
  if (inEllipse(x, y, ...LAKE, 0.2)) { sol[y][x] = "sand"; flat[y][x] = true; }
  if (height[y][x] >= TOP || inGlacier(x, y)) return;
  for (const [cx, cy, r, h] of RISES) {
    const d = Math.hypot(x + 0.5 - cx, y + 0.5 - cy);
    if (d < r) height[y][x] = q(height[y][x] + h * smooth(r, r * 0.35, d));
  }
  const rock = OUTCROPS.find(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, 0.4));
  if (rock) height[y][x] = q(lowland(x, y) + rock[4]);
});
// The crevasses, the bridges (kept ice), the glacier's snowy margins (2 tiles along its west face,
// the peaks and the col; the snout stays ice to its edge).
{
  const nearEdge = distanceTo((x, y) => !inGlacier(x, y) && (x < glacierWest(y) || y <= northFace(x) || x >= colWest(y)));
  each((x, y) => {
    if (!inGlacier(x, y)) return;
    if (isCrevasse(x, y)) { height[y][x] = CREVASSE; sol[y][x] = "sand"; return; }
    if (nearEdge[y][x] <= 2 && !isBridge(x, y)) sol[y][x] = "grass";
  });
}
// The notches, the gully.
each((x, y) => {
  if (inRect(x, y, CAVE_NOTCH)) { height[y][x] = GLACIER; sol[y][x] = "grass"; flat[y][x] = true; }
  if (inRect(x, y, DOOR_NOTCH)) { height[y][x] = TOP; sol[y][x] = "grass"; flat[y][x] = true; }
  if (inRect(x, y, GULLY)) { height[y][x] = y >= 5 ? q(TOP + 0.6 * (9 - y)) : CIEUX; sol[y][x] = "path"; flat[y][x] = true; }
});
// The ramps (sloping evenly, the last step onto the level above).
for (const r of RAMPS) {
  const [rx, ry, rw, rh] = r.rect;
  const n = r.axis === "x" ? rw : rh;
  for (let i = 0; i < rw; i++) for (let j = 0; j < rh; j++) {
    const k = r.axis === "x" ? i : rh - 1 - j;   // (along the climb)
    height[ry + j][rx + i] = q(r.from + (r.to - r.from) * (k + 1) / (n + 1));
    sol[ry + j][rx + i] = "grass";
    flat[ry + j][rx + i] = true;
  }
}

// ---------------------------------------------------------------- woods
// The woods north of the way in (the Côte's go on), the conifers along the west edge (from the
// way in down to the south edge) and along the south edge; stands of conifers in the valley and
// the tundra; a few on the knoll and on the col's terrace edges.
const WOODS_EAST = (y) => 29 + Math.round((fbm(1.3, y * 0.15) - 0.5) * 6);
const WOODS_SOUTH = (x) => 25 + Math.round((fbm(x * 0.2, 8.1) - 0.5) * 2);
const STANDS = [[9, 66, 4, 3], [26, 88, 3.5, 2.5], [55, 98, 5, 2.5], [74, 60, 4, 2.5], [104, 58, 5, 3], [118, 84, 4, 6],
  [96, 96, 5, 3], [68, 84, 3, 2], [52, 58, 2.5, 2], [21, 53.5, 3.2, 1.8]];
each((x, y) => {
  if (inPeaks(x, y) || inGlacier(x, y) || inCol(x, y)) return;
  const woods = x < PEAKS_WEST && y <= WOODS_SOUTH(x) && x < WOODS_EAST(y);
  const west = y >= 34 && x <= 2 + Math.round((fbm(y * 0.2, 5.5) - 0.3) * 3);
  const south = y >= 104 + Math.round((fbm(x * 0.17, 9.2) - 0.5) * 3);
  const stand = STANDS.some((r) => inEllipse(x, y, ...r, 0.5));
  if (woods || west || south || stand) sol[y][x] = "forest";
});

// ---------------------------------------------------------------- the junction with the Côte
// The Monts' first columns are the Côte's last one (ground and height), so the two maps meet
// exactly where they are shown side by side; the Côte's rows 28-99 are the Monts' rows 0-71.
const COTE_SOLS = `${OUT}/cote_sols.png`, COTE_RELIEF = `${OUT}/cote_relief.png`;
const coteSols = await sharp(COTE_SOLS).raw().toBuffer({ resolveWithObject: true });
const coteRelief = await sharp(COTE_RELIEF).raw().toBuffer({ resolveWithObject: true });
const solOf = (buf, i) => {
  const c = [buf.data[i], buf.data[i + 1], buf.data[i + 2]];
  return Object.keys(SOLS).find((k) => SOLS[k].every((v, j) => Math.abs(v - c[j]) < 6)) ?? "grass";
};
const CW = coteSols.info.width, CH = coteSols.info.height;
const coteAt = (y) => {
  const cy = y + COTE_SHIFT, i = cy * CW + (CW - 1);
  return [solOf(coteSols, i * coteSols.info.channels), coteRelief.data[i * coteRelief.info.channels] * 0.05];
};
for (let y = 0; y < H && y + COTE_SHIFT < CH; y++) {
  const [s, h] = coteAt(y);
  for (let k = 0; k < JUNCTION_COLS; k++) {
    sol[y][k] = s;
    height[y][k] = h;
    flat[y][k] = true;
  }
}

// ---------------------------------------------------------------- trails
function stroke(points, width, value, wobble = 1.0) {
  for (let i = 0; i < points.length - 1; i++) {
    const [x0, y0] = points[i], [x1, y1] = points[i + 1];
    const n = Math.ceil(Math.hypot(x1 - x0, y1 - y0) * 3);
    for (let k = 0; k <= n; k++) {
      const t = k / n;
      const wob = (noise((x0 + x1) * 0.1 + t * 4, (y0 + y1) * 0.1) - 0.5) * wobble;
      const px = x0 + (x1 - x0) * t + (y1 !== y0 ? wob : 0), py = y0 + (y1 - y0) * t + (x1 !== x0 ? wob : 0);
      for (let dy = 0; dy < width; dy++) for (let dx = 0; dx < width; dx++) {
        const tx = Math.floor(px - width / 2 + dx + 0.5), ty = Math.floor(py - width / 2 + dy + 0.5);
        if (inside(tx, ty) && sol[ty][tx] !== "forest" && !isCrevasse(tx, ty) && !inOutcrop(tx, ty) && !inKnoll(tx, ty) && height[ty][tx] < PEAK) sol[ty][tx] = value;
      }
    }
  }
}
const TRAILS = [
  [[[0, 30], [12, 30]], 0],                                                                          // from the Côte (its trail's rows)
  [[[12, 30], [22, 31], [30, 32.5], [36, 32.5]], 0.6],                                               // to the glacier's slope
  [[[36, 32.5], [42, 33.5], [47, 34.5]], 0.4],                                                       // onto the glacier
  [[[47, 34.5], [53, 31], [57, 29.5], [57, 25], [58.5, 22.5], [63, 20.5], [67, 19.5], [67, 14], [66, 10.5], [66, 8]], 0.3],   // over the bridges to the caves
  [[[47, 34.5], [58, 37], [72, 38.5], [84, 37.5], [90, 37.5]], 0.5],                                  // east across the glacier
  [[[90, 37.5], [94, 37.5]], 0],                                                                     // the ramp to the col's terrace
  [[[94, 37.5], [100, 38], [105, 36.5]], 0.4], [[[105, 36.5], [105, 31]], 0],                         // the terrace, the ramp to the top
  [[[105, 31], [107, 26], [111, 20], [114, 14], [114.5, 9]], 0.5],                                    // the col's top, to the door
  [[[107, 26], [104, 20], [101.5, 14], [100.5, 10]], 0.5], [[[100.5, 10], [100.5, 0]], 0],            // the gully to the Cieux
  [[[12, 30], [14, 35], [17, 41], [23, 46], [29.5, 50], [30, 55], [26, 59], [23, 60]], 0.7],          // down to the valley, Bertille's camp
  [[[30, 55], [33, 61], [38, 67], [41, 74], [42, 79]], 0.8],                                        // the herds' meadow, the lake
  [[[38, 67], [48, 69], [58, 70], [70, 70.5], [80, 70], [88, 71.5]], 0.8],                            // east to the tundra
  [[[33, 61], [24, 70], [17, 80], [13, 88], [11, 93]], 0.8],                                          // south-west, to the rise
];
for (const [pts, wobble] of TRAILS) stroke(pts, 2, "path", wobble);

// ---------------------------------------------------------------- tundra tufts (encounters)
// Tufts of the tundra in the valley and the tundra (the herds graze there), on the glacier's
// snowy margins (the Leaellynasaura hide there at night), a few on the col's top (the storms).
const TUFTS = [
  [16, 66, 4, 2.5], [44, 60, 4, 2], [30, 78, 3.5, 2.2], [52, 80, 3, 2.4], [22, 97, 3.5, 2], [48, 94, 4, 2],
  [36, 100, 3, 1.6], [58, 64, 2.6, 2], [7, 80, 2.5, 3], [19, 38, 3, 1.6], [26, 36, 2, 1.4],
  [78, 52, 4, 2], [92, 62, 4, 2.4], [110, 70, 4, 3], [82, 90, 4, 2.5], [100, 86, 3.5, 2], [115, 98, 3, 2], [66, 96, 3, 2],
  [38, 38, 1.6, 3.5], [38, 19, 1.6, 3.5], [78, 10, 3, 1.4], [52, 9.5, 3, 1.3], [91, 22, 1.6, 3],
  [118, 20, 2.5, 3], [99, 16, 2, 2.5], [116, 40, 3, 2], [122, 28, 1.5, 3],
];
each((x, y) => {
  if (sol[y][x] !== "grass" || height[y][x] >= PEAK || inRect(x, y, CAVE_NOTCH) || inRect(x, y, DOOR_NOTCH)) return;
  if (RAMPS.some((r) => inRect(x, y, r.rect)) || inKnoll(x, y) || inOutcrop(x, y) || x < JUNCTION_COLS + 2) return;
  if (TUFTS.some(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, 0.6))) sol[y][x] = "tall_grass";
});

// ---------------------------------------------------------------- places kept level
// Bertille's camp (in front of her shelter), the fires, the door's square, the way in.
const LEVEL = [[16, 57, 10, 5], SHELTER, [12, 34, 5, 4], [84, 68, 7, 5], [115, 21, 6, 6], [108, 9, 13, 5], [0, 27, 8, 7], [8, 91, 6, 7]];
each((x, y) => { if (LEVEL.some((r) => inRect(x, y, r))) flat[y][x] = true; });

// ---------------------------------------------------------------- gentle rolls
// Snowdrifts on the open snow (the way in, the valley, the tundra, the col), never a step; none
// by the faces, the paths, the ice, the level places, the edges (they meet their neighbours
// there at the same height).
const isCliff = (x, y) => DIRS.some(([dx, dy]) => inside(x + dx, y + dy) && Math.abs(height[y + dy][x + dx] - height[y][x]) > 0.75);
const nearPath = distanceTo((x, y) => sol[y][x] === "path");
const nearHard = distanceTo((x, y) => isCliff(x, y) || flat[y][x] || sol[y][x] === "sand");
each((x, y) => {
  if (!["grass", "tall_grass", "forest"].includes(sol[y][x]) || flat[y][x] || height[y][x] >= PEAK || inKnoll(x, y)) return;
  const fade = smooth(1, 4, nearHard[y][x]) * smooth(0.5, 2.5, nearPath[y][x]) * smooth(3, 8, edgeDistance(x, y));
  const roll = Math.max(0, fbm(x * 0.13 + 41, y * 0.13 + 7) - 0.4) * 0.8 * fade;
  height[y][x] = q(height[y][x] + Math.min(0.35, roll));
});

// ---------------------------------------------------------------- checks
const WALK = ["grass", "path", "tall_grass", "sand", "mud", "rock"];
function reach(from, blocked = () => false) {
  const seen = grid(false), queue = [from];
  seen[from[1]][from[0]] = true;
  for (let i = 0; i < queue.length; i++) {
    const [x, y] = queue[i];
    for (const [dx, dy] of DIRS) {
      const xx = x + dx, yy = y + dy;
      if (!inside(xx, yy) || seen[yy][xx] || blocked(xx, yy)) continue;
      if (!WALK.includes(sol[yy][xx])) continue;
      if (Math.abs(height[yy][xx] - height[y][x]) > 0.75) continue;
      seen[yy][xx] = true;
      queue.push([xx, yy]);
    }
  }
  return seen;
}
const ENTRY_TILE = [1, 30];
const shut = reach(ENTRY_TILE, isBridge), open = reach(ENTRY_TILE);
let ice = 0, forest = 0, walk = 0, onFoot = 0, afterWalls = 0, tufts = 0;
each((x, y) => {
  if (sol[y][x] === "sand") ice++;
  if (sol[y][x] === "forest") forest++;
  if (sol[y][x] === "tall_grass") tufts++;
  if (WALK.includes(sol[y][x])) { walk++; if (shut[y][x]) onFoot++; if (open[y][x]) afterWalls++; }
});
console.log(`glace : ${(100 * ice / (W * H)).toFixed(1)} %, bois : ${(100 * forest / (W * H)).toFixed(1)} %, touffes : ${tufts} cases ; sol ouvert ${walk} cases : ${onFoot} à pied (murs fermés), ${afterWalls} murs brisés`);
let failures = 0;
for (const [name, [x, y, how]] of Object.entries(PLACES)) {
  const ok = how === "pied" ? shut[y][x] : open[y][x] && !shut[y][x];
  if (!ok) failures++;
  console.log(`  ${ok ? "ok " : "NON"} ${name} (${x}, ${y}) ${how} : ${sol[y][x]} ${height[y][x].toFixed(2)} m, murs fermés ${shut[y][x] ? "oui" : "non"}, murs brisés ${open[y][x] ? "oui" : "non"}`);
}
// Each wall alone must hold: with the first one broken only, the north band stays out of reach.
{
  const firstOnly = reach(ENTRY_TILE, (x, y) => isBridge(x, y) && y < 22);
  const ok = firstOnly[21][60] && !firstOnly[10][66];
  if (!ok) failures++;
  console.log(`  ${ok ? "ok " : "NON"} le mur 1 ouvre la bande du milieu, le mur 2 ferme encore la bande nord`);
}
// Open ground nobody reaches (not the knoll's top, the crevasses' floors, the peaks).
let lost = 0;
const lostAt = [];
each((x, y) => {
  if (!WALK.includes(sol[y][x]) || open[y][x] || height[y][x] >= PEAK || inKnoll(x, y) || inOutcrop(x, y) || isCrevasse(x, y)) return;
  lost++;
  if (lostAt.length < 16) lostAt.push(`(${x}, ${y})`);
});
console.log(`  sol ouvert injoignable : ${lost} cases ${lostAt.join(" ")}`);
// Steps on the trails (a cliff across a trail would cut it).
each((x, y) => {
  if (sol[y][x] !== "path") return;
  for (const [dx, dy] of [[1, 0], [0, 1]]) {
    const xx = x + dx, yy = y + dy;
    if (inside(xx, yy) && sol[yy][xx] === "path" && Math.abs(height[yy][xx] - height[y][x]) > 0.62) console.log(`  MARCHE sur le sentier : (${x}, ${y}) -> (${xx}, ${yy})`);
  }
});
// The junction with the Côte: the Monts' first column against the Côte's last.
{
  let diff = 0, same = 0, rows = 0;
  for (let y = 0; y < H && y + COTE_SHIFT < CH; y++) {
    const [s, h] = coteAt(y);
    diff = Math.max(diff, Math.abs(h - height[y][0]));
    rows++;
    if (s === sol[y][0]) same++;
  }
  console.log(`  raccord avec la Côte : écart de hauteur max ${diff.toFixed(2)} m, même sol sur ${same}/${rows} rangées`);
}
// Where the ice walls stand: the middle of each bridge.
for (const c of CREVASSES) {
  const tiles = [];
  each((x, y) => { if (isBridge(x, y) && x >= c.gap[0] && x <= c.gap[1]) tiles.push([x, y]); });
  const ys = tiles.map((t) => t[1]);
  console.log(`  pont x ${c.gap[0]}-${c.gap[1]} : rangées ${Math.min(...ys)}-${Math.max(...ys)} (mur au pied y ≈ ${(Math.max(...ys) + 0.6).toFixed(1)})`);
}
console.log(failures ? `${failures} LIEU(X) EN DÉFAUT` : "tous les lieux sont bons");

// ---------------------------------------------------------------- the snow (cover layer)
// The Monts' ground is ordinary ground (the Côte's grass and earth) under a layer of snow dosed
// tile by tile (Region.cover_data; monts_neige.png: black none, white all covered). The ground
// shader lays a layer in patches from a dose of about 0.28 (none) to 0.72 (all), half at 0.5: the
// snow is half there at the join with the Côte, all there SNOW_RAMP tiles on (the carpet, its
// front wandering), gone as far into the Côte (a few patches thinning out: cote_neige.png, made
// by the same function); all covered farther on, but for grassy patches on the sheltered valley
// floor (the herds graze there). The ice stays ice (the zone is cold: the layer spares it).
// Global tiles: gx = the Monts' x (the Côte's x - 128), gy = the Monts' y (the Côte's y - 28).
const SNOW_RAMP = 15;
function snowAt(gx, gy) {
  const front = (fbm(0.7, gy * 0.08) - 0.5) * 6;
  const dose = 0.5 + 0.22 * (gx + front) / SNOW_RAMP + (fbm(gx * 0.22 + 60, gy * 0.22 + 60) - 0.5) * 0.25;
  return Math.max(0, Math.min(1, dose)) * smooth(-SNOW_RAMP - 8, -SNOW_RAMP, gx);
}
const snow = grid(1);
// (Bertille's knoll and its foot stay under the snow: a snowy rock, not half an earth bank.)
const nearKnoll = distanceTo(inKnoll);
each((x, y) => {
  const sheltered = smooth(4.3, 3.7, height[y][x]) * smooth(0.5, 0.72, fbm(x * 0.11 + 5, y * 0.11 + 9));
  snow[y][x] = Math.max(snowAt(x, y) * (1 - 0.7 * sheltered), smooth(4, 1, nearKnoll[y][x]));
});
{
  const bare = [0, 0, 0];
  each((x, y) => { if (x < 3) bare[0] = Math.max(bare[0], snow[y][x]); else if (x < 20) bare[1] += snow[y][x] < 0.5 ? 1 : 0; });
  console.log(`  neige : au plus ${bare[0].toFixed(2)} sur les 3 premières colonnes, ${bare[1]} cases dégagées (< 0,5) de x 3 à 19`);
}
{
  const cw = coteSols.info.width, ch = coteSols.info.height, buf = Buffer.alloc(cw * ch);
  let most = 0;
  for (let y = 0; y < ch; y++) for (let x = 0; x < cw; x++) {
    const v = snowAt(x - cw, y - COTE_SHIFT);
    most = Math.max(most, v);
    buf[y * cw + x] = Math.round(v * 255);
  }
  await sharp(buf, { raw: { width: cw, height: ch, channels: 1 } }).png().toFile(`${OUT}/cote_neige.png`);
  let edge = 0;
  for (let y = 0; y < H && y + COTE_SHIFT < ch; y++) edge = Math.max(edge, Math.abs(buf[(y + COTE_SHIFT) * cw + cw - 1] / 255 - snow[y][0]));
  console.log(`  neige côté Côte : au plus ${most.toFixed(2)} ; écart entre voisines de part et d’autre de la jointure : ${edge.toFixed(2)} au plus`);
}

// ---------------------------------------------------------------- write
const snowBuf = Buffer.alloc(W * H);
each((x, y) => { snowBuf[y * W + x] = Math.round(Math.max(0, Math.min(1, snow[y][x])) * 255); });
await sharp(snowBuf, { raw: { width: W, height: H, channels: 1 } }).png().toFile(`${OUT}/monts_neige.png`);
const solBuf = Buffer.alloc(W * H * 3), hBuf = Buffer.alloc(W * H);
each((x, y) => {
  solBuf.set(SOLS[sol[y][x]], (y * W + x) * 3);
  hBuf[y * W + x] = Math.max(0, Math.min(255, Math.round(height[y][x] / 0.05)));
});
await sharp(solBuf, { raw: { width: W, height: H, channels: 3 } }).png().toFile(`${OUT}/monts_sols.png`);
await sharp(hBuf, { raw: { width: W, height: H, channels: 1 } }).png().toFile(`${OUT}/monts_relief.png`);
console.log(`${OUT}/monts_sols.png, monts_relief.png, monts_neige.png, cote_neige.png (${W} x ${H})`);
