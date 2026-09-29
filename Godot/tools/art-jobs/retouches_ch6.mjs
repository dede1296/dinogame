// Touch-ups before chapter 6 (29/09).
// - The masks frieze over the sunken temple's entrance: « des dizaines de petits masques d'os
//   sculptés… des becs, des crêtes, des cornes » (story/marais_temple.gd). Replaces the first
//   frieze (five skulls, finition.mjs « frise_masques_plaque »), which read as a plaque.
// - The campfire's hearth, painted (it was the web version's flat drawing, tools/draw-placeholders.mjs,
//   which must not be run again for it): stones, charred logs, embers; no flame (world_view.gd
//   _fire_flame plays props/flamme_anim.png over it).
// Scale 0.5 of the sources, like the other props; their size in the game is set by Prop.KINDS.
export default ({ props, OUT }) => [
  [`${OUT}/retouches/frise_masques`, () => props({ id: "7bjgtu", scale: 0.5, outDir: `${OUT}/props`, names: ["frise_masques"] })],
  [`${OUT}/retouches/feu_camp`, () => props({ id: "d1apov", scale: 0.5, outDir: `${OUT}/props`, names: ["feu_camp"] })],
  // The frost door of the sanctuary (Monts), strictly front-on (the first one, monts.mjs, was drawn
  // at an angle: it looked turned aside in its notch), its four hollows empty.
  [`${OUT}/retouches/porte_givre`, () => props({ id: "oanutv", scale: 0.5, outDir: `${OUT}/props`, names: ["porte_givre"] })],
  // The same door with 1, 2, 3 of Chloé's Cœurs set in its hollows (top left, top right, bottom left;
  // the 4th, bottom right, waits for the Cœur of the sanctuary): the hearts of the first drawing
  // (4zk7z8, same geometry) pasted into the empty door (derived-porte-givre-coeurs<n>.png).
  ...[1, 2, 3].map((n) => [`${OUT}/retouches/porte_givre_${n}`, () => props({ id: `derived-porte-givre-coeurs${n}`, scale: 0.5, outDir: `${OUT}/props`, names: [`porte_givre_${n}`] })]),
];
