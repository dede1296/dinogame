// Post-game, lot A' — les quatre géants du cratère (+ 3 images du lot E : Brac gardien, panneau BARC, sandwich).
// Espèces (anatomie réelle donnée dans chaque prompt nano-banana, membres comptés image par image) :
//   therizinosaurus_geant : bipède, 2 pattes arrière (4 doigts), 2 bras à 3 très longues griffes droites, bec, gros ventre, duvet ;
//   argentinosaurus : quadrupède, 4 pattes en colonnes, cou très long, minuscule tête, queue en fouet, sans plaques ;
//   dacentrurus : quadrupède (avant plus courtes), double rangée de petites plaques puis de pointes vers la queue, 4 longues
//                 pointes au bout de la queue, toute petite tête basse à bec ;
//   deinocheirus : bipède, 2 pattes arrière à 3 doigts, 2 longs bras à 3 doigts émoussés, bec plat de canard, bosse dorsale,
//                 éventail de plumes au bout de la queue.
// Pour chacune : `<id>.png` (profil 3×2 : 3 pas, repos, repos 2 ou broute, cri), `<id>_face_dos.png` (4×2 : face puis dos,
// 4 images de marche) et `<id>_leve.png` (3×2 : le géant se réveille et se lève : couché ou assis -> debout, bâillement).
// Méthode : nano-banana, édition de planches du jeu (therizinosaurus, stegosaurus, brachiosaurus, souverain) comme référence de
// style et de grille seulement ; face/dos et lever partent d'UNE pose de profil recadrée (sinon la planche est recopiée).
// Sources dans generated_imgs/ (id = fin du nom du fichier). Cellules : hauteur d'image 220 comme le Souverain (475×228).
// Props : blocs d'ambre `bloc_geant_<n>_oeil` (œil ambré ouvert) et `_vide` (fendu en deux, vide, éclats dorés), à la taille
// des blocs existants (671×848, 682×848, 342×413). Lot E : brac_gardien (4×4 comme brac), panneau_barc, sandwich.
import fs from "node:fs";

const FRAME = 220;
const GEN = "generated_imgs";
const sourceOf = (id) => `${GEN}/${fs.readdirSync(GEN).find((n) => n.includes(id))}`;

export default ({ sheet, props, icons, sharp, OUT }) => {
  const jobs = [];
  // Blocs retouchés le 20/10 : tailles de l'ancien bloc [largeur, hauteur] par numéro.
  const RETOUCHES = { 1: [null, [673, 850]], 3: [null, [670, 847]] };
  const fitTo = async (file, [w, h]) => {
    await sharp(file).resize(w, h, { fit: "fill" }).png({ compressionLevel: 9 }).toFile(`${file}.tmp`);
    fs.renameSync(`${file}.tmp`, file);
    return `${file} remis à ${w}x${h}`;
  };
  /** Planche 3×3 (nano-banana dessine 9 poses au lieu de 6) -> 3×2 avec les cases choisies [rangée, colonne], sans déformation. */
  const recompose = (id, pick, derive = null) => async (out) => {
    const tmp = out.replace(/\.png$/, "_tmp9x9.png");
    await sheet({ id: derive ? await derive(id) : id, rows: 3, cols: 3, frameHeight: FRAME, align: "bottom", isolate: true, out: tmp });
    const meta = await sharp(tmp).metadata();
    const fw = Math.round(meta.width / 3), fh = Math.round(meta.height / 3);
    const parts = await Promise.all(pick.map(async ([r, c], i) => ({
      input: await sharp(tmp).extract({ left: c * fw, top: r * fh, width: fw, height: fh }).png().toBuffer(),
      left: (i % 3) * fw, top: Math.floor(i / 3) * fh,
    })));
    await sharp({ create: { width: fw * 3, height: fh * 2, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })
      .composite(parts).png({ compressionLevel: 9 }).toFile(out);
    fs.unlinkSync(tmp);
    if (derive) await despeckle(out, 3, 2);
    return `${out} (3×2 de ${fw}×${fh}, recomposé 3×3 -> 3×2 depuis ${id})`;
  };
  /** Efface (dans chaque case de `cols`×`rows`) les îlots de moins de `minPixels` pixels : éclats de pointes coupées par la séparation des poses. */
  const despeckle = async (file, cols, rows, minPixels = 1500) => {
    const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const { width: w, height: h } = info, seen = new Uint8Array(w * h);
    for (let s0 = 0; s0 < w * h; s0++) {
      if (seen[s0] || data[s0 * 4 + 3] < 24) continue;
      const blob = [s0], stack = [s0]; seen[s0] = 1;
      while (stack.length) {
        const p = stack.pop(), x = p % w, y = (p / w) | 0;
        for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          const nx = x + dx, ny = y + dy, q = ny * w + nx;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h || seen[q] || data[q * 4 + 3] < 24) continue;
          seen[q] = 1; stack.push(q); blob.push(q);
        }
      }
      if (blob.length < minPixels) for (const p of blob) data[p * 4 + 3] = 0;
    }
    await sharp(data, { raw: { width: w, height: h, channels: 4 } }).png({ compressionLevel: 9 }).toFile(`${file}.tmp`);
    fs.renameSync(`${file}.tmp`, file);
  };
  /** Efface les pixels roses clairs qui restent au bord de la lueur de la lanterne (le jaune de la lueur n'a pas de bleu). */
  const clearPink = async (file) => {
    const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    for (let i = 0; i < data.length; i += 4) if (data[i + 3] > 0 && data[i] > 170 && data[i + 2] > data[i + 1] + 5 && data[i] > data[i + 1] + 40) data[i + 3] = 0;
    await sharp(data, { raw: { width: info.width, height: info.height, channels: 4 } }).png({ compressionLevel: 9 }).toFile(`${file}.tmp`);
    fs.renameSync(`${file}.tmp`, file);
  };
  const profile = (id) => (out) => sheet({ id, rows: 2, cols: 3, frameHeight: FRAME, align: "bottom", isolate: true, out });
  /**
   * Face/dos dans des cellules de la taille de celles du profil (mêmes pieds, même échelle). `swaps` : [rangée, case à refaire,
   * case modèle] : nano-banana a dessiné certaines images de marche en trois-quarts ; elles sont remplacées par le miroir d'une
   * image bien de face (ou de dos), pour que le cycle garde le même point de vue.
   */
  const faceDos = (id, derive = null, swaps = []) => async (out) => {
    const prof = out.replace("_face_dos", "");
    if (!fs.existsSync(prof)) throw new Error(`${out} : produire d'abord le profil (${prof})`);
    const meta = await sharp(prof).metadata();
    const cell = [Math.round(meta.width / 3), Math.round(meta.height / 2)];
    const msg = await sheet({ id: derive ? await derive(id) : id, rows: 2, cols: 4, frameHeight: FRAME - 2, cell, out });
    if (!swaps.length) return msg;
    const [cw, ch] = cell;
    const cut = (r, c) => ({ left: c * cw, top: r * ch, width: cw, height: ch });
    const patches = [];
    for (const [r, dst, src] of swaps) {
      const flipped = await sharp(out).extract(cut(r, src)).flop().png().toBuffer();
      patches.push({ r, dst, flipped });
    }
    let img = sharp(out);
    for (const { r, dst } of patches) img = sharp(await img.composite([{ input: await sharp({ create: { width: cw, height: ch, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 1 } } }).png().toBuffer(), left: dst * cw, top: r * ch, blend: "dest-out" }]).png().toBuffer());
    img = sharp(await img.composite(patches.map(({ r, dst, flipped }) => ({ input: flipped, left: dst * cw, top: r * ch }))).png().toBuffer());
    await img.png({ compressionLevel: 9 }).toFile(`${out}.tmp`);
    fs.renameSync(`${out}.tmp`, out);
    return `${msg} ; ${swaps.length} images trois-quarts remplacées par un miroir`;
  };
  /**
   * Copie de la source dont les bords de cellules (`cols` colonnes, `rows` rangées) sont repeints en magenta : efface les traits de
   * grille et sépare les poses qui se touchent (museau contre queue) pour que chacune garde sa case.
   */
  const wipeGrid = (cols, rows) => async (id) => {
    const derived = `derived-geants-${id}`;
    const { data, info } = await sharp(sourceOf(id)).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const band = 2, paint = (x, y) => { const i = (y * info.width + x) * 4; data[i] = 255; data[i + 1] = 0; data[i + 2] = 255; data[i + 3] = 255; };
    for (let k = 1; k < cols; k++) for (let y = 0; y < info.height; y++) for (let d = -band; d <= band; d++) paint(Math.round(info.width * k / cols) + d, y);
    for (let k = 1; k < rows; k++) for (let x = 0; x < info.width; x++) for (let d = -band; d <= band; d++) paint(x, Math.round(info.height * k / rows) + d);
    await sharp(data, { raw: { width: info.width, height: info.height, channels: 4 } }).png().toFile(`${GEN}/${derived}.png`);
    return derived;
  };
  const species = [
    ["therizinosaurus_geant", profile("mxcdd7"), "3zbjfx", null, [[0, 2, 1], [1, 0, 1], [1, 3, 2]], profile("bdjrbm")],
    ["argentinosaurus", recompose("j3t7oa", [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [2, 2]]), "892rch", wipeGrid(4, 2), [], profile("y6qn9h")],
    ["dacentrurus", recompose("vfw1uh", [[0, 0], [0, 1], [0, 2], [1, 0], [2, 0], [2, 2]]), "ah3vox", null, [],
      recompose("uxamjb", [[0, 0], [0, 1], [0, 2], [1, 0], [2, 1], [2, 2]], wipeGrid(3, 3))],
    ["deinocheirus", profile("0t8afo"), "4iam5b", null, [[0, 1, 0], [0, 3, 2], [1, 1, 0], [1, 3, 2]], profile("8ey7l5")],
  ];
  for (const [name, prof, fd, derive, swaps, leve] of species) {
    jobs.push([`${OUT}/dinos/${name}.png`, prof]);
    jobs.push([`${OUT}/dinos/${name}_face_dos.png`, faceDos(fd, derive, swaps)]);
    jobs.push([`${OUT}/dinos/${name}_leve.png`, leve]);
  }

  // Blocs d'ambre : un œil ambré ouvert (l'ambre luit) ; fendu en deux et vide. Échelle = taille des blocs existants.
  const BLOCS = [["1", "npebbb", "9k6cqk", 0.74], ["2", "cdpsju", "zrqzy3", 0.74], ["3", "hi2ryc", "7uaesv", 0.74], ["4", "20q0rq", "sntz3g", 0.371, 0.335]];
  for (const [n, oeil, vide, scale, scaleVide = scale] of BLOCS) {
    jobs.push([`${OUT}/props/bloc_geant_${n}_oeil.png`, async () => {
      const msg = await props({ id: oeil, scale, gap: 40, outDir: `${OUT}/props`, names: [`bloc_geant_${n}_oeil`] });
      return RETOUCHES[n] ? `${msg} ; ${await fitTo(`${OUT}/props/bloc_geant_${n}_oeil.png`, RETOUCHES[n][1])}` : msg;
    }]);
    jobs.push([`${OUT}/props/bloc_geant_${n}_vide.png`, () => props({ id: vide, scale: scaleVide, gap: 60, outDir: `${OUT}/props`, names: [`bloc_geant_${n}_vide`] })]);
  }

  // Retouches 20/10 : bloc 3 refait en Dacentrurus (deux rangées de pointes étroites, 4 pointes de queue), œil fermé ; sceau du Tricératops.
  jobs.push([`${OUT}/props/bloc_geant_3.png`, async () => {
    const msg = await props({ id: "or54at", scale: 0.74, gap: 40, outDir: `${OUT}/props`, names: ["bloc_geant_3"] });
    return `${msg} ; ${await fitTo(`${OUT}/props/bloc_geant_3.png`, [682, 848])}`;
  }]);
  jobs.push([`${OUT}/ui/sceau_plaines.png`, () => icons({ id: "tzeqks", cols: 1, rows: 1, size: 160, outDir: `${OUT}/ui`, names: ["sceau_plaines"] })]);

  // Lot E. Brac gardien de nuit (lanterne à la main, chapeau, pas de masque ; 4×4 : face, gauche, droite, dos). La lueur de la
  // lanterne sortait rose sur le magenta : les pixels roses sont repeints en magenta pur avant le détourage.
  jobs.push([`${OUT}/characters/brac_gardien.png`, async (out) => {
    const { data, info } = await sharp(sourceOf("u87xdv")).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    for (let i = 0; i < data.length; i += 4) {
      if (data[i] > 150 && Math.min(data[i], data[i + 2]) - data[i + 1] > 32) { data[i] = 255; data[i + 1] = 0; data[i + 2] = 255; }
    }
    await sharp(data, { raw: { width: info.width, height: info.height, channels: 4 } }).png().toFile(`${GEN}/derived-geants-brac.png`);
    const msg = await sheet({ id: "derived-geants-brac", rows: 4, cols: 4, frameHeight: 176, out });
    await despeckle(out, 4, 4, 400);
    await clearPink(out);
    return msg;
  }]);
  jobs.push([`${OUT}/props/panneau_barc.png`, () => props({ id: "0q0jmt", scale: 0.2, outDir: `${OUT}/props`, names: ["panneau_barc"] })]);
  jobs.push([`${OUT}/props/sandwich.png`, () => props({ id: "q682k3", scale: 0.06, outDir: `${OUT}/props`, names: ["sandwich"] })]);
  return jobs;
};
