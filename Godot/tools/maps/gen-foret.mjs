// Draws the two map images of the Forêt Jurassique (1 pixel = 1 tile, 130 x 100):
//   foret_sols.png   — the ground, by colour (see SOLS below; any other colour = grass)
//   foret_relief.png — the height, in grey levels (1 level = 5 cm; black = 0 m)
// They are the source of the region: retouch them in any paint program (keep the exact
// colours of SOLS, and 1 pixel = 1 tile), then rebuild the region:
//   godot --headless --path Godot --script res://tools/build_zone.gd -- foret --force
// Running this script again overwrites them (from the layout below), and prints the checks:
// share of forest tiles, places reachable from the entrance, the footbridges (tools/zones/foret.gd).
// Usage (from the repository root): node Godot/tools/maps/gen-foret.mjs
//
// Layout (tiles; the places are the ones tools/zones/foret.gd fills):
//   east    the Lisière: the way in from the Plaines (x 129, y 51-52), light woods, meadows,
//           the Mare de lune (page 10, full moon), the brachiosaurs' meadow (south);
//   centre  the Sous-bois: winding trails between walls of trees, tall ferns (encounters),
//           the stream from the northern spring to the Mare aux libellules, page 7 (68, 52);
//   north   the Clairière (page 9, 46, 24); north-west the Clairière aux fougères géantes
//           (24, 18, the Alpha's, chapter 2 part 2); north-east the Clairières rocheuses;
//   south   the Haute futaie: a plateau 2.4 m up (ledges), three ramps, page 8 (70, 82); north
//           of its trail, the Masque's rock and footbridge between two giant trees (56, 74);
//   west    the Cœur de la forêt around the Mare du cœur; the rock face of the poachers' camp:
//           a notch in the south face at the back of its bay (11-12, 39-40), the cracked wall
//           in it, the way to the camp
//           (zone camp_ombre, up on the rock: the ridge's west end is as high as the camp);
//           south-west, in a wooded upland, the hidden ravine of Griffe-Grise (22, 80),
//           reached by a faint trail.
//   north-west  the bridge to the Marais over a marshy pond (0-5, 11-12), its trail from the
//           Alpha's clearing.
import sharp from "sharp";

export const SOLS = {
  grass: [90, 158, 58], path: [200, 160, 96], tall_grass: [47, 107, 31],
  water: [46, 111, 181], forest: [31, 64, 32], sand: [232, 212, 154],
};
const W = 130, H = 100;
const OUT = "Godot/tools/maps";
/** Places to check (reachable from the entrance, on open ground). */
const PLACES = {
  "entrée": [126, 52], "page 10 (lisière)": [118, 40], "page 7 (sous-bois)": [68, 52],
  "page 8 (haute futaie)": [70, 82], "page 9 (clairière)": [46, 24], "clairière de l'Alpha": [24, 18],
  "Griffe-Grise (ravin)": [22, 80], "mur du camp (devant)": [12, 42], "entaille du camp": [12, 39],
  "clairières rocheuses": [96, 22], "cœur de la forêt": [32, 56], "prairie des brachiosaures": [116, 68],
  "pont du Marais": [3, 12], "Maïa (pont)": [6, 12], "sous la passerelle du Masque": [56, 77],
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
const sol = grid("grass");
const height = grid(0);
const clearing = grid(false);   // kept open: no wall of trees
const bridge = grid(false);     // path laid over water (a footbridge)
const inside = (x, y) => x >= 0 && y >= 0 && x < W && y < H;
const set = (x, y, v) => { if (inside(x, y)) sol[y][x] = v; };
const inEllipse = (x, y, cx, cy, rx, ry, wobble = 0) =>
  ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 < 1 + wobble * (fbm(x * 0.35, y * 0.35) - 0.5);
const each = (f) => { for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) f(x, y); };
const DIRS = [[1, 0], [-1, 0], [0, 1], [0, -1]];

/** A line of `value` tiles along a polyline, `width` tiles wide, wavy by `wobble` tiles. */
function stroke(points, width, value, wobble = 1.2) {
  for (let i = 0; i < points.length - 1; i++) {
    const [x0, y0] = points[i], [x1, y1] = points[i + 1];
    const n = Math.ceil(Math.hypot(x1 - x0, y1 - y0) * 3);
    for (let k = 0; k <= n; k++) {
      const t = k / n;
      const wob = (noise((x0 + x1) * 0.1 + t * 4, (y0 + y1) * 0.1) - 0.5) * wobble;
      const px = x0 + (x1 - x0) * t + (y1 !== y0 ? wob : 0), py = y0 + (y1 - y0) * t + (x1 !== x0 ? wob : 0);
      for (let dy = 0; dy < width; dy++) for (let dx = 0; dx < width; dx++) {
        const tx = Math.floor(px - width / 2 + dx + 0.5), ty = Math.floor(py - width / 2 + dy + 0.5);
        if (!inside(tx, ty)) continue;
        if (value === "path" && sol[ty][tx] === "water") bridge[ty][tx] = true;
        sol[ty][tx] = value;
      }
    }
  }
}
const path = (points, width = 2, wobble = 1.2) => stroke(points, width, "path", wobble);

// 1. Borders, closed all round by the woods (the way in from the Plaines open), and by rock
//    in the north-east, rising in ledges of 2.4 m (a smooth slope would show as a blurred bank).
const LEDGE = 2.4;
each((x, y) => {
  const n = fbm(x * 0.12, y * 0.12);
  const edge = Math.min(x, y, W - 1 - x, H - 1 - y);
  if (edge < 2.5 + n * 3) sol[y][x] = "forest";
  const north = smooth(11 + n * 4, 2, y) * smooth(70, 82, x);
  const rise = north * (7 + fbm(x * 0.07, y * 0.07) * 5);
  if (north > 0) height[y][x] = Math.max(height[y][x], Math.floor(rise / LEDGE) * LEDGE);
  if (height[y][x] >= LEDGE && edge >= 2) sol[y][x] = "grass";   // bare rock up there
});

// 2. Relief: the Haute futaie (a plateau in the south), the wooded upland of the south-west
//    (the ravine cut into it), the rock ridge of the camp (west), the rocky outcrops (north-east).
const PLATEAU = 2.4, UPLAND = 3.6, MASK_ROCK = PLATEAU + 1.4;
const plateauAt = (x, y) => {
  const w = fbm(x * 0.09 + 12, y * 0.09 + 3);
  // Straight edges where the ramps meet it.
  if (x >= 76 && x <= 85 && y >= 60 && y <= 72) return y >= 68;
  if (y >= 72 && y <= 81 && x >= 42 && x <= 52) return x >= 48;
  if (y >= 80 && y <= 89 && x >= 103 && x <= 112) return x <= 107;
  return y >= 66 + w * 4 && x >= 46 + w * 3 && x <= 106 + w * 4;
};
const uplandAt = (x, y) => {
  const w = fbm(x * 0.1 + 40, y * 0.1 + 21);
  return x <= 38 + w * 3 && y >= 64 + w * 4;
};
each((x, y) => {
  if (plateauAt(x, y)) height[y][x] = PLATEAU;
  if (uplandAt(x, y)) height[y][x] = y >= 86 ? PLATEAU : UPLAND;
  if (ridgeAt(x, y)) height[y][x] = UPLAND;
  if (maskRockAt(x, y)) height[y][x] = MASK_ROCK;
});
// The camp's ridge: a rock face along x = 10, a bay in front of it (the end of the trail).
// Its west end, by the border, runs further north: the camp (zone camp_ombre, beyond the west
// edge) is up on the rock, as high as it (UPLAND = its relief level 3), all along their join.
function ridgeAt(x, y) {
  const wr = fbm(x * 0.15 + 7, y * 0.15 + 70);
  if (x <= 5 && y >= 24 && y <= 62) return true;
  return y >= 32 && y <= 62 && (x <= 10 || (x <= 12 + wr * 2 && (y < 41 || y > 51)));
}
// The notch in the bay's back wall (its face looks south, at the camera): the cracked wall
// stands in it, the tunnel to the camp opens at its back (tools/zones/foret.gd).
const CAMP_NOTCH = { x0: 11, x1: 12, y0: 39, y1: 40 };
each((x, y) => {
  if (x >= CAMP_NOTCH.x0 && x <= CAMP_NOTCH.x1 && y >= CAMP_NOTCH.y0 && y <= CAMP_NOTCH.y1) height[y][x] = 0;
});
// The Masque's rock: a low shelf up on the Haute futaie, just north of its trail, its straight
// face towards the trail (south, y = 75: the camera looks north, at it). The footbridge hangs at
// its foot, the two giant trees stand on it behind; he stands on the lip between them, just
// behind the footbridge, as high as its deck (1.4 m over the plateau: out of reach).
// (tools/zones/foret.gd places them.)
function maskRockAt(x, y) {
  return y >= 72 && y <= 74 && inEllipse(x, y, 56.3, 74.8, 4.8, 3.2, 0.2);
}
// The ramps up to the plateau: 3 steps of 0.6 m (and the floor), 2 tiles wide.
for (let i = 0; i < 4; i++) for (const x of [80, 81]) height[67 - i][x] = PLATEAU - 0.6 * (i + 1);   // north
for (let i = 0; i < 4; i++) for (const y of [76, 77]) height[y][47 - i] = PLATEAU - 0.6 * (i + 1);   // west
for (let i = 0; i < 4; i++) for (const y of [84, 85]) height[y][108 + i] = PLATEAU - 0.6 * (i + 1);  // east
// The ravine of Griffe-Grise: a narrow cut in the upland's north face, down to a hollow that
// opens southwards to the border woods. (It all runs north-south: the camera looks north, a
// wall south of the way would hide Chloé.)
const RAVINE = [[31, 61], [30.5, 68], [29, 74], [26, 77]];
const nearPolyline = (x, y, pts, r) => {
  for (let i = 0; i < pts.length - 1; i++) {
    const [ax, ay] = pts[i], [bx, by] = pts[i + 1];
    const px = x + 0.5, py = y + 0.5, dx = bx - ax, dy = by - ay;
    const t = Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)));
    if (Math.hypot(px - ax - t * dx, py - ay - t * dy) <= r) return true;
  }
  return false;
};
each((x, y) => {
  if (inEllipse(x, y, 22, 80, 6.5, 5, 0.25) || inEllipse(x, y, 22, 88.5, 7.5, 8, 0.3) || nearPolyline(x, y, RAVINE, 1.6)) {
    height[y][x] = 0;
    clearing[y][x] = true;
  }
});
// 3. Water: the spring under the northern rocks, its stream down to the Mare aux libellules
//    and on to the Mare du cœur (neither touches the edge: it is not the sea); the Mare de lune.
each((x, y) => {
  if (inEllipse(x, y, 64, 9, 2.4, 1.8, 0.3) || inEllipse(x, y, 54, 44, 5.2, 3.2, 0.35)
    || inEllipse(x, y, 37.5, 61, 4.2, 2.6, 0.3) || inEllipse(x, y, 122, 37, 3.2, 2.2, 0.3)) sol[y][x] = "water";
  // The marshy pond by the west border, where the forest sinks into the Marais (not touching
  // the edge: it is not the sea); the bridge crosses it.
  if (x >= 1 && inEllipse(x, y, 2.6, 12.2, 3.0, 4.2, 0.3)) sol[y][x] = "water";
});
stroke([[64, 10], [61, 15], [62, 21], [58.5, 27], [59, 33], [56, 38.5], [55, 42]], 2, "water", 1.4);
stroke([[51, 46], [46.5, 51], [42, 56.5], [39.5, 59.5]], 2, "water", 1.2);

// 4. Trails (drawn over the water: footbridges there). Straight, even, where they meet the
//    Plaines and the ramps.
path([[130, 52], [123, 52]], 2, 0);                                                           // from the Plaines
path([[123, 52], [114, 53], [106, 55], [98, 53], [90, 56], [82, 55.5], [74, 57], [66, 56.5], [62, 56]]);  // the main trail
path([[62, 56], [64, 48], [66, 40], [65, 32], [63, 25.5]]);                                   // north, to the stream
path([[63, 25.5], [53, 25.5]], 2, 0);                                                         // over the stream
path([[53, 25.5], [46, 28], [38, 26], [30, 20]]);                                             // the Clairière, the Alpha's
path([[66, 40], [74, 36], [82, 31], [90, 28.5], [96, 24], [104, 19]]);                         // the rocky clearings
path([[90, 28.5], [97, 36], [103, 43], [105, 50], [106, 55]]);                                // back to the main trail
path([[62, 56], [55, 56.5], [48, 56]]);                                                       // west…
path([[48, 56], [38, 56]], 2, 0);                                                             // …over the stream
path([[38, 56], [30, 54.5], [22, 49], [15, 46.5]]);                                           // the cœur, the camp's face
path([[15, 46.5], [13, 44], [12, 41.5], [12, 39.5]], 2, 0);                                   // …into the notch (the wall)
path([[0, 12], [6, 12]], 2, 0);                                                               // the bridge to the Marais
path([[6, 12], [10, 13.5], [15, 16.5]], 2, 0.8);                                              // …from the Alpha's clearing
path([[82, 55.5], [81, 60], [81, 64]]);                                                        // south, to the plateau
path([[81, 64], [81, 69]], 2, 0);                                                             // the north ramp
path([[81, 69], [78, 74], [72, 78.5], [64, 79.5], [56, 77.5], [49, 77]]);                      // along the Haute futaie
path([[49, 77], [43, 77]], 2, 0);                                                             // the west ramp
path([[43, 77], [43.5, 70], [44.5, 64], [45, 57]]);                                           // the valley, up to the cœur
path([[72, 78.5], [80, 81], [90, 84], [100, 85]]);                                            // east on the plateau
path([[100, 85], [113, 85]], 2, 0);                                                           // the east ramp
path([[113, 85], [115, 78], [116, 70], [113, 62], [111, 55]]);                                // the brachiosaurs' meadow
path([[118, 53], [117, 47], [118.5, 43]]);                                                    // the Mare de lune
path([[36, 56.5], [32.5, 59], [31, 63.5]], 1, 0.8);                                           // the faint trail…
path([[31, 63.5], [30.5, 68], [29, 74], [26, 77], [23, 78.5]], 1, 0.4);                        // …down the ravine

// 5. Clearings: open ground around the places (no wall of trees there).
const CLEARINGS = [
  [46, 24, 9, 6], [24, 18, 9.5, 7], [119, 40, 6, 4.5], [62, 55, 4, 3], [68, 52.5, 3.2, 2.4],
  [15, 46, 5, 6], [36, 58, 8, 5.5], [70, 81, 7, 4.5], [116, 68, 7, 6], [96, 22, 5, 4], [90, 29, 4, 3],
  [118, 55, 5, 3.5], [100, 84, 4, 3],
  // The bridge's landing (Maïa waits there); before the Masque's footbridge, seen from the trail.
  [6.5, 12.5, 3.5, 3], [56.5, 75.5, 4.5, 1.2],
];
each((x, y) => {
  if (CLEARINGS.some(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, 0.4))) {
    clearing[y][x] = true;
    if (sol[y][x] === "forest" && Math.min(x, y, W - 1 - x, H - 1 - y) >= 2) sol[y][x] = "grass";
  }
});

// What the camera must see (the trails, the water, the clearings): it looks north from the
// south, 40° down, so trees standing less than SHADOW tiles south of them (or two tiles aside)
// would hide them. No wall of trees there (low undergrowth only: tools/zones/foret.gd); the
// way in stays open.
const SHADOW = 5;
const inView = (x, y) => inside(x, y) && (sol[y][x] === "path" || sol[y][x] === "water" || clearing[y][x]);
const shadow = grid(false);
each((x, y) => {
  for (let k = 1; k <= SHADOW && !shadow[y][x]; k++) for (let dx = -2; dx <= 2; dx++) if (inView(x + dx, y - k)) shadow[y][x] = true;
});
each((x, y) => {
  const edge = Math.min(x, y, W - 1 - x, H - 1 - y);
  // (And by the two ways out on the edges: from the Plaines, east; to the Marais, south of the bridge.)
  if (sol[y][x] === "forest" && ((shadow[y][x] && edge >= 2) || (x >= 119 && y >= 47 && y <= 57) || (x <= 3 && y >= 13 && y <= 18))) sol[y][x] = "grass";
});

// Distance (tiles, by steps) to the nearest tile of some kinds.
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
const isCliff = (x, y) => DIRS.some(([dx, dy]) => inside(x + dx, y + dy) && Math.abs(height[y + dy][x + dx] - height[y][x]) > 0.75);

// 6. Walls of trees: winding bands a few tiles thick (the contour lines of a noise), and a
//    few groves; sparser in the Lisière and under the Haute futaie. Never on a trail's edge,
//    by the water, in a clearing, on a ramp.
const nearPath = distanceTo((x, y) => sol[y][x] === "path");
const nearWater = distanceTo((x, y) => sol[y][x] === "water");
// (First, the rocky clearings of the north-east: outcrops of bare rock between little
// clearings, clear of the trails.)
const OUTCROPS = [[87, 15, 4, 2.6, 3.6], [99, 12, 4.5, 2.5, 2.4], [106, 25, 3.5, 3, 3.6], [94, 35, 2.6, 2, 2.4],
  [113, 17, 3, 4, 2.4], [84, 23, 2.5, 2.2, 2.4], [100, 27, 2.2, 1.8, 2.4], [117, 27, 2.6, 2, 2.4]];
each((x, y) => {
  if (nearPath[y][x] < 2 || nearWater[y][x] < 2 || sol[y][x] !== "grass") return;
  for (const [cx, cy, rx, ry, h] of OUTCROPS) {
    if (inEllipse(x, y, cx, cy, rx, ry, 0.5)) height[y][x] = Math.max(height[y][x], h);
  }
});
each((x, y) => {
  if (sol[y][x] !== "grass" || clearing[y][x] || shadow[y][x] || nearPath[y][x] < 2 || nearWater[y][x] < 2) return;
  if (height[y][x] > 0 && !(height[y][x] === PLATEAU && plateauAt(x, y))) return;   // (ramps, rock)
  const band = Math.abs(fbm(x * 0.075 + 31, y * 0.075 + 7) - 0.5);
  const band2 = Math.abs(fbm(x * 0.11 + 3, y * 0.11 + 57) - 0.5);
  const lisiere = smooth(104, 112, x);
  const futaie = height[y][x] === PLATEAU ? 1 : 0;
  const width = 0.036 * (1 - lisiere * 0.6) * (1 - futaie * 0.35);
  const grove = fbm(x * 0.13 + 71, y * 0.13 + 13) > 0.73 + lisiere * 0.04;
  if (band < width || band2 < width * 0.45 || grove) sol[y][x] = "forest";
});
// The uplands (south-west, the camp's ridge) are wooded, except the rim over the ravine and
// south of its hollow (the trees there would hide it from the camera, which looks north).
// (The camp's rock face stays bare, the camp's wall is to stand there: chapter 2, part 2.)
each((x, y) => {
  const upland = uplandAt(x, y) && height[y][x] >= PLATEAU, ridge = ridgeAt(x, y) && x < 7;
  if (!(upland || ridge) || sol[y][x] !== "grass" || clearing[y][x] || shadow[y][x]) return;
  const overRavine = (x >= 12 && x <= 32 && y >= 76) || (x >= 29 && x <= 34 && y >= 64);
  if (!overRavine && fbm(x * 0.2 + 5, y * 0.2 + 5) > 0.42) sol[y][x] = "forest";
});

// 7. Gentle hills on the forest floor and on the plateau, fading out by the trails, the water
//    and the cliffs (so a ledge always stays a ledge).
const nearCliff = distanceTo((x, y) => isCliff(x, y));
const nearFlat = distanceTo((x, y) => sol[y][x] === "path" || sol[y][x] === "water");
each((x, y) => {
  const base = height[y][x];
  if (base !== 0 && base !== PLATEAU) return;
  if (base === 0 && isRamp(x, y)) return;
  const amp = base === 0 ? 1.1 : 0.5;
  const hill = Math.max(0, fbm(x * 0.09 + 40, y * 0.09 + 11) - 0.45) * amp * smooth(1, 5, nearFlat[y][x]) * smooth(1, 4, nearCliff[y][x]);
  height[y][x] = base + Math.min(0.6, hill);
});
function isRamp(x, y) {
  return (y >= 63 && y <= 68 && x >= 79 && x <= 82) || (x >= 43 && x <= 48 && y >= 75 && y <= 78)
    || (x >= 107 && x <= 112 && y >= 83 && y <= 86);
}
// Water, and the trails down the ravine, stay at their level.
each((x, y) => { if (sol[y][x] === "water") height[y][x] = 0; });

// 8. Tall ferns and grass (encounters): the undergrowth by the trails, the meadows.
const PATCHES = [
  [72, 60, 5, 3], [88, 50, 5, 3], [100, 58, 4, 3], [58, 48, 3, 3], [70, 44, 4, 3], [76, 30, 4, 3], [52, 32, 4, 3],
  [40, 32, 4, 3], [16, 36, 3, 3], [40, 13, 4, 2], [26, 44, 4, 3], [30, 58, 3, 2], [44, 70, 3, 4],
  [60, 84, 5, 3], [84, 76, 5, 3], [96, 80, 4, 3], [88, 90, 5, 2], [66, 72, 4, 2],
  [112, 42, 4, 4], [124, 60, 3, 5], [118, 72, 5, 4], [110, 66, 3, 3], [114, 30, 4, 3], [124, 46, 3, 3],
  [94, 18, 3, 2], [104, 32, 3, 2], [84, 38, 3, 2],
];
each((x, y) => {
  if (sol[y][x] !== "grass" || isCliff(x, y) || nearCliff[y][x] < 2) return;
  if (inEllipse(x, y, 22, 80, 7, 6) || maskRockAt(x, y)) return;   // (the ravine stays calm; bare rock)
  if (PATCHES.some(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, 0.6))) sol[y][x] = "tall_grass";
  // Along the edge by the way in: the forest floor meets the Plaines' meadow there.
  if (x >= 127 && ((y >= 45 && y <= 49) || (y >= 54 && y <= 58))) sol[y][x] = "tall_grass";
});

// 9. Every open tile reachable: small pockets closed by the trees are filled with trees,
//    bigger ones opened through the thinnest wall. The uplands stay out of reach.
const walk = (x, y) => inside(x, y) && ["grass", "path", "tall_grass", "sand"].includes(sol[y][x]);
function reach(from) {
  const seen = grid(false), queue = [from];
  seen[from[1]][from[0]] = true;
  for (let i = 0; i < queue.length; i++) {
    const [x, y] = queue[i];
    for (const [dx, dy] of DIRS) {
      const xx = x + dx, yy = y + dy;
      if (!walk(xx, yy) || seen[yy][xx] || Math.abs(height[yy][xx] - height[y][x]) > 0.75) continue;
      seen[yy][xx] = true;
      queue.push([xx, yy]);
    }
  }
  return seen;
}
const ENTRY = [126, 52];
for (let pass = 0; pass < 40; pass++) {
  const seen = reach(ENTRY);
  // The first pocket (open ground, same level as the forest floor or the plateau) not reached.
  let pocket = null;
  each((x, y) => {
    if (pocket || seen[y][x] || !walk(x, y)) return;
    // (Only the forest floor and the plateau's top: the rock up there is out of reach.)
    const h = height[y][x], top = plateauAt(x, y) && h >= PLATEAU - 0.01 && h < PLATEAU + 0.7;
    if (!(h < 1.3 || top) || isRamp(x, y)) return;
    pocket = [x, y];
  });
  if (!pocket) break;
  // Its tiles; small: trees; else a way through the trees (same level) to reached ground.
  const tiles = [], mark = grid(false), queue = [pocket];
  mark[pocket[1]][pocket[0]] = true;
  for (let i = 0; i < queue.length; i++) {
    const [x, y] = queue[i];
    tiles.push([x, y]);
    for (const [dx, dy] of DIRS) {
      const xx = x + dx, yy = y + dy;
      if (!walk(xx, yy) || mark[yy][xx] || Math.abs(height[yy][xx] - height[y][x]) > 0.75) continue;
      mark[yy][xx] = true;
      queue.push([xx, yy]);
    }
  }
  if (tiles.length < 12) {
    for (const [x, y] of tiles) sol[y][x] = "forest";
    continue;
  }
  const prev = new Map(), q2 = tiles.map(([x, y]) => [x, y]);
  const key = (x, y) => y * W + x;
  for (const [x, y] of tiles) prev.set(key(x, y), null);
  let found = null;
  for (let i = 0; i < q2.length && !found; i++) {
    const [x, y] = q2[i];
    for (const [dx, dy] of DIRS) {
      const xx = x + dx, yy = y + dy;
      if (!inside(xx, yy) || prev.has(key(xx, yy)) || Math.abs(height[yy][xx] - height[y][x]) > 0.75) continue;
      if (Math.min(xx, yy, W - 1 - xx, H - 1 - yy) < 2) continue;
      if (seen[yy][xx]) { found = [x, y]; break; }
      if (sol[yy][xx] !== "forest") continue;
      prev.set(key(xx, yy), [x, y]);
      q2.push([xx, yy]);
    }
  }
  if (!found) { for (const [x, y] of tiles) sol[y][x] = "forest"; continue; }
  for (let c = found; c; c = prev.get(key(c[0], c[1]))) if (sol[c[1]][c[0]] === "forest") sol[c[1]][c[0]] = "grass";
}

// 10. Up on the ridge, where the camp (beyond the west edge) meets the forest: open rock and the
//     camp's trail going on a little (seen from the camp, past its way out: rows 37-40 face its
//     rows 12-15). Out of reach from the forest floor.
each((x, y) => {
  if (x <= 6 && y >= 35 && y <= 42) sol[y][x] = x <= 3 && y >= 37 && y <= 40 ? "path" : "grass";
});

// ---------------------------------------------------------------- checks
const seen = reach(ENTRY);
let forest = 0, open = 0, reached = 0;
each((x, y) => {
  if (sol[y][x] === "forest") forest++;
  if (walk(x, y)) { open++; if (seen[y][x]) reached++; }
});
console.log(`forêt : ${(100 * forest / (W * H)).toFixed(1)} % des cases ; sol ouvert atteint : ${reached}/${open}`);
for (const [name, [x, y]] of Object.entries(PLACES)) {
  console.log(`  ${seen[y][x] ? "ok " : "NON"} ${name} (${x}, ${y}) ${sol[y][x]} ${height[y][x].toFixed(2)} m`);
}
each((x, y) => {
  if (sol[y][x] !== "path") return;
  for (const [dx, dy] of [[1, 0], [0, 1]]) {
    const xx = x + dx, yy = y + dy;
    if (inside(xx, yy) && sol[yy][xx] === "path" && Math.abs(height[yy][xx] - height[y][x]) > 0.75) console.log(`  FALAISE sur le sentier : (${x}, ${y}) -> (${xx}, ${yy})`);
  }
});
// The footbridges: path laid over water, as rectangles (tools/zones/foret.gd, Dock).
const done = grid(false);
each((x, y) => {
  if (!bridge[y][x] || done[y][x]) return;
  let x0 = x, y0 = y, x1 = x, y1 = y;
  const queue = [[x, y]];
  done[y][x] = true;
  for (let i = 0; i < queue.length; i++) {
    const [cx, cy] = queue[i];
    x0 = Math.min(x0, cx); y0 = Math.min(y0, cy); x1 = Math.max(x1, cx); y1 = Math.max(y1, cy);
    for (const [dx, dy] of DIRS) {
      const xx = cx + dx, yy = cy + dy;
      if (inside(xx, yy) && bridge[yy][xx] && !done[yy][xx]) { done[yy][xx] = true; queue.push([xx, yy]); }
    }
  }
  console.log(`  passerelle : Rect2(${x0}, ${y0}, ${x1 - x0 + 1}, ${y1 - y0 + 1})`);
});

// ---------------------------------------------------------------- write
const solBuf = Buffer.alloc(W * H * 3), hBuf = Buffer.alloc(W * H);
each((x, y) => {
  solBuf.set(SOLS[sol[y][x]], (y * W + x) * 3);
  hBuf[y * W + x] = Math.max(0, Math.min(255, Math.round(height[y][x] / 0.05)));
});
await sharp(solBuf, { raw: { width: W, height: H, channels: 3 } }).png().toFile(`${OUT}/foret_sols.png`);
await sharp(hBuf, { raw: { width: W, height: H, channels: 1 } }).png().toFile(`${OUT}/foret_relief.png`);
console.log(`${OUT}/foret_sols.png, ${OUT}/foret_relief.png (${W} x ${H})`);
