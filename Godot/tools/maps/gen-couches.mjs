// Draws the layers that soften the joins between neighbouring regions (29/09): for each zone
// and each neighbour whose ground differs, <zone>_couche_<neighbour>.png (1 pixel = 1 tile, grey:
// black none, white all covered): how much of the neighbour's ground lies over this zone's
// (Region.cover_*, tools/zones/borders.gd). About half of it at the edge, less and less inwards
// over BAND tiles, its front wandering, in patches; only along the part of the edge the
// neighbour is shown beyond. The neighbour does the same with this zone's ground, so the two
// meet half and half at the edge (a dose of 0.5 there).
// The maps are only read here (tools/maps/<zone>_sols.png, for their size); run it again after
// changing a layer below, then rebuild the zone:
//   node Godot/tools/maps/gen-couches.mjs
//   godot --headless --path Godot --script res://tools/build_zone.gd -- <zone> --force
// (The Côte ↔ Monts join has its own layer, the snow: gen-monts.mjs.)
import sharp from "sharp";

const OUT = "Godot/tools/maps";
/** Below this dose the ground shader lays nothing of a layer (ground.gdshader, cover_amount). */
const LOW = 0.28;
/** zone, neighbour, the zone's edge they share, the dose at the edge (0-1), how deep the band
 *  goes (tiles), the part of the edge the neighbour lies beyond ([first, last] tile along it). */
const LAYERS = [
  // Plaines (west) ↔ Forêt (east): same rows (the exits, rows 50-54, face each other).
  { zone: "plaines", neighbour: "foret", edge: "west", seam: 0.5, band: 16, span: [0, 89] },
  { zone: "foret", neighbour: "plaines", edge: "east", seam: 0.5, band: 16, span: [0, 89] },
  // Forêt (west) ↔ Marais (east): Marais row = Forêt row + 58.
  { zone: "foret", neighbour: "marais", edge: "west", seam: 0.5, band: 14, span: [0, 37] },
  { zone: "marais", neighbour: "foret", edge: "east", seam: 0.5, band: 14, span: [58, 95] },
  // Marais (north) ↔ Désert (south): Désert x = Marais x + 16. « Le Marais s'arrête d'un coup » :
  // a shorter band, but no ruler-straight cut.
  { zone: "marais", neighbour: "desert", edge: "north", seam: 0.5, band: 9, span: [0, 103] },
  { zone: "desert", neighbour: "marais", edge: "south", seam: 0.5, band: 10, span: [16, 119] },
];

// ---------------------------------------------------------------- noise (as the map generators)
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

/** The dose of a layer on tile (x, y) of a W x H zone. */
function dose(layer, x, y, W, H, salt) {
  const { edge, seam, band, span } = layer;
  const d = { west: x + 0.5, east: W - x - 0.5, north: y + 0.5, south: H - y - 0.5 }[edge];   // from the edge
  const a = edge === "west" || edge === "east" ? y : x;                                        // along it
  if (d > band * 1.6) return 0;
  const front = (fbm(a * 0.09 + salt, 1.3) - 0.5) * band * 0.5;
  // The ground shader lays a layer in patches from a dose of about LOW (none) to 1 - LOW (all),
  // half of it at 0.5: from `seam` at the edge down to LOW at the band's end, then nothing.
  const t = (d + front) / band;
  const core = seam + (LOW - seam) * Math.min(1, Math.max(0, t)) + (fbm(x * 0.25 + salt, y * 0.25 + salt * 0.7) - 0.5) * 0.25;
  const along = smooth(span[0] - 1, span[0] + 5, a) * smooth(span[1] + 1, span[1] - 5, a);
  return Math.max(0, core) * smooth(1.35, 1.0, t) * along;
}

for (const [i, layer] of LAYERS.entries()) {
  const meta = await sharp(`${OUT}/${layer.zone}_sols.png`).metadata();
  const W = meta.width, H = meta.height, buf = Buffer.alloc(W * H);
  let covered = 0, most = 0;
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const v = dose(layer, x, y, W, H, 31 + i * 17);
    buf[y * W + x] = Math.round(v * 255);
    if (v > 0.05) covered++;
    most = Math.max(most, v);
  }
  const file = `${OUT}/${layer.zone}_couche_${layer.neighbour}.png`;
  await sharp(buf, { raw: { width: W, height: H, channels: 1 } }).png().toFile(file);
  console.log(`${file} (${W} x ${H}) : bord ${layer.edge}, au plus ${most.toFixed(2)}, ${covered} cases touchées`);
}
