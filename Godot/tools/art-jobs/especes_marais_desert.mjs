// Marais Brumeux and Désert Aride (bestiary), plus the Carnotaurus corrompu variant.
// Two Anciens (aged same-species elders): la Voix du Marais (Parasaurolophus) and le Vieux
// Rempart (Ankylosaurus). Two Alphas: Spinosaure Ancestral and Carnotaurus Rouge.
export default ({ sheet, OUT }) => {
  // [name, source id, frameHeight] — profile sheets (3x2, walking/rest/attack).
  const PROFILES = [
    ["iguanodon", "9sopsc", 210],
    ["corythosaurus", "vkiu7g", 200],
    ["baryonyx", "k09b21", 190],
    ["koolasuchus", "pt635v", 160],
    ["therizinosaurus", "32h0ij", 190],
    ["suchomimus", "ugir6f", 190],
    ["spinosaurus", "5tes8x", 240],
    ["oviraptor", "2xrb6i", 130],
    ["pinacosaurus", "530i4x", 130],
    ["stygimoloch", "5d65j7", 165],
    ["ouranosaurus", "zgblu5", 190],
    ["velociraptor_sables", "cnezqi", 200],
    ["majungasaurus", "842uaw", 200],
    ["carnotaurus", "lkvbzi", 220],
    ["voix_du_marais", "m303xd", 170],
    ["vieux_rempart", "gekl56", 140],
    ["carnotaurus_corrompu", "5rxz9b", 220],
  ];
  // [name, source id, frameHeight (profile - 2), cell [w, h] from the profile sheet's output]
  const FACE_DOS = [
    ["iguanodon", "od0r74", 208, [300, 218]],
    ["corythosaurus", "3sidkh", 198, [274, 208]],
    ["baryonyx", "ncu2pn", 188, [245, 198]],
    ["koolasuchus", "yai7j7", 158, [259, 168]],
    ["therizinosaurus", "bbp544", 188, [235, 198]],
    ["suchomimus", "mvv1gz", 188, [241, 198]],
    ["spinosaurus", "ilk0t5", 238, [305, 248]],
    ["oviraptor", "px9hx6", 128, [163, 138]],
    ["pinacosaurus", "lppg0k", 128, [192, 138]],
    ["stygimoloch", "jbekdc", 163, [201, 173]],
    ["ouranosaurus", "560y1w", 188, [272, 198]],
    ["velociraptor_sables", "26djsc", 198, [254, 208]],
    ["majungasaurus", "8mf9ks", 198, [244, 208]],
    ["carnotaurus", "o4onzl", 218, [263, 228]],
    ["voix_du_marais", "342uw2", 168, [251, 178]],
    ["vieux_rempart", "hcef9c", 138, [206, 148]],
  ];
  const jobs = PROFILES.map(([name, id, frameHeight]) =>
    [`${OUT}/dinos/${name}.png`, (out) => sheet({ id, rows: 2, cols: 3, frameHeight, out })]);
  for (const [name, id, frameHeight, cell] of FACE_DOS) {
    if (id === "TBD" || !cell) continue;
    jobs.push([`${OUT}/dinos/${name}_face_dos.png`, (out) => sheet({ id, rows: 2, cols: 4, frameHeight, cell, out })]);
  }
  return jobs;
};
