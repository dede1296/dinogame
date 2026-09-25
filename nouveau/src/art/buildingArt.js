// Canvas-drawn buildings and interior furniture (3/4 top-down view).
// Each factory returns { canvas, ax, ay }: the anchor is the bottom-left corner of
// the footprint, so the sprite can be placed at (footprint.x, footprint.y + h).

import { TILE } from "../world/tiles.js";
import { hash } from "../world/mapBuilder.js";

function make(w, h, draw) {
  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  draw(canvas.getContext("2d"), w, h);
  return canvas;
}

function shade(ctx, x, y, w, h, from, to) {
  const g = ctx.createLinearGradient(0, y, 0, y + h);
  g.addColorStop(0, from);
  g.addColorStop(1, to);
  ctx.fillStyle = g;
  ctx.fillRect(x, y, w, h);
}

// ---------------------------------------------------------------- building parts
function wallStone(ctx, x, y, w, h, base = [168, 158, 138]) {
  shade(ctx, x, y, w, h, `rgb(${base.join(",")})`, `rgb(${base.map((v) => v - 40).join(",")})`);
  const bh = 12;
  for (let j = 0; j * bh < h; j++) {
    const off = (j % 2) * 14;
    for (let i = -1; i * 28 < w; i++) {
      const bx = x + i * 28 + off, by = y + j * bh;
      const s = hash(i, j, 31) * 24 - 12;
      ctx.fillStyle = `rgba(${s > 0 ? "255,250,235" : "40,30,20"},${Math.abs(s) / 90})`;
      ctx.fillRect(Math.max(x, bx + 1), by + 1, Math.min(26, x + w - bx - 1), bh - 2);
    }
    ctx.fillStyle = "rgba(50,40,30,0.35)";
    ctx.fillRect(x, y + j * bh, w, 1);
  }
}

function wallPlaster(ctx, x, y, w, h, color = "#efe2c4") {
  shade(ctx, x, y, w, h, color, "#cbb993");
  // Timber frame.
  ctx.fillStyle = "#6b4526";
  ctx.fillRect(x, y, w, 6);
  ctx.fillRect(x, y + h - 8, w, 8);
  for (let i = 0; i <= w; i += 60) ctx.fillRect(x + Math.min(i, w - 6), y, 6, h);
}

function wallPlanks(ctx, x, y, w, h, color = [120, 150, 170]) {
  for (let j = 0; j * 10 < h; j++) {
    const s = hash(j, 3, 12) * 20 - 10;
    ctx.fillStyle = `rgb(${color.map((v) => v + s).join(",")})`;
    ctx.fillRect(x, y + j * 10, w, 9);
    ctx.fillStyle = "rgba(20,30,40,0.35)";
    ctx.fillRect(x, y + j * 10 + 9, w, 1);
  }
}

function roof(ctx, x, y, w, h, style, color) {
  const [r, g, b] = color;
  // Main surface, darker toward the eaves.
  shade(ctx, x, y, w, h, `rgb(${r + 25},${g + 25},${b + 25})`, `rgb(${r - 25},${g - 25},${b - 25})`);
  if (style === "tiles") {
    for (let j = 0; j * 12 < h; j++) {
      ctx.fillStyle = "rgba(40,15,10,0.35)";
      for (let i = 0; i * 16 < w + 16; i++) {
        ctx.beginPath();
        ctx.arc(x + i * 16 + (j % 2) * 8, y + j * 12 + 12, 8, 0, Math.PI);
        ctx.fill();
      }
      ctx.fillStyle = "rgba(255,220,190,0.12)";
      ctx.fillRect(x, y + j * 12 + 2, w, 2);
    }
  } else if (style === "slate") {
    for (let j = 0; j * 11 < h; j++) {
      ctx.fillStyle = "rgba(10,15,25,0.45)";
      ctx.fillRect(x, y + j * 11 + 10, w, 1.5);
      for (let i = 0; i * 18 < w; i++) ctx.fillRect(x + i * 18 + (j % 2) * 9, y + j * 11, 1.2, 11);
    }
  } else if (style === "thatch") {
    ctx.strokeStyle = "rgba(90,60,20,0.45)";
    ctx.lineWidth = 1.2;
    for (let i = 0; i < w * h / 60; i++) {
      const sx = x + hash(i, 1, 55) * w, sy = y + hash(i, 2, 55) * h;
      ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(sx + 2, sy + 10); ctx.stroke();
    }
    ctx.fillStyle = "rgba(120,80,30,0.6)";
    for (let i = 0; i < w; i += 7) ctx.fillRect(x + i, y + h - 4, 4, 7 + hash(i, 4, 5) * 4);
  }
  // Ridge and eave.
  ctx.fillStyle = `rgba(255,255,255,0.18)`;
  ctx.fillRect(x, y, w, 4);
  ctx.fillStyle = "rgba(0,0,0,0.35)";
  ctx.fillRect(x, y + h - 3, w, 3);
}

function door(ctx, x, y, w, h, color = "#6b3f1f") {
  ctx.fillStyle = "#3a2410";
  ctx.beginPath(); ctx.roundRect(x - 4, y - 4, w + 8, h + 4, [w / 2 + 4, w / 2 + 4, 0, 0]); ctx.fill();
  const g = ctx.createLinearGradient(x, 0, x + w, 0);
  g.addColorStop(0, color); g.addColorStop(1, "#4a2a12");
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.roundRect(x, y, w, h, [w / 2, w / 2, 0, 0]); ctx.fill();
  ctx.strokeStyle = "rgba(30,15,5,0.55)";
  ctx.lineWidth = 1.5;
  for (let i = 1; i < 3; i++) { ctx.beginPath(); ctx.moveTo(x + (i * w) / 3, y + 6); ctx.lineTo(x + (i * w) / 3, y + h); ctx.stroke(); }
  ctx.fillStyle = "#e0b04a";
  ctx.beginPath(); ctx.arc(x + w - 7, y + h * 0.58, 2.5, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = "#8a8272";
  ctx.fillRect(x - 6, y + h, w + 12, 5);
}

function windowPane(ctx, x, y, w, h, flowers = false) {
  ctx.fillStyle = "#3a2410";
  ctx.fillRect(x - 3, y - 3, w + 6, h + 6);
  const g = ctx.createLinearGradient(0, y, 0, y + h);
  g.addColorStop(0, "#ffe7a8"); g.addColorStop(1, "#e6a44a");
  ctx.fillStyle = g;
  ctx.fillRect(x, y, w, h);
  ctx.fillStyle = "rgba(255,255,255,0.45)";
  ctx.beginPath(); ctx.moveTo(x, y + h * 0.6); ctx.lineTo(x + w * 0.6, y); ctx.lineTo(x + w * 0.85, y); ctx.lineTo(x, y + h * 0.9); ctx.fill();
  ctx.fillStyle = "#3a2410";
  ctx.fillRect(x + w / 2 - 1.5, y, 3, h);
  ctx.fillRect(x, y + h / 2 - 1.5, w, 3);
  ctx.fillStyle = "#8a7258";
  ctx.fillRect(x - 5, y + h + 2, w + 10, 4);
  if (flowers) {
    ctx.fillStyle = "#6b3f1f";
    ctx.fillRect(x - 3, y + h + 5, w + 6, 7);
    for (let i = 0; i < 5; i++) {
      ctx.fillStyle = ["#e8475b", "#f2c94c", "#f28bb3"][i % 3];
      ctx.beginPath(); ctx.arc(x + 2 + i * ((w - 4) / 4), y + h + 4, 3, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = "#3f6b22";
      ctx.fillRect(x + 1 + i * ((w - 4) / 4), y + h + 6, 2, 3);
    }
  }
}

function footShadow(ctx, w, y) {
  const g = ctx.createLinearGradient(0, y, 0, y + 14);
  g.addColorStop(0, "rgba(10,20,5,0.4)"); g.addColorStop(1, "rgba(10,20,5,0)");
  ctx.fillStyle = g;
  ctx.fillRect(4, y, w - 4, 14);
}

// ---------------------------------------------------------------- buildings
export function building(kind, wTiles, hTiles) {
  const T = TILE, W = wTiles * T, H = (hTiles + 1.4) * T;
  const base = H; // bottom of footprint
  const wallH = Math.round(T * 1.9);
  const wallTop = base - wallH;
  const roofTop = Math.round(T * 0.5);
  const canvas = make(W + 16, H + 14, (ctx) => {
    ctx.translate(8, 0);
    footShadow(ctx, W + 8, base);
    if (kind === "cabinet") {
      // Observatory tower on the left, drawn first so the main hall overlaps it.
      const tx = 6, tw = 84;
      wallStone(ctx, tx, roofTop + 40, tw, base - roofTop - 40, [150, 140, 122]);
      ctx.fillStyle = "#6a8f86";
      ctx.beginPath(); ctx.ellipse(tx + tw / 2, roofTop + 42, tw / 2 + 6, 44, 0, Math.PI, 0); ctx.fill();
      const dg = ctx.createLinearGradient(tx, 0, tx + tw, 0);
      dg.addColorStop(0, "#9fc2b6"); dg.addColorStop(0.5, "#6f9a8e"); dg.addColorStop(1, "#3f6b60");
      ctx.fillStyle = dg;
      ctx.beginPath(); ctx.ellipse(tx + tw / 2, roofTop + 40, tw / 2 + 2, 40, 0, Math.PI, 0); ctx.fill();
      ctx.fillStyle = "#1c2a2a";
      ctx.fillRect(tx + tw / 2 - 6, roofTop + 4, 12, 36);
      ctx.fillStyle = "#c9a44a";
      ctx.fillRect(tx - 2, roofTop + 38, tw + 4, 6);
      windowPane(ctx, tx + tw / 2 - 12, roofTop + 64, 24, 30);
      // Main hall.
      const hx = 72;
      roof(ctx, hx - 8, roofTop + 30, W - hx + 16, wallTop - roofTop - 30, "slate", [70, 84, 104]);
      wallStone(ctx, hx, wallTop, W - hx, wallH);
      for (const cx of [hx + 20, W - 64]) windowPane(ctx, cx, wallTop + 18, 34, 42);
      door(ctx, 3 * T + 4, base - 64, 40, 64, "#7a4a26");
      // Sign with the amber emblem.
      ctx.fillStyle = "#3a2410";
      ctx.beginPath(); ctx.roundRect(3 * T - 38, wallTop - 20, 124, 24, 5); ctx.fill();
      ctx.fillStyle = "#d4b27a";
      ctx.beginPath(); ctx.roundRect(3 * T - 35, wallTop - 17, 118, 18, 4); ctx.fill();
      ctx.fillStyle = "#3a2410";
      ctx.font = "bold 13px Georgia, serif";
      ctx.textAlign = "center";
      ctx.fillText("LE CABINET", 3 * T + 24, wallTop - 3);
      const ag = ctx.createRadialGradient(3 * T + 24, wallTop - 38, 1, 3 * T + 24, wallTop - 36, 11);
      ag.addColorStop(0, "#fff0b0"); ag.addColorStop(0.5, "#f0a020"); ag.addColorStop(1, "#8a4a08");
      ctx.fillStyle = ag;
      ctx.beginPath(); ctx.arc(3 * T + 24, wallTop - 36, 10, 0, Math.PI * 2); ctx.fill();
      // Brass pipes and lamps.
      ctx.fillStyle = "#b8893a";
      ctx.fillRect(W - 30, roofTop + 6, 10, wallTop - roofTop);
      ctx.fillStyle = "#8f6a2a";
      ctx.fillRect(W - 34, roofTop + 2, 18, 8);
      for (const lx of [3 * T - 14, 3 * T + 62]) {
        const lg = ctx.createRadialGradient(lx, base - 70, 1, lx, base - 70, 18);
        lg.addColorStop(0, "rgba(255,210,120,0.9)"); lg.addColorStop(1, "rgba(255,180,60,0)");
        ctx.fillStyle = lg; ctx.fillRect(lx - 18, base - 88, 36, 36);
        ctx.fillStyle = "#2a1a0a"; ctx.fillRect(lx - 3, base - 76, 6, 12);
      }
      // Ivy.
      ctx.fillStyle = "#3f6b22";
      for (let i = 0; i < 40; i++) {
        const vx = hx + hash(i, 1, 66) * 50, vy = wallTop + hash(i, 2, 66) * wallH * 0.9;
        ctx.beginPath(); ctx.ellipse(vx, vy, 4, 3, hash(i, 3, 66) * 3, 0, Math.PI * 2); ctx.fill();
      }
    } else if (kind === "house") {
      roof(ctx, -8, roofTop + 10, W + 16, wallTop - roofTop - 10, "tiles", [168, 70, 50]);
      ctx.fillStyle = "#7a6a5a";
      ctx.fillRect(W - 60, roofTop - 16, 22, 44);
      ctx.fillStyle = "#5a4a3a";
      ctx.fillRect(W - 63, roofTop - 20, 28, 8);
      wallPlaster(ctx, 0, wallTop, W, wallH);
      windowPane(ctx, 18, wallTop + 22, 34, 34, true);
      windowPane(ctx, W - 54, wallTop + 22, 34, 34, true);
      door(ctx, 2 * T + 5, base - 60, 38, 60, "#2f5a7a");
    } else if (kind === "harbour") {
      roof(ctx, -8, roofTop + 12, W + 16, wallTop - roofTop - 12, "slate", [60, 70, 80]);
      wallPlanks(ctx, 0, wallTop, W, wallH);
      windowPane(ctx, 16, wallTop + 22, 36, 32);
      windowPane(ctx, W - 52, wallTop + 22, 36, 32);
      door(ctx, 2 * T + 5, base - 60, 38, 60, "#8a2a22");
      // Anchor emblem.
      ctx.strokeStyle = "#e8e2d0"; ctx.lineWidth = 4;
      const ax = W / 2, ay = wallTop - 26;
      ctx.beginPath(); ctx.arc(ax, ay - 12, 5, 0, Math.PI * 2); ctx.moveTo(ax, ay - 7); ctx.lineTo(ax, ay + 12);
      ctx.moveTo(ax - 12, ay + 4); ctx.quadraticCurveTo(ax, ay + 20, ax + 12, ay + 4); ctx.stroke();
    } else {
      // Fisher's hut.
      roof(ctx, -8, roofTop + 30, W + 16, wallTop - roofTop - 30, "thatch", [196, 160, 90]);
      wallPlanks(ctx, 0, wallTop, W, wallH, [140, 105, 70]);
      windowPane(ctx, 16, wallTop + 26, 28, 26);
      ctx.strokeStyle = "rgba(230,220,190,0.7)"; ctx.lineWidth = 1;
      for (let i = 0; i < 8; i++) { ctx.beginPath(); ctx.moveTo(W - 70 + i * 7, wallTop + 10); ctx.lineTo(W - 74 + i * 7, wallTop + 70); ctx.stroke(); }
      for (let i = 0; i < 8; i++) { ctx.beginPath(); ctx.moveTo(W - 74, wallTop + 14 + i * 8); ctx.lineTo(W - 20, wallTop + 12 + i * 8); ctx.stroke(); }
    }
  });
  return { canvas, ax: 8, ay: H };
}

// ---------------------------------------------------------------- furniture
export function furniture(kind, wTiles, hTiles) {
  const T = TILE, W = wTiles * T, H = hTiles * T + 20;
  const base = H;
  const canvas = make(W, H, (ctx) => {
    ctx.fillStyle = "rgba(20,10,5,0.3)";
    ctx.fillRect(4, base - 8, W - 8, 8);
    if (kind === "machine") {
      const g = ctx.createLinearGradient(0, 0, W, 0);
      g.addColorStop(0, "#6b5230"); g.addColorStop(0.5, "#c9a24e"); g.addColorStop(1, "#6b5230");
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.roundRect(10, 30, W - 20, base - 40, 10); ctx.fill();
      // Glowing amber tank.
      const tg = ctx.createLinearGradient(0, 40, 0, 120);
      tg.addColorStop(0, "#ffe6a0"); tg.addColorStop(1, "#d2780f");
      ctx.fillStyle = "#2a1a0a";
      ctx.beginPath(); ctx.roundRect(W / 2 - 30, 12, 60, 96, 26); ctx.fill();
      ctx.fillStyle = tg;
      ctx.beginPath(); ctx.roundRect(W / 2 - 25, 17, 50, 86, 22); ctx.fill();
      ctx.fillStyle = "rgba(255,255,255,0.4)";
      ctx.fillRect(W / 2 - 18, 24, 6, 70);
      // DNA helix silhouette inside.
      ctx.strokeStyle = "rgba(120,50,5,0.7)"; ctx.lineWidth = 2;
      ctx.beginPath();
      for (let y = 26; y < 98; y += 2) ctx.lineTo(W / 2 + Math.sin(y * 0.2) * 12, y);
      ctx.stroke();
      ctx.beginPath();
      for (let y = 26; y < 98; y += 2) ctx.lineTo(W / 2 - Math.sin(y * 0.2) * 12, y);
      ctx.stroke();
      for (const [x, c] of [[26, "#4ae08a"], [W - 32, "#e84a4a"], [W - 46, "#f2c94c"]]) {
        ctx.fillStyle = c; ctx.beginPath(); ctx.arc(x, 128, 4, 0, Math.PI * 2); ctx.fill();
      }
      ctx.fillStyle = "#1c2a2a"; ctx.fillRect(18, 112, 40, 22);
      ctx.fillStyle = "#4ae0a0"; ctx.fillRect(21, 115, 34, 16);
      ctx.fillStyle = "#b8893a";
      ctx.fillRect(4, 50, 10, 80); ctx.fillRect(W - 14, 50, 10, 80);
    } else if (kind === "shelf") {
      ctx.fillStyle = "#4a2c16"; ctx.fillRect(4, 8, W - 8, base - 12);
      ctx.fillStyle = "#6b4526"; ctx.fillRect(8, 12, W - 16, base - 20);
      for (let s = 0; s < 3; s++) {
        const sy = 16 + s * ((base - 26) / 3);
        ctx.fillStyle = "#3a2410"; ctx.fillRect(8, sy + 28, W - 16, 4);
        for (let i = 0; i < 8; i++) {
          const x = 12 + i * ((W - 24) / 8), jar = hash(i, s, 3) < 0.5;
          if (jar) {
            ctx.fillStyle = `rgba(${230 - s * 20},${150 + i * 8},40,0.9)`;
            ctx.beginPath(); ctx.roundRect(x, sy + 12, 8, 16, 3); ctx.fill();
          } else {
            ctx.fillStyle = ["#7a2a2a", "#2a4a7a", "#3f6b22", "#8a6a2a"][(i + s) % 4];
            ctx.fillRect(x, sy + 6 + hash(i, s, 4) * 6, 8, 22);
          }
        }
      }
    } else if (kind === "desk") {
      ctx.fillStyle = "#5a3a20"; ctx.fillRect(6, 30, W - 12, base - 38);
      ctx.fillStyle = "#8a5f38"; ctx.fillRect(2, 24, W - 4, 14);
      ctx.fillStyle = "#f0e6cc"; ctx.fillRect(14, 16, 30, 12);
      ctx.fillStyle = "#e0d4b0"; ctx.fillRect(48, 12, 26, 16);
      ctx.fillStyle = "#c9c1ad"; ctx.beginPath(); ctx.arc(W - 20, 18, 7, 0, Math.PI * 2); ctx.fill();
    } else if (kind === "pedestal") {
      ctx.fillStyle = "#8a8272"; ctx.fillRect(8, 30, W - 16, base - 36);
      ctx.fillStyle = "#b5ae9f"; ctx.fillRect(4, 24, W - 8, 10);
      ctx.fillStyle = "rgba(200,240,255,0.35)";
      ctx.beginPath(); ctx.ellipse(W / 2, 16, 16, 18, 0, 0, Math.PI * 2); ctx.fill();
      const eg = ctx.createRadialGradient(W / 2 - 3, 12, 1, W / 2, 16, 10);
      eg.addColorStop(0, "#fff8e0"); eg.addColorStop(1, "#d8a040");
      ctx.fillStyle = eg;
      ctx.beginPath(); ctx.ellipse(W / 2, 18, 8, 10, 0, 0, Math.PI * 2); ctx.fill();
    } else if (kind === "plant") {
      ctx.fillStyle = "#8a4a2a"; ctx.beginPath(); ctx.moveTo(12, base - 22); ctx.lineTo(36, base - 22); ctx.lineTo(32, base - 4); ctx.lineTo(16, base - 4); ctx.fill();
      for (let i = 0; i < 9; i++) {
        const a = -Math.PI / 2 + (i - 4) * 0.35;
        ctx.strokeStyle = i % 2 ? "#3d6d24" : "#5a9a36"; ctx.lineWidth = 4; ctx.lineCap = "round";
        ctx.beginPath(); ctx.moveTo(24, base - 22); ctx.quadraticCurveTo(24 + Math.cos(a) * 14, base - 36, 24 + Math.cos(a) * 22, base - 30 + Math.sin(a) * 20); ctx.stroke();
      }
    } else if (kind === "bed") {
      ctx.fillStyle = "#5a3a20"; ctx.fillRect(2, 6, W - 4, base - 10);
      ctx.fillStyle = "#e8e0cc"; ctx.fillRect(6, 10, W - 12, 20);
      ctx.fillStyle = "#4a6a9a"; ctx.fillRect(6, 30, W - 12, base - 38);
      ctx.fillStyle = "rgba(255,255,255,0.2)";
      for (let y = 36; y < base - 10; y += 10) ctx.fillRect(6, y, W - 12, 2);
    } else if (kind === "table") {
      ctx.fillStyle = "#6b4526"; ctx.fillRect(8, 26, 8, base - 30); ctx.fillRect(W - 16, 26, 8, base - 30);
      ctx.fillStyle = "#9a6d42"; ctx.fillRect(2, 16, W - 4, 14);
      ctx.fillStyle = "#f3ead2"; ctx.save(); ctx.translate(W / 2, 18); ctx.rotate(-0.12); ctx.fillRect(-12, -8, 24, 14); ctx.restore();
      ctx.fillStyle = "#b8352b"; ctx.beginPath(); ctx.arc(W / 2 + 4, 16, 3, 0, Math.PI * 2); ctx.fill();
    } else if (kind === "fireplace") {
      ctx.fillStyle = "#7a6a5a"; ctx.fillRect(4, 4, W - 8, base - 8);
      ctx.fillStyle = "#1a120c"; ctx.beginPath(); ctx.roundRect(18, 36, W - 36, base - 44, [16, 16, 0, 0]); ctx.fill();
      ctx.fillStyle = "#5a3a20"; ctx.fillRect(24, base - 16, W - 48, 6);
      ctx.fillStyle = "#9a8a78"; ctx.fillRect(0, 26, W, 10);
    }
  });
  return { canvas, ax: 0, ay: H };
}
