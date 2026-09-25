// Paints the terrain layer of a map region onto a 2D canvas.
//
// Terrains are drawn in priority order; a terrain spills a few pixels, with an
// irregular edge, over lower-priority neighbours so borders look organic rather
// than tiled. Details (grass blades, pebbles, waves…) are seeded per tile so a
// map always renders identically.

import { TILE, tileAt } from "../world/tiles.js";
import { hash } from "../world/mapBuilder.js";

const PRIORITY = { water: 0, cave: 0.5, sand: 1, path: 2, stone: 3, grass: 4 };
const RECT_GROUNDS = new Set(["planks", "cliff", "floor", "wall", "carpet", "cavewall"]);
const isRock = (n) => n === "cliff" || n === "cavewall";

const COLORS = {
  grass: ["#5f9139", "#6a9c40", "#578834"],
  path: ["#c3a06c", "#b8955f", "#caa874"],
  sand: ["#e7d29c", "#e1ca91", "#ecd9a6"],
  water: ["#2f7fa8", "#2a76a0", "#3587b0"],
  stone: ["#7a6f5c", "#7a6f5c", "#7a6f5c"],
  cave: ["#4a4046", "#453b42", "#4e444a"],
};

function rng(x, y, salt) {
  let i = 0;
  return () => hash(x * 7 + i++, y * 13 + salt, 91);
}

// Outside the map, the nearest edge tile continues (no seams at map borders).
function groundOf(rows, x, y) {
  const h = rows.length, w = rows[0].length;
  const t = tileAt(rows, Math.max(0, Math.min(w - 1, x)), Math.max(0, Math.min(h - 1, y)));
  return t ? t.ground : null;
}

// ---------------------------------------------------------------- details
function grassDetail(ctx, px, py, r) {
  // Soft patches of darker/lighter grass for large-scale variation.
  if (r() < 0.35) {
    const g = ctx.createRadialGradient(px + r() * 48, py + r() * 48, 2, px + 24, py + 24, 34);
    g.addColorStop(0, r() < 0.5 ? "rgba(40,70,20,0.18)" : "rgba(150,200,90,0.14)");
    g.addColorStop(1, "rgba(0,0,0,0)");
    ctx.fillStyle = g;
    ctx.fillRect(px - 10, py - 10, 68, 68);
  }
  const blades = ["#446f26", "#537f2e", "#78a947", "#8dbd57"];
  for (let i = 0; i < 16; i++) {
    const x = px + r() * TILE, y = py + 6 + r() * (TILE - 6);
    const h = 3 + r() * 5, lean = (r() - 0.5) * 4;
    ctx.strokeStyle = blades[Math.floor(r() * blades.length)];
    ctx.lineWidth = 1.3;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.quadraticCurveTo(x + lean * 0.3, y - h * 0.6, x + lean, y - h);
    ctx.stroke();
  }
  if (r() < 0.12) {
    // Tiny clover.
    const x = px + 8 + r() * 32, y = py + 8 + r() * 32;
    ctx.fillStyle = "#7fb84e";
    for (let k = 0; k < 3; k++) {
      const a = (k * 2 * Math.PI) / 3;
      ctx.beginPath();
      ctx.arc(x + Math.cos(a) * 2.2, y + Math.sin(a) * 2.2, 2, 0, Math.PI * 2);
      ctx.fill();
    }
  }
}

function pathDetail(ctx, px, py, r) {
  for (let i = 0; i < 3; i++) {
    ctx.fillStyle = `rgba(110,80,45,${0.08 + r() * 0.1})`;
    ctx.beginPath();
    ctx.ellipse(px + r() * 48, py + r() * 48, 6 + r() * 10, 3 + r() * 5, r() * 3, 0, Math.PI * 2);
    ctx.fill();
  }
  for (let i = 0; i < 6; i++) {
    const x = px + r() * 46 + 1, y = py + r() * 46 + 1, s = 1 + r() * 2.2;
    ctx.fillStyle = r() < 0.5 ? "#9b7c52" : "#e0c79a";
    ctx.beginPath();
    ctx.ellipse(x, y, s, s * 0.75, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "rgba(60,40,20,0.25)";
    ctx.beginPath();
    ctx.ellipse(x + 0.6, y + s * 0.6, s, s * 0.35, 0, 0, Math.PI * 2);
    ctx.fill();
  }
}

function sandDetail(ctx, px, py, r) {
  for (let i = 0; i < 14; i++) {
    ctx.fillStyle = r() < 0.5 ? "rgba(170,140,80,0.35)" : "rgba(255,250,230,0.5)";
    ctx.fillRect(px + r() * 48, py + r() * 48, 1.4, 1.4);
  }
  if (r() < 0.25) {
    ctx.strokeStyle = "rgba(180,150,95,0.4)";
    ctx.lineWidth = 1.2;
    const y = py + 10 + r() * 28;
    ctx.beginPath();
    ctx.moveTo(px + 4, y);
    ctx.bezierCurveTo(px + 16, y - 3, px + 30, y + 3, px + 44, y);
    ctx.stroke();
  }
  if (r() < 0.05) {
    // Shell.
    const x = px + 12 + r() * 24, y = py + 12 + r() * 24;
    ctx.fillStyle = "#f4e3cf";
    ctx.strokeStyle = "#c79e7c";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x - 4, y + 2);
    ctx.quadraticCurveTo(x, y - 6, x + 4, y + 2);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
  }
}

function waterDetail(ctx, px, py, r) {
  for (let i = 0; i < 2; i++) {
    const x = px + 6 + r() * 30, y = py + 8 + r() * 32, w = 8 + r() * 10;
    ctx.strokeStyle = `rgba(210,240,255,${0.18 + r() * 0.18})`;
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.quadraticCurveTo(x + w / 2, y - 3, x + w, y);
    ctx.stroke();
  }
}

// Cobblestones: irregular rounded stones on a jittered grid, moss in the joints.
function stoneDetail(ctx, px, py, r) {
  const n = 3, cell = TILE / n;
  for (let j = 0; j < n; j++) {
    for (let i = 0; i < n; i++) {
      const cx = px + (i + 0.5) * cell + (r() - 0.5) * 3, cy = py + (j + 0.5) * cell + (r() - 0.5) * 3;
      const rx = cell * (0.42 + r() * 0.08), ry = cell * (0.36 + r() * 0.08), rot = r() * 0.6 - 0.3;
      const tone = 150 + Math.floor(r() * 42);
      ctx.fillStyle = `rgb(${tone + 20},${tone + 8},${tone - 18})`;
      ctx.beginPath(); ctx.ellipse(cx, cy, rx, ry, rot, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = "rgba(255,250,235,0.28)";
      ctx.beginPath(); ctx.ellipse(cx - rx * 0.25, cy - ry * 0.3, rx * 0.55, ry * 0.35, rot, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = "rgba(60,50,35,0.25)";
      ctx.beginPath(); ctx.ellipse(cx + rx * 0.15, cy + ry * 0.45, rx * 0.8, ry * 0.3, rot, 0, Math.PI * 2); ctx.fill();
    }
  }
  if (r() < 0.35) {
    ctx.fillStyle = "rgba(95,140,60,0.55)";
    for (let k = 0; k < 4; k++) ctx.fillRect(px + r() * 44, py + r() * 44, 3, 2);
  }
}

function flowers(ctx, px, py, r) {
  const palette = [["#fdfdf5", "#f2c94c"], ["#f7d948", "#b5831c"], ["#f28bb3", "#fff0a8"], ["#b58cf0", "#fff0a8"], ["#f26a4b", "#ffe38a"]];
  const n = 3 + Math.floor(r() * 3);
  const [petal, heart] = palette[Math.floor(r() * palette.length)];
  for (let i = 0; i < n; i++) {
    const x = px + 8 + r() * 32, y = py + 10 + r() * 30;
    ctx.strokeStyle = "#3f6b22";
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    ctx.moveTo(x, y + 2);
    ctx.lineTo(x + (r() - 0.5) * 2, y + 7);
    ctx.stroke();
    ctx.fillStyle = petal;
    for (let k = 0; k < 5; k++) {
      const a = (k * 2 * Math.PI) / 5;
      ctx.beginPath();
      ctx.arc(x + Math.cos(a) * 2.4, y + Math.sin(a) * 2.4, 1.9, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.fillStyle = heart;
    ctx.beginPath();
    ctx.arc(x, y, 1.4, 0, Math.PI * 2);
    ctx.fill();
  }
}

function fern(ctx, px, py, r) {
  const cx = px + 24 + (r() - 0.5) * 10, cy = py + 38;
  for (let k = 0; k < 6; k++) {
    const a = -Math.PI / 2 + (k - 2.5) * 0.45;
    const len = 14 + r() * 8;
    const ex = cx + Math.cos(a) * len, ey = cy + Math.sin(a) * len;
    ctx.strokeStyle = k % 2 ? "#3d6d24" : "#4f8530";
    ctx.lineWidth = 1.6;
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.quadraticCurveTo((cx + ex) / 2 + Math.cos(a + 1.2) * 3, (cy + ey) / 2, ex, ey);
    ctx.stroke();
    for (let s = 0.3; s < 1; s += 0.14) {
      const x = cx + (ex - cx) * s, y = cy + (ey - cy) * s;
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x + Math.cos(a - 1.2) * 4 * (1.1 - s), y + Math.sin(a - 1.2) * 4 * (1.1 - s));
      ctx.moveTo(x, y);
      ctx.lineTo(x + Math.cos(a + 1.2) * 4 * (1.1 - s), y + Math.sin(a + 1.2) * 4 * (1.1 - s));
      ctx.stroke();
    }
  }
}

function bones(ctx, px, py) {
  ctx.strokeStyle = "#8b8069";
  ctx.lineWidth = 3.2;
  ctx.lineCap = "round";
  ctx.beginPath();
  ctx.moveTo(px + 10, py + 30); ctx.lineTo(px + 34, py + 22);
  ctx.moveTo(px + 16, py + 38); ctx.lineTo(px + 38, py + 34);
  ctx.stroke();
  ctx.strokeStyle = "#efe6cf";
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.lineCap = "butt";
}

// ---------------------------------------------------------------- rect grounds
function planks(ctx, px, py, r) {
  ctx.fillStyle = "rgba(0,20,40,0.35)";
  ctx.fillRect(px + 4, py + 4, TILE, TILE);
  for (let j = 0; j < 4; j++) {
    const y = py + j * 12;
    const shade = 140 + Math.floor(r() * 30);
    ctx.fillStyle = `rgb(${shade + 10},${Math.floor(shade * 0.72)},${Math.floor(shade * 0.42)})`;
    ctx.fillRect(px, y + 1, TILE, 10);
    ctx.fillStyle = "rgba(255,230,190,0.18)";
    ctx.fillRect(px, y + 1, TILE, 2);
    ctx.fillStyle = "rgba(60,35,15,0.35)";
    ctx.fillRect(px + r() * 40, y + 5, 6 + r() * 6, 1);
    ctx.fillStyle = "#4b3018";
    ctx.fillRect(px + 3, y + 5, 2, 2);
    ctx.fillRect(px + TILE - 5, y + 5, 2, 2);
  }
  ctx.fillStyle = "#3a2410";
  ctx.fillRect(px, py, 2, TILE);
  ctx.fillRect(px + TILE - 2, py, 2, TILE);
}

function cliff(ctx, px, py, r, rows, x, y) {
  const below = groundOf(rows, x, y + 1);
  const front = below !== "cliff";
  const left = groundOf(rows, x - 1, y) !== "cliff", right = groundOf(rows, x + 1, y) !== "cliff";
  // Top surface.
  ctx.fillStyle = "#8d8674";
  ctx.fillRect(px, py, TILE, TILE);
  for (let i = 0; i < 5; i++) {
    ctx.fillStyle = `rgba(${r() < 0.5 ? "60,55,45" : "190,185,165"},0.25)`;
    ctx.beginPath();
    ctx.ellipse(px + r() * 48, py + r() * 48, 4 + r() * 8, 2 + r() * 4, r() * 3, 0, Math.PI * 2);
    ctx.fill();
  }
  if (r() < 0.4) {
    ctx.fillStyle = "#6e9a3e";
    ctx.beginPath();
    ctx.ellipse(px + 10 + r() * 28, py + 8 + r() * 20, 6, 3, 0, 0, Math.PI * 2);
    ctx.fill();
  }
  if (front) {
    // Rock face with strata.
    const top = py + 16;
    const g = ctx.createLinearGradient(0, top, 0, py + TILE);
    g.addColorStop(0, "#766f5f");
    g.addColorStop(1, "#4c463b");
    ctx.fillStyle = g;
    ctx.fillRect(px, top, TILE, TILE - 16);
    ctx.strokeStyle = "rgba(35,30,24,0.55)";
    ctx.lineWidth = 1.5;
    for (let i = 0; i < 4; i++) {
      const sx = px + 5 + r() * 38;
      ctx.beginPath();
      ctx.moveTo(sx, top + 2);
      ctx.lineTo(sx + (r() - 0.5) * 6, py + TILE - 2);
      ctx.stroke();
    }
    ctx.fillStyle = "rgba(210,200,175,0.35)";
    ctx.fillRect(px, top, TILE, 2);
    ctx.fillStyle = "#4f7a2b";
    for (let i = 0; i < 6; i++) ctx.fillRect(px + i * 8 + r() * 4, top - 2 + r() * 2, 5, 3);
  }
  if (left) { ctx.fillStyle = "rgba(30,25,20,0.35)"; ctx.fillRect(px, py, 3, TILE); }
  if (right) { ctx.fillStyle = "rgba(30,25,20,0.35)"; ctx.fillRect(px + TILE - 3, py, 3, TILE); }
}

// Cave floor: packed dark earth, pebbles and cracks. `gravel` marks the tiles where wild dinos lurk.
function caveDetail(ctx, px, py, r, gravel) {
  for (let i = 0; i < (gravel ? 16 : 5); i++) {
    const tone = gravel ? 40 + Math.floor(r() * 50) : 70 + Math.floor(r() * 40);
    ctx.fillStyle = `rgba(${tone},${tone - 8},${tone},${gravel ? 0.8 : 0.55})`;
    ctx.beginPath();
    ctx.ellipse(px + r() * TILE, py + r() * TILE, 1.5 + r() * (gravel ? 3 : 4), 1 + r() * 2.5, r() * 3, 0, Math.PI * 2);
    ctx.fill();
  }
  if (r() < 0.35) {
    ctx.strokeStyle = "rgba(20,14,20,0.45)";
    ctx.lineWidth = 1.2;
    let x = px + r() * TILE, y = py + r() * TILE;
    ctx.beginPath(); ctx.moveTo(x, y);
    for (let k = 0; k < 3; k++) { x += (r() - 0.5) * 18; y += (r() - 0.5) * 18; ctx.lineTo(x, y); }
    ctx.stroke();
  }
}

// Cave rock: a dark mass seen from above, with a lit face where it meets the floor.
function caveWall(ctx, px, py, r, rows, x, y) {
  const front = groundOf(rows, x, y + 1) !== "cavewall";
  const left = groundOf(rows, x - 1, y) !== "cavewall", right = groundOf(rows, x + 1, y) !== "cavewall";
  const back = groundOf(rows, x, y - 1) !== "cavewall";
  ctx.fillStyle = "#1c171d";
  ctx.fillRect(px, py, TILE, TILE);
  for (let i = 0; i < 4; i++) {
    ctx.fillStyle = `rgba(${r() < 0.5 ? "10,8,12" : "70,60,72"},0.4)`;
    ctx.beginPath();
    ctx.ellipse(px + r() * 48, py + r() * 48, 5 + r() * 9, 3 + r() * 5, r() * 3, 0, Math.PI * 2);
    ctx.fill();
  }
  if (back) { ctx.fillStyle = "rgba(120,105,120,0.35)"; ctx.fillRect(px, py, TILE, 3); }
  if (front) {
    const top = py + 12;
    const g = ctx.createLinearGradient(0, top, 0, py + TILE);
    g.addColorStop(0, "#5a4f5a");
    g.addColorStop(1, "#342c35");
    ctx.fillStyle = g;
    ctx.fillRect(px, top, TILE, TILE - 12);
    ctx.strokeStyle = "rgba(15,10,16,0.6)";
    ctx.lineWidth = 1.5;
    for (let i = 0; i < 4; i++) {
      const sx = px + 5 + r() * 38;
      ctx.beginPath(); ctx.moveTo(sx, top + 2); ctx.lineTo(sx + (r() - 0.5) * 8, py + TILE - 2); ctx.stroke();
    }
    ctx.fillStyle = "rgba(190,170,190,0.3)";
    ctx.fillRect(px, top, TILE, 2);
    // Amber veins glinting in the rock.
    if (r() < 0.22) {
      const vx = px + 8 + r() * 30, vy = top + 8 + r() * 18;
      ctx.fillStyle = "#e89a30";
      ctx.beginPath(); ctx.moveTo(vx, vy - 5); ctx.lineTo(vx + 3, vy); ctx.lineTo(vx, vy + 3); ctx.lineTo(vx - 3, vy); ctx.closePath(); ctx.fill();
      ctx.fillStyle = "rgba(255,200,110,0.25)";
      ctx.beginPath(); ctx.arc(vx, vy, 9, 0, Math.PI * 2); ctx.fill();
    }
  }
  if (left) { ctx.fillStyle = "rgba(0,0,0,0.35)"; ctx.fillRect(px, py, 3, TILE); }
  if (right) { ctx.fillStyle = "rgba(0,0,0,0.35)"; ctx.fillRect(px + TILE - 3, py, 3, TILE); }
}

function floor(ctx, px, py, r) {
  for (let j = 0; j < 4; j++) {
    const shade = 165 + Math.floor(r() * 18);
    ctx.fillStyle = `rgb(${shade + 20},${Math.floor(shade * 0.78)},${Math.floor(shade * 0.5)})`;
    ctx.fillRect(px, py + j * 12, TILE, 11);
    ctx.fillStyle = "rgba(80,50,25,0.35)";
    ctx.fillRect(px, py + j * 12 + 11, TILE, 1);
    ctx.fillRect(px + ((j * 19 + Math.floor(r() * 10)) % 40), py + j * 12, 1, 11);
  }
}

function wall(ctx, px, py, rows, x, y) {
  const floorBelow = groundOf(rows, x, y + 1) !== "wall";
  ctx.fillStyle = "#d8c7a0";
  ctx.fillRect(px, py, TILE, TILE);
  ctx.fillStyle = "rgba(160,120,80,0.25)";
  for (let i = 0; i < 4; i++) ctx.fillRect(px + i * 12 + 5, py, 3, TILE);
  if (!floorBelow) {
    ctx.fillStyle = "rgba(60,40,25,0.35)";
    ctx.fillRect(px, py, TILE, TILE);
  } else {
    ctx.fillStyle = "#7a5634";
    ctx.fillRect(px, py + TILE - 10, TILE, 10);
    ctx.fillStyle = "#9a7148";
    ctx.fillRect(px, py + TILE - 10, TILE, 2);
  }
}

function carpet(ctx, px, py, rows, x, y) {
  ctx.fillStyle = "#8e2c2a";
  ctx.fillRect(px, py, TILE, TILE);
  ctx.strokeStyle = "rgba(230,190,110,0.5)";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(px + 24, py + 12); ctx.lineTo(px + 36, py + 24); ctx.lineTo(px + 24, py + 36); ctx.lineTo(px + 12, py + 24); ctx.closePath();
  ctx.stroke();
  ctx.fillStyle = "#d9a441";
  const edge = (dx, dy) => groundOf(rows, x + dx, y + dy) !== "carpet";
  if (edge(0, -1)) ctx.fillRect(px, py, TILE, 4);
  if (edge(0, 1)) ctx.fillRect(px, py + TILE - 4, TILE, 4);
  if (edge(-1, 0)) ctx.fillRect(px, py, 4, TILE);
  if (edge(1, 0)) ctx.fillRect(px + TILE - 4, py, 4, TILE);
}

// ---------------------------------------------------------------- smooth masks
// Terrain borders come from a blurred coverage field thresholded with a little
// noise: borders curve naturally instead of following the tile grid.
const RES = 8;     // field samples per tile
const MARGIN = 2;  // tiles of context around the chunk so borders match across chunks

function boxBlur(src, W, H, r) {
  const tmp = new Float32Array(W * H), out = new Float32Array(W * H), k = 1 / (2 * r + 1);
  for (let y = 0; y < H; y++) {
    let acc = 0;
    for (let x = -r; x <= r; x++) acc += src[y * W + Math.min(W - 1, Math.max(0, x))];
    for (let x = 0; x < W; x++) {
      tmp[y * W + x] = acc * k;
      acc += src[y * W + Math.min(W - 1, x + r + 1)] - src[y * W + Math.max(0, x - r)];
    }
  }
  for (let x = 0; x < W; x++) {
    let acc = 0;
    for (let y = -r; y <= r; y++) acc += tmp[Math.min(H - 1, Math.max(0, y)) * W + x];
    for (let y = 0; y < H; y++) {
      out[y * W + x] = acc * k;
      acc += tmp[Math.min(H - 1, y + r + 1) * W + x] - tmp[Math.max(0, y - r) * W + x];
    }
  }
  return out;
}

function buildField(rows, x0, y0, w, h, test) {
  const W = (w + 2 * MARGIN) * RES, H = (h + 2 * MARGIN) * RES;
  let a = new Float32Array(W * H);
  let any = false;
  for (let ty = 0; ty < h + 2 * MARGIN; ty++) {
    for (let tx = 0; tx < w + 2 * MARGIN; tx++) {
      const g = groundOf(rows, x0 + tx - MARGIN, y0 + ty - MARGIN);
      if (!test(g)) continue;
      any = true;
      for (let j = 0; j < RES; j++) a.fill(1, (ty * RES + j) * W + tx * RES, (ty * RES + j) * W + tx * RES + RES);
    }
  }
  if (!any) return null;
  a = boxBlur(boxBlur(a, W, H, 4), W, H, 4);
  return { a, W, H };
}

// Field value at a chunk-local pixel (bilinear).
function sample(f, px, py) {
  const gx = (px / TILE + MARGIN) * RES - 0.5, gy = (py / TILE + MARGIN) * RES - 0.5;
  const x = Math.max(0, Math.min(f.W - 2, Math.floor(gx))), y = Math.max(0, Math.min(f.H - 2, Math.floor(gy)));
  const fx = Math.min(1, Math.max(0, gx - x)), fy = Math.min(1, Math.max(0, gy - y));
  const i = y * f.W + x;
  const top = f.a[i] * (1 - fx) + f.a[i + 1] * fx;
  const bot = f.a[i + f.W] * (1 - fx) + f.a[i + f.W + 1] * fx;
  return top * (1 - fy) + bot * fy;
}

// Border threshold with a gentle wobble, in world pixels so chunks agree.
function threshold(wx, wy) {
  return 0.5 + 0.06 * Math.sin(wx * 0.09 + wy * 0.05) * Math.cos(wy * 0.08 - wx * 0.035) + 0.012 * Math.sin(wx * 0.23 + wy * 0.19);
}

const smooth = (e0, e1, v) => {
  const t = Math.min(1, Math.max(0, (v - e0) / (e1 - e0)));
  return t * t * (3 - 2 * t);
};

function newCanvas(w, h) {
  const c = document.createElement("canvas");
  c.width = w;
  c.height = h;
  return c;
}

// Alpha mask canvas for a field, plus optional shoreline effects on the water side.
// Masks are computed at half resolution and scaled up with smoothing: 4× cheaper,
// and the slight softness suits painted terrain borders.
const MASK_SCALE = 0.5;
function maskFrom(field, x0, y0, w, h, shore) {
  const S = MASK_SCALE, W = Math.round(w * TILE * S), H = Math.round(h * TILE * S);
  const mask = newCanvas(W, H), mctx = mask.getContext("2d");
  const img = mctx.createImageData(W, H), d = img.data;
  let fx = null, fd = null;
  if (shore) { fx = mctx.createImageData(W, H); fd = fx.data; }
  for (let py = 0; py < H; py++) {
    for (let px = 0; px < W; px++) {
      const v = sample(field, px / S, py / S);
      const t = threshold(x0 * TILE + px / S, y0 * TILE + py / S);
      const i = (py * W + px) * 4;
      d[i + 3] = 255 * smooth(t - 0.025, t + 0.025, v);
      if (shore && v < t && v > t - 0.4) {
        // Shallow water tint, then two foam bands hugging the shore.
        let a = 0.45 * smooth(t - 0.4, t - 0.02, v), r = 150, g = 215, b = 230;
        const f1 = 1 - Math.abs(v - (t - 0.07)) / 0.025, f2 = 1 - Math.abs(v - (t - 0.17)) / 0.018;
        if (f1 > 0) { a = Math.max(a, 0.75 * f1); r = g = b = 245; }
        else if (f2 > 0) { a = Math.max(a, 0.32 * f2); r = g = b = 240; }
        fd[i] = r; fd[i + 1] = g; fd[i + 2] = b; fd[i + 3] = 255 * a;
      }
    }
  }
  mctx.putImageData(img, 0, 0);
  let shoreCanvas = null;
  if (shore) {
    shoreCanvas = newCanvas(W, H);
    shoreCanvas.getContext("2d").putImageData(fx, 0, 0);
  }
  return { mask, shoreCanvas };
}

// ---------------------------------------------------------------- main
const ORGANIC = ["water", "cave", "sand", "path", "stone", "grass"];
const isLand = (g) => g !== null && g !== "water" && g !== "planks" && g !== "floor" && g !== "wall" && g !== "carpet";

/**
 * Paints tiles [x0, x0+w) × [y0, y0+h) of `rows` onto ctx, whose origin is the
 * chunk's top-left corner.
 */
export function paintGround(ctx, rows, x0, y0, w, h) {
  const T = TILE, W = w * T, H = h * T;
  const inChunk = (fn, m = 1) => {
    for (let y = y0 - m; y < y0 + h + m; y++) for (let x = x0 - m; x < x0 + w + m; x++) fn(x, y);
  };
  const toWorld = (c) => { c.translate(-x0 * T, -y0 * T); return c; };

  // 1. Water everywhere underneath, with its ripples.
  ctx.fillStyle = COLORS.water[0];
  ctx.fillRect(0, 0, W, H);
  ctx.save();
  toWorld(ctx);
  inChunk((x, y) => {
    if (groundOf(rows, x, y) === "water" || groundOf(rows, x, y) === "planks") waterDetail(ctx, x * T, y * T, rng(x, y, 2));
  });
  ctx.restore();

  // 2. Organic terrains, lowest first. Each one covers every tile of equal or higher
  //    priority (so there is never a gap under the terrain drawn above it).
  for (const g of ORGANIC.slice(1)) {
    const pr = PRIORITY[g];
    const field = buildField(rows, x0, y0, w, h, (n) => (n in PRIORITY ? PRIORITY[n] >= pr : n === "cliff" || (n === "cavewall" && g === "cave")));
    if (!field) continue;
    const { mask, shoreCanvas } = maskFrom(field, x0, y0, w, h, g === "sand");
    if (shoreCanvas) ctx.drawImage(shoreCanvas, 0, 0, W, H);

    const layer = newCanvas(W, H), l = layer.getContext("2d");
    l.fillStyle = COLORS[g][0];
    l.fillRect(0, 0, W, H);
    l.save();
    toWorld(l);
    inChunk((x, y) => {
      // Large soft tone variations (reach up to ~2.5 tiles, hence the wider margin).
      if (hash(x, y, 17) < 0.22) {
        const cx = x * T + hash(x, y, 18) * T, cy = y * T + hash(x, y, 19) * T, rad = 50 + hash(x, y, 20) * 60;
        const grad = l.createRadialGradient(cx, cy, 0, cx, cy, rad);
        grad.addColorStop(0, hash(x, y, 21) < 0.5 ? "rgba(20,40,10,0.13)" : "rgba(255,255,220,0.1)");
        grad.addColorStop(1, "rgba(0,0,0,0)");
        l.fillStyle = grad;
        l.fillRect(cx - rad, cy - rad, rad * 2, rad * 2);
      }
      // Details are drawn on every tile; the smooth mask trims them to the terrain.
      const r = rng(x, y, 2), px = x * T, py = y * T;
      if (g === "grass") {
        grassDetail(l, px, py, r);
        // Dense, darker ground under tall grass so the tufts read as one meadow.
        if (rows[y]?.[x] === ",") { l.fillStyle = "rgba(25,60,12,0.45)"; l.beginPath(); l.roundRect(px - 4, py - 4, TILE + 8, TILE + 8, 14); l.fill(); }
      }
      else if (g === "path") pathDetail(l, px, py, r);
      else if (g === "sand") sandDetail(l, px, py, r);
      else if (g === "stone") stoneDetail(l, px, py, r);
      else if (g === "cave") caveDetail(l, px, py, r, rows[y]?.[x] === "g");
    }, 3);
    l.restore();
    l.globalCompositeOperation = "destination-in";
    l.drawImage(mask, 0, 0, W, H);

    ctx.save();
    if (g === "grass" || g === "stone" || g === "cave") {
      ctx.shadowColor = "rgba(25,35,12,0.4)";
      ctx.shadowBlur = 5;
      ctx.shadowOffsetY = 2;
    }
    ctx.drawImage(layer, 0, 0);
    ctx.restore();
  }

  ctx.save();
  toWorld(ctx);
  ctx.beginPath();
  ctx.rect(x0 * T, y0 * T, W, H);
  ctx.clip();

  // 3. Small ground decorations.
  inChunk((x, y) => {
    const ch = rows[y]?.[x], r = rng(x, y, 3), px = x * T, py = y * T;
    if (ch === ":") flowers(ctx, px, py, r);
    if (ch === "y") fern(ctx, px, py, r);
    if (ch === "_") bones(ctx, px, py);
  });

  // 4. Rectangular grounds (docks, cliffs, interiors).
  inChunk((x, y) => {
    const g = groundOf(rows, x, y);
    if (!RECT_GROUNDS.has(g)) return;
    const r = rng(x, y, 4), px = x * T, py = y * T;
    if (g === "planks") planks(ctx, px, py, r);
    else if (g === "cliff") cliff(ctx, px, py, r, rows, x, y);
    else if (g === "floor") floor(ctx, px, py, r);
    else if (g === "wall") wall(ctx, px, py, rows, x, y);
    else if (g === "carpet") carpet(ctx, px, py, rows, x, y);
    else if (g === "cavewall") caveWall(ctx, px, py, r, rows, x, y);
  });

  // 5. Shadows cast by cliffs on the ground below.
  inChunk((x, y) => {
    if (isRock(groundOf(rows, x, y)) || !isRock(groundOf(rows, x, y - 1))) return;
    const px = x * T, py = y * T;
    const sh = ctx.createLinearGradient(0, py, 0, py + 16);
    sh.addColorStop(0, "rgba(20,25,15,0.4)");
    sh.addColorStop(1, "rgba(20,25,15,0)");
    ctx.fillStyle = sh;
    ctx.fillRect(px, py, T, 16);
  });

  ctx.restore();
}
