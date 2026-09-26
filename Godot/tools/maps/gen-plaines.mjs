// Draws the two map images of the Plaines des Fougères (1 pixel = 1 tile, 120 x 90):
//   plaines_sols.png   — the ground, by colour (see SOLS below; any other colour = grass)
//   plaines_relief.png — the height, in grey levels (1 level = 5 cm; black = 0 m)
// They are the source of the region: retouch them in any paint program (keep the exact
// colours of SOLS, and 1 pixel = 1 tile), then rebuild the region:
//   godot --headless --path Godot --script res://tools/build_zone.gd -- plaines --force
// Running this script again overwrites them (from the layout below).
// Usage (from the repository root): node Godot/tools/maps/gen-plaines.mjs
import sharp from "sharp";

export const SOLS = {
  grass: [90, 158, 58], path: [200, 160, 96], tall_grass: [47, 107, 31],
  water: [46, 111, 181], forest: [31, 64, 32], sand: [232, 212, 154],
};
const W = 120, H = 90;
const OUT = "Godot/tools/maps";

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
const sol = Array.from({ length: H }, () => Array(W).fill("grass"));
const height = Array.from({ length: H }, () => Array(W).fill(0));
const set = (x, y, v) => { if (x >= 0 && y >= 0 && x < W && y < H) sol[y][x] = v; };
const inEllipse = (x, y, cx, cy, rx, ry, wobble = 0) =>
  ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 < 1 + wobble * (fbm(x * 0.35, y * 0.35) - 0.5);
const each = (f) => { for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) f(x, y); };

// Paths: polylines, 2 tiles wide, slightly wavy.
function path(points, width = 2) {
  for (let i = 0; i < points.length - 1; i++) {
    const [x0, y0] = points[i], [x1, y1] = points[i + 1];
    const n = Math.ceil(Math.hypot(x1 - x0, y1 - y0) * 3);
    for (let k = 0; k <= n; k++) {
      const t = k / n;
      const wob = (noise((x0 + x1) * 0.1 + t * 4, (y0 + y1) * 0.1) - 0.5) * 1.2;
      const px = x0 + (x1 - x0) * t + (y1 !== y0 ? wob : 0), py = y0 + (y1 - y0) * t + (x1 !== x0 ? wob : 0);
      for (let dy = 0; dy < width; dy++) for (let dx = 0; dx < width; dx++) set(Math.floor(px - width / 2 + dx + 0.5), Math.floor(py - width / 2 + dy + 0.5), "path");
    }
  }
}

// 1. Borders: mountains north and east, forest west and south (the road and the cove open).
//    The mountains rise in ledges of 2 levels (a smooth slope would show as a blurred bank).
const LEDGE = 2.4;
each((x, y) => {
  const n = fbm(x * 0.12, y * 0.12);
  const north = smooth(13 + n * 4, 4, y);
  const east = smooth(106 + n * 4, 117, x);
  const mountain = Math.max(north, east);
  const rise = mountain * (8 + fbm(x * 0.07, y * 0.07) * 5);
  if (mountain > 0) height[y][x] = Math.max(height[y][x], Math.floor(rise / LEDGE) * LEDGE);
  const west = x < 4 + n * 4, south = y > 84 - n * 3;
  if (west || (south && !(x >= 55 && x <= 64))) sol[y][x] = "forest";
});

// 2. Paths (drawn first: the woods below close in on them except at their openings).
path([[60, 90], [60, 70], [59, 58], [60, 46]]);                     // from the port up to the crossroads
path([[60, 46], [58, 36], [58, 26]]);                               // to the Grotte des Échos
path([[60, 46], [44, 48], [30, 48], [20, 45], [20, 36]]);           // to Hélène's grove (the trunk)
path([[60, 46], [72, 42], [86, 42], [93, 39], [93, 30], [96, 26]]); // to the cliffs (the amber door)
path([[86, 42], [94, 54], [96, 64], [104, 65]]);                    // to the Grand Crâne
path([[96, 26], [96, 20], [92, 16], [95, 11]]);                     // up the terraces
path([[20, 36], [16, 30]], 1);                                      // into the grove

// 3. The cove (south-west): the sea comes in, with a sandy beach around it.
each((x, y) => {
  if (inEllipse(x, y, 16, 84, 22, 17, 0.5) || inEllipse(x, y, 30, 90, 10, 12, 0.4)) sol[y][x] = "water";
});
each((x, y) => {
  if (sol[y][x] === "water") return;
  for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) {
    const yy = y + dy, xx = x + dx;
    if (yy >= 0 && xx >= 0 && yy < H && xx < W && sol[yy][xx] === "water" && Math.hypot(dx, dy) <= 2.3) sol[y][x] = "sand";
  }
});

// 4. The pond, east of the crossroads, south of the path; an islet in its middle (Hélène's
//    page 2), reached at full moon by an amber ford from the north shore (tiles 78-79, 45-46).
each((x, y) => { if (inEllipse(x, y, 79, 48, 5.5, 3.2, 0.3)) sol[y][x] = "water"; });
each((x, y) => { if (x >= 78 && x <= 79 && y >= 47 && y <= 48) sol[y][x] = "grass"; });
for (const y of [45, 46]) for (const x of [78, 79]) sol[y][x] = "water";

// 5. Woods: Hélène's grove enclosed by forest (a 2-tile opening on its south side, where the
//    trunk lies), and a few groves in the meadows.
each((x, y) => {
  const ring = inEllipse(x, y, 18, 31, 12, 12) && !inEllipse(x, y, 18, 31, 8.5, 8.5);
  if (ring && !(x >= 19 && x <= 20 && y > 36)) sol[y][x] = "forest";
  if (inEllipse(x, y, 40, 30, 6, 4, 0.5) || inEllipse(x, y, 86, 72, 6, 5, 0.5) || inEllipse(x, y, 33, 58, 5, 4, 0.5)
    || inEllipse(x, y, 74, 64, 4, 3, 0.5)) sol[y][x] = "forest";
});

// 6. Gentle hills in the meadows, fading out near paths, water and beaches.
const near = Array.from({ length: H }, () => Array(W).fill(99));
const queue = [];
each((x, y) => { if (["path", "water", "sand"].includes(sol[y][x])) { near[y][x] = 0; queue.push([x, y]); } });
for (let i = 0; i < queue.length; i++) {
  const [x, y] = queue[i];
  for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
    const xx = x + dx, yy = y + dy;
    if (xx >= 0 && yy >= 0 && xx < W && yy < H && near[yy][xx] > near[y][x] + 1) { near[yy][xx] = near[y][x] + 1; queue.push([xx, yy]); }
  }
}
each((x, y) => {
  const hill = Math.max(0, fbm(x * 0.09 + 40, y * 0.09 + 11) - 0.45) * 3.2 * smooth(1, 5, near[y][x]);
  height[y][x] = Math.max(height[y][x], hill);
});

// 7. Landmarks.
// The Grotte hill (north), a notch for the cave in its south face, a ramp up on its east side.
each((x, y) => {
  if (inEllipse(x, y, 58, 17, 13, 8)) height[y][x] = 3.6;
  if (x >= 57 && x <= 58 && y >= 23 && y <= 24) height[y][x] = 0;
});
for (let i = 0; i < 6; i++) for (let y = 15; y <= 17; y++) height[y][71 - i] = Math.min(3.6, 0.6 * (i + 1));
// The cliffs (north-east): a ridge closing the basin, a 2-tile gorge (the amber door), two terraces.
each((x, y) => {
  if (x >= 78 && x <= 80 && y >= 8 && y <= 37) height[y][x] = 3.6;
  if (y >= 36 && y <= 37 && x >= 78 && x <= 111 && !(x >= 92 && x <= 93)) height[y][x] = 3.6;
  if (y >= 36 && y <= 37 && x >= 92 && x <= 93) height[y][x] = 0;
  if (x >= 84 && x <= 108 && y >= 8 && y <= 20) height[y][x] = Math.max(height[y][x], 2.4);
  if (x >= 88 && x <= 104 && y >= 8 && y <= 13) height[y][x] = Math.max(height[y][x], 4.8);
});
for (let i = 0; i < 4; i++) for (const x of [96, 97]) height[21 + i][x] = 2.4 - 0.6 * (i + 1);
for (let i = 0; i < 4; i++) for (const x of [90, 91]) height[14 + i][x] = 4.8 - 0.6 * (i + 1);
// The Grand Crâne (south-east): a rock mound, a 4-tile notch closed by the amber door.
each((x, y) => {
  if (inEllipse(x, y, 104, 57, 8, 5)) height[y][x] = 3.6;
  if (x >= 102 && x <= 105 && y >= 58 && y <= 61) height[y][x] = 0;
});
// Water and beaches stay at sea level (the water sheet is at a fixed height).
each((x, y) => { if (["water", "sand"].includes(sol[y][x])) height[y][x] = 0; });

// 8. Tall grass patches (encounters), on plain, fairly flat grass.
const patches = [[46, 70, 7, 4], [70, 76, 6, 4], [38, 40, 6, 4], [70, 55, 5, 3], [22, 64, 5, 3], [100, 30, 6, 3],
  [86, 28, 4, 3], [98, 76, 7, 4], [110, 72, 3, 5], [50, 56, 4, 3], [16, 28, 3, 3]];
each((x, y) => {
  if (sol[y][x] !== "grass" || height[y][x] > 1.2) return;
  if (patches.some(([cx, cy, rx, ry]) => inEllipse(x, y, cx, cy, rx, ry, 0.6))) sol[y][x] = "tall_grass";
});

// ---------------------------------------------------------------- write
const solBuf = Buffer.alloc(W * H * 3), hBuf = Buffer.alloc(W * H);
each((x, y) => {
  const c = SOLS[sol[y][x]];
  solBuf.set(c, (y * W + x) * 3);
  hBuf[y * W + x] = Math.max(0, Math.min(255, Math.round(height[y][x] / 0.05)));
});
await sharp(solBuf, { raw: { width: W, height: H, channels: 3 } }).png().toFile(`${OUT}/plaines_sols.png`);
await sharp(hBuf, { raw: { width: W, height: H, channels: 1 } }).png().toFile(`${OUT}/plaines_relief.png`);
console.log(`${OUT}/plaines_sols.png, ${OUT}/plaines_relief.png (${W} x ${H})`);
