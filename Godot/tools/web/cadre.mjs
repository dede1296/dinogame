// Le jeu, dans le navigateur, tient dans un cadre de la taille d'un téléphone posé au milieu
// d'une page sombre, au lieu de s'étirer sur tout l'écran : c'est un jeu pensé pour le
// téléphone, et étiré sur un grand écran il est illisible et il rame. Godot fabrique son
// index.html depuis son propre modèle ; on y ajoute seulement cette mise en forme, plutôt que
// d'entretenir un modèle complet qui casserait à chaque version du moteur.
// Usage : node tools/web/cadre.mjs build/web/index.html
import fs from "node:fs";

const STYLE = `
<style>
  /* Ambrelune : le jeu dans un cadre de téléphone, au milieu de la page (tools/web/cadre.mjs). */
  html, body { background: #14120f; height: 100%; }
  body { margin: 0; display: flex; align-items: center; justify-content: center; }
  #canvas {
    display: block;
    /* Deux fois un écran de téléphone en paysage (844 x 390 : le format le plus courant),
       et jamais plus grand que la fenêtre. */
    aspect-ratio: 844 / 390;
    width: min(100vw, 1688px, calc(100vh * 844 / 390));
    height: auto;
    max-height: 100vh;
    outline: none;
    border-radius: 12px;
    box-shadow: 0 0 40px #0008;
    touch-action: none;
  }
  #status, #status-splash, #status-progress { max-width: min(100vw, 1688px); }
</style>
`;

const file = process.argv[2];
if (!file) {
  console.error("Usage : node tools/web/cadre.mjs <index.html>");
  process.exit(1);
}
let html = fs.readFileSync(file, "utf8");
if (html.includes("tools/web/cadre.mjs")) {
  console.log(`${file} : déjà encadré`);
} else {
  const at = html.indexOf("</head>");
  html = at < 0 ? html + STYLE : html.slice(0, at) + STYLE + html.slice(at);
  fs.writeFileSync(file, html);
  console.log(`${file} : cadre de téléphone ajouté (${at < 0 ? "en fin de fichier" : "avant </head>"})`);
}
