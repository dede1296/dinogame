// Registers the canvas-drawn art as Phaser textures, on demand.

import * as props from "../art/propArt.js";
import { building, furniture } from "../art/buildingArt.js";
import { characterSheet, FRAME_W, FRAME_H, DIRS } from "../art/characterArt.js";
import { buildDino } from "../art/dinoArt.js";
import { buildDinoView } from "../art/dinoViews.js";

// Anchor (origin) of every generated texture, so sprites can be placed by their base.
export const anchors = {};

function addCanvas(scene, key, { canvas, ax, ay }) {
  if (!scene.textures.exists(key)) {
    scene.textures.addCanvas(key, canvas);
    anchors[key] = { x: ax / canvas.width, y: ay / canvas.height };
  }
  return key;
}

export function propTexture(scene, kind, variant = 0) {
  const key = `prop-${kind}-${variant}`;
  if (scene.textures.exists(key)) return key;
  const factory = {
    tree: () => props.tree(variant),
    pine: () => props.pine(variant),
    bush: () => props.bush(variant),
    rock: () => props.rock(variant),
    tallgrass: () => props.tallGrass(variant),
    fence: () => props.fence(),
    sign: () => props.sign(),
    boulder: () => props.boulder(),
    log: () => props.log(variant || 2),
    cave: () => props.caveMouth(),
    skull: () => props.skull(),
    boat: () => props.boat(),
    orb: () => props.itemOrb(),
    sparkle: () => props.sparkle(),
  }[kind];
  return addCanvas(scene, key, factory());
}

export function buildingTexture(scene, kind, w, h) {
  const key = `bld-${kind}-${w}x${h}`;
  if (scene.textures.exists(key)) return key;
  return addCanvas(scene, key, building(kind, w, h));
}

export function furnitureTexture(scene, kind, w, h) {
  const key = `fur-${kind}-${w}x${h}`;
  if (scene.textures.exists(key)) return key;
  return addCanvas(scene, key, furniture(kind, w, h));
}

export function butterflyTexture(scene, color, i) {
  const key = `butterfly-${i}`;
  if (!scene.textures.exists(key)) scene.textures.addCanvas(key, props.butterfly(color));
  return key;
}

// Character sheet: frames named `${dir}-${n}`.
export function characterTexture(scene, look) {
  const key = `chr-${look}`;
  if (scene.textures.exists(key)) return key;
  const tex = scene.textures.addCanvas(key, characterSheet(look));
  DIRS.forEach((dir, row) => {
    for (let n = 0; n < 3; n++) tex.add(`${dir}-${n}`, 0, n * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H);
  });
  anchors[key] = { x: 0.5, y: 62 / FRAME_H };
  return key;
}

// Rasterizes a dino (vector art) at a given height; resolves with the texture key.
// `size` is the image height in px; with options.unitScale a fixed px-per-unit scale
// is used instead, so the side/front/back views of one dino match in size.
// options.view: "side" (default), "front" or "back".
export function dinoTexture(scene, build, size, options = {}) {
  const view = options.view || "side";
  const sizeKey = options.fit ? `${options.fit.w}x${options.fit.h}` : options.unitScale || size;
  const key = `dino-${view}-${Object.values(build).join("-")}-${sizeKey}-${options.pattern || "none"}`;
  if (scene.textures.exists(key)) return Promise.resolve(key);
  const id = key.replace(/[^\w]/g, "");
  const dino = view === "side" ? buildDino(build, { ...options, id }) : buildDinoView(build, view, { ...options, id });
  const [, , vw, vh] = dino.viewBox;
  // options.fit = { w, h }: the largest size fitting that box, keeping proportions.
  const height = options.fit
    ? Math.round(Math.min(options.fit.h, (options.fit.w * vh) / vw))
    : options.unitScale ? Math.round(vh * options.unitScale) : size;
  const width = Math.round((vw / vh) * height);
  const svg = dino.svg.replace("<svg ", `<svg width="${width}" height="${height}" `);
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      if (!scene.textures.exists(key)) scene.textures.addImage(key, img);
      // The dino stands on its ground line inside the viewBox.
      anchors[key] = { x: (0 - dino.viewBox[0]) / vw, y: (dino.ground - dino.viewBox[1]) / vh };
      resolve(key);
    };
    img.onerror = () => resolve(null);
    img.src = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svg);
  });
}
