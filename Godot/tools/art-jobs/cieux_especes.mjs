// Chapitre 7 — Les Cieux Éternels : les 5 espèces (profil 3×2 + face/dos 4×2).
// Même méthode que monts.mjs : nano-banana édite la planche du Ptéranodon (référence de style et de
// grille, fond magenta) avec l'anatomie réelle de l'espèce dans le prompt ; la planche face/dos part de
// la planche de profil de l'espèce (+ celle du Ptéranodon pour la grille). Format : scratchpad ch7
// specs_planches.md (agent mécaniques). Les sources sont dans generated_imgs/ (id = fin du nom).
import fs from "node:fs";
import path from "node:path";

// [nom, id du profil, hauteur d'image du profil]
const PROFILES = [
  ["rhamphorhynchus", "ype7ub", 150],
  ["tapejara", "5zr69e", 180],
  ["tupandactylus", "ntaycf", 190],
  ["hatzegopteryx", "xhxtdj", 215],
  ["quetzalcoatlus", "q46dmn", 220],
];
// Face (rangée 1) et dos (rangée 2). `cols` = nombre de colonnes réellement dessinées par rangée,
// `pick` = les 4 colonnes gardées par rangée (nano-banana a parfois dessiné 6 colonnes au lieu de 4,
// ou recopié la vue de profil dans une case : on recompose une planche 4×2 propre). 2e passe (retouches
// demandées 11/10) : rhamphorhynchus (queue en losange tendue, dents), tapejara (crête de face courte),
// hatzegopteryx (crâne de face et de dos), quetzalcoatlus (ailes grises) sont sorties à 4 colonnes.
const FACE_DOS = {
  rhamphorhynchus: { id: "h76haj" },
  tapejara: { id: "qgwh6r" },
  tupandactylus: { id: "u0jsuk", cols: [4, 6], pick: [[0, 1, 2, 3], [1, 2, 4, 5]] },
  hatzegopteryx: { id: "medpgo" },
  quetzalcoatlus: { id: "4lzion" },
};

// Vol de profil, 4 images : ailes hautes, à plat, basses, à plat (cycle de battement). Source : une ligne de
// 4 poses en vol par espèce (nano-banana, 4:1, éditée depuis la planche de profil). La 2e pose (ailes
// mi-hautes) sortait à chaque essai avec un filé rose flou : écartée, le plané la remplace en 4e image.
// pick = [[ligne, colonne], …] dans la grille source (rows × cols), 4 entrées.
const VOL = {
  quetzalcoatlus: { id: "zy42m0", rows: 1, cols: 4, pick: [[0, 0], [0, 2], [0, 3], [0, 2]] },
  hatzegopteryx: { id: "f00025", rows: 1, cols: 4, pick: [[0, 0], [0, 2], [0, 3], [0, 2]] },
  tupandactylus: { id: "awphss", rows: 1, cols: 4, pick: [[0, 0], [0, 2], [0, 3], [0, 2]] },
  tapejara: { id: "iqe93z", rows: 1, cols: 4, pick: [[0, 0], [0, 2], [0, 3], [0, 2]] },
};
// Vol de face (rangée 1) et de dos (rangée 2), 4 colonnes : ailes en V, plané, ailes basses, plané.
// Échelle : le corps (hauteur de la pose en plané, tête aux pattes) est calé à ±1 % sur celui du profil
// en vol de la même espèce (`<id>_vol.png`, 2e image) ; la cellule est la plus petite qui contienne tout.
const VOL_FACE_DOS = {
  quetzalcoatlus: "4dhns0", hatzegopteryx: "cz9vfe", tupandactylus: "6ftu5n", tapejara: "iy3cfe", pteranodon: "d6hoyx",
};
const VOL_CELL = [380, 230];   // cellule de sortie ; frameHeight 215 = la plus haute pose

export default ({ sheet, sharp, find, OUT }) => {
  const profileDone = {};
  const jobs = [];
  for (const [name, id, frameHeight] of PROFILES) {
    const out = `${OUT}/dinos/${name}.png`;
    profileDone[name] = null;
    jobs.push([out, async (o) => { profileDone[name] = sheet({ id, rows: 2, cols: 3, frameHeight, align: "bottom", isolate: true, out: o }); return profileDone[name]; }]);
  }
  for (const [name, , frameHeight] of PROFILES) {
    const spec = FACE_DOS[name];
    jobs.push([`${OUT}/dinos/${name}_face_dos.png`, async (out) => {
      const profile = `${OUT}/dinos/${name}.png`;
      if (!fs.existsSync(profile)) throw new Error(`${name} : produire d'abord le profil (${profile})`);
      const meta = await sharp(profile).metadata();
      const cell = [Math.round(meta.width / 3), Math.round(meta.height / 2)];
      const id = spec.pick ? await composeFourColumns(sharp, find, spec, name) : spec.id;
      return sheet({ id, rows: 2, cols: 4, frameHeight: frameHeight - 2, cell, out });
    }]);
  }
  for (const [name, id] of Object.entries(VOL_FACE_DOS)) {
    jobs.push([`${OUT}/dinos/${name}_vol_face_dos.png`, (out) => volFaceDos(sheet, sharp, id, name, out, OUT, find)]);
  }
  for (const [name, spec] of Object.entries(VOL)) {
    jobs.push([`${OUT}/dinos/${name}_vol.png`, (out) => volFromSheet(sheet, sharp, find, spec, name, out)]);
  }
  return jobs;
};

/** Une planche 1×4 de vol depuis une grille source (voir VOL) : la grille est d'abord découpée par
 * `sheet` en cases de VOL_CELL (chaque pose est trouvée entière), puis les 4 cases choisies sont
 * recopiées, centrées, dans une ligne. */
async function volFromSheet(sheet, sharp, find, spec, name, out) {
  let id = spec.id;
  if (spec.bgFix) id = await flattenBackground(sharp, find, spec.id, name);
  const tmp = out.replace(/.png$/, "_tmpgrid.png");
  await sheet({ id, rows: spec.rows, cols: spec.cols, frameHeight: 215, cell: VOL_CELL, out: tmp });
  const [cw, ch] = VOL_CELL;
  const parts = await Promise.all(spec.pick.map(async ([r, c], i) => ({
    input: await sharp(tmp).extract({ left: c * cw, top: r * ch, width: cw, height: ch }).png().toBuffer(), left: i * cw, top: 0,
  })));
  await sharp({ create: { width: cw * 4, height: ch, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
    .composite(parts).png({ compressionLevel: 9 }).toFile(out);
  fs.unlinkSync(tmp);
  return `${out} (4x1 frames de ${cw}x${ch}, source ${spec.id})`;
}

/** nano-banana a rendu un magenta terne (pas #FF00FF) : les pixels proches de la couleur du coin
 * deviennent du vrai magenta avant le détourage (sinon un halo rose reste à demi opaque). */
async function flattenBackground(sharp, find, srcId, name) {
  const src = find(srcId);
  const out = path.join(path.dirname(src), `derived-vol-${name}.png`);
  if (fs.existsSync(out)) return path.basename(out, ".png");
  const { data, info } = await sharp(src).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const bg = [data[0], data[1], data[2]];
  const TOLERANCE = 70;
  for (let i = 0; i < data.length; i += 3) {
    const d = Math.hypot(data[i] - bg[0], data[i + 1] - bg[1], data[i + 2] - bg[2]);
    if (d < TOLERANCE) { data[i] = 255; data[i + 1] = 0; data[i + 2] = 255; }
  }
  await sharp(data, { raw: { width: info.width, height: info.height, channels: 3 } }).png().toFile(out);
  return path.basename(out, ".png");
}

/** Recompose une planche 4×2 propre depuis une source qui a n colonnes par rangée (n ≠ 4) : les
 * colonnes `pick` de chaque rangée, posées dans des cases égales sur fond magenta. */
async function composeFourColumns(sharp, find, spec, name) {
  const src = find(spec.id);
  const out = path.join(path.dirname(src), `derived-faces-${name}.png`);
  if (fs.existsSync(out)) return path.basename(out, ".png");
  const { width: W, height: H } = await sharp(src).metadata();
  const rowH = Math.floor(H / 2);
  const cellW = Math.floor(W / 4);
  const parts = [];
  for (let r = 0; r < 2; r++) {
    const n = spec.cols[r];
    const colW = Math.floor(W / n);
    for (let i = 0; i < 4; i++) {
      const c = spec.pick[r][i];
      const buf = await sharp(src).extract({ left: c * colW, top: r * rowH, width: colW, height: rowH }).png().toBuffer();
      parts.push({ input: buf, left: i * cellW + Math.round((cellW - colW) / 2), top: r * rowH });
    }
  }
  await sharp({ create: { width: cellW * 4, height: rowH * 2, channels: 3, background: { r: 255, g: 0, b: 255 } } })
    .composite(parts).png().toFile(out);
  return path.basename(out, ".png");
}

/** Hauteur (px) de la boîte opaque d'une zone [x, y, l, h] de l'image `file`. */
async function opaqueHeight(sharp, file, box) {
  const { data, info } = await sharp(file).ensureAlpha().extract({ left: box[0], top: box[1], width: box[2], height: box[3] })
    .raw().toBuffer({ resolveWithObject: true });
  let top = info.height, bottom = -1;
  for (let y = 0; y < info.height; y++) for (let x = 0; x < info.width; x++) {
    if (data[(y * info.width + x) * 4 + 3] > 24) { top = Math.min(top, y); bottom = Math.max(bottom, y); }
  }
  return bottom < 0 ? 0 : bottom - top + 1;
}

/** Planche de vol face/dos : 1) découpe d'essai dans de grandes cases, 2) mesure de la pose en plané
 * (rangée de face, colonne 2) et de la plus grande image, 3) découpe finale à l'échelle qui donne au
 * plané la même hauteur que le plané de profil, dans la cellule minimale. */
async function volFaceDos(sheet, sharp, srcId, name, out, OUT, find) {
  // (la planche du Quetzalcoatlus a un magenta clair, #FF66FF : ramené à #FF00FF avant le détourage)
  const id = name === "quetzalcoatlus" ? await flattenBackground(sharp, find, srcId, `${name}-facedos`) : srcId;
  const profile = `${OUT}/dinos/${name}_vol.png`;
  const pm = await sharp(profile).metadata();
  const pcw = Math.round(pm.width / 4);
  const wanted = await opaqueHeight(sharp, profile, [pcw, 0, pcw, pm.height]);   // plané de profil
  const BIG = [1100, 900], TRIAL = 400;
  const tmp = out.replace(/.png$/, "_tmptrial.png");
  await sheet({ id, rows: 2, cols: 4, frameHeight: TRIAL, cell: BIG, out: tmp });
  const glide = await opaqueHeight(sharp, tmp, [BIG[0], 0, BIG[0], BIG[1]]);
  const { data, info } = await sharp(tmp).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  let maxW = 0, maxH = 0;
  for (let r = 0; r < 2; r++) for (let c = 0; c < 4; c++) {
    let x0 = BIG[0], x1 = -1, y0 = BIG[1], y1 = -1;
    for (let y = 0; y < BIG[1]; y++) for (let x = 0; x < BIG[0]; x++) {
      if (data[((r * BIG[1] + y) * info.width + c * BIG[0] + x) * 4 + 3] > 24) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
    }
    maxW = Math.max(maxW, x1 - x0 + 1); maxH = Math.max(maxH, y1 - y0 + 1);
  }
  fs.unlinkSync(tmp);
  const k = wanted / glide;
  const cell = [Math.ceil(maxW * k) + 12, Math.ceil(maxH * k) + 12];
  await sheet({ id, rows: 2, cols: 4, frameHeight: Math.round(TRIAL * k), cell, out });
  return `${out} (4x2 frames de ${cell.join("x")}, plané calé sur le profil : ${wanted} px)`;
}
