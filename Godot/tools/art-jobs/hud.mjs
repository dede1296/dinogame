// The battle HUD's action wheel (29/09): the icons of the round buttons that the other UI
// pictures do not cover (sac.png, baie.png, fougere.png, collier.webp are reused as they are).
// One nano-banana sheet, 2 × 2 on magenta, drawn with sac/baie/collier as style references:
// claw marks (Attaquer), a three-toed footprint on an amber medallion (Dinos), a running boot
// with its dust puff (Fuir), an open hand under a pale-gold heart (Apaiser; its button is violet).
// 160 px like the other item icons. The claw marks and the hand have a soft glow: the pinkish
// half-transparent pixels the magenta leaves around it are cleared (as GLOWING does for props).
export default ({ icons, sharp, OUT }) => [
  [`${OUT}/ui/hud_icones`, async () => {
    const outDir = `${OUT}/ui`;
    const names = ["hud_griffe", "hud_dinos", "hud_fuir", "hud_apaiser"];
    const done = await icons({ id: "fu6nm4", cols: 2, rows: 2, size: 160, outDir, names });
    for (const name of ["hud_griffe", "hud_apaiser"]) {
      const file = `${outDir}/${name}.png`;
      const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
      for (let i = 0; i < data.length; i += 4) {
        const r = data[i], g = data[i + 1], b = data[i + 2];
        if (data[i + 3] < 250 && Math.min(r, b) - g > 18) data[i + 3] = 0;
      }
      await sharp(data, { raw: { width: info.width, height: info.height, channels: 4 } }).png({ compressionLevel: 9 }).toFile(file);
    }
    return done;
  }],
];
