// Walking character sprite sheets, drawn on canvas.
// Sheet layout: 4 rows (down, left, right, up) × 3 columns (stand, step A, step B),
// each frame FRAME_W × FRAME_H with the feet at the bottom center.

export const FRAME_W = 48;
export const FRAME_H = 64;
export const DIRS = ["down", "left", "right", "up"];

const OUT = "#2a1a10";

// `scale`: adults 1, Chloé (12 years old) a bit smaller, the little boy smaller still.
export const LOOKS = {
  chloe: { scale: 0.88, skin: "#f1c7a3", hair: "#9a4320", hairStyle: "ponytail", top: "#2f8f8a", vest: "#c9a86a", bottom: "#4f5f3a", shoes: "#6b4526", pack: "#b8742a" },
  professor: { skin: "#eac09a", hair: "#c9c6c0", hairStyle: "bald", top: "#f4f1ea", coat: true, bottom: "#5a5f66", shoes: "#3a2a1a", glasses: true, beard: "#c9c6c0" },
  maia: { skin: "#a8704a", hair: "#1e1410", hairStyle: "curly", bandana: "#c0392b", top: "#e0a030", bottom: "#2f4f7a", shoes: "#3a2a1a" },
  fisher: { skin: "#e2b08a", hair: "#6a4a30", hairStyle: "short", hat: "#2f4f7a", top: "#e8c230", bottom: "#3a4a5a", shoes: "#2a2a2a", beard: "#6a4a30" },
  kid: { skin: "#f5d0b0", hair: "#e8c060", hairStyle: "short", top: "#d04a4a", stripes: "#f4f1ea", bottom: "#3a5a8a", shoes: "#f4f1ea", scale: 0.78 },
  elder: { skin: "#eac5a5", hair: "#f0ede6", hairStyle: "bun", top: "#7a4a8a", shawl: true, bottom: "#5a4a6a", shoes: "#3a2a1a" },
  grunt: { skin: "#d9b294", hair: "#1c1622", hairStyle: "hood", top: "#2a2230", bottom: "#1c1822", shoes: "#141014", mask: "#5a2a7a", sash: "#8a3fc0" },
  hiker: { skin: "#d8a47e", hair: "#3a2a1a", hairStyle: "short", hat: "#4f7a3a", top: "#b8a070", bottom: "#6a5a3a", shoes: "#4a3020", pack: "#4f6a3a", bigPack: true },
};

function rr(ctx, x, y, w, h, r, fill, stroke = OUT, lw = 2) {
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, r);
  ctx.fillStyle = fill;
  ctx.fill();
  if (stroke) { ctx.strokeStyle = stroke; ctx.lineWidth = lw; ctx.stroke(); }
}

function ellipse(ctx, x, y, rx, ry, fill, stroke = OUT, lw = 2) {
  ctx.beginPath();
  ctx.ellipse(x, y, rx, ry, 0, 0, Math.PI * 2);
  ctx.fillStyle = fill;
  ctx.fill();
  if (stroke) { ctx.strokeStyle = stroke; ctx.lineWidth = lw; ctx.stroke(); }
}

function drawFrame(ctx, look, dir, frame) {
  const s = look.scale || 1;
  ctx.save();
  ctx.translate(24, 62);
  ctx.scale(s, s);
  ctx.translate(-24, -62);

  const side = dir === "left" || dir === "right";
  const flip = dir === "left";
  if (flip) { ctx.translate(48, 0); ctx.scale(-1, 1); }
  const step = frame === 0 ? 0 : frame === 1 ? 1 : -1;
  const bob = frame === 0 ? 0 : -1;

  // Shadow.
  ctx.fillStyle = "rgba(10,20,5,0.3)";
  ctx.beginPath(); ctx.ellipse(24, 60, 13, 4, 0, 0, Math.PI * 2); ctx.fill();

  ctx.translate(0, bob);

  // Big backpack seen from behind or the side.
  if (look.pack && (dir === "up" || side)) {
    const pw = look.bigPack ? 22 : 18, ph = look.bigPack ? 22 : 16;
    if (dir === "up") rr(ctx, 24 - pw / 2, 28, pw, ph, 5, look.pack);
    else rr(ctx, 8, 29, 11, ph, 4, look.pack);
  }

  // Legs.
  if (side) {
    rr(ctx, 17 + step * 4, 44, 7, 14, 3, look.bottom);
    rr(ctx, 24 - step * 4, 44, 7, 14, 3, look.bottom);
    rr(ctx, 15 + step * 5, 55, 10, 5, 2, look.shoes);
    rr(ctx, 22 - step * 5, 55, 10, 5, 2, look.shoes);
  } else {
    rr(ctx, 16, 44 - (step > 0 ? 2 : 0), 7, 14, 3, look.bottom);
    rr(ctx, 25, 44 - (step < 0 ? 2 : 0), 7, 14, 3, look.bottom);
    rr(ctx, 15, 55 - (step > 0 ? 2 : 0), 9, 5, 2, look.shoes);
    rr(ctx, 24, 55 - (step < 0 ? 2 : 0), 9, 5, 2, look.shoes);
  }

  // Torso.
  const torsoColor = look.coat ? look.top : look.top;
  rr(ctx, 13, 29, 22, 18, 6, torsoColor);
  if (look.stripes) {
    ctx.fillStyle = look.stripes;
    for (const y of [33, 38, 43]) ctx.fillRect(14, y, 20, 2);
  }
  if (look.vest && dir !== "up") {
    ctx.fillStyle = look.vest;
    ctx.fillRect(side ? 20 : 14, 30, side ? 14 : 6, 15);
    if (!side) ctx.fillRect(28, 30, 6, 15);
    ctx.fillStyle = "rgba(0,0,0,0.2)";
    if (!side) { ctx.fillRect(15, 38, 4, 3); ctx.fillRect(29, 38, 4, 3); }
  }
  if (look.coat) {
    ctx.fillStyle = "#dcd6c8";
    ctx.fillRect(13, 43, 22, 6);
    ctx.strokeStyle = OUT; ctx.lineWidth = 2;
    ctx.strokeRect(13, 43, 22, 6);
    if (dir === "down") { ctx.beginPath(); ctx.moveTo(24, 30); ctx.lineTo(24, 48); ctx.stroke(); }
  }
  if (look.shawl) rr(ctx, 12, 28, 24, 9, 4, "#c0a0d0");
  if (look.sash) {
    ctx.fillStyle = look.sash;
    ctx.save(); ctx.beginPath(); ctx.roundRect(13, 29, 22, 18, 6); ctx.clip();
    ctx.beginPath(); ctx.moveTo(13, 30); ctx.lineTo(18, 30); ctx.lineTo(35, 44); ctx.lineTo(35, 48); ctx.closePath(); ctx.fill();
    ctx.restore();
  }
  if (look.pack && dir === "down") {
    ctx.fillStyle = look.pack;
    ctx.fillRect(14, 30, 3, 14); ctx.fillRect(31, 30, 3, 14);
  }

  // Arms swing opposite to the legs.
  if (side) {
    rr(ctx, 21 - step * 4, 31, 7, 13, 3, look.coat ? look.top : look.skin);
  } else {
    rr(ctx, 8, 31 + step, 6, 13, 3, look.coat ? look.top : look.skin);
    rr(ctx, 34, 31 - step, 6, 13, 3, look.coat ? look.top : look.skin);
    if (look.coat) { ellipse(ctx, 11, 45 + step, 3, 3, look.skin); ellipse(ctx, 37, 45 - step, 3, 3, look.skin); }
  }

  // Head.
  ellipse(ctx, 24, 18, 13, 12.5, look.skin);

  // Hair.
  const hair = look.hair;
  ctx.fillStyle = hair;
  ctx.strokeStyle = OUT;
  ctx.lineWidth = 2;
  if (look.hairStyle === "hood") {
    // Hood: a dark shell around the face (evenodd cut-out), full from behind.
    ctx.beginPath();
    if (dir === "up") ctx.ellipse(24, 17, 15, 14.5, 0, 0, Math.PI * 2);
    else {
      ctx.moveTo(8, 30); ctx.bezierCurveTo(6, 8, 14, 1, 24, 1); ctx.bezierCurveTo(34, 1, 42, 8, 40, 30); ctx.closePath();
      if (side) ctx.ellipse(28, 20, 9, 9.5, 0, 0, Math.PI * 2);
      else ctx.ellipse(24, 20, 10.5, 10, 0, 0, Math.PI * 2);
    }
    ctx.fill("evenodd");
    ctx.stroke();
  } else if (look.hairStyle === "bald") {
    ctx.beginPath(); ctx.ellipse(24, 14, 13, 5, 0, Math.PI, 0); ctx.fill();
    if (dir !== "up") { ctx.beginPath(); ctx.ellipse(side ? 16 : 13, 18, 3, 5, 0, 0, Math.PI * 2); ctx.fill(); if (!side) { ctx.beginPath(); ctx.ellipse(35, 18, 3, 5, 0, 0, Math.PI * 2); ctx.fill(); } }
  } else {
    ctx.beginPath();
    if (dir === "up") ctx.ellipse(24, 17, 13.5, 13, 0, 0, Math.PI * 2);
    else if (side) { ctx.ellipse(21, 13, 13, 9, -0.2, Math.PI * 0.95, Math.PI * 2.1); ctx.lineTo(12, 22); }
    else { ctx.ellipse(24, 12, 13.5, 8.5, 0, Math.PI, 0); ctx.lineTo(37, 17); ctx.quadraticCurveTo(30, 11, 24, 13); ctx.quadraticCurveTo(18, 11, 11, 17); }
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    if (look.hairStyle === "ponytail") {
      const px = dir === "up" ? 24 : side ? 9 : 24, py = dir === "up" ? 26 : side ? 16 : 6;
      if (dir !== "down") { ellipse(ctx, px, py + 6, 5, 9, hair); }
      else { ellipse(ctx, 34, 8, 4, 4, hair); }
      ellipse(ctx, dir === "up" ? 24 : side ? 11 : 34, dir === "up" ? 24 : side ? 12 : 9, 2.5, 2, "#2f8f8a", OUT, 1.5);
    }
    if (look.hairStyle === "curly") {
      for (const [x, y] of [[13, 12], [18, 7], [24, 5], [30, 7], [35, 12]]) ellipse(ctx, x, y, 4.5, 4.5, hair, null);
    }
    if (look.hairStyle === "bun") ellipse(ctx, 24, 4, 6, 5, hair);
  }
  if (look.bandana) {
    rr(ctx, 11, 8, 26, 5, 2, look.bandana);
    if (dir !== "down") { ellipse(ctx, side ? 10 : 24, 12, 3, 3, look.bandana); }
  }
  if (look.hat) {
    rr(ctx, 9, 7, 30, 5, 2, look.hat);
    ctx.beginPath(); ctx.ellipse(24, 8, 11, 7, 0, Math.PI, 0); ctx.fillStyle = look.hat; ctx.fill(); ctx.stroke();
    if (dir === "down" || side) rr(ctx, side ? 24 : 16, 9, side ? 16 : 16, 4, 2, look.hat);
  }

  // Face.
  if (dir !== "up") {
    const ex = side ? [30] : [19, 29];
    for (const x of ex) {
      ellipse(ctx, x, 20, 2.2, 3, "#1a0e08", null);
      ellipse(ctx, x - 0.6, 18.8, 0.8, 0.8, "#fff", null);
    }
    if (look.glasses) {
      ctx.strokeStyle = "#3a3a3a"; ctx.lineWidth = 1.5;
      for (const x of ex) { ctx.beginPath(); ctx.arc(x, 20, 4, 0, Math.PI * 2); ctx.stroke(); }
      if (!side) { ctx.beginPath(); ctx.moveTo(23, 20); ctx.lineTo(25, 20); ctx.stroke(); }
    }
    if (look.mask) {
      // Obsidian half-mask with glowing violet eye slits.
      rr(ctx, side ? 22 : 12, 15, side ? 15 : 24, 9, 4, look.mask);
      ctx.fillStyle = "#e6b8ff";
      for (const x of ex) { ctx.beginPath(); ctx.ellipse(x, 19.5, 2.6, 1.3, 0, 0, Math.PI * 2); ctx.fill(); }
    }
    ctx.fillStyle = "rgba(230,110,100,0.35)";
    if (!side && !look.mask) { ctx.beginPath(); ctx.arc(16, 25, 2.5, 0, Math.PI * 2); ctx.arc(32, 25, 2.5, 0, Math.PI * 2); ctx.fill(); }
    if (look.beard) {
      ctx.fillStyle = look.beard;
      ctx.beginPath(); ctx.ellipse(side ? 28 : 24, 27, side ? 7 : 9, 5, 0, 0, Math.PI); ctx.fill();
    } else {
      ctx.strokeStyle = "#7a3a2a"; ctx.lineWidth = 1.4;
      ctx.beginPath(); ctx.arc(side ? 31 : 24, 25, 2, 0.2, Math.PI - 0.2); ctx.stroke();
    }
  }
  ctx.restore();
}

export function characterSheet(lookId) {
  const look = LOOKS[lookId] || LOOKS.chloe;
  const canvas = document.createElement("canvas");
  canvas.width = FRAME_W * 3;
  canvas.height = FRAME_H * 4;
  const ctx = canvas.getContext("2d");
  DIRS.forEach((dir, row) => {
    for (let frame = 0; frame < 3; frame++) {
      ctx.save();
      ctx.translate(frame * FRAME_W, row * FRAME_H);
      drawFrame(ctx, look, dir, frame);
      ctx.restore();
    }
  });
  return canvas;
}
