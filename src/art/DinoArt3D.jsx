import { useRef, useEffect } from "react";
import * as THREE from "three";
import { DINOS } from "../data/dinos.js";
import { makePalette, HEAD_SPRITES, HEAD_NECK_OFFSET, BODY_SPRITE, LEG_SPRITES } from "./sprites.jsx";

// ============ MAIN DINO COMPONENT ============
// ============ 3D VOXEL DINO (Three.js) ============
export function collectDinoPixels(build) {
  const color = build.customColor || DINOS[build.color]?.color || "#888";
  const palette = makePalette(color);
  const pixels = [];

  const addSprite = (data, offX, offY, z) => {
    for (let r = 0; r < data.length; r++) {
      for (let c = 0; c < data[r].length; c++) {
        const ch = data[r][c];
        const col = palette[ch];
        if (col) pixels.push({ x: offX + c, y: offY + r, z, color: col });
      }
    }
  };

  const headD = DINOS[build.head];
  const teethD = DINOS[build.teeth];
  const backD = DINOS[build.back];
  const frontD = DINOS[build.frontLegs];
  const backLegsD = DINOS[build.backLegs];
  const tailD = DINOS[build.tail];

  const bipedFams = ["tyrant", "spino", "raptor", "hadrosaur"];
  const quadFams = ["sauropod", "ceratopsian", "armored"];
  const posture = bipedFams.includes(backLegsD.family) ? "biped"
    : quadFams.includes(backLegsD.family) ? "quad"
    : backLegsD.family === "flyer" ? "flyer" : "marine";

  const bodyX = 18, bodyY = 20, bodyW = 31, bodyH = 16;

  // Body (thick: 3 layers)
  addSprite(BODY_SPRITE, bodyX, bodyY, -1);
  addSprite(BODY_SPRITE, bodyX, bodyY, 0);
  addSprite(BODY_SPRITE, bodyX, bodyY, 1);

  // ===== DORSAL FEATURES (sail, plates, spikes) =====
  const dorsalFamily = backD.family;
  const dorsalSpikes = backD.stats?.force || 5;
  if (dorsalFamily === "spino") {
    // Tall sail on back
    const sailH = 9 + Math.floor(dorsalSpikes / 2);
    for (let i = 0; i < sailH; i++) {
      const w = bodyW - 8 - Math.floor(Math.abs(i - sailH / 2) * 1.5);
      const sx = bodyX + 4 + Math.floor((bodyW - 8 - w) / 2);
      for (let c = 0; c < w; c++) {
        const col = (i === 0 || c === 0 || c === w - 1) ? palette.o : palette.s;
        pixels.push({ x: sx + c, y: bodyY - sailH + i, z: 0, color: col });
      }
    }
  } else if (dorsalFamily === "armored" && dorsalSpikes >= 6) {
    // Stego plates
    for (let p = 0; p < 5; p++) {
      const px = bodyX + 3 + p * 5;
      for (let dy = 0; dy < 4; dy++) {
        const w = dy < 2 ? 3 : 5;
        const sx = px - Math.floor(w / 2);
        for (let c = 0; c < w; c++) {
          const col = (dy === 0 || c === 0 || c === w - 1) ? palette.o : palette.l;
          pixels.push({ x: sx + c, y: bodyY - 4 + dy, z: 0, color: col });
        }
      }
    }
  } else if (dorsalFamily === "armored") {
    // Anky bumps
    for (let p = 0; p < 6; p++) {
      const px = bodyX + 2 + p * 4;
      pixels.push({ x: px, y: bodyY - 1, z: 0, color: palette.d });
      pixels.push({ x: px + 1, y: bodyY - 1, z: 0, color: palette.l });
      pixels.push({ x: px, y: bodyY - 2, z: 0, color: palette.o });
    }
  } else if (dorsalSpikes > 4) {
    // Generic spikes
    const n = Math.min(7, 3 + Math.floor(dorsalSpikes / 2));
    for (let i = 0; i < n; i++) {
      const px = bodyX + 3 + i * Math.floor((bodyW - 6) / n);
      const h = 2 + Math.floor(dorsalSpikes / 4);
      for (let dy = 0; dy < h; dy++) {
        pixels.push({ x: px, y: bodyY - h + dy, z: 0, color: dy === 0 ? palette.o : palette.s });
      }
    }
  }

  // ===== HEAD =====
  const headSprite = HEAD_SPRITES[headD.family] || HEAD_SPRITES.tyrant;
  const headOff = HEAD_NECK_OFFSET[headD.family] || { x: 1, y: 5 };
  const neckLen = headD.family === "sauropod" ? 16 : headD.family === "flyer" ? 6 : 7;
  const neckAngle = headD.family === "sauropod" && posture === "quad" ? -1.1 : -0.55;
  const neckStartX = bodyX + bodyW - 4;
  const neckStartY = bodyY + 2;
  const neckEndX = Math.floor(neckStartX + Math.cos(neckAngle) * neckLen);
  const neckEndY = Math.floor(neckStartY + Math.sin(neckAngle) * neckLen);
  const headX = neckEndX - headOff.x;
  const headY = neckEndY - headOff.y;

  // Neck (thicker, 3 layers)
  const nSteps = Math.max(Math.abs(neckEndX - neckStartX), Math.abs(neckEndY - neckStartY));
  for (let s = 0; s <= nSteps; s++) {
    const t = s / Math.max(1, nSteps);
    const nx = Math.round(neckStartX + (neckEndX - neckStartX) * t);
    const ny = Math.round(neckStartY + (neckEndY - neckStartY) * t);
    for (let z = -1; z <= 1; z++) {
      pixels.push({ x: nx, y: ny, z, color: z === 0 ? palette.b : palette.o });
      pixels.push({ x: nx, y: ny + 1, z, color: z === 0 ? palette.b : palette.o });
    }
  }

  // Head sprite (3 layers)
  addSprite(headSprite, headX, headY, -1);
  addSprite(headSprite, headX, headY, 0);
  addSprite(headSprite, headX, headY, 1);

  // ===== TEETH =====
  const teethCount = teethD.teeth?.count || 0;
  const teethSharp = teethD.teeth?.sharp || 0;
  if (teethCount > 0 && headD.family !== "flyer") {
    // Find mouth row in head sprite (row with 'm')
    let mouthRow = -1, mouthStartC = 99, mouthEndC = 0;
    headSprite.forEach((row, r) => {
      for (let c = 0; c < row.length; c++) {
        if (row[c] === 'm') {
          if (mouthRow === -1) mouthRow = r;
          mouthStartC = Math.min(mouthStartC, c);
          mouthEndC = Math.max(mouthEndC, c);
        }
      }
    });
    if (mouthRow >= 0) {
      const mw = mouthEndC - mouthStartC;
      const n = Math.min(mw, Math.max(2, teethCount + 1));
      const fangH = teethSharp > 7 ? 2 : 1;
      for (let i = 0; i < n; i++) {
        const tx = headX + mouthStartC + Math.floor(i * mw / n) + 1;
        const ty = headY + mouthRow - 1;
        for (let fh = 0; fh < fangH; fh++) {
          pixels.push({ x: tx, y: ty + fh, z: 0, color: palette.t });
          pixels.push({ x: tx, y: ty + fh, z: 1, color: palette.t });
        }
      }
    }
  }

  // ===== LEGS (4 legs: 2 front, 2 back) =====
  let frontLeg, backLeg;
  if (posture === "biped") {
    frontLeg = frontD.family === "tyrant" ? LEG_SPRITES.armTiny
      : (frontD.family === "raptor" || frontD.family === "spino") ? LEG_SPRITES.armClawed
      : LEG_SPRITES.armMedium;
    backLeg = backLegsD.family === "raptor" ? LEG_SPRITES.bipedFast
      : backLegsD.family === "hadrosaur" ? LEG_SPRITES.bipedHadro
      : LEG_SPRITES.bipedBig;
  } else if (posture === "quad") {
    frontLeg = LEG_SPRITES.quadColumn;
    backLeg = LEG_SPRITES.quadColumn;
  } else if (posture === "flyer") {
    frontLeg = LEG_SPRITES.wing;
    backLeg = LEG_SPRITES.armMedium;
  } else {
    frontLeg = LEG_SPRITES.flipper;
    backLeg = LEG_SPRITES.flipper;
  }

  const legY = bodyY + bodyH - 2;
  // Front legs: z=2 and z=-2
  addSprite(frontLeg, bodyX + bodyW - (frontLeg[0]?.length || 4) - 2, legY, 2);
  addSprite(frontLeg, bodyX + bodyW - (frontLeg[0]?.length || 4) - 2, legY, -2);
  // Back legs: z=3 and z=-3
  addSprite(backLeg, bodyX + 1, legY, 3);
  addSprite(backLeg, bodyX + 1, legY, -3);

  // ===== TAIL (procedural) =====
  const tailLen = 8 + Math.floor((tailD.tail?.length || 5) * 1.2);
  for (let i = 0; i < tailLen; i++) {
    const t = i / tailLen;
    const tx = bodyX - i + 2;
    const ty = bodyY + Math.floor(bodyH / 2) + Math.floor(t * t * 4);
    const thick = Math.max(1, Math.floor((1 - t) * 3));
    for (let j = 0; j < thick; j++) {
      const col = j === 0 ? palette.h : j === thick - 1 ? palette.f : palette.b;
      pixels.push({ x: tx, y: ty + j, z: 0, color: col });
      if (thick > 1) {
        pixels.push({ x: tx, y: ty + j, z: -1, color: palette.o });
        pixels.push({ x: tx, y: ty + j, z: 1, color: palette.o });
      }
    }
    // Armored tail club
    if (tailD.family === "armored" && t > 0.85) {
      for (let z = -1; z <= 1; z++) {
        pixels.push({ x: tx, y: ty - 1, z, color: palette.d });
        pixels.push({ x: tx, y: ty + thick, z, color: palette.d });
      }
    }
  }

  return pixels;
}

export function DinoArt3D({ build }) {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || typeof THREE === "undefined") return;

    const w = 400, h = 260;
    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
    renderer.setSize(w, h, false); // false = don't override CSS styles
    renderer.setClearColor(0x141810, 1);

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(30, w / h, 1, 500);
    camera.position.set(0, -5, 80);
    camera.lookAt(0, 0, 0);

    scene.add(new THREE.AmbientLight(0xffffff, 0.5));
    const sun = new THREE.DirectionalLight(0xffffff, 1);
    sun.position.set(5, 10, 15);
    scene.add(sun);

    // Collect pixels from all sprites
    const pixels = collectDinoPixels(build);
    const colorMap = {};
    pixels.forEach(p => {
      if (!colorMap[p.color]) colorMap[p.color] = [];
      colorMap[p.color].push(p);
    });

    const group = new THREE.Group();
    const box = new THREE.BoxGeometry(0.85, 0.85, 0.85);

    Object.entries(colorMap).forEach(([hex, pts]) => {
      const mat = new THREE.MeshLambertMaterial({ color: new THREE.Color(hex) });
      const inst = new THREE.InstancedMesh(box, mat, pts.length);
      const obj = new THREE.Object3D();
      pts.forEach((p, i) => {
        obj.position.set(p.x - 38, -(p.y - 28), p.z);
        obj.updateMatrix();
        inst.setMatrixAt(i, obj.matrix);
      });
      inst.instanceMatrix.needsUpdate = true;
      group.add(inst);
    });

    scene.add(group);

    let rotY = 0;
    let dragging = false;
    let lastX = 0;
    let af;

    const loop = () => {
      if (!dragging) rotY += 0.006;
      group.rotation.y = rotY;
      renderer.render(scene, camera);
      af = requestAnimationFrame(loop);
    };
    loop();

    const onDown = (e) => { dragging = true; lastX = (e.touches?.[0] || e).clientX; };
    const onMove = (e) => { if (!dragging) return; const x = (e.touches?.[0] || e).clientX; rotY += (x - lastX) * 0.01; lastX = x; };
    const onUp = () => { dragging = false; };

    canvas.addEventListener("mousedown", onDown);
    canvas.addEventListener("touchstart", onDown, { passive: true });
    window.addEventListener("mousemove", onMove);
    window.addEventListener("touchmove", onMove, { passive: true });
    window.addEventListener("mouseup", onUp);
    window.addEventListener("touchend", onUp);

    return () => {
      cancelAnimationFrame(af);
      canvas.removeEventListener("mousedown", onDown);
      canvas.removeEventListener("touchstart", onDown);
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("touchmove", onMove);
      window.removeEventListener("mouseup", onUp);
      window.removeEventListener("touchend", onUp);
      renderer.dispose();
    };
  }, [build.head, build.teeth, build.frontLegs, build.backLegs, build.back, build.tail, build.color, build.customColor]);

  if (typeof THREE === "undefined") {
    return <div style={{ padding: "20px", textAlign: "center", opacity: 0.5 }}>3D non disponible</div>;
  }

  return <canvas ref={canvasRef} width={400} height={260} style={{ width: "100%", height: "auto", display: "block", borderRadius: "8px" }} />;
}
