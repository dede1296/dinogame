// Draws the two map images of the Marais Brumeux (1 pixel = 1 tile, 120 x 96):
//   marais_sols.png   — the ground, by colour (see SOLS below; any other colour = grass)
//   marais_relief.png — the height, in grey levels (1 level = 5 cm; black = 0 m)
// They are the source of the region: retouch them in any paint program (keep the exact
// colours of SOLS, and 1 pixel = 1 tile), then rebuild the region:
//   godot --headless --path Godot --script res://tools/build_zone.gd -- marais --force
// Running this script again overwrites them (from the layout below), and prints the checks:
// the places reachable on foot from the way in (before Joss's swimming vest) or only swimming
// (after it), the Voix's rock reached only through its amber door, the boardwalks.
// Usage (from the repository root): node Godot/tools/maps/gen-marais.mjs
//
// A marsh: little firm ground, mud ("mud", the vase: walkable), reed beds (tall grass:
// encounters), deep water (the Nage), boardwalks on posts (path cells: tools/zones/marais.gd
// lays a Dock over each straight run of them, so the water runs on under the planks).
// Layout (tiles; the places are the ones tools/zones/marais.gd fills):
//   east (on foot, before the vest): the boardwalk from the Forêt's bridge (x 119, y 69-70)
//        to the Débarcadère (Joss's hut on stilts, a campfire); north over a channel to the
//        Roselière de l'est (the Baryonyx with the vest on its sand bank, 84, 41; a campfire);
//        on north along the long boardwalk (Roc's night walk) to the Roselière du nord, Maïa
//        and the way to the Désert (x 84-87, y 0); south to the Bassin des nénuphars (page 16,
//        full moon, at the end of its pier, 96, 85).
//   the Grand chenal all around it (never less than 3 tiles of deep water): the Nage opens
//        the rest, a mud marsh cut by channels —
//   centre-west: the Îlot de la Voix (56, 41) in the heart of the reed beds: its rock (1.8 m)
//        is reached by one notch in its south face, where the amber door stands (56, 42);
//   west: the Îlot aux racines (26, 36): Dame Suie, page 13, her boat at her pier;
//   north-west: the Île du temple (30, 12): a rock, the temple's door at its foot (30, 11),
//        a paved square before it, statues and columns;
//   south-west: the Forêt noyée (drowned trees, pools, a boardwalk to page 14, 26, 74);
//   the chenaux: page 15 on a sand bar (70, 72).
import sharp from "sharp";

export const SOLS = {
  grass: [90, 158, 58], path: [200, 160, 96], tall_grass: [47, 107, 31],
  water: [46, 111, 181], forest: [31, 64, 32], sand: [232, 212, 154], mud: [107, 90, 54],
};
const W = 120, H = 96;
const OUT = "Godot/tools/maps";
/** Places to check: [x, y, how] — "pied": on foot from the way in (before the vest);
 *  "nage": only swimming (not on foot); "voix": on the Voix's rock (only through its door). */
const PLACES = {
  "arrivée (ponton est)": [117, 69, "pied"], "Débarcadère": [104, 70, "pied"], "Joss (cabane)": [101, 66, "pied"],
  "feu du Débarcadère": [95, 71, "pied"], "Baryonyx au gilet (banc de sable)": [84, 41, "pied"],
  "feu de la roselière est": [100, 38, "pied"], "Roc (grand ponton)": [99, 20, "pied"],
  "Maïa (roselière du nord)": [86, 6, "pied"], "sortie nord (Désert)": [86, 1, "pied"],
  "feu de la roselière nord": [78, 8, "pied"], "page 16 (ponton des nénuphars)": [95, 85, "pied"],
  "banc des nénuphars": [101, 81, "pied"],
  "porte de la Voix (plage)": [56, 43, "nage"], "Dame Suie (îlot aux racines)": [26, 35, "nage"],
  "page 13 (îlot aux racines)": [29, 34, "nage"], "feu de l'îlot aux racines": [21, 38, "nage"],
  "page 14 (forêt noyée)": [26, 74, "nage"], "feu de la forêt noyée": [36, 79, "nage"],
  "page 15 (banc de sable des chenaux)": [70, 72, "nage"], "porte du temple (parvis)": [30, 12, "nage"],
  "la Voix (sur son rocher)": [56, 37, "voix"],
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

// ---------------------------------------------------------------- layers
const grid = (v) => Array.from({ length: H }, () => Array(W).fill(v));
const sol = grid("water");
const height = grid(0);
const east = grid(false);     // the part walked before the vest (the Débarcadère, the roselières)
const inside = (x, y) => x >= 0 && y >= 0 && x < W && y < H;
const inEllipse = (x, y, cx, cy, rx, ry, wobble = 0) =>
  ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 < 1 + wobble * (fbm(x * 0.35, y * 0.35) - 0.5);
const each = (f) => { for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) f(x, y); };
const DIRS = [[1, 0], [-1, 0], [0, 1], [0, -1]];
const inRect = (x, y, [rx, ry, rw, rh]) => x >= rx && y >= ry && x < rx + rw && y < ry + rh;

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
        if (inside(tx, ty)) sol[ty][tx] = value;
      }
    }
  }
}
const blob = (list, value, wobble = 0.35, only = null) => each((x, y) => {
  if (only && !only(x, y)) return;
  if (list.some(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, wobble))) sol[y][x] = value;
});

// 1. The west: a mud marsh (cut by channels below), its east shore wandering around x 64.
each((x, y) => { if (x < 64 + (fbm(y * 0.06 + 1, 3.3) - 0.5) * 18 + (fbm(x * 0.2, y * 0.2) - 0.5) * 4) sol[y][x] = "mud"; });

// 2. The east, walked before the vest: the Débarcadère, the south land round the Bassin des
//    nénuphars, the Roselière de l'est, the Roselière du nord and its track north.
const EAST_LAND = [
  [100, 70, 9, 6.5],                                   // the Débarcadère
  [99, 83, 12, 6.5],                                   // round the Bassin des nénuphars
  [93, 44, 14, 11], [102, 33, 8, 7], [84, 52, 6, 4], [108, 45, 6, 8],   // the Roselière de l'est
  [82, 10, 15, 6.5], [70, 13, 7, 5],                   // the Roselière du nord
];
each((x, y) => {
  if (EAST_LAND.some(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, 0.3)) || inRect(x, y, [82, 0, 8, 6])) {
    sol[y][x] = "mud";
    east[y][x] = true;
  }
});
// A ditch between the Débarcadère and the land of the lily pond (a boardwalk crosses it).
each((x, y) => { if (east[y][x] && y >= 76 && y <= 77 && x >= 86 && x <= 112) { sol[y][x] = "water"; east[y][x] = false; } });

// 3. Islands out in the Grand chenal (reached swimming), the sand bar of page 15.
blob([[62, 62, 5, 3.5], [74, 86, 5, 3], [70, 28, 4, 3], [73, 44, 4, 5.5], [66, 80, 5, 3.5], [78, 62, 3, 2.5]], "mud");
blob([[70, 72, 2.2, 1.4]], "sand", 0.1);

// 4. The islands of the west, each in its ring of deep water: the Voix's, the roots', the temple's.
const VOIX = [56, 41, 8, 7.5], RACINES = [26, 36, 8, 6], TEMPLE = [30, 12, 10.5, 7];
const RINGS = [[56, 41, 11.5, 10.5], [26, 36, 11, 8.5], [30, 12, 14, 10]];
each((x, y) => {
  for (let i = 0; i < 3; i++) {
    const [cx, cy, rx, ry] = RINGS[i], isle = [VOIX, RACINES, TEMPLE][i];
    if (inEllipse(x, y, cx, cy, rx, ry, 0.25)) sol[y][x] = inEllipse(x, y, ...isle, 0.2) ? "mud" : "water";
  }
});

// 5. Channels through the west marsh (to swim along), creeks and pools in the Forêt noyée.
stroke([[66, 56], [54, 55], [44, 51], [34, 48], [22, 49], [10, 51], [2, 52]], 3, "water", 2.0);
stroke([[62, 22], [50, 22], [43, 20]], 3, "water", 1.6);
stroke([[40, 24], [40, 30], [37, 35]], 3, "water", 1.4);
stroke([[46, 58], [47, 68], [52, 78], [58, 86], [66, 91]], 3, "water", 2.0);
stroke([[36, 58], [30, 62], [20, 61], [11, 66]], 2, "water", 1.6);
stroke([[8, 30], [12, 21], [9, 8]], 3, "water", 1.6);
blob([[18, 70, 3, 2], [32, 83, 3.5, 2.2], [12, 80, 3, 2.5], [38, 69, 2.5, 2], [21, 88, 3, 1.8], [44, 77, 2.5, 2],
  [47, 9, 4, 3], [12, 40, 3, 4], [50, 88, 3, 2]], "water", 0.4, (x, y) => !east[y][x]);
// Pools in the Roselière de l'est (small: the way round them stays open).
blob([[95, 40, 2.5, 1.6], [101, 46, 2, 1.4], [88, 49, 1.8, 1.3]], "water", 0.2);

// 6. Firm ground (grass), reed beds (tall grass: encounters), sand banks.
blob([[100, 70, 6.5, 4.5], [91, 84, 4, 3], [107, 85, 4, 3], [100, 38, 4, 3], [90, 45, 3, 2], [84, 7, 4.5, 2.5],
  [78, 8.5, 3, 2], [26, 35, 5, 3.5], [26, 74, 3.5, 2.5], [36, 79, 3, 2.2], [62, 62, 3, 2], [14, 58, 4, 3],
  [48, 26, 3, 2.2]], "grass", 0.3, (x, y) => sol[y][x] === "mud");
blob([[86, 36, 5, 3.5], [97, 50, 5, 3], [104, 30, 4, 3], [80, 50, 3.5, 2.5], [92, 32, 3, 2.5],
  [74, 12, 5, 3], [91, 11, 4, 2.2], [67, 14, 3, 2.5], [90, 80, 2.5, 2], [104, 90, 4, 1.6], [106, 64, 2.5, 1.5]],
  "tall_grass", 0.5, (x, y) => east[y][x] && sol[y][x] !== "water");
blob([[44, 32, 4, 3], [66, 34, 4, 2.5], [44, 50, 3.5, 2.5], [48, 62, 4, 3], [20, 26, 4, 2.5], [8, 44, 3, 4],
  [36, 90, 5, 2], [14, 72, 3, 3], [40, 64, 3, 2.5], [52, 14, 4, 2.5], [10, 16, 3, 3], [62, 64, 2.5, 1.5]],
  "tall_grass", 0.5, (x, y) => sol[y][x] === "mud");
blob([[84, 41, 3.5, 2.2]], "sand", 0.2, (x, y) => east[y][x]);
blob([[56, 45.5, 5, 2.5]], "sand", 0.2, (x, y) => sol[y][x] === "mud");           // the Voix's beach
each((x, y) => { if (x >= 83 && x <= 89 && y <= 3 + (hash(x, 7) > 0.5 ? 1 : 0)) sol[y][x] = "sand"; });   // dry track north

// 7. The Grand chenal: never less than 3 tiles of deep water between the east and the rest
//    (so the east is all one walks before the vest, and the rest is all swimming).
{
  const d = grid(99), q = [];
  each((x, y) => { if (east[y][x] && sol[y][x] !== "water") { d[y][x] = 0; q.push([x, y]); } });
  for (let i = 0; i < q.length; i++) {
    const [x, y] = q[i];
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
      const xx = x + dx, yy = y + dy;
      if (inside(xx, yy) && d[yy][xx] > d[y][x] + 1 && d[y][x] < 4) { d[yy][xx] = d[y][x] + 1; q.push([xx, yy]); }
    }
  }
  each((x, y) => { if (!east[y][x] && d[y][x] <= 3 && sol[y][x] !== "water") sol[y][x] = "water"; });
}

// 8. The woods closing the marsh all round (a mangrove thicket), open where the ways out are:
//    the Forêt's bridge (east, rows 69-70) over a pond at the edge, the track north (x 83-89).
each((x, y) => {
  const n = fbm(x * 0.12, y * 0.12);
  const edge = Math.min(x, y, W - 1 - x, H - 1 - y);
  const eastWay = x >= 108 && y >= 61 && y <= 79, northWay = x >= 82 && x <= 90 && y <= 6;
  if (eastWay) {
    // The pond reaches the last columns, which are its bank (as on the Forêt's side, where
    // the bridge lands at x 0): no water cut off by the edge of the map.
    if (x >= W - 3) sol[y][x] = y >= 66 ? "mud" : "forest";   // (open on the camera's side)
    else if (edge < 6 || x >= 110) sol[y][x] = "water";
    return;
  }
  if (northWay) return;
  const south = y > H - 8;
  if (edge < (south ? 1.5 + n * 1.5 : 2.5 + n * 2.5)) sol[y][x] = "forest";
});

// 9. The boardwalks (path: a Dock over each straight run, tools/zones/marais.gd), 2 tiles wide.
const BOARDWALKS = [
  [106, 69, 14, 2],   // from the Forêt's bridge to the Débarcadère
  [97, 53, 2, 12],    // the Débarcadère -> the Roselière de l'est, over the channel
  [98, 75, 2, 4],     // over the ditch, to the Bassin des nénuphars
  [95, 81, 2, 5],     // the pier into the lily pond (page 16 at its end)
  [99, 12, 2, 16],    // the long boardwalk north (Roc's night walk)
  [93, 12, 6, 2],     // …its last stretch west, to the Roselière du nord
  [29, 18, 2, 4],     // the temple's landing (swimming)
  [24, 41, 2, 3],     // Dame Suie's pier
  [30, 73, 10, 2],    // the planks through the Forêt noyée, to page 14
];
// The lily pond, dug after the boardwalks' land (the pier juts into it).
blob([[97, 85, 5, 2.8]], "water", 0.15);
for (const r of BOARDWALKS) each((x, y) => { if (inRect(x, y, r)) sol[y][x] = "path"; });
// The paved square before the temple's door (path too: paved with the temple's slabs there).
const PLAZA = [25, 11, 11, 6];
each((x, y) => { if (inRect(x, y, PLAZA) && (sol[y][x] === "mud" || sol[y][x] === "grass")) sol[y][x] = "path"; });

// 10. Relief. The temple's rock (2.4 m) behind its door; the Voix's rock (1.8 m), its notch in
//     the south face (a ramp of three steps, the amber door at its foot); low hummocks on the
//     firm ground; the rest flat (a marsh), the water dug in by the game.
const ROCK = 2.4, VOIX_ROCK = 1.8;
const templeRock = (x, y) => inEllipse(x, y, 30, 7.5, 8.5, 3.6, 0.15) && y <= 10;
const notch = (x, y) => x >= 55 && x <= 56 && y >= 39 && y <= 41;
const voixRock = (x, y) => (inEllipse(x, y, 56, 38.5, 4.8, 3.8) || (x >= 54 && x <= 57 && y >= 39 && y <= 41)) && !notch(x, y);
each((x, y) => {
  if (templeRock(x, y)) { height[y][x] = ROCK; sol[y][x] = "grass"; }
  if (voixRock(x, y)) { height[y][x] = VOIX_ROCK; sol[y][x] = "grass"; }
  if (notch(x, y)) { height[y][x] = VOIX_ROCK * (42 - y) / 4; sol[y][x] = "grass"; }
  if (!voixRock(x, y) && !notch(x, y) && !templeRock(x, y)) {
    if (sol[y][x] === "grass") height[y][x] = 0.1 + Math.max(0, fbm(x * 0.2 + 9, y * 0.2 + 4) - 0.4) * 0.5;
    else if (sol[y][x] === "sand" || sol[y][x] === "tall_grass") height[y][x] = 0.04;
  }
});

// ---------------------------------------------------------------- checks
const WALK = ["grass", "path", "tall_grass", "sand", "mud"];
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
const ENTRY = [117, 69];
const foot = reach(ENTRY, false), swim = reach(ENTRY, true);
// The Voix's rock with its door shut (the notch's mouth blocked): out of reach.
const shut = reach(ENTRY, true, (x, y) => notch(x, y) && y === 41);
let water = 0, open = 0, onFoot = 0, bySwim = 0, forest = 0;
each((x, y) => {
  if (sol[y][x] === "water") water++;
  if (sol[y][x] === "forest") forest++;
  if (WALK.includes(sol[y][x])) { open++; if (foot[y][x]) onFoot++; if (swim[y][x]) bySwim++; }
});
console.log(`eau : ${(100 * water / (W * H)).toFixed(1)} %, bois : ${(100 * forest / (W * H)).toFixed(1)} % ; sol ouvert ${open} cases : ${onFoot} à pied, ${bySwim} en nageant`);
let failures = 0;
for (const [name, [x, y, how]] of Object.entries(PLACES)) {
  let ok;
  if (how === "pied") ok = foot[y][x];
  else if (how === "nage") ok = swim[y][x] && !foot[y][x];
  else ok = swim[y][x] && !foot[y][x] && !shut[y][x];
  if (!ok) failures++;
  console.log(`  ${ok ? "ok " : "NON"} ${name} (${x}, ${y}) ${how} : ${sol[y][x]} ${height[y][x].toFixed(2)} m, à pied ${foot[y][x] ? "oui" : "non"}, à la nage ${swim[y][x] ? "oui" : "non"}`);
}
// Open ground nobody reaches, even swimming (walled in): listed, it should be none.
let lost = 0;
each((x, y) => { if (WALK.includes(sol[y][x]) && !swim[y][x] && height[y][x] < 1.0) lost++; });
console.log(`  sol ouvert injoignable (hors rochers) : ${lost} cases`);
console.log(failures ? `${failures} LIEU(X) EN DÉFAUT` : "tous les lieux sont bons");

// ---------------------------------------------------------------- write
const solBuf = Buffer.alloc(W * H * 3), hBuf = Buffer.alloc(W * H);
each((x, y) => {
  solBuf.set(SOLS[sol[y][x]], (y * W + x) * 3);
  hBuf[y * W + x] = Math.max(0, Math.min(255, Math.round(height[y][x] / 0.05)));
});
await sharp(solBuf, { raw: { width: W, height: H, channels: 3 } }).png().toFile(`${OUT}/marais_sols.png`);
await sharp(hBuf, { raw: { width: W, height: H, channels: 1 } }).png().toFile(`${OUT}/marais_relief.png`);
console.log(`${OUT}/marais_sols.png, ${OUT}/marais_relief.png (${W} x ${H})`);
