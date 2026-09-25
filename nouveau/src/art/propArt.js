// Canvas-drawn world props. Each factory returns { canvas, ax, ay } where (ax, ay)
// is the anchor point that sits at the bottom-center of the prop's tile.

import { hash } from "../world/mapBuilder.js";

function make(w, h, draw) {
  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  draw(ctx, w, h);
  return canvas;
}

function circle(ctx, x, y, r, fill) {
  ctx.fillStyle = fill;
  ctx.beginPath();
  ctx.arc(x, y, r, 0, Math.PI * 2);
  ctx.fill();
}

function groundShadow(ctx, x, y, rx, ry, alpha = 0.3) {
  const g = ctx.createRadialGradient(x, y, 0, x, y, rx);
  g.addColorStop(0, `rgba(10,20,5,${alpha})`);
  g.addColorStop(1, "rgba(10,20,5,0)");
  ctx.save();
  ctx.scale(1, ry / rx);
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.arc(x, (y * rx) / ry, rx, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

const TREE_PALETTES = [
  ["#1f3d17", "#2f5a22", "#407a2d", "#62a03d", "#93cb5d"],
  ["#223f19", "#34602a", "#4d8233", "#75ab45", "#a8d46a"],
  ["#2b3f15", "#46621f", "#63862b", "#8fb13c", "#c5db6c"],
];

export function tree(variant = 0) {
  const [outline, dark, mid, light, glow] = TREE_PALETTES[variant % TREE_PALETTES.length];
  const W = 124, H = 172, cx = 62, base = 162;
  const canvas = make(W, H, (ctx) => {
    groundShadow(ctx, cx + 6, base - 2, 44, 14, 0.38);
    // Trunk with bark and roots.
    const tg = ctx.createLinearGradient(cx - 10, 0, cx + 10, 0);
    tg.addColorStop(0, "#5a3a20"); tg.addColorStop(0.5, "#7a5230"); tg.addColorStop(1, "#4a2f18");
    ctx.fillStyle = tg;
    ctx.beginPath();
    ctx.moveTo(cx - 9, base - 50);
    ctx.lineTo(cx - 11, base - 6);
    ctx.quadraticCurveTo(cx - 18, base, cx - 20, base + 1);
    ctx.lineTo(cx + 20, base + 1);
    ctx.quadraticCurveTo(cx + 16, base, cx + 11, base - 6);
    ctx.lineTo(cx + 9, base - 50);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = "rgba(40,25,10,0.6)";
    ctx.lineWidth = 1.2;
    for (let i = 0; i < 4; i++) {
      ctx.beginPath();
      ctx.moveTo(cx - 6 + i * 4, base - 44);
      ctx.lineTo(cx - 7 + i * 4.5, base - 8);
      ctx.stroke();
    }
    // Canopy: dark mass, mid leaves, lit leaves, then sparkles of light.
    const r = (i) => hash(i, variant, 77);
    const blobs = [[-30, 8, 30], [30, 8, 30], [0, -12, 38], [-20, -32, 27], [22, -34, 27], [0, 18, 30], [-40, -10, 22], [40, -10, 22]];
    const cy = base - 86;
    for (const [dx, dy, rr] of blobs) circle(ctx, cx + dx, cy + dy, rr + 3, outline);
    for (const [dx, dy, rr] of blobs) circle(ctx, cx + dx, cy + dy, rr, dark);
    for (const [dx, dy, rr] of blobs) circle(ctx, cx + dx - 3, cy + dy - 5, rr * 0.82, mid);
    for (const [dx, dy, rr] of blobs) circle(ctx, cx + dx - 7, cy + dy - 10, rr * 0.5, light);
    for (let i = 0; i < 60; i++) {
      const a = r(i) * Math.PI * 2, d = r(i + 100) * 44;
      const x = cx + Math.cos(a) * d * 1.15, y = cy - 6 + Math.sin(a) * d * 0.9;
      ctx.strokeStyle = r(i + 200) < 0.5 ? dark : light;
      ctx.lineWidth = 1.6;
      ctx.beginPath();
      ctx.arc(x, y, 3.5, Math.PI * 0.15, Math.PI * 0.85);
      ctx.stroke();
    }
    for (let i = 0; i < 10; i++) circle(ctx, cx - 26 + r(i + 300) * 40, cy - 40 + r(i + 400) * 30, 2 + r(i + 500) * 2, glow);
    // Soft shading at the bottom of the canopy.
    const sh = ctx.createLinearGradient(0, cy - 40, 0, cy + 50);
    sh.addColorStop(0, "rgba(0,0,0,0)");
    sh.addColorStop(1, "rgba(0,15,0,0.35)");
    ctx.globalCompositeOperation = "source-atop";
    ctx.fillStyle = sh;
    ctx.fillRect(0, cy - 40, W, 100);
    ctx.globalCompositeOperation = "source-over";
  });
  return { canvas, ax: cx, ay: base };
}

export function pine(variant = 0) {
  const W = 100, H = 156, cx = 50, base = 146;
  const cols = variant % 2 ? ["#15301f", "#1f4a2e", "#2f6a3f", "#4f9160"] : ["#132b1a", "#1d4226", "#2c5e35", "#4a8a52"];
  const canvas = make(W, H, (ctx) => {
    groundShadow(ctx, cx + 5, base - 2, 34, 11, 0.38);
    ctx.fillStyle = "#5a3b22";
    ctx.fillRect(cx - 6, base - 26, 12, 26);
    const tiers = [[base - 18, 44], [base - 50, 36], [base - 80, 28], [base - 106, 19]];
    for (const [y, w] of tiers) {
      ctx.fillStyle = cols[0];
      ctx.beginPath();
      ctx.moveTo(cx, y - w * 1.25 - 3);
      ctx.lineTo(cx + w + 3, y + 2);
      ctx.quadraticCurveTo(cx, y + 12, cx - w - 3, y + 2);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = cols[1];
      ctx.beginPath();
      ctx.moveTo(cx, y - w * 1.25);
      ctx.lineTo(cx + w, y);
      ctx.quadraticCurveTo(cx, y + 9, cx - w, y);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = cols[2];
      ctx.beginPath();
      ctx.moveTo(cx, y - w * 1.25);
      ctx.lineTo(cx - w * 0.15, y + 6);
      ctx.quadraticCurveTo(cx - w * 0.6, y + 4, cx - w, y);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = cols[3];
      ctx.lineWidth = 1.3;
      for (let i = 0; i < 8; i++) {
        const t = hash(i, y, 5);
        const x0 = cx - w * 0.8 + t * w * 1.2;
        ctx.beginPath();
        ctx.moveTo(x0, y - 4 - hash(i, y, 6) * w * 0.7);
        ctx.lineTo(x0 - 4, y - hash(i, y, 7) * 6);
        ctx.stroke();
      }
    }
    circle(ctx, cx - 4, base - 124, 2.5, "#e8f5d0");
  });
  return { canvas, ax: cx, ay: base };
}

export function bush(variant = 0) {
  const W = 64, H = 56, cx = 32, base = 50;
  const canvas = make(W, H, (ctx) => {
    groundShadow(ctx, cx + 3, base - 1, 28, 8, 0.35);
    const blobs = [[-14, -12, 15], [14, -12, 15], [0, -20, 17], [0, -8, 18]];
    for (const [dx, dy, r] of blobs) circle(ctx, cx + dx, base + dy, r + 2, "#1e3b16");
    for (const [dx, dy, r] of blobs) circle(ctx, cx + dx, base + dy, r, "#35642a");
    for (const [dx, dy, r] of blobs) circle(ctx, cx + dx - 3, base + dy - 4, r * 0.65, "#4f8a36");
    for (const [dx, dy, r] of blobs) circle(ctx, cx + dx - 5, base + dy - 7, r * 0.3, "#7cb654");
    if (variant % 2) {
      for (let i = 0; i < 7; i++) {
        const x = cx - 18 + hash(i, 1, 9) * 36, y = base - 30 + hash(i, 2, 9) * 22;
        circle(ctx, x, y, 3, "#c0283a");
        circle(ctx, x - 1, y - 1, 1, "#ff9aa6");
      }
    }
  });
  return { canvas, ax: cx, ay: base };
}

export function rock(variant = 0) {
  const W = 60, H = 52, cx = 30, base = 46;
  const canvas = make(W, H, (ctx) => {
    groundShadow(ctx, cx + 4, base, 26, 8, 0.4);
    ctx.fillStyle = "#3f3a32";
    ctx.beginPath();
    ctx.moveTo(cx - 24, base);
    ctx.bezierCurveTo(cx - 28, base - 22, cx - 12, base - 36, cx + 4, base - 34);
    ctx.bezierCurveTo(cx + 22, base - 32, cx + 28, base - 16, cx + 24, base);
    ctx.closePath();
    ctx.fill();
    const g = ctx.createLinearGradient(cx - 20, base - 34, cx + 16, base);
    g.addColorStop(0, "#b5ae9e"); g.addColorStop(0.5, "#8c8576"); g.addColorStop(1, "#5e584c");
    ctx.fillStyle = g;
    ctx.beginPath();
    ctx.moveTo(cx - 21, base - 2);
    ctx.bezierCurveTo(cx - 25, base - 21, cx - 11, base - 33, cx + 4, base - 31);
    ctx.bezierCurveTo(cx + 19, base - 29, cx + 25, base - 15, cx + 21, base - 2);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = "rgba(50,45,38,0.6)";
    ctx.lineWidth = 1.3;
    ctx.beginPath();
    ctx.moveTo(cx - 4, base - 30); ctx.lineTo(cx + 2, base - 16); ctx.lineTo(cx - 6, base - 6);
    ctx.stroke();
    ctx.fillStyle = "rgba(255,255,255,0.25)";
    ctx.beginPath();
    ctx.ellipse(cx - 8, base - 24, 7, 3, -0.4, 0, Math.PI * 2);
    ctx.fill();
    if (variant % 2 === 0) {
      ctx.fillStyle = "#5f8f36";
      ctx.beginPath();
      ctx.ellipse(cx + 8, base - 29, 9, 4, 0.2, 0, Math.PI * 2);
      ctx.fill();
    }
  });
  return { canvas, ax: cx, ay: base };
}

// Tall grass tuft, wider than a tile so neighbours overlap into a meadow.
// `frame` = variant * 2 + (0 resting | 1 swept aside by someone walking through).
export function tallGrass(frame = 0) {
  const variant = Math.floor(frame / 2), swept = frame % 2;
  const W = 72, H = 74, base = 68;
  const canvas = make(W, H, (ctx) => {
    const sh = ctx.createRadialGradient(36, base - 4, 2, 36, base - 4, 34);
    sh.addColorStop(0, "rgba(15,40,8,0.45)");
    sh.addColorStop(1, "rgba(15,40,8,0)");
    ctx.fillStyle = sh;
    ctx.fillRect(0, base - 20, W, 30);
    // Back blades are darker, front blades lighter: gives the tuft some depth.
    const layers = [["#244d18", "#2f5e1f"], ["#3a7026", "#4a8530"], ["#5a9a38", "#79b449"]];
    layers.forEach(([c1, c2], li) => {
      const n = 12 + li * 4;
      for (let i = 0; i < n; i++) {
        const x = 6 + hash(i, li + variant * 7, 44) * 60;
        const h = (34 + hash(i, li + 3 + variant * 7, 44) * 24) * (0.78 + li * 0.1);
        const lean = (hash(i, li + 5 + variant * 7, 44) - 0.5) * 12 + (swept ? (x < 36 ? -10 : 10) : 0);
        const g = ctx.createLinearGradient(0, base, 0, base - h);
        g.addColorStop(0, c1);
        g.addColorStop(1, c2);
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.moveTo(x - 2.6, base - li * 2);
        ctx.quadraticCurveTo(x - 2 + lean * 0.3, base - h * 0.6, x + lean, base - h);
        ctx.quadraticCurveTo(x + 1 + lean * 0.3, base - h * 0.5, x + 2.6, base - li * 2);
        ctx.closePath();
        ctx.fill();
      }
    });
    // A few seed heads catching the light.
    for (let i = 0; i < 3; i++) {
      const x = 12 + hash(i, variant, 45) * 48, y = base - 46 - hash(i, variant, 46) * 10;
      ctx.fillStyle = "#c9d98a";
      ctx.beginPath(); ctx.ellipse(x, y, 1.6, 3.2, 0.3, 0, Math.PI * 2); ctx.fill();
    }
  });
  return { canvas, ax: 36, ay: base };
}

export function fence() {
  const W = 48, H = 46, base = 42;
  const canvas = make(W, H, (ctx) => {
    ctx.fillStyle = "rgba(10,20,5,0.25)";
    ctx.fillRect(0, base - 2, 48, 5);
    for (const y of [base - 26, base - 13]) {
      ctx.fillStyle = "#6e4a2a";
      ctx.fillRect(0, y, 48, 6);
      ctx.fillStyle = "#9a6d42";
      ctx.fillRect(0, y, 48, 2);
    }
    for (const x of [4, 40]) {
      ctx.fillStyle = "#5a3b20";
      ctx.fillRect(x, base - 34, 7, 34);
      ctx.fillStyle = "#8a5f38";
      ctx.fillRect(x, base - 34, 3, 34);
      ctx.fillStyle = "#4a2f18";
      ctx.beginPath();
      ctx.moveTo(x, base - 34); ctx.lineTo(x + 3.5, base - 39); ctx.lineTo(x + 7, base - 34);
      ctx.fill();
    }
  });
  return { canvas, ax: 24, ay: base };
}

export function sign() {
  const W = 48, H = 54, base = 50;
  const canvas = make(W, H, (ctx) => {
    groundShadow(ctx, 26, base, 16, 5, 0.35);
    ctx.fillStyle = "#5a3b20";
    ctx.fillRect(21, base - 26, 6, 26);
    ctx.fillStyle = "#4a2f18";
    ctx.beginPath(); ctx.roundRect(5, base - 46, 38, 24, 4); ctx.fill();
    ctx.fillStyle = "#b88a55";
    ctx.beginPath(); ctx.roundRect(7, base - 44, 34, 20, 3); ctx.fill();
    ctx.fillStyle = "rgba(255,240,210,0.3)";
    ctx.fillRect(8, base - 43, 32, 3);
    ctx.fillStyle = "#5a3b20";
    for (const y of [base - 38, base - 32]) ctx.fillRect(12, y, 24, 2);
  });
  return { canvas, ax: 24, ay: base };
}

export function boulder() {
  const r = rock(1);
  const W = 64, H = 60;
  const canvas = make(W, H, (ctx) => {
    ctx.drawImage(r.canvas, 0, 0, 60, 52, -4, -4, 72, 64);
    ctx.strokeStyle = "rgba(40,35,28,0.7)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(20, 18); ctx.lineTo(30, 30); ctx.lineTo(24, 44);
    ctx.stroke();
  });
  return { canvas, ax: 32, ay: 54 };
}

export function log(widthTiles = 2) {
  const W = widthTiles * 48 + 12, H = 50, base = 44;
  const canvas = make(W, H, (ctx) => {
    groundShadow(ctx, W / 2 + 4, base, W / 2, 7, 0.4);
    const g = ctx.createLinearGradient(0, base - 30, 0, base);
    g.addColorStop(0, "#8a5c33"); g.addColorStop(0.5, "#6b4424"); g.addColorStop(1, "#43290f");
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.roundRect(6, base - 30, W - 18, 28, 12); ctx.fill();
    ctx.strokeStyle = "rgba(40,22,8,0.6)";
    ctx.lineWidth = 1.4;
    for (let i = 0; i < 6; i++) {
      ctx.beginPath();
      ctx.moveTo(14 + i * 14, base - 26);
      ctx.quadraticCurveTo(20 + i * 14, base - 16, 12 + i * 14, base - 6);
      ctx.stroke();
    }
    ctx.fillStyle = "#c79a62";
    ctx.beginPath(); ctx.ellipse(W - 14, base - 16, 9, 14, 0, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = "#8a5c33";
    for (const rr of [3, 6, 9]) { ctx.beginPath(); ctx.ellipse(W - 14, base - 16, rr * 0.65, rr, 0, 0, Math.PI * 2); ctx.stroke(); }
    ctx.fillStyle = "#5f8f36";
    ctx.beginPath(); ctx.ellipse(40, base - 29, 12, 4, 0, 0, Math.PI * 2); ctx.fill();
  });
  return { canvas, ax: 24, ay: base };
}

export function caveMouth() {
  const canvas = make(56, 52, (ctx) => {
    const g = ctx.createRadialGradient(28, 44, 2, 28, 40, 30);
    g.addColorStop(0, "#050403"); g.addColorStop(1, "#2a241c");
    ctx.fillStyle = g;
    ctx.beginPath();
    ctx.moveTo(6, 52);
    ctx.bezierCurveTo(4, 20, 16, 10, 28, 10);
    ctx.bezierCurveTo(40, 10, 52, 20, 50, 52);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = "#3a342a";
    ctx.lineWidth = 3;
    ctx.stroke();
  });
  return { canvas, ax: 28, ay: 52 };
}

export function skull() {
  const W = 150, H = 100;
  const canvas = make(W, H, (ctx) => {
    groundShadow(ctx, 78, 88, 64, 12, 0.35);
    // Frill.
    ctx.fillStyle = "#cfc3a4";
    ctx.strokeStyle = "#6d6450";
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(24, 78);
    ctx.bezierCurveTo(8, 40, 30, 8, 64, 10);
    ctx.bezierCurveTo(90, 12, 100, 40, 96, 70);
    ctx.closePath();
    ctx.fill(); ctx.stroke();
    ctx.fillStyle = "#a79b7f";
    for (const [x, y] of [[44, 34], [70, 30]]) { ctx.beginPath(); ctx.ellipse(x, y, 10, 8, 0, 0, Math.PI * 2); ctx.fill(); }
    // Face.
    ctx.fillStyle = "#e3d8bb";
    ctx.beginPath();
    ctx.moveTo(60, 84);
    ctx.bezierCurveTo(70, 50, 110, 44, 134, 62);
    ctx.lineTo(140, 78);
    ctx.bezierCurveTo(120, 90, 80, 92, 60, 84);
    ctx.closePath();
    ctx.fill(); ctx.stroke();
    ctx.fillStyle = "#3a3226";
    ctx.beginPath(); ctx.ellipse(96, 64, 7, 6, 0, 0, Math.PI * 2); ctx.fill();
    // Horns.
    ctx.fillStyle = "#efe6cc";
    for (const [x, y, dx, dy] of [[88, 56, 22, -40], [104, 54, 30, -34], [128, 64, 10, -18]]) {
      ctx.beginPath();
      ctx.moveTo(x - 5, y); ctx.quadraticCurveTo(x + dx * 0.4, y + dy * 0.6, x + dx, y + dy); ctx.quadraticCurveTo(x + dx * 0.5, y + dy * 0.3, x + 6, y);
      ctx.closePath(); ctx.fill(); ctx.stroke();
    }
    ctx.fillStyle = "#5f8f36";
    ctx.beginPath(); ctx.ellipse(40, 80, 18, 6, 0, 0, Math.PI * 2); ctx.fill();
  });
  return { canvas, ax: 24, ay: 92 };
}

export function boat() {
  const W = 200, H = 104;
  const canvas = make(W, H, (ctx) => {
    ctx.fillStyle = "rgba(0,30,50,0.35)";
    ctx.beginPath(); ctx.ellipse(104, 62, 92, 30, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = "#4a2c16";
    ctx.beginPath();
    ctx.moveTo(12, 50); ctx.quadraticCurveTo(20, 16, 100, 14); ctx.quadraticCurveTo(170, 14, 192, 50);
    ctx.quadraticCurveTo(170, 88, 100, 88); ctx.quadraticCurveTo(20, 86, 12, 50);
    ctx.fill();
    ctx.fillStyle = "#9a6a3e";
    ctx.beginPath();
    ctx.moveTo(22, 50); ctx.quadraticCurveTo(28, 24, 100, 22); ctx.quadraticCurveTo(162, 22, 182, 50);
    ctx.quadraticCurveTo(162, 80, 100, 80); ctx.quadraticCurveTo(28, 78, 22, 50);
    ctx.fill();
    ctx.strokeStyle = "rgba(60,35,15,0.6)";
    ctx.lineWidth = 1.5;
    for (let i = 1; i < 6; i++) { ctx.beginPath(); ctx.moveTo(40 + i * 22, 26); ctx.lineTo(40 + i * 22, 76); ctx.stroke(); }
    ctx.fillStyle = "#c9c1ad";
    ctx.beginPath(); ctx.moveTo(100, 4); ctx.lineTo(100, 50); ctx.lineTo(150, 46); ctx.closePath(); ctx.fill();
    ctx.fillStyle = "#5a3b20";
    ctx.fillRect(97, 2, 5, 52);
    ctx.fillStyle = "#b8352b";
    ctx.fillRect(100, 2, 14, 7);
  });
  return { canvas, ax: 24, ay: 96 };
}

// Collectible lying on the ground: a glowing amber drop.
export function itemOrb() {
  const canvas = make(36, 36, (ctx) => {
    const glow = ctx.createRadialGradient(18, 18, 2, 18, 18, 17);
    glow.addColorStop(0, "rgba(255,210,90,0.8)"); glow.addColorStop(1, "rgba(255,180,40,0)");
    ctx.fillStyle = glow; ctx.fillRect(0, 0, 36, 36);
    const g = ctx.createRadialGradient(15, 14, 1, 18, 18, 9);
    g.addColorStop(0, "#fff3c0"); g.addColorStop(0.4, "#f2a52a"); g.addColorStop(1, "#9a4d0c");
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.arc(18, 18, 8, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = "#5a2c05"; ctx.lineWidth = 1.5; ctx.stroke();
    circle(ctx, 15, 15, 2, "#fffbe8");
  });
  return { canvas, ax: 18, ay: 28 };
}

export function sparkle() {
  const canvas = make(16, 16, (ctx) => {
    ctx.fillStyle = "#fffbe0";
    ctx.beginPath();
    ctx.moveTo(8, 0); ctx.lineTo(9.5, 6.5); ctx.lineTo(16, 8); ctx.lineTo(9.5, 9.5); ctx.lineTo(8, 16); ctx.lineTo(6.5, 9.5); ctx.lineTo(0, 8); ctx.lineTo(6.5, 6.5);
    ctx.closePath(); ctx.fill();
  });
  return { canvas, ax: 8, ay: 8 };
}

export function butterfly(color = "#f2c94c") {
  return make(12, 10, (ctx) => {
    ctx.fillStyle = color;
    ctx.beginPath(); ctx.ellipse(3.5, 4, 3.5, 3, -0.4, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.ellipse(8.5, 4, 3.5, 3, 0.4, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = "#2a1a0a";
    ctx.fillRect(5.5, 2, 1, 7);
  });
}

// Campfire: stone ring and crossed logs (the flame is a separate, animated sprite).
export function campfire() {
  const W = 64, H = 56;
  const canvas = make(W, H, (ctx) => {
    groundShadow(ctx, 32, 44, 28, 9, 0.35);
    ctx.fillStyle = "#2a1c10";
    ctx.beginPath(); ctx.ellipse(32, 42, 18, 7, 0, 0, Math.PI * 2); ctx.fill();
    ctx.lineCap = "round";
    for (const [x1, y1, x2, y2] of [[16, 46, 46, 36], [18, 36, 48, 46], [24, 48, 40, 34]]) {
      ctx.strokeStyle = "#3b2414"; ctx.lineWidth = 9;
      ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
      ctx.strokeStyle = "#7a5230"; ctx.lineWidth = 5;
      ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
    }
    circle(ctx, 32, 41, 6, "#e0672a");
    circle(ctx, 32, 41, 3, "#ffd36a");
    for (let i = 0; i < 9; i++) {
      const a = (i / 9) * Math.PI * 2;
      const x = 32 + Math.cos(a) * 22, y = 42 + Math.sin(a) * 9;
      ctx.fillStyle = i % 2 ? "#8d877a" : "#a9a392";
      ctx.strokeStyle = "#4b473e"; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.ellipse(x, y, 6, 4.5, a, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
    }
  });
  return { canvas, ax: 8, ay: 52 };
}

export function flame() {
  const W = 36, H = 44;
  const canvas = make(W, H, (ctx) => {
    const tongue = (w, h, fill) => {
      ctx.fillStyle = fill;
      ctx.beginPath();
      ctx.moveTo(18 - w, 42);
      ctx.bezierCurveTo(18 - w * 1.2, 42 - h * 0.5, 18 - w * 0.2, 42 - h * 0.7, 18, 42 - h);
      ctx.bezierCurveTo(18 + w * 0.4, 42 - h * 0.6, 18 + w * 1.2, 42 - h * 0.45, 18 + w, 42);
      ctx.closePath(); ctx.fill();
    };
    tongue(15, 40, "#d9481e");
    tongue(11, 30, "#f28a2a");
    tongue(6, 18, "#ffe07a");
  });
  return { canvas, ax: 18, ay: 42 };
}

export function stalagmite(variant = 0) {
  const W = 48, H = 76;
  const canvas = make(W, H, (ctx) => {
    groundShadow(ctx, 24, 68, 18, 6, 0.45);
    const spikes = variant ? [[24, 22, 12], [12, 44, 6], [35, 48, 5]] : [[20, 14, 11], [33, 38, 7]];
    for (const [x, top, w] of spikes) {
      const g = ctx.createLinearGradient(x - w, 0, x + w, 0);
      g.addColorStop(0, "#2b242d"); g.addColorStop(0.45, "#6a5d6a"); g.addColorStop(1, "#2b242d");
      ctx.fillStyle = g;
      ctx.strokeStyle = "#161216"; ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(x - w, 68); ctx.quadraticCurveTo(x - w * 0.5, top + (68 - top) * 0.4, x, top);
      ctx.quadraticCurveTo(x + w * 0.5, top + (68 - top) * 0.4, x + w, 68);
      ctx.closePath(); ctx.fill(); ctx.stroke();
      ctx.strokeStyle = "rgba(200,180,200,0.25)"; ctx.lineWidth = 1;
      for (let k = 1; k < 4; k++) { const yy = top + (68 - top) * k / 4; ctx.beginPath(); ctx.moveTo(x - w * k / 5, yy); ctx.lineTo(x + w * k / 6, yy + 2); ctx.stroke(); }
    }
  });
  return { canvas, ax: 24, ay: 68 };
}

export function crystal() {
  const W = 64, H = 80;
  const canvas = make(W, H, (ctx) => {
    const glow = ctx.createRadialGradient(32, 50, 0, 32, 50, 32);
    glow.addColorStop(0, "rgba(255,180,70,0.5)"); glow.addColorStop(1, "rgba(255,180,70,0)");
    ctx.fillStyle = glow; ctx.fillRect(0, 10, W, 70);
    groundShadow(ctx, 32, 70, 16, 5, 0.4);
    for (const [x, top, w, lean] of [[32, 14, 8, 0], [20, 38, 5, -8], [44, 34, 6, 7], [27, 48, 4, -3]]) {
      ctx.fillStyle = "#d9831f"; ctx.strokeStyle = "#5a300a"; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(x - w, 70); ctx.lineTo(x - w + lean * 0.3, top + 8); ctx.lineTo(x + lean, top); ctx.lineTo(x + w + lean * 0.3, top + 8); ctx.lineTo(x + w, 70); ctx.closePath();
      ctx.fill(); ctx.stroke();
      ctx.fillStyle = "rgba(255,230,150,0.75)";
      ctx.beginPath(); ctx.moveTo(x - w * 0.4, 66); ctx.lineTo(x - w * 0.4 + lean * 0.3, top + 10); ctx.lineTo(x + lean * 0.8, top + 3); ctx.lineTo(x + lean * 0.1, 66); ctx.closePath(); ctx.fill();
    }
  });
  return { canvas, ax: 32, ay: 70 };
}

// Rope ladder going up through a shaft of daylight.
export function ladder() {
  const W = 48, H = 110;
  const canvas = make(W, H, (ctx) => {
    const light = ctx.createLinearGradient(0, 0, 0, H);
    light.addColorStop(0, "rgba(255,245,200,0.55)"); light.addColorStop(1, "rgba(255,245,200,0)");
    ctx.fillStyle = light;
    ctx.beginPath(); ctx.moveTo(8, 0); ctx.lineTo(40, 0); ctx.lineTo(46, H); ctx.lineTo(2, H); ctx.closePath(); ctx.fill();
    ctx.strokeStyle = "#6b4a2a"; ctx.lineWidth = 3;
    ctx.beginPath(); ctx.moveTo(14, 0); ctx.lineTo(14, 100); ctx.moveTo(34, 0); ctx.lineTo(34, 100); ctx.stroke();
    ctx.lineWidth = 4; ctx.strokeStyle = "#9a6e3e";
    for (let y = 12; y < 100; y += 14) { ctx.beginPath(); ctx.moveTo(14, y); ctx.lineTo(34, y + 1); ctx.stroke(); }
  });
  return { canvas, ax: 0, ay: 102 };
}

// A dark hole in the cave floor leading down.
export function hole() {
  const W = 56, H = 40;
  const canvas = make(W, H, (ctx) => {
    ctx.fillStyle = "#5a4f5a";
    ctx.beginPath(); ctx.ellipse(28, 22, 24, 14, 0, 0, Math.PI * 2); ctx.fill();
    const g = ctx.createRadialGradient(28, 24, 2, 28, 22, 22);
    g.addColorStop(0, "#000"); g.addColorStop(0.7, "#0a070b"); g.addColorStop(1, "#2a222b");
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.ellipse(28, 23, 20, 11, 0, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = "#6b4a2a"; ctx.lineWidth = 3;
    ctx.beginPath(); ctx.moveTo(22, 14); ctx.lineTo(22, 34); ctx.moveTo(34, 14); ctx.lineTo(34, 34); ctx.stroke();
    ctx.strokeStyle = "#9a6e3e";
    for (const y of [18, 25, 32]) { ctx.beginPath(); ctx.moveTo(22, y); ctx.lineTo(34, y); ctx.stroke(); }
  });
  return { canvas, ax: 4, ay: 38 };
}
