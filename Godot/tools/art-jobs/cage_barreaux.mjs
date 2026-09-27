// The front bars of the camp's cages (tools/zones/camp_ombre.gd): drawn in front of a caged
// dino, the cage picture behind it, so that the dino stands inside, between its bars.
export default ({ props, OUT }) => [
  [`${OUT}/props/barreaux_cage`, () => props({
    id: "x344fq", scale: 0.21, outDir: `${OUT}/props`,
    boxes: [[0, 0, 1200, 896]],
    names: ["barreaux_cage"],
  })],
];
