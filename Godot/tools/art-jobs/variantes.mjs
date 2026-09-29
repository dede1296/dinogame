// Character variants (docs/direction-artistique.md, « Variantes de personnages »): Chloé with an
// accessory or in another position, Joss with his jar. Each one edited by nano-banana from the
// character's own sheet (same grid, same style), and cut out at the SAME drawing scale as it
// (px of the output per px of the character), so the game shows them with the base sheet's
// sprite scale (Heights) and they can be added to the same SpriteFrames (Outfits).
import fs from "node:fs";
import path from "node:path";

// Chloé swimming on her own: nano-banana drew the side views of the first row swapped, and both
// side views of the second row facing right. Put back in the sheet's order (front, left, right,
// back) — the second row's left view is its right one mirrored.
const NAGE_SRC = "e47l4z";
const NAGE_FIXED = "derived-chloe-nage";

async function fixNage(sharp, find) {
  const src = find(NAGE_SRC);
  const out = path.join(path.dirname(src), `${NAGE_FIXED}.png`);
  if (fs.existsSync(out)) return;
  const { width: w, height: h } = await sharp(src).metadata();
  const cw = w / 4, ch = h / 2;
  const cell = (c, r, flip = false) => {
    const img = sharp(src).extract({ left: Math.round(c * cw), top: Math.round(r * ch), width: Math.round(cw), height: Math.round(ch) });
    return (flip ? img.flop() : img).png().toBuffer();
  };
  // [from column, from row, mirrored] for each place, row by row.
  const order = [[0, 0], [2, 0], [1, 0], [3, 0], [0, 1], [1, 1, true], [2, 1], [3, 1]];
  const composites = [];
  for (const [i, [c, r, flip]] of order.entries()) {
    composites.push({ input: await cell(c, r, flip), left: Math.round((i % 4) * cw), top: Math.round(Math.floor(i / 4) * ch) });
  }
  await sharp({ create: { width: w, height: h, channels: 3, background: { r: 255, g: 0, b: 255 } } })
    .composite(composites).png().toFile(out);
}

// Sitting poses (29/09): row 1 = the pose, row 2 = the person standing, drawn by nano-banana at the
// same scale as row 1 so that it sets the scale: every drawing is cut out at `frameHeight` / the
// standing height, i.e. the person's drawn height in its walking sheet (Heights). nano-banana
// mixes up the side views: `views` puts row 1 back in the sheet's order (front, left, right, back),
// [column, mirrored] for each place; row 2 is kept as drawn (it only gives the scale).
const SITTING = [
  // [output, source id, drawn height (Heights), views]
  ["maia_assise", "ixl8vx", 173.5, [[0], [2, true], [2], [3]]],
  ["chloe_assise", "zbrjeb", 172.5, [[0], [1], [2], [3]]],
  ["tante_sirocco_assise", "i9c5n9", 174.5, [[0], [1, true], [1], [3]]],
  ["roc_assis", "ybd02o", 171.0, [[0], [2], [1], [3]]],
  ["pecheur_assis", "q10c06", 176.0, [[0], [1], [1, true], [3]]],
  ["sbire_assis", "ihqomu", 172.0, [[0], [1], [2], [3]]],
];

async function orderViews(sharp, find, id, views, name) {
  const src = find(id);
  const out = path.join(path.dirname(src), `derived-vues-${name}.png`);   // (a name without the id: find(id) keeps finding the source)
  if (fs.existsSync(out)) return path.basename(out, ".png");
  const { width: w, height: h } = await sharp(src).metadata();
  const cw = w / 4, ch = h / 2;
  const cell = (c, r, flip = false) => {
    const img = sharp(src).extract({ left: Math.round(c * cw), top: Math.round(r * ch), width: Math.round(cw), height: Math.round(ch) });
    return (flip ? img.flop() : img).png().toBuffer();
  };
  const composites = [];
  for (const [i, [c, flip]] of views.entries()) composites.push({ input: await cell(c, 0, flip), left: Math.round(i * cw), top: 0 });
  for (let i = 0; i < 4; i++) composites.push({ input: await cell(i, 1), left: Math.round(i * cw), top: Math.round(ch) });
  await sharp({ create: { width: w, height: h, channels: 3, background: { r: 255, g: 0, b: 255 } } })
    .composite(composites).png().toFile(out);
  return path.basename(out, ".png");
}

// Scene poses (29/09, finition B): nano-banana drew each from the character's walking sheet
// (0wbmww for Chloé, 5fwqyr for Maïa) as a 4-row x 4-col sheet echoing that sheet's own layout
// (it ignored the "2 rows" instruction), rows 0-1 = the pose duplicated, rows 2-3 = the standing
// reference duplicated. Only row 0 (pose) and row 2 (standing) are used. `poseViews`: per output
// column of row 0, [source column, mirrored] — nano-banana sometimes repeats a view (two fronts)
// or skips one (no right profile): the missing view is then the mirror of its nearest neighbour,
// same fix as `orderViews` above. Row 2 (standing) is kept as drawn, columns unchanged: it is only
// used to measure the scale (tallest blob in the sheet), so its own view order does not matter.
const POSE4 = [
  // [output, source id, output frame height, poseViews for row 0]. 176: chloe.png's and maia.png's
  // own frameHeight (Heights' 172.5 / 173.5 is the drawn figure inside that frame, not this
  // parameter) — same value keeps these poses at the base sheet's sprite scale.
  ["chloe_main", "9gfztm", 176, [[0], [1], [2], [3]]],
  ["chloe_grimpe", "2x7afh", 176, [[0], [2], [2, true], [3]]],
  ["maia_accroupi", "k6ci3a", 176, [[0], [1], [1, true], [3]]],
];

async function orderPose4(sharp, find, id, poseViews, name) {
  const src = find(id);
  const out = path.join(path.dirname(src), `derived-pose4-${name}.png`);
  if (fs.existsSync(out)) return path.basename(out, ".png");
  const { width: w, height: h } = await sharp(src).metadata();
  const cw = w / 4, ch = h / 4;
  const cell = (c, r, flip = false) => {
    const img = sharp(src).extract({ left: Math.round(c * cw), top: Math.round(r * ch), width: Math.round(cw), height: Math.round(ch) });
    return (flip ? img.flop() : img).png().toBuffer();
  };
  const composites = [];
  for (const [i, [c, flip]] of poseViews.entries()) composites.push({ input: await cell(c, 0, flip), left: Math.round(i * cw), top: 0 });
  for (let i = 0; i < 4; i++) composites.push({ input: await cell(i, 2), left: Math.round(i * cw), top: Math.round(ch) });
  await sharp({ create: { width: w, height: h / 2, channels: 3, background: { r: 255, g: 0, b: 255 } } })
    .composite(composites).png().toFile(out);
  return path.basename(out, ".png");
}

export default ({ sheet, sharp, find, OUT }) => [
  // No `cell`: the per-cell union crop (not the global blob search of `sheetInCells`) — the global
  // search picked up a spurious blob spanning the whole sheet (a faint JPEG seam between cells,
  // its bounding box bigger than any character's) and let it win column 1 in every one of these
  // three sheets. The plain per-cell crop only ever looks inside its own cell's rectangle.
  ...POSE4.map(([name, id, drawn, poseViews]) => [`${OUT}/characters/${name}.png`, async (out) =>
    sheet({ id: await orderPose4(sharp, find, id, poseViews, name), rows: 2, cols: 4, frameHeight: drawn, out })]),
  // Wide cells (240 px: a net spread on a lap, legs stretched out), 184 px high like the walking
  // frames, feet 4 px above the bottom: the sprite stays centred, its feet stay put.
  ...SITTING.map(([name, id, drawn, views]) => [`${OUT}/characters/${name}.png`, async (out) =>
    sheet({ id: await orderViews(sharp, find, id, views, name), rows: 2, cols: 4, frameHeight: drawn, cell: [240, 184], out })]),
  // In the saddle (same grid and scale as chloe_selle.png: its source redrawn at 2x): with Joss's
  // diving mask (under the sea, Player.diving), with the swimming vest (on a swimmer's back).
  [`${OUT}/characters/chloe_selle_masque.png`, (out) => sheet({ id: "tvpon2", rows: 1, cols: 4, frameHeight: 220, cell: [150, 228], out })],
  [`${OUT}/characters/chloe_selle_gilet.png`, (out) => sheet({ id: "g97rgx", rows: 1, cols: 4, frameHeight: 220, cell: [150, 228], out })],
  // Walking in Rosalie's boots (amber soles): chloe.png's grid; the soles make the union 0.8 %
  // taller, so 177 px keeps chloe.png's scale (176 px for its union).
  [`${OUT}/characters/chloe_bottes.png`, (out) => sheet({ id: "be1r6q", rows: 4, cols: 4, frameHeight: 177, out })],
  // Joss's jar (prototype n° 7): joss.png's grid; the jar makes the union 2.3 % taller (180 px
  // keeps joss.png's scale; Heights has « joss_bocal » accordingly).
  [`${OUT}/characters/joss_bocal.png`, (out) => sheet({ id: "yn5lea", rows: 4, cols: 4, frameHeight: 180, out })],
  // Poses (Outfits.POSES): one row of the four directions (front, left, right, back), in cells the
  // size of chloe.png's frames (123 x 184, feet 4 px above the bottom) so her feet stay put.
  // Scale from her head's width (76 px in chloe.png): crouching 0.221 px per source px (tallest
  // drawing 704 px), swimming 0.2085 (731 px). Second rows: the crouch again (unused), the second
  // phase of the stroke.
  [`${OUT}/characters/chloe_accroupie.png`, (out) => sheet({ id: "m3pyem", rows: 2, cols: 4, frameHeight: 156, cell: [123, 184], out })],
  [`${OUT}/characters/chloe_nage.png`, async (out) => {
    await fixNage(sharp, find);
    return sheet({ id: NAGE_FIXED, rows: 2, cols: 4, frameHeight: 152, cell: [132, 184], out });
  }],
];
