// Draws the two map images of the Désert Aride (1 pixel = 1 tile, 120 x 100):
//   desert_sols.png   — the ground, by colour (see SOLS below; any other colour = grass)
//   desert_relief.png — the height, in grey levels (1 level = 5 cm; black = 0 m)
// They are the source of the region: retouch them in any paint program (keep the exact
// colours of SOLS, and 1 pixel = 1 tile), then rebuild the region:
//   godot --headless --path Godot --script res://tools/build_zone.gd -- desert --force
// Running this script again overwrites them (from the layout below), and prints the checks:
// the places reachable on foot from the way in with the fallen rocks still there, the walled
// canyon's reached only once they are gone, open ground nobody reaches.
// Usage (from the repository root): node Godot/tools/maps/gen-desert.mjs
//
// A desert closed by canyon walls (rock, "rock" tiles, cliffs of 2.4 to 3.6 m), dunes of sand
// ("sand", rolling gently), trails of trodden earth (path) between the places.
// Layout (tiles; the places are the ones tools/zones/desert.gd fills):
//   south-east  the Canyon d'entrée: the way in from the Marais (x 100-103, y 99), the marsh
//               drying up (mud, puddles, dry reeds), the Lac de sel to the west (78, 88);
//   centre-south the Cimetière des Géants (x 62-88, y 60-81): giant bones on the hardpan, Tante
//               Sirocco's tent at its north-east corner (86.5, 66), the six fossils;
//   west        the Rochers de l'ouest (the basin) and the West plateau (2.4 m), the Canyon muré
//               cut into it from the south: its mouth (x 26-31, y 52-58) closed by the fallen
//               rocks (Charge), the Vieux Rempart's hollow at its end (20.5, 33), page 20;
//   centre      the Grand Erg: dunes, a few buttes, the trail north;
//   north       the sanctuary des Vents: its door in the rock face at the north edge (x 59-61,
//               a notch running to the edge: the sanctuary lies beyond it), the square before it;
//               the Canyon des Vents winding west from the square to a dead end (14.5, 9.5);
//   north-east  the Oasis (99, 31), the Grande Dune north of it (103.5, 14.5), the way to the Côte
//               through the dunes (x 98-101, y 0).
import sharp from "sharp";

export const SOLS = {
  grass: [90, 158, 58], path: [200, 160, 96], tall_grass: [47, 107, 31],
  water: [46, 111, 181], forest: [31, 64, 32], sand: [232, 212, 154], mud: [107, 90, 54], rock: [176, 96, 60],
};
const W = 120, H = 100;
const OUT = "Godot/tools/maps";
/** Places to check: [x, y, how] — "pied": on foot from the way in, the fallen rocks still
 *  there; "rempart": in the walled canyon, reached only once they are gone. */
const PLACES = {
  "entrée (canyon sud)": [102, 97, "pied"], "Sirocco (devant sa tente)": [86, 68, "pied"],
  "feu de Sirocco": [89, 69, "pied"], "cimetière (le grand crâne)": [74, 72, "pied"],
  "fossile 1 (sous le grand crâne)": [74, 71, "pied"], "fossile 2 (côtes du squelette)": [66, 77, "pied"],
  "fossile 3 (os géant près de la tente)": [83, 69, "pied"], "fossile 4 (bord du lac de sel)": [77, 84, "pied"],
  "fossile 5 (sous l'arche, à l'ouest)": [62, 69, "pied"], "fossile 6 (buisson sec, au nord)": [73, 62, "pied"],
  "page 17 (cimetière)": [80, 76, "pied"], "lac de sel (rive nord)": [78, 84, "pied"],
  "devant les éboulis": [28, 60, "pied"], "place du sanctuaire": [60, 9, "pied"],
  "devant la porte des Vents": [60, 6, "pied"], "entrée du canyon des Vents": [48, 10, "pied"],
  "poursuite 1": [44, 11, "pied"], "poursuite 2": [34, 15, "pied"], "poursuite 3": [25, 12, "pied"],
  "Brac (cul-de-sac)": [15, 12, "pied"], "chariot (devant)": [13, 10, "pied"], "Carnotaurus (cul-de-sac)": [18, 8, "pied"],
  "oasis (Maïa)": [93, 31, "pied"], "puits de l'oasis": [92, 28, "pied"], "page 19 (oasis)": [94, 27, "pied"],
  "Grande Dune (le sommet)": [103, 14, "pied"], "sortie vers la Côte": [100, 1, "pied"],
  "Vieux Rempart (au fond)": [20, 33, "rempart"], "page 20 (canyon muré)": [16, 30, "rempart"],
};
/** The fallen rocks across the walled canyon's mouth (tiles blocked by the Obstacle). */
const RUBBLE = [26, 56, 6, 3];
/** The sanctuary's door, in its notch (x 59-61) at the north edge (blocked while shut). */
const NOTCH = [59, 0, 3, 3];

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
const sol = grid("sand");
const height = grid(0);
const butte = grid(false);     // the buttes of the erg (no ledge on them)
const flat = grid(false);      // kept level: canyon floors, the square, the places (no dunes)
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
/** The polyline's y at column x (it runs east-west; clamped at its ends). */
function polylineY(x, pts) {
  const sorted = [...pts].sort((a, b) => a[0] - b[0]);
  if (x <= sorted[0][0]) return sorted[0][1];
  for (let i = 0; i < sorted.length - 1; i++) {
    const [ax, ay] = sorted[i], [bx, by] = sorted[i + 1];
    if (x <= bx) return ay + (by - ay) * (x - ax) / (bx - ax);
  }
  return sorted[sorted.length - 1][1];
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

// ---------------------------------------------------------------- the rock
const RIM = 3.0, HIGH = 3.6, PLATEAU = 2.4, BUTTE = 2.4;
// The Canyon des Vents (floor 0), from the square west to its dead end; the Canyon muré, from
// its mouth (south) north to the Vieux Rempart's hollow.
const VENTS = [[53, 8.5], [46, 10.5], [40, 13.8], [33, 15.2], [27, 13.2], [21.5, 10.5]];
const VENTS_END = [14.5, 9.5, 7.5, 5.4];
const MURE = [[28.5, 60], [28.5, 51], [26.5, 45], [23.5, 39.5]];
const MURE_END = [20.5, 33.2, 6.8, 5.2];
const inVents = (x, y) => toPolyline(x, y, VENTS) < 3.3 + (fbm(x * 0.3 + 5, y * 0.3) - 0.5) * 1.2 || inEllipse(x, y, ...VENTS_END, 0.25);
// The walled canyon: straight walls at its mouth (the fallen rocks fill it, wall to wall).
const inMure = (x, y) => {
  if (y >= 52) return x >= 26 && x <= 31;
  return toPolyline(x, y, MURE) < 3.0 + (fbm(x * 0.3 + 9, y * 0.3) - 0.5) * 1.0 || inEllipse(x, y, ...MURE_END, 0.25);
};
// The rock of the north-west: 3.6 m north of the Canyon des Vents, the West plateau (2.4 m)
// south of it, down to its south face (y 59 around the walled canyon's mouth).
const westFace = (x) => (x >= 20 && x <= 37 ? 59 : 57 + (fbm(x * 0.12, 3.1) - 0.5) * 5);
const inNorthWest = (x, y) => {
  const w = (fbm(x * 0.1 + 3, y * 0.1 + 8) - 0.5) * 5;
  return (x < 51 + w * 0.4 && y < 19 + w * 0.6) || (x < 37 + w && y < westFace(x));
};
const SQUARE = [50, 3, 21, 12];   // the sanctuary's square (floor 0)
// The rock face of the sanctuary along the north edge (its face at y 3 by the door).
const inNorthRock = (x, y) => x >= 38 && x <= 82 && y < 3 + (x < 52 || x > 69 ? Math.max(0, (fbm(x * 0.2, 7.7) - 0.3) * 6) : 0);
const BUTTES = [[52, 34, 3.6, 2.8, 3.0], [80, 22, 3.0, 2.3, BUTTE], [71, 51, 2.4, 1.8, BUTTE], [45, 47, 2.6, 2.0, BUTTE],
  [110, 44, 3.0, 2.4, BUTTE], [22, 84, 3.6, 2.6, 3.0], [48, 80, 2.4, 1.8, BUTTE], [108, 66, 2.6, 2.0, BUTTE]];
// The spur west of the way in, and the ways through the rim (the way in, the way to the Côte).
const inSpur = (x, y) => x >= 87 && x <= 95 && y >= 89 + (fbm(x * 0.3, 2.2) - 0.5) * 3;
const SOUTH_WAY = (x, y) => x >= 96 && x <= 107 && y >= 80;
const NORTH_WAY = (x, y) => x >= 95 && x <= 105 && y <= 8;

each((x, y) => {
  const n = fbm(x * 0.12, y * 0.12);
  const edge = Math.min(x, y, W - 1 - x, H - 1 - y);
  let h = 0;
  if (edge < 2.5 + n * 2.5 && !SOUTH_WAY(x, y) && !NORTH_WAY(x, y)) h = RIM;
  if (inSpur(x, y)) h = PLATEAU;
  // The east wall of the way in: the rim, thicker there.
  if (x >= 108 && y >= 80 + (fbm(3.3, y * 0.2) - 0.5) * 4) h = RIM;
  if (inNorthRock(x, y)) h = HIGH;
  if (inNorthWest(x, y)) h = y < polylineY(x, VENTS) ? HIGH : PLATEAU;
  for (const [cx, cy, rx, ry, bh] of BUTTES) if (inEllipse(x, y, cx, cy, rx, ry, 0.35)) { h = Math.max(h, bh); butte[y][x] = true; }
  height[y][x] = h;
  if (h > 0) sol[y][x] = "rock";
});
// Floors cut into the rock: the canyons, the square, the sanctuary's notch.
each((x, y) => {
  if (inVents(x, y) || inMure(x, y) || inRect(x, y, SQUARE) || inRect(x, y, NOTCH)) {
    if (inMure(x, y) && y >= 59) return;   // (the basin, south of the mouth)
    height[y][x] = 0;
    flat[y][x] = true;
    // Sand blown in, bare rock showing through here and there.
    sol[y][x] = fbm(x * 0.22 + 30, y * 0.22 + 12) < 0.4 ? "rock" : "sand";
  }
});
// A ledge (1.2 m) along the walls standing just south of a floor: the camera looks north,
// 40° down, and a whole wall there would hide Chloé walking along its foot. Still a cliff on
// both sides (from the floor, from the wall).
const LEDGE = 1.2, LEDGE_DEPTH = 2;
{
  const low = (x, y) => inside(x, y) && height[y][x] < 0.5;
  const ledges = [];
  each((x, y) => {
    if (height[y][x] < PLATEAU - 0.01 || butte[y][x]) return;
    for (let k = 1; k <= LEDGE_DEPTH; k++) for (let dx = -1; dx <= 1; dx++) if (low(x + dx, y - k)) { ledges.push([x, y]); return; }
  });
  for (const [x, y] of ledges) height[y][x] = LEDGE;
}

// ---------------------------------------------------------------- water, the oasis, the salt lake
const OASIS = [99, 31], LAKE = [78, 88.5];
each((x, y) => {
  if (inEllipse(x, y, OASIS[0], OASIS[1], 10, 6.8, 0.35)) { sol[y][x] = "grass"; flat[y][x] = true; }
  if (inEllipse(x, y, LAKE[0], LAKE[1], 10, 5, 0.3)) { sol[y][x] = "sand"; flat[y][x] = true; }   // the salt crust
});
each((x, y) => {
  if (inEllipse(x, y, OASIS[0], OASIS[1], 4.6, 2.7, 0.2)) sol[y][x] = "water";
  if (inEllipse(x, y, LAKE[0], LAKE[1], 6.8, 3.1, 0.25)) sol[y][x] = "water";
});
// The marsh drying up by the way in: mud, a few puddles.
each((x, y) => {
  if (SOUTH_WAY(x, y) && height[y][x] === 0 && y >= 90 + (fbm(x * 0.25, y * 0.25) - 0.5) * 4) { sol[y][x] = "mud"; flat[y][x] = true; }
});
for (const [cx, cy, rx, ry] of [[98.5, 95, 1.6, 1.1], [105.5, 93, 1.3, 1.0], [104.8, 97.5, 1.2, 0.9]]) {
  each((x, y) => { if (inEllipse(x, y, cx, cy, rx, ry, 0.1) && sol[y][x] === "mud") sol[y][x] = "water"; });
}

// ---------------------------------------------------------------- the places (level ground)
// The cemetery's hardpan, Sirocco's camp, the basin before the walled canyon, the square.
const HARDPAN = [[75, 71, 13.5, 10.5], [44, 64, 16, 6], [98, 84, 7, 5]];
each((x, y) => {
  if (height[y][x] > 0) return;
  if (HARDPAN.some(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, 0.4))) {
    flat[y][x] = true;
    if (sol[y][x] === "sand" && fbm(x * 0.22 + 4, y * 0.22 + 9) < 0.56) sol[y][x] = "rock";
  }
});
// Sand drifting over the hardpan, here and there.
each((x, y) => {
  if (sol[y][x] === "rock" && height[y][x] === 0 && !inRect(x, y, SQUARE) && fbm(x * 0.25 + 30, y * 0.25 + 12) > 0.6) sol[y][x] = "sand";
});

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
        if (inside(tx, ty) && sol[ty][tx] !== "water" && height[ty][tx] === 0) sol[ty][tx] = value;
      }
    }
  }
}
const TRAILS = [
  [[101.5, 100], [101.5, 92], [100, 86], [97, 80], [93.5, 74.5], [90.5, 71]],                 // from the Marais to Sirocco
  [[88, 71.5], [80, 73.5], [72, 74], [64, 71.5], [55, 67], [45, 63.5], [36, 61], [29, 60.5]],   // the cemetery, west to the rubble
  [[76, 72], [75, 63], [72, 55], [67, 47], [64, 38], [62, 28], [61, 19], [61, 13]],             // north, over the erg, to the square
  [[66.5, 44], [74, 40], [83, 35.5], [90, 32.5]],                                              // east, to the oasis
  [[96.5, 25], [93.5, 18], [95, 10], [99.5, 5], [99.5, 0]],                                    // the oasis, north to the Côte
];
for (const t of TRAILS) stroke(t, 2, "path", 0.8);

// ---------------------------------------------------------------- tall grass (encounters)
const TUFTS = [[92, 35, 2.6, 1.7], [106, 27, 2.4, 1.6], [104, 36, 2.2, 1.4],   // the oasis
  [66, 64, 2.6, 1.6], [85, 79, 2.4, 1.5],                                      // the cemetery's edges
  [105, 89, 2.0, 1.4],                                                         // reeds by the way in
  [30, 78, 3.0, 2.0], [46, 90, 2.6, 1.8], [108, 54, 2.6, 2.0], [52, 25, 2.6, 1.6], [86, 12, 2.4, 1.6]];
each((x, y) => {
  if (height[y][x] !== 0 || !["sand", "grass", "rock", "mud"].includes(sol[y][x])) return;
  if (TUFTS.some(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, 0.6))) sol[y][x] = "tall_grass";
});

// ---------------------------------------------------------------- dunes
// Long ridges across the wind (from the west-north-west), their height varying; none on the
// level places, by the trails, the water or the cliffs.
const isCliff = (x, y) => DIRS.some(([dx, dy]) => inside(x + dx, y + dy) && Math.abs(height[y + dy][x + dx] - height[y][x]) > 0.75);
const nearPath = distanceTo((x, y) => sol[y][x] === "path" || sol[y][x] === "water");
const nearFlat = distanceTo((x, y) => flat[y][x] || height[y][x] > 0);
const DUNE = [103.5, 14.5, 7.5, 2.4];   // the Grande Dune, north of the oasis: [x, y, radius, height]
each((x, y) => {
  if (height[y][x] !== 0 || flat[y][x] || sol[y][x] === "water" || sol[y][x] === "path") return;
  const ridge = 0.5 + 0.5 * Math.sin(0.3 * (x * 0.85 + y * 0.52) + 3.2 * fbm(x * 0.05, y * 0.05));
  const amp = 0.35 + 0.95 * fbm(x * 0.045 + 10, y * 0.045 + 3);
  const fade = smooth(0.5, 3.5, nearPath[y][x]) * smooth(0.5, 3.0, nearFlat[y][x]);
  let h = 1.25 * ridge * ridge * amp * fade;
  const d = Math.hypot(x + 0.5 - DUNE[0], y + 0.5 - DUNE[1]);
  h = Math.max(h, DUNE[3] * Math.exp(-1.6 * (d / DUNE[2]) ** 2) * smooth(0.5, 5, nearPath[y][x]));
  height[y][x] = Math.round(h / 0.05) * 0.05;
});
// No dune steeper than DUNE_SLOPE a tile (steeper ground is drawn as a little cliff): the
// higher side lowered, a few passes (the rock walls are left alone).
const DUNE_SLOPE = 0.3;
const dune = (x, y) => !flat[y][x] && ["sand", "tall_grass"].includes(sol[y][x]);
for (let pass = 0; pass < 12; pass++) {
  each((x, y) => {
    if (!dune(x, y)) return;
    for (const [dx, dy] of DIRS) {
      const xx = x + dx, yy = y + dy;
      if (!inside(xx, yy) || sol[yy][xx] === "rock") continue;
      if (height[y][x] - height[yy][xx] > DUNE_SLOPE) height[y][x] = Math.floor((height[yy][xx] + DUNE_SLOPE) / 0.05 + 1e-6) * 0.05;
    }
  });
}
// Gentle rolls on the level places (the cemetery, the canyons), never a step.
each((x, y) => {
  if (!flat[y][x] || height[y][x] !== 0 || sol[y][x] === "water" || inRect(x, y, SQUARE) || inRect(x, y, NOTCH)) return;
  if (inMure(x, y) && y >= 50) return;   // (the walled canyon's mouth stays level for the rocks)
  height[y][x] = Math.round(Math.max(0, fbm(x * 0.15 + 21, y * 0.15 + 2) - 0.45) * 0.4 / 0.05) * 0.05;
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
      if (!inside(xx, yy) || seen[yy][xx] || blocked(xx, yy) || !WALK.includes(sol[yy][xx])) continue;
      if (Math.abs(height[yy][xx] - height[y][x]) > 0.75) continue;
      seen[yy][xx] = true;
      queue.push([xx, yy]);
    }
  }
  return seen;
}
const ENTRY = [102, 98];
const door = (x, y) => inRect(x, y, NOTCH) && y <= 2;
const before = reach(ENTRY, (x, y) => inRect(x, y, RUBBLE) || door(x, y));
const after = reach(ENTRY, door);
let open = 0, walked = 0, rockTiles = 0, sandTiles = 0;
each((x, y) => {
  if (WALK.includes(sol[y][x])) { open++; if (after[y][x]) walked++; }
  if (sol[y][x] === "rock") rockTiles++;
  if (sol[y][x] === "sand") sandTiles++;
});
console.log(`roche : ${(100 * rockTiles / (W * H)).toFixed(1)} %, sable : ${(100 * sandTiles / (W * H)).toFixed(1)} % ; sol ouvert ${open} cases, ${walked} atteintes`);
let failures = 0;
for (const [name, [x, y, how]] of Object.entries(PLACES)) {
  const ok = how === "pied" ? before[y][x] : after[y][x] && !before[y][x];
  if (!ok) failures++;
  console.log(`  ${ok ? "ok " : "NON"} ${name} (${x}, ${y}) ${how} : ${sol[y][x]} ${height[y][x].toFixed(2)} m, avant les éboulis ${before[y][x] ? "oui" : "non"}, après ${after[y][x] ? "oui" : "non"}`);
}
// Low open ground nobody reaches (not the rock tops, not behind the sanctuary's door).
let lost = 0;
const lostAt = [];
each((x, y) => {
  if (WALK.includes(sol[y][x]) && !after[y][x] && height[y][x] < 1.0 && !inRect(x, y, NOTCH)) { lost++; if (lostAt.length < 12) lostAt.push(`(${x}, ${y})`); }
});
console.log(`  sol bas injoignable : ${lost} cases ${lostAt.join(" ")}`);
// Steps on the trails (a cliff across a trail would cut it).
each((x, y) => {
  if (sol[y][x] !== "path") return;
  for (const [dx, dy] of [[1, 0], [0, 1]]) {
    const xx = x + dx, yy = y + dy;
    if (inside(xx, yy) && sol[yy][xx] === "path" && Math.abs(height[yy][xx] - height[y][x]) > 0.3) console.log(`  MARCHE sur le sentier : (${x}, ${y}) -> (${xx}, ${yy})`);
  }
});
// The steepest dune slope (above 0.45 m a tile the ground is drawn as a small cliff).
let steep = 0;
each((x, y) => {
  if (height[y][x] >= 1.8 || isCliff(x, y)) return;
  for (const [dx, dy] of [[1, 0], [0, 1]]) {
    const xx = x + dx, yy = y + dy;
    if (inside(xx, yy) && height[yy][xx] < 1.8) steep = Math.max(steep, Math.abs(height[yy][xx] - height[y][x]));
  }
});
console.log(`  pente la plus raide des dunes : ${steep.toFixed(2)} m par case`);
console.log(failures ? `${failures} LIEU(X) EN DÉFAUT` : "tous les lieux sont bons");

// ---------------------------------------------------------------- write
const solBuf = Buffer.alloc(W * H * 3), hBuf = Buffer.alloc(W * H);
each((x, y) => {
  solBuf.set(SOLS[sol[y][x]], (y * W + x) * 3);
  hBuf[y * W + x] = Math.max(0, Math.min(255, Math.round(height[y][x] / 0.05)));
});
await sharp(solBuf, { raw: { width: W, height: H, channels: 3 } }).png().toFile(`${OUT}/desert_sols.png`);
await sharp(hBuf, { raw: { width: W, height: H, channels: 1 } }).png().toFile(`${OUT}/desert_relief.png`);
console.log(`${OUT}/desert_sols.png, ${OUT}/desert_relief.png (${W} x ${H})`);
