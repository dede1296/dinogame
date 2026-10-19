// Finitions des chapitres 8 et 9 (agent IMAGES, 19/10). Chaque planche part d'une image nano-banana retouchée
// puis recomposée sur fond magenta (generated_imgs/derived-*.png, cases agrandies d'un facteur K) ; ce job la détoure
// et la réduit à la taille finale. Les anciens fichiers sont gardés en `_v1` ; rien n'est remplacé avant comparaison.
// Lancer depuis la racine du dépôt, avec un chemin précis : node Godot/tools/process-art.mjs characters/helene_assise_sans_fauteuil
export default ({ sharp, find, OUT }) => {
  const clamp = (v) => Math.max(0, Math.min(255, Math.round(v)));
  /** Détoure le magenta (même règle que process-art.mjs) puis réduit de `k`. */
  async function keyDown(id, out, k) {
    const { data, info } = await sharp(find(id)).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    for (let i = 0; i < data.length; i += 4) {
      const r = data[i], g = data[i + 1], b = data[i + 2], m = Math.min(r, b) - g;
      const a = Math.max(0, Math.min(1, 1 - (m - 70) / 80));
      if (a === 0) { data[i + 3] = 0; continue; }
      if (a < 1) { data[i] = clamp((r - (1 - a) * 255) / a); data[i + 2] = clamp((b - (1 - a) * 255) / a); data[i + 1] = clamp(g / a > 255 ? 255 : g); }
      else if (m > 10) { const cap = g + 10; if (r > cap && b > cap) { data[i] = Math.max(cap, r - m); data[i + 2] = Math.max(cap, b - m); } }
      data[i + 3] = Math.round(a * 255);
    }
    await sharp(data, { raw: { width: info.width, height: info.height, channels: 4 } })
      .resize(Math.round(info.width / k), Math.round(info.height / k), { kernel: "lanczos3" }).png().toFile(out);
    return `${out} ${Math.round(info.width / k)}x${Math.round(info.height / k)}`;
  }
  return [
    // (1) Hélène assise sans fauteuil, pour le Cabinet (le fauteuil de Roc est dessiné par le décor) : 2×4 cases de 240×184.
    [`${OUT}/characters/helene_assise_sans_fauteuil.png`, (out) => keyDown("derived-helene-assise-sans-fauteuil", out, 4)],
    // (2) Firmin sans masque (épilogue, jetée de Port-Ambre) : 4×4 cases de 100×184 comme sbire.png (face, gauche, droite, dos ; 4 pas par rangée).
    [`${OUT}/characters/firmin_sans_masque.png`, (out) => keyDown("derived-firmin-sans-masque", out, 4)],
    // (3) Maïa assise sur la pierre, avec le manteau de maia_arche (2×4 cases de 260×240 comme maia_pierre.png ; ancienne = _v1).
    [`${OUT}/characters/maia_pierre_nouveau.png`, (out) => keyDown("derived-maia-pierre-manteau", out, 4)],
    // (4) Léonce sans masque qui raccommode un filet, pour Port-Ambre : 4×4 cases de 116×184 comme pecheur.png (Gustave).
    [`${OUT}/characters/leonce_port.png`, (out) => keyDown("derived-leonce-port", out, 4)],
  ];
};
