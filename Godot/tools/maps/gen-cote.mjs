// Draws the two map images of the Côte Préhistorique (1 pixel = 1 tile, 128 x 100):
//   cote_sols.png   — the ground, by colour (see SOLS below; any other colour = grass)
//   cote_relief.png — the height, in grey levels (1 level = 5 cm; black = 0 m)
// They are the source of the region: retouch them in any paint program (keep the exact
// colours of SOLS, and 1 pixel = 1 tile), then rebuild the region:
//   godot --headless --path Godot --script res://tools/build_zone.gd -- cote --force
// Running this script again overwrites them (from the layout below), and prints the checks:
// the places reachable on foot from the way in, those reached only swimming (the Nage), the
// lagoon closed by its reef but for the pass, open ground nobody reaches, steps on the trails.
// Usage (from the repository root): node Godot/tools/maps/gen-cote.mjs
//
// North is the sea (all the water touches the north edge: the Nage; the Plongée goes under it).
// Layout (tiles; the places are the ones tools/zones/cote.gd fills, story/cote_places.gd names):
//   south-west  the way in from the Désert (x 15-25 at the south edge, x 18-19 its trail): the
//               Désert's north rim goes on here, its last rows copied from desert_*.png so the two
//               meet exactly (Désert x = Côte x + 80); dunes, the last one (19.5, 82) over the bay;
//   west        the Baie des Tortues, open to the north, and the Plage aux tortues on its south
//               shore (x 4-36, y 70-80): the turtles' nests above the tide line, at its west end the
//               Cale des Anciens (a carved platform, its steps going down into the bay; page 24);
//   centre-west the Pointe des Palmes (x 40-51), from the mainland north to its rocky tip (45, 30);
//   centre      the Lagon (x 50-86, y 30-55): an islet with palms (75, 42), the Plesiosaurus's
//               rock on its south shore (62.5, 53), its reef to the north (a ridge of rock 1 m
//               out of the water, from the Pointe's tip to the headland) with one pass (x 67-70),
//               the dive to the sanctuary's reef beyond it (68.5, 20.5), a sand bar by the pass;
//   east        the Falaises à Ptéranodons: the east beach at their foot (x 86-95), two terraces
//               (2.4 m from x 96, 4.8 m from x 106) with a ramp each, the headland over the sea
//               (4.8 m, its ledges at 2.4 m), its south face over a small cove whose shingle beach
//               (reached swimming) has the sea caves' mouth at the back of a notch (93, 25);
//               the lookout on the first terrace above the cove (98, 30); the way on to the Monts
//               Gelés at the east edge, up on the top (y 56-59);
//   south       a grove of palms and cycads (forest) closing the meadows behind the lagoon.
import sharp from "sharp";

export const SOLS = {
  grass: [90, 158, 58], path: [200, 160, 96], tall_grass: [47, 107, 31],
  water: [46, 111, 181], forest: [31, 64, 32], sand: [232, 212, 154], mud: [107, 90, 54], rock: [176, 96, 60],
};
const W = 128, H = 100;
const OUT = "Godot/tools/maps";
/** The Désert (tools/zones/desert.gd: its exit x 98-102 at its north edge) joins the Côte's
 *  way in (x 18-22 at its south edge): Désert x = Côte x + DESERT_SHIFT. */
const DESERT_SHIFT = 80;
/** Rows of the Côte copied from the Désert's first row (ground and height), at the junction. */
const JUNCTION_ROWS = 3;
/** Places to check: [x, y, how] — "pied": on foot from the way in; "nage": only swimming;
 *  "eau": a water tile reached swimming. */
const PLACES = {
  "entrée (depuis le Désert)": [19, 98, "pied"], "arrivée": [20, 91, "pied"], "haut de la dune": [19, 82, "pied"],
  "plage aux tortues": [20, 76, "pied"], "nid 1": [11, 77, "pied"], "nid 2": [16, 78, "pied"], "nid 3": [25, 76, "pied"],
  "nid 4": [34, 70, "pied"], "page 24 (cale des Anciens)": [5, 75, "pied"], "cale (marches)": [5, 71, "pied"],
  "pêcheurs": [26, 73, "pied"], "barque échouée": [27, 71, "pied"], "feu de la plage": [23, 81, "pied"],
  "pointe des palmes": [45, 45, "pied"], "bout de la pointe": [45, 32, "pied"],
  "rive du lagon": [70, 59, "pied"], "bord du Plésiosaure": [62, 53, "pied"], "feu du lagon": [72, 63, "pied"],
  "Plésiosaure (eau)": [62, 50, "eau"], "page 25 (fond du lagon)": [80, 36, "eau"],
  "îlot du lagon": [75, 42, "nage"], "îlot des tortues": [23, 57, "nage"], "banc de sable (retour du récif)": [73, 29, "nage"],
  "passe (eau)": [68, 27, "eau"], "accès au récif (eau)": [68, 20, "eau"],
  "plage est (pied des falaises)": [88, 50, "pied"], "feu de la plage est": [90, 58, "pied"],
  "crique des grottes": [93, 28, "nage"], "entrée des grottes (encoche)": [93, 25, "nage"],
  "rampe (bas)": [91, 63, "pied"], "terrasse": [97, 63, "pied"], "belvédère": [98, 30, "pied"], "page 23": [100, 29, "pied"],
  "rampe du sommet": [103, 46, "pied"], "sommet": [110, 48, "pied"], "feu du sommet": [115, 52, "pied"],
  "colonie des Ptéranodons": [108, 20, "pied"], "sortie vers les Monts": [127, 58, "pied"],
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

// ---------------------------------------------------------------- layers
const grid = (v) => Array.from({ length: H }, () => Array(W).fill(v));
const sol = grid("water");
const height = grid(0);
const flat = grid(false);      // kept level: beaches, places, ramps (no dunes, no rolling)
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
/** The polyline's y at column x (it runs west-east; clamped at its ends). */
function polylineY(x, pts) {
  if (x <= pts[0][0]) return pts[0][1];
  for (let i = 0; i < pts.length - 1; i++) {
    const [ax, ay] = pts[i], [bx, by] = pts[i + 1];
    if (x <= bx) return ay + (by - ay) * (x - ax) / (bx - ax);
  }
  return pts[pts.length - 1][1];
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

// ---------------------------------------------------------------- the land
// The mainland's north shore, west to east: the bay (its south shore, the turtles' beach),
// the base of the Pointe, the lagoon's south shore, up to the east beach.
const SHORE = [[0, 74.5], [8, 74], [16, 73], [24, 71], [31, 68], [36, 65], [40, 63], [46, 62], [50, 60],
  [54, 57.5], [60, 56], [66, 55.5], [72, 56], [78, 55.5], [83, 54], [86, 52]];
const shoreY = (x) => polylineY(x, SHORE) + (fbm(x * 0.15, 4.2) - 0.5) * 2.2;
// The Pointe des Palmes: a tongue of land from the mainland north to its rocky tip.
const POINTE_TIP = [45.5, 30.5];
const inPointe = (x, y) => {
  if (inEllipse(x, y, POINTE_TIP[0], POINTE_TIP[1] + 0.5, 3.2, 2.4, 0.2)) return true;
  if (y < POINTE_TIP[1] || y > 64) return false;
  const hw = 2.6 + 3.4 * smooth(32, 60, y) + (fbm(x * 0.3, y * 0.3) - 0.5) * 1.2;
  const cx = POINTE_TIP[0] + (fbm(3.1, y * 0.08) - 0.5) * 2.4;
  return Math.abs(x + 0.5 - cx) < hw;
};
// The east: the terraces (x from T1 at 2.4 m, from T2 at 4.8 m), straight where the ramps meet them.
const T1 = (y) => (y <= 40 || (y >= 57 && y <= 68) ? 96 : 96 + Math.round((fbm(1.7, y * 0.12) - 0.5) * 3));
const T2 = (y) => (y >= 40 && y <= 51 ? 106 : 106 + Math.round((fbm(5.3, y * 0.1) - 0.5) * 4));
const TERRACE = 2.4, TOP = 4.8, LEDGE = 1.2;
// The headland over the sea (rows up to its south face, HEAD_FACE; its north face wanders).
const HEAD_FACE = 26;
const headTop = (x) => (x >= 96 ? 9 : 9 + ((96 - x) / 9) ** 2 * 6) + (fbm(x * 0.18, 1.1) - 0.5) * 2.5;
const headWest = (y) => 87 + (Math.max(0, 20 - y) / 6) ** 2 * 4;
const inHeadland = (x, y) => y <= HEAD_FACE && y >= headTop(x) && x >= headWest(y);
// The cove under the headland: its shingle beach (rows 27-29), the notch of the sea caves in the
// face behind it, the water in front (rows 30-35), and the spur (1.2 m) that cuts the beach off
// from the east beach (so the cove is reached swimming).
const COVE_BEACH = [89, 27, 7, 3];
const NOTCH = [92, 25, 2, 2];
const SPUR = [94, 30, 2, 6];
const EAST_BEACH_TOP = 36;
const inEastBeach = (x, y) => y >= EAST_BEACH_TOP && x >= 85 + Math.round((fbm(9.1, y * 0.2) - 0.5) * 2) && x < T1(y);
// The islet in the lagoon, the Plesiosaurus's rock (a sandy point) on its south shore.
const ISLET = [75, 42, 3.8, 2.6];
const PLESIO_POINT = [62.5, 53.6, 1.7, 2.6];

each((x, y) => {
  let land = y > shoreY(x) || inPointe(x, y) || inEastBeach(x, y) || x >= T1(y) && y > HEAD_FACE || inHeadland(x, y)
    || inRect(x, y, COVE_BEACH) || inRect(x, y, SPUR) || inEllipse(x, y, ...ISLET, 0.25) || inEllipse(x, y, ...PLESIO_POINT, 0.1);
  if (!land) return;
  sol[y][x] = "grass";
});

// ---------------------------------------------------------------- relief of the east
each((x, y) => {
  if (sol[y][x] === "water") return;
  if (inHeadland(x, y)) height[y][x] = TOP;
  else if (y > HEAD_FACE && x >= T2(y)) height[y][x] = TOP;
  else if (y > HEAD_FACE && x >= T1(y)) height[y][x] = TERRACE;
  if (inRect(x, y, SPUR)) { height[y][x] = LEDGE; sol[y][x] = "sand"; }
  if (inRect(x, y, COVE_BEACH) || inRect(x, y, NOTCH)) { height[y][x] = 0; sol[y][x] = "sand"; flat[y][x] = true; }
});
// The headland's ledges (2.4 m) along the sea, one or two tiles wide: the Pteranodons' nests,
// out of reach (a cliff from the top, a cliff from the sea).
{
  const nearSea = distanceTo((x, y) => sol[y][x] === "water");
  each((x, y) => {
    if (!inHeadland(x, y) || inRect(x, y, NOTCH)) return;
    const wide = 1 + (fbm(x * 0.4, y * 0.4) > 0.5 ? 1 : 0);
    if (nearSea[y][x] <= wide) height[y][x] = TERRACE;
  });
}
// The ramps: 4 steps of 0.6 m, 2 tiles wide — the east beach up to the terrace (rows 62-63),
// the terrace up to the top (rows 45-46).
const RAMPS = [[92, 62, 4, 2, 0], [102, 45, 4, 2, TERRACE]];
for (const [rx, ry, rw, rh, base] of RAMPS) {
  for (let i = 0; i < rw; i++) for (let j = 0; j < rh; j++) {
    height[ry + j][rx + i] = base + 0.6 * (i + 1);
    sol[ry + j][rx + i] = "grass";
    flat[ry + j][rx + i] = true;
  }
}

// ---------------------------------------------------------------- the reef
// A ridge of rock 1 m out of the water, from the Pointe's tip to the headland's west end, one
// pass through it (x 67-70); two big rocks either side of the pass; a sand bar by the pass
// (inside), where one comes back up from the sanctuary.
const REEF_WEST = [[47.5, 30.8], [52, 30], [57, 29], [62, 28.2], [66.4, 27.7]];
const REEF_EAST = [[70.6, 27.3], [75, 26.8], [80, 26], [84, 25], [88, 23.5]];
const PASS = [67, 24, 4, 7];
const REEF_ROCKS = [[65.6, 27.7, 1.5, 1.3], [71.6, 27.2, 1.5, 1.3], [54.6, 29.6, 1.4, 1.0], [78.2, 26.4, 1.4, 1.0]];
const SANDBARS = [[74, 29.8, 3.0, 1.7], [58, 31.2, 2.6, 1.5]];
const REEF_H = 1.0;
const isReef = (x, y) => !inRect(x, y, PASS) && (toPolyline(x, y, REEF_WEST) < 0.85 || toPolyline(x, y, REEF_EAST) < 0.85
  || REEF_ROCKS.some((r) => inEllipse(x, y, ...r, 0.2)));
each((x, y) => {
  if (sol[y][x] !== "water") return;
  if (isReef(x, y)) { sol[y][x] = "rock"; height[y][x] = REEF_H; }
});
each((x, y) => {
  if (sol[y][x] === "water" && SANDBARS.some((r) => inEllipse(x, y, ...r, 0.15))) { sol[y][x] = "sand"; flat[y][x] = true; }
});
// Sea stacks out in the bay and the open sea (4.8 m, grass on top: the Pteranodons perch
// there, out of reach), and the turtles' islet in the bay (reached swimming).
const STACKS = [[13, 45, 1.7, 1.4], [29, 35, 2.1, 1.6], [22, 17, 1.8, 1.5], [55, 13, 1.6, 1.3], [79, 9, 1.9, 1.4], [38, 6, 1.5, 1.2]];
const TURTLE_ISLET = [23, 57, 3.2, 2.0];
each((x, y) => {
  if (sol[y][x] !== "water") return;
  if (STACKS.some((r) => inEllipse(x, y, ...r, 0.3))) { sol[y][x] = "grass"; height[y][x] = TOP; }
  else if (inEllipse(x, y, ...TURTLE_ISLET, 0.3)) { sol[y][x] = "sand"; flat[y][x] = true; }
});
const inStack = (x, y) => STACKS.some((r) => inEllipse(x, y, ...r, 0.3));

// ---------------------------------------------------------------- the south: the Désert's rim, the grove
const DESERT_SOLS = `${OUT}/desert_sols.png`, DESERT_RELIEF = `${OUT}/desert_relief.png`;
const RIM = 3.0;
const CORRIDOR = [15, 25];   // (Désert x 95-105: its way north, no rim there)
const rimTop = (x) => 94.5 - (fbm(x * 0.2, 6.6) - 0.3) * 4;
each((x, y) => {
  if (x > 43 || (x >= CORRIDOR[0] && x <= CORRIDOR[1])) return;
  if (y >= rimTop(x)) { height[y][x] = RIM; sol[y][x] = "rock"; }
});
// The grove closing the meadows behind the lagoon (south edge, up to the terraces).
each((x, y) => {
  if (x <= 43 || x >= T1(y)) return;
  if (y >= 92 + (fbm(x * 0.15, 8.8) - 0.5) * 5) sol[y][x] = "forest";
});
// The top's east edge south of the way to the Monts: woods (the Monts' first conifers).
each((x, y) => {
  if (y > HEAD_FACE + 2 && (y < 54 || y > 61) && x >= 124 + (fbm(y * 0.2, 3.3) - 0.5) * 3) sol[y][x] = "forest";
});
// The junction: the Côte's last rows are the Désert's first one (ground and height), so the
// two maps meet exactly where they are shown side by side.
const desertSols = await sharp(DESERT_SOLS).raw().toBuffer({ resolveWithObject: true });
const desertRelief = await sharp(DESERT_RELIEF).raw().toBuffer({ resolveWithObject: true });
const solOf = (buf, i) => {
  const c = [buf.data[i], buf.data[i + 1], buf.data[i + 2]];
  return Object.keys(SOLS).find((k) => SOLS[k].every((v, j) => Math.abs(v - c[j]) < 6)) ?? "grass";
};
for (let x = 0; x < W; x++) {
  const dx = x + DESERT_SHIFT;
  if (dx >= desertSols.info.width) break;
  const s = solOf(desertSols, dx * desertSols.info.channels);
  const h = desertRelief.data[dx * desertRelief.info.channels] * 0.05;
  for (let k = 0; k < JUNCTION_ROWS; k++) {
    sol[H - 1 - k][x] = s;
    height[H - 1 - k][x] = h;
    flat[H - 1 - k][x] = true;
  }
}
// Above the junction, the Désert's little dunes fade out over a few rows (no step).
for (let x = 0; x < W && x + DESERT_SHIFT < desertRelief.info.width; x++) {
  const h0 = height[H - 1][x];
  if (h0 >= LEDGE) continue;
  for (let k = 1; k <= 5; k++) {
    const y = H - JUNCTION_ROWS - k;
    if (height[y][x] < LEDGE) { height[y][x] = Math.max(height[y][x], Math.round(h0 * (1 - k / 6) / 0.05) * 0.05); flat[y][x] = true; }
  }
}
// A ledge (1.2 m) along the rim standing just south of the dunes: the camera looks north, 40°
// down, and a whole wall there would hide Chloé walking along its foot.
{
  const ledges = [];
  each((x, y) => {
    if (height[y][x] < RIM - 0.01 || y >= H - JUNCTION_ROWS || x > 43) return;
    for (let k = 1; k <= 2; k++) for (let dx = -1; dx <= 1; dx++) {
      const xx = x + dx, yy = y - k;
      if (inside(xx, yy) && height[yy][xx] < 0.5 && sol[yy][xx] !== "water") { ledges.push([x, y]); return; }
    }
  });
  for (const [x, y] of ledges) height[y][x] = LEDGE;
}

// ---------------------------------------------------------------- beaches
// Sand along the water: wide on the bay (the turtles' beach), a few tiles on the lagoon, a
// rim round the Pointe and the islet; the east beach and the cove's all sand.
{
  const nearWater = distanceTo((x, y) => sol[y][x] === "water");
  each((x, y) => {
    if (sol[y][x] !== "grass" || height[y][x] > 0) return;
    const bay = x < 40 ? 6.5 + (fbm(x * 0.2, y * 0.2 + 3) - 0.5) * 3 : 0;
    const lagoon = x >= 50 && x < 86 && y > 40 ? 3 + (fbm(x * 0.3, y * 0.3) - 0.5) * 2 : 0;
    const around = inPointe(x, y) || inEllipse(x, y, ...ISLET) ? 1.6 : 0;
    const reach = Math.max(bay, lagoon, around);
    if (nearWater[y][x] <= reach || inEastBeach(x, y) || inEllipse(x, y, ...PLESIO_POINT, 0.1)) { sol[y][x] = "sand"; flat[y][x] = true; }
  });
}
// The Cale des Anciens (west end of the beach): a platform of carved rock (0.6 m) at the back
// of the beach, its steps going down north into the bay (the ancients launched their boats
// there; page 24).
const CALE = [3, 74, 6, 2];
const CALE_STEPS = [4, 70, 3, 4];
each((x, y) => {
  if (inRect(x, y, CALE)) { sol[y][x] = "rock"; height[y][x] = 0.6; flat[y][x] = true; }
  if (inRect(x, y, CALE_STEPS)) { sol[y][x] = "rock"; height[y][x] = 0.15 * (y - CALE_STEPS[1]); flat[y][x] = true; }
});
// The islet's middle and the Pointe's spine stay grass (palms there).
each((x, y) => { if (inEllipse(x, y, ISLET[0], ISLET[1], 2.2, 1.3, 0.2) && sol[y][x] === "sand") sol[y][x] = "grass"; });
// The dunes behind the bay: sand from the beach down to the rim, west of the meadows.
const DUNES_EAST = (y) => 38 + (fbm(2.2, y * 0.1) - 0.5) * 6;
each((x, y) => {
  if (sol[y][x] !== "grass" || height[y][x] >= LEDGE || inPointe(x, y)) return;
  if (x < DUNES_EAST(y) && y > shoreY(x)) sol[y][x] = "sand";
});
// The Pointe's tip: bare rock facing the open sea (level with the ground).
each((x, y) => { if (inEllipse(x, y, POINTE_TIP[0], POINTE_TIP[1] + 0.2, 2.2, 1.4, 0.3) && sol[y][x] !== "water") sol[y][x] = "rock"; });

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
        if (inside(tx, ty) && !["water", "forest"].includes(sol[ty][tx]) && !(sol[ty][tx] === "rock" && height[ty][tx] > 0)) sol[ty][tx] = value;
      }
    }
  }
}
const TRAILS = [
  [[[19, 97], [19, 92]], 0],                                                                         // from the Désert (its trail's columns)
  [[[19, 92], [19.5, 88], [18.5, 84], [18.5, 81]], 0.8],                                             // over the last dune, to the beach
  [[[19.5, 88], [26, 86.5], [33, 84.5], [39, 80.5], [44, 75.5], [50, 71], [57, 68.5], [65, 67.5], [73, 67.5],
    [80, 66.5], [86, 64.5], [91, 63]], 0.8],                                                         // east, behind the lagoon
  [[[91, 63], [96, 63]], 0],                                                                         // the ramp up to the terrace
  [[[96, 63], [98.5, 58], [99, 50], [99, 41], [98.5, 35], [98, 31]], 0.6],                          // the terrace, north to the lookout
  [[[99, 46], [102, 46]], 0], [[[102, 46], [106, 46]], 0],                                           // the ramp up to the top
  [[[106, 46], [111, 48], [116, 52], [121, 56], [124, 58], [128, 58]], 0.6],                        // east, to the Monts
  [[[111, 48], [112, 40], [111, 32], [109, 25], [107, 19]], 0.6],                                    // north, to the headland
  [[[44.5, 76], [46, 68], [45.5, 60], [45.5, 50], [45.5, 40], [45.5, 34]], 0.6],                    // the Pointe des Palmes
  [[[62, 68], [62.5, 62], [62.5, 57]], 0.4],                                                         // down to the Plesiosaurus's rock
  [[[86, 64.5], [88.5, 58], [89, 50], [89.5, 42], [90, 38]], 0.6],                                  // the east beach, north
];
for (const [pts, wobble] of TRAILS) stroke(pts, 2, "path", wobble);

// ---------------------------------------------------------------- tall grass (encounters)
// Dune grass (marram), the edge of the turtles' beach, sea grass on the lagoon's shore (the
// Plesiosaurus lunges from the shallows), the Pointe's tip (the open sea), the meadows, the
// east beach, the terraces and the headland (the Pteranodons).
const TUFTS = [
  [8, 86, 3, 2], [31, 90, 3, 1.8], [34, 79, 2.5, 1.6], [6, 81, 2.4, 1.5], [26, 82, 2.2, 1.4],
  [12, 80, 3, 1.3], [28, 78, 3, 1.3],
  [54.5, 59.5, 2.6, 1.3], [70, 58, 3.5, 1.4], [79, 57.5, 3, 1.4], [75, 44, 1.8, 1.0], [73.5, 29.4, 1.8, 0.8],
  [46, 48, 2.2, 3], [45, 34.5, 2, 1.8],
  [58, 74, 4, 2.4], [74, 77, 4, 2.4], [86, 72, 3, 2], [52, 84, 3, 2], [66, 84, 3, 1.8],
  [89, 45, 2.2, 3],
  [100, 56, 2.6, 3], [101, 78, 3, 2.5], [114, 36, 4, 3], [118, 68, 3, 3], [102, 19.5, 3.5, 2], [117, 18, 3, 2], [112, 80, 3, 2.5],
];
each((x, y) => {
  if (!["grass", "sand"].includes(sol[y][x]) || (sol[y][x] === "rock")) return;
  if (inRect(x, y, COVE_BEACH) || inRect(x, y, NOTCH) || RAMPS.some(([rx, ry, rw, rh]) => inRect(x, y, [rx, ry, rw, rh]))) return;
  if (TUFTS.some(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, 0.6))) sol[y][x] = "tall_grass";
});

// ---------------------------------------------------------------- dunes and gentle rolls
// Dunes behind the bay (long ridges across the sea wind), the last one high over the beach;
// none by the trails, the beach, the rim, the edges of the map (they meet their neighbours
// there at the same height).
const isCliff = (x, y) => DIRS.some(([dx, dy]) => inside(x + dx, y + dy) && Math.abs(height[y + dy][x + dx] - height[y][x]) > 0.75);
const nearPath = distanceTo((x, y) => sol[y][x] === "path" || sol[y][x] === "water");
const nearFlat = distanceTo((x, y) => flat[y][x] || height[y][x] > 0);
const DUNE = [19.5, 82.5, 6, 1.2];   // the last dune, over the beach: [x, y, radius, height]
const dune = (x, y) => !flat[y][x] && ["sand", "tall_grass"].includes(sol[y][x]) && x < 42 && height[y][x] === 0;
each((x, y) => {
  if (!dune(x, y) && !(sol[y][x] === "path" && Math.hypot(x + 0.5 - DUNE[0], y + 0.5 - DUNE[1]) < DUNE[2])) return;
  const ridge = 0.5 + 0.5 * Math.sin(0.34 * (x * 0.8 - y * 0.6) + 3.0 * fbm(x * 0.05, y * 0.05));
  const amp = 0.3 + 0.7 * fbm(x * 0.05 + 10, y * 0.05 + 3);
  const fade = smooth(0.5, 3.5, nearPath[y][x]) * smooth(0.5, 3.0, nearFlat[y][x]) * smooth(2, 6, edgeDistance(x, y));
  let h = sol[y][x] === "path" ? 0 : 1.0 * ridge * ridge * amp * fade;
  const d = Math.hypot(x + 0.5 - DUNE[0], y + 0.5 - DUNE[1]);
  h = Math.max(h, DUNE[3] * Math.exp(-1.6 * (d / DUNE[2]) ** 2) * smooth(2, 6, edgeDistance(x, y)));
  height[y][x] = Math.round(h / 0.05) * 0.05;
});
// No dune steeper than DUNE_SLOPE a tile (the higher side lowered, a few passes).
const DUNE_SLOPE = 0.3;
for (let pass = 0; pass < 12; pass++) {
  each((x, y) => {
    if (!(dune(x, y) || sol[y][x] === "path") || x >= 42 || height[y][x] >= RIM - 0.01) return;
    for (const [dx, dy] of DIRS) {
      const xx = x + dx, yy = y + dy;
      if (!inside(xx, yy) || height[yy][xx] >= LEDGE - 0.01 || sol[yy][xx] === "water") continue;
      if (height[y][x] - height[yy][xx] > DUNE_SLOPE) height[y][x] = Math.floor((height[yy][xx] + DUNE_SLOPE) / 0.05 + 1e-6) * 0.05;
    }
  });
}
// Gentle rolls on the meadows (the mainland, the Pointe's spine, the terraces' tops), never a
// step; none by the water, the paths, the edges.
const nearWaterOrCliff = distanceTo((x, y) => sol[y][x] === "water" || isCliff(x, y) || flat[y][x]);
each((x, y) => {
  if (!["grass", "tall_grass"].includes(sol[y][x]) || flat[y][x]) return;
  const base = height[y][x];
  if (base !== 0 && base !== TERRACE && base !== TOP) return;
  const fade = smooth(1, 4, nearWaterOrCliff[y][x]) * smooth(0.5, 2.5, nearPath[y][x]) * smooth(2, 6, edgeDistance(x, y));
  const roll = Math.max(0, fbm(x * 0.13 + 21, y * 0.13 + 2) - 0.4) * 0.8 * fade;
  height[y][x] = base + Math.round(Math.min(0.35, roll) / 0.05) * 0.05;
});

// ---------------------------------------------------------------- checks
const WALK = ["grass", "path", "tall_grass", "sand", "mud", "rock"];
function reach(from, swim, blocked = () => false) {
  const seen = grid(false), queue = [from];
  seen[from[1]][from[0]] = true;
  for (let i = 0; i < queue.length; i++) {
    const [x, y] = queue[i];
    for (const [dx, dy] of DIRS) {
      const xx = x + dx, yy = y + dy;
      if (!inside(xx, yy) || seen[yy][xx] || blocked(xx, yy)) continue;
      const s = sol[yy][xx];
      if (!(WALK.includes(s) || (swim && s === "water"))) continue;
      if (Math.abs(height[yy][xx] - height[y][x]) > 0.75) continue;
      seen[yy][xx] = true;
      queue.push([xx, yy]);
    }
  }
  return seen;
}
const ENTRY = [19, 98];
const foot = reach(ENTRY, false), swim = reach(ENTRY, true);
let water = 0, open = 0, onFoot = 0, bySwim = 0, sand = 0, forest = 0;
each((x, y) => {
  if (sol[y][x] === "water") water++;
  if (sol[y][x] === "sand") sand++;
  if (sol[y][x] === "forest") forest++;
  if (WALK.includes(sol[y][x])) { open++; if (foot[y][x]) onFoot++; if (swim[y][x]) bySwim++; }
});
console.log(`eau : ${(100 * water / (W * H)).toFixed(1)} %, sable : ${(100 * sand / (W * H)).toFixed(1)} %, bois : ${(100 * forest / (W * H)).toFixed(1)} % ; sol ouvert ${open} cases : ${onFoot} à pied, ${bySwim} en nageant`);
let failures = 0;
for (const [name, [x, y, how]] of Object.entries(PLACES)) {
  let ok;
  if (how === "pied") ok = foot[y][x];
  else if (how === "nage") ok = swim[y][x] && !foot[y][x] && sol[y][x] !== "water";
  else ok = swim[y][x] && sol[y][x] === "water";
  if (!ok) failures++;
  console.log(`  ${ok ? "ok " : "NON"} ${name} (${x}, ${y}) ${how} : ${sol[y][x]} ${height[y][x].toFixed(2)} m, à pied ${foot[y][x] ? "oui" : "non"}, à la nage ${swim[y][x] ? "oui" : "non"}`);
}
// The lagoon, the pass shut: its water must not reach the open sea by water (the reef closes it).
{
  const shut = reach([70, 44], true, (x, y) => inRect(x, y, PASS) || sol[y][x] !== "water");
  const ok = !shut[5][68] && !shut[40][20];
  if (!ok) failures++;
  console.log(`  ${ok ? "ok " : "NON"} le récif ferme le lagon (sans la passe, pas de chemin vers le large)`);
}
// Open ground nobody reaches, even swimming (not the reef's rock, not the headland's ledges).
let lost = 0;
const lostAt = [];
each((x, y) => {
  if (!WALK.includes(sol[y][x]) || swim[y][x] || isReef(x, y) || inStack(x, y) || height[y][x] >= TERRACE - 0.01 && inHeadland(x, y)) return;
  if (height[y][x] >= RIM - 0.01 && x <= 43) return;   // (the rim's top)
  if (height[y][x] === LEDGE) return;                  // (the rim's ledge, the cove's spur)
  lost++;
  if (lostAt.length < 12) lostAt.push(`(${x}, ${y})`);
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
// The junction with the Désert: the Côte's last row against the Désert's first.
{
  let diff = 0;
  for (let x = 0; x < W && x + DESERT_SHIFT < desertRelief.info.width; x++) {
    const dh = desertRelief.data[(x + DESERT_SHIFT) * desertRelief.info.channels] * 0.05;
    diff = Math.max(diff, Math.abs(dh - height[H - 1][x]));
  }
  console.log(`  raccord avec le Désert : écart de hauteur max ${diff.toFixed(2)} m sur la dernière rangée`);
}
console.log(failures ? `${failures} LIEU(X) EN DÉFAUT` : "tous les lieux sont bons");

// ---------------------------------------------------------------- write
const solBuf = Buffer.alloc(W * H * 3), hBuf = Buffer.alloc(W * H);
each((x, y) => {
  solBuf.set(SOLS[sol[y][x]], (y * W + x) * 3);
  hBuf[y * W + x] = Math.max(0, Math.min(255, Math.round(height[y][x] / 0.05)));
});
await sharp(solBuf, { raw: { width: W, height: H, channels: 3 } }).png().toFile(`${OUT}/cote_sols.png`);
await sharp(hBuf, { raw: { width: W, height: H, channels: 1 } }).png().toFile(`${OUT}/cote_relief.png`);
console.log(`${OUT}/cote_sols.png, ${OUT}/cote_relief.png (${W} x ${H})`);
