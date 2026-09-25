// Battle arena backdrops, painted on a canvas at screen resolution.

import { hash } from "../world/mapBuilder.js";

const THEMES = {
  plaines: {
    sky: ["#7ec2e6", "#bfe3ee", "#f3e9c8"],
    far: "#8aa8a0", mid: "#5d8a4a", ground: ["#6a9c40", "#4c7f2c"], platform: ["#8cbc55", "#5e8f35"], accent: "#f2c94c",
  },
};

export function paintArena(width, height, zone = "plaines") {
  const t = THEMES[zone] || THEMES.plaines;
  const c = document.createElement("canvas");
  c.width = width;
  c.height = height;
  const ctx = c.getContext("2d");
  const W = width, H = height, horizon = H * 0.5;

  // Sky with a warm glow near the horizon.
  const sky = ctx.createLinearGradient(0, 0, 0, horizon);
  sky.addColorStop(0, t.sky[0]); sky.addColorStop(0.7, t.sky[1]); sky.addColorStop(1, t.sky[2]);
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, W, horizon + 2);
  const sun = ctx.createRadialGradient(W * 0.78, horizon * 0.35, 4, W * 0.78, horizon * 0.35, W * 0.35);
  sun.addColorStop(0, "rgba(255,248,215,0.95)"); sun.addColorStop(0.15, "rgba(255,240,190,0.55)"); sun.addColorStop(1, "rgba(255,240,190,0)");
  ctx.fillStyle = sun;
  ctx.fillRect(0, 0, W, horizon);
  // Clouds.
  for (let i = 0; i < 5; i++) {
    const cx = hash(i, 1, 70) * W, cy = horizon * (0.12 + hash(i, 2, 70) * 0.35), s = W * (0.06 + hash(i, 3, 70) * 0.06);
    ctx.fillStyle = "rgba(255,255,255,0.75)";
    for (let k = 0; k < 5; k++) { ctx.beginPath(); ctx.ellipse(cx + (k - 2) * s * 0.7, cy + Math.sin(k * 1.7) * s * 0.15, s * 0.75, s * 0.45, 0, 0, Math.PI * 2); ctx.fill(); }
  }
  // Distant volcano and mountains.
  ctx.fillStyle = t.far;
  ctx.beginPath();
  ctx.moveTo(0, horizon);
  for (let x = 0; x <= W; x += W / 14) ctx.lineTo(x, horizon - H * (0.06 + hash(x | 0, 4, 71) * 0.08));
  ctx.lineTo(W, horizon); ctx.closePath(); ctx.fill();
  ctx.fillStyle = "#6f8a86";
  ctx.beginPath();
  ctx.moveTo(W * 0.08, horizon); ctx.lineTo(W * 0.24, horizon - H * 0.22); ctx.lineTo(W * 0.3, horizon - H * 0.21); ctx.lineTo(W * 0.46, horizon); ctx.closePath(); ctx.fill();
  ctx.fillStyle = "rgba(200,210,215,0.5)";
  ctx.beginPath(); ctx.ellipse(W * 0.27, horizon - H * 0.26, W * 0.05, H * 0.03, 0, 0, Math.PI * 2); ctx.fill();
  // Tree line.
  for (let i = 0; i < 40; i++) {
    const x = (i / 40) * W + hash(i, 5, 72) * 20, r = W * (0.025 + hash(i, 6, 72) * 0.025);
    ctx.fillStyle = i % 3 ? t.mid : "#4a7a3a";
    ctx.beginPath(); ctx.arc(x, horizon - r * 0.4, r, 0, Math.PI * 2); ctx.fill();
  }
  // Ground.
  const g = ctx.createLinearGradient(0, horizon, 0, H);
  g.addColorStop(0, t.ground[0]); g.addColorStop(1, t.ground[1]);
  ctx.fillStyle = g;
  ctx.fillRect(0, horizon - 2, W, H - horizon + 2);
  // Soft haze between sky and ground.
  const haze = ctx.createLinearGradient(0, horizon - H * 0.05, 0, horizon + H * 0.08);
  haze.addColorStop(0, "rgba(240,240,220,0)"); haze.addColorStop(0.5, "rgba(240,240,220,0.35)"); haze.addColorStop(1, "rgba(240,240,220,0)");
  ctx.fillStyle = haze;
  ctx.fillRect(0, horizon - H * 0.05, W, H * 0.13);
  // Grass strokes, denser toward the camera.
  for (let i = 0; i < 700; i++) {
    const y = horizon + Math.pow(hash(i, 7, 73), 0.7) * (H - horizon);
    const x = hash(i, 8, 73) * W, s = 3 + ((y - horizon) / (H - horizon)) * 9;
    ctx.strokeStyle = hash(i, 9, 73) < 0.5 ? "rgba(40,80,20,0.5)" : "rgba(150,200,90,0.45)";
    ctx.lineWidth = 1 + s * 0.12;
    ctx.beginPath(); ctx.moveTo(x, y); ctx.quadraticCurveTo(x + s * 0.2, y - s * 0.6, x + s * 0.35, y - s); ctx.stroke();
  }
  return c;
}

// Grassy platform a dino stands on.
export function paintPlatform(width) {
  const t = THEMES.plaines;
  const h = width * 0.26;
  const c = document.createElement("canvas");
  c.width = width;
  c.height = h * 1.4;
  const ctx = c.getContext("2d");
  const cx = width / 2, cy = h * 0.55;
  ctx.fillStyle = "rgba(20,40,10,0.35)";
  ctx.beginPath(); ctx.ellipse(cx, cy + h * 0.18, width * 0.49, h * 0.45, 0, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = "#6b5236";
  ctx.beginPath(); ctx.ellipse(cx, cy + h * 0.1, width * 0.48, h * 0.42, 0, 0, Math.PI * 2); ctx.fill();
  const g = ctx.createRadialGradient(cx - width * 0.1, cy - h * 0.1, 4, cx, cy, width * 0.5);
  g.addColorStop(0, t.platform[0]); g.addColorStop(1, t.platform[1]);
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.ellipse(cx, cy, width * 0.47, h * 0.38, 0, 0, Math.PI * 2); ctx.fill();
  for (let i = 0; i < 70; i++) {
    const a = hash(i, 1, 74) * Math.PI * 2, r = Math.sqrt(hash(i, 2, 74));
    const x = cx + Math.cos(a) * r * width * 0.44, y = cy + Math.sin(a) * r * h * 0.34;
    ctx.strokeStyle = hash(i, 3, 74) < 0.5 ? "rgba(50,90,25,0.6)" : "rgba(190,230,120,0.5)";
    ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + 2, y - 6); ctx.stroke();
  }
  return { canvas: c, footY: cy };
}

// Soft round particle, tinted at runtime.
export function paintSpark() {
  const c = document.createElement("canvas");
  c.width = c.height = 32;
  const ctx = c.getContext("2d");
  const g = ctx.createRadialGradient(16, 16, 0, 16, 16, 16);
  g.addColorStop(0, "rgba(255,255,255,1)"); g.addColorStop(0.4, "rgba(255,255,255,0.7)"); g.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, 32, 32);
  return c;
}
