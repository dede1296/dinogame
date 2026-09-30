// L'icône du jeu, celle qu'on voit une fois Ambrelune installé (nano-banana id bn4lnu) :
// une goutte d'ambre avec un sauropode en silhouette dedans, et le croissant de lune qui
// dépasse derrière — le nom même du jeu, ambre et lune.
// Le ciel de nuit derrière est dessiné ici plutôt que généré : une icône doit rester nette à
// 48 px, et un dégradé propre y résiste mieux qu'une peinture réduite. Sa couleur de fond est
// celle des panneaux du jeu (SettingsMenu.INK) et du manifeste web.
//
// Ce qui en sert, et qui s'en sert (embleme.png n'est qu'une étape, effacée à la fin : chaque
// PNG laissé ici part dans le jeu comme une texture, et aucune scène ne s'en sert) :
//   jeu.png      512   l'icône complète : project.godot config/icon → l'APK, la PWA, l'éditeur
//   android.png  192   launcher_icons/main_192x192 (les vieux Android, sans icône adaptative)
//   fond.png     432   launcher_icons/adaptive_background_432x432
//   avant.png    432   launcher_icons/adaptive_foreground_432x432 — l'emblème seul, à l'intérieur
//                      du cercle de sécurité : Android rogne jusqu'à 1/3 du bord selon le
//                      téléphone (rond, écusson, goutte…), donc l'ambre tient dans 58 % du carré.
//   mono.png     432   launcher_icons/adaptive_monochrome_432x432 — la silhouette pleine que les
//                      lanceurs Android 13+ teintent quand les icônes thématiques sont activées.
//                      Sans elle, Godot remet la sienne : la tête de son robot (vu dans l'APK).
import fs from "node:fs";

const DIR = "Godot/assets/art/icone";
/** Part du carré occupée par l'ambre : pleine icône, puis avant-plan adaptatif (zone sûre). */
const FILL = 0.78;
const FILL_ADAPTIVE = 0.58;

/** Le ciel de nuit : bleu d'encre, une lueur chaude au centre (l'ambre) et quelques étoiles. */
const sky = (size) => {
  const stars = [[0.16, 0.2, 0.9], [0.83, 0.15, 0.7], [0.12, 0.74, 0.7], [0.88, 0.66, 0.9],
    [0.28, 0.09, 0.5], [0.72, 0.87, 0.6], [0.06, 0.45, 0.5], [0.94, 0.4, 0.5]]
    .map(([x, y, r]) => `<circle cx="${(x * size).toFixed(1)}" cy="${(y * size).toFixed(1)}" r="${(r * size / 100).toFixed(2)}" fill="#fff7ea" opacity="0.75"/>`)
    .join("");
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}">
    <defs>
      <radialGradient id="nuit" cx="50%" cy="46%" r="72%">
        <stop offset="0%" stop-color="#37304a"/>
        <stop offset="55%" stop-color="#232838"/>
        <stop offset="100%" stop-color="#1b1f28"/>
      </radialGradient>
      <radialGradient id="lueur" cx="50%" cy="54%" r="42%">
        <stop offset="0%" stop-color="#ffb648" stop-opacity="0.42"/>
        <stop offset="100%" stop-color="#ffb648" stop-opacity="0"/>
      </radialGradient>
    </defs>
    <rect width="100%" height="100%" fill="url(#nuit)"/>
    ${stars}
    <rect width="100%" height="100%" fill="url(#lueur)"/>
  </svg>`);
};

/**
 * La silhouette à teinter, tirée de l'emblème : on garde le clair (l'ambre, la lune) et on
 * évide le sombre (le contour, le dinosaure). Le dessin reste donc lisible d'une seule couleur —
 * le dinosaure devient un trou, et le trait qui sépare la lune de l'ambre aussi.
 */
// L'emblème a deux masses nettes et rien entre les deux : le contour et le dinosaure vers 20-40,
// l'ambre et la lune à partir de 110 (2 % des pixels au milieu, ce sont les bords adoucis).
// Le seuil se pose dans ce creux, sinon l'ombrage de l'ambre ressort en taches à demi transparentes.
const MONO_DARK = 60;    // en dessous de cette luminance : trou
const MONO_LIGHT = 105;  // au-dessus : plein (entre les deux, un bord adouci)
async function monochrome(sharp, from, out) {
  const { data, info } = await sharp(from).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  for (let i = 0; i < data.length; i += 4) {
    const lum = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
    const keep = Math.max(0, Math.min(1, (lum - MONO_DARK) / (MONO_LIGHT - MONO_DARK)));
    data[i] = data[i + 1] = data[i + 2] = 255;
    data[i + 3] = Math.round(data[i + 3] * keep);
  }
  await sharp(data, { raw: { width: info.width, height: info.height, channels: 4 } })
    .png({ compressionLevel: 9 }).toFile(out);
  return `mono.png ${info.width}`;
}

export default ({ icons, sharp, OUT }) => [
  [`${OUT}/icone`, async () => {
    fs.mkdirSync(DIR, { recursive: true });
    await icons({ id: "bn4lnu", cols: 1, rows: 1, size: 1024, outDir: DIR, names: ["embleme"] });
    const embleme = `${DIR}/embleme.png`;

    // L'emblème posé au milieu d'un carré, sur le ciel ou sur rien.
    const compose = async (size, fill, background, out) => {
      const inner = Math.round(size * fill);
      const art = await sharp(embleme).resize(inner, inner, { fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } }).png().toBuffer();
      const at = Math.round((size - inner) / 2);
      const base = background
        ? sharp(sky(size)).png()
        : sharp({ create: { width: size, height: size, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } });
      await base.composite([{ input: art, left: at, top: at }]).png({ compressionLevel: 9 }).toFile(out);
      return `${out.split("/").pop()} ${size}`;
    };

    const done = [
      await compose(512, FILL, true, `${DIR}/jeu.png`),
      await compose(192, FILL, true, `${DIR}/android.png`),
      await compose(432, FILL_ADAPTIVE, false, `${DIR}/avant.png`),
    ];
    await sharp(sky(432)).png({ compressionLevel: 9 }).toFile(`${DIR}/fond.png`);
    done.push("fond.png 432");
    done.push(await monochrome(sharp, `${DIR}/avant.png`, `${DIR}/mono.png`));
    for (const f of [embleme, `${embleme}.import`]) fs.rmSync(f, { force: true });
    return `${DIR}: ${done.join(", ")}`;
  }],
];
