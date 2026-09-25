// Battle arena backdrops, painted on a canvas at screen resolution.

import { hash } from "../world/mapBuilder.js";

const THEMES = {
  plaines: {
    sky: ["#7ec2e6", "#bfe3ee", "#f3e9c8"],
    far: "#8aa8a0", mid: "#5d8a4a", ground: ["#6a9c40", "#4c7f2c"], platform: ["#8cbc55", "#5e8f35"], accent: "#f2c94c",
  },
};

export function paintArena(width, height, zone = "plaines") {
  if (zone === "grotte") return paintCave(width, height);
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

// Grotte des Échos: dark rock, stalactites, glowing amber veins.
function paintCave(W, H) {
  const c = document.createElement("canvas");
  c.width = W; c.height = H;
  const ctx = c.getContext("2d");
  const horizon = H * 0.5;
  const back = ctx.createLinearGradient(0, 0, 0, horizon);
  back.addColorStop(0, "#0d0a10"); back.addColorStop(1, "#2a2230");
  ctx.fillStyle = back;
  ctx.fillRect(0, 0, W, horizon + 2);
  // Rock columns receding into the dark.
  for (let layer = 0; layer < 3; layer++) {
    ctx.fillStyle = ["#1a1520", "#241d2a", "#2f2735"][layer];
    for (let i = 0; i < 9; i++) {
      const x = (i / 8) * W + (hash(i, layer, 80) - 0.5) * W * 0.12, w = W * (0.05 + hash(i, layer + 3, 80) * 0.06);
      ctx.beginPath();
      ctx.moveTo(x - w, horizon + 4);
      ctx.bezierCurveTo(x - w * 0.6, horizon * 0.6, x - w * 0.8, horizon * 0.3, x - w * 0.4, 0);
      ctx.lineTo(x + w * 0.5, 0);
      ctx.bezierCurveTo(x + w * 0.9, horizon * 0.35, x + w * 0.5, horizon * 0.65, x + w, horizon + 4);
      ctx.fill();
    }
  }
  // Stalactites.
  for (let i = 0; i < 26; i++) {
    const x = hash(i, 1, 81) * W, w = 6 + hash(i, 2, 81) * 18, h = H * (0.05 + hash(i, 3, 81) * 0.14);
    ctx.fillStyle = i % 2 ? "#3a3040" : "#2c2432";
    ctx.beginPath(); ctx.moveTo(x - w, 0); ctx.quadraticCurveTo(x - w * 0.2, h * 0.6, x, h); ctx.quadraticCurveTo(x + w * 0.2, h * 0.6, x + w, 0); ctx.fill();
  }
  // Amber crystals glowing in the walls.
  for (let i = 0; i < 9; i++) {
    const x = hash(i, 4, 82) * W, y = horizon * (0.35 + hash(i, 5, 82) * 0.6), r = 5 + hash(i, 6, 82) * 8;
    const g = ctx.createRadialGradient(x, y, 0, x, y, r * 6);
    g.addColorStop(0, "rgba(255,170,60,0.45)"); g.addColorStop(1, "rgba(255,170,60,0)");
    ctx.fillStyle = g; ctx.fillRect(x - r * 6, y - r * 6, r * 12, r * 12);
    ctx.fillStyle = "#f2a83a";
    ctx.beginPath(); ctx.moveTo(x, y - r * 1.6); ctx.lineTo(x + r * 0.6, y); ctx.lineTo(x, y + r * 0.5); ctx.lineTo(x - r * 0.6, y); ctx.closePath(); ctx.fill();
    ctx.fillStyle = "#ffe2a0";
    ctx.beginPath(); ctx.moveTo(x, y - r * 1.2); ctx.lineTo(x + r * 0.25, y - r * 0.2); ctx.lineTo(x - r * 0.2, y - r * 0.1); ctx.closePath(); ctx.fill();
  }
  // Floor.
  const g = ctx.createLinearGradient(0, horizon, 0, H);
  g.addColorStop(0, "#3a3238"); g.addColorStop(1, "#211c22");
  ctx.fillStyle = g;
  ctx.fillRect(0, horizon - 2, W, H - horizon + 2);
  for (let i = 0; i < 260; i++) {
    const y = horizon + Math.pow(hash(i, 7, 83), 0.7) * (H - horizon);
    const x = hash(i, 8, 83) * W, s = 2 + ((y - horizon) / (H - horizon)) * 7;
    ctx.fillStyle = hash(i, 9, 83) < 0.5 ? "rgba(15,10,18,0.5)" : "rgba(120,105,115,0.35)";
    ctx.beginPath(); ctx.ellipse(x, y, s, s * 0.45, 0, 0, Math.PI * 2); ctx.fill();
  }
  // Mist near the floor.
  const mist = ctx.createLinearGradient(0, horizon - H * 0.04, 0, horizon + H * 0.1);
  mist.addColorStop(0, "rgba(150,120,170,0)"); mist.addColorStop(0.5, "rgba(150,120,170,0.18)"); mist.addColorStop(1, "rgba(150,120,170,0)");
  ctx.fillStyle = mist;
  ctx.fillRect(0, horizon - H * 0.04, W, H * 0.14);
  return c;
}

// Platform a dino stands on (grass outside, bare stone in caves).
export function paintPlatform(width, zone = "plaines") {
  const t = zone === "grotte" ? { platform: ["#6a5e66", "#3a3238"] } : THEMES.plaines;
  const cave = zone === "grotte";
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
    ctx.strokeStyle = cave ? (hash(i, 3, 74) < 0.5 ? "rgba(20,15,22,0.5)" : "rgba(170,150,160,0.35)") : hash(i, 3, 74) < 0.5 ? "rgba(50,90,25,0.6)" : "rgba(190,230,120,0.5)";
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
