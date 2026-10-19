// Chapitre 9 — Terre des Apex : icône d'objet (insigne de gardienne) et fond de combat.
// Fond : même cadrage que battle/volcan.jpg (deux plateaux, vide au centre), salle ronde du cratère.
export default ({ icons, sharp, find, OUT }) => {
  const jobs = [];
  jobs.push([`${OUT}/ui/insigne_gardienne.png`, () => icons({
    id: "dzlf4n", cols: 1, rows: 1, size: 160, outDir: `${OUT}/ui`, boxes: [[0, 0, 1024, 1024]], names: ["insigne_gardienne"],
  })]);
  jobs.push([`${OUT}/battle/apex.jpg`, (out) => sharp(find("ojyj4r")).resize(1920, 1072, { fit: "cover" })
    .jpeg({ quality: 86, mozjpeg: true }).toFile(out).then(() => out)]);
  return jobs;
};
