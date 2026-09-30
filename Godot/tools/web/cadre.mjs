// Prépare la page web après l'export de Godot :
//   - le jeu lui-même part dans « jeu.html », dans un cadre de la taille d'un téléphone posé au
//     milieu d'une page sombre (étiré sur tout un grand écran, un jeu pensé pour le téléphone
//     est illisible et il rame) ;
//   - « index.html » devient une page d'accueil avec un bouton qui ouvre le jeu dans une
//     FENÊTRE à part, à la bonne taille. Un navigateur n'obéit pas à « fenêtre non
//     redimensionnable » (c'est interdit exprès), mais il obéit à la taille d'ouverture.
//     Sur un petit écran (téléphone), le bouton ouvre le jeu dans l'onglet courant.
// On ajoute seulement ce qu'il faut à la page produite par Godot, plutôt que d'entretenir un
// modèle HTML complet qui casserait à chaque version du moteur.
// Usage : node tools/web/cadre.mjs build/web/index.html
import fs from "node:fs";
import path from "node:path";

/** Deux fois un écran de téléphone en paysage (844 x 390, le format le plus courant). */
const GAME = { w: 1688, h: 780 };
const MARK = "tools/web/cadre.mjs";

const STYLE = `
<style>
  /* Ambrelune : le jeu dans un cadre de téléphone, au milieu de la page (${MARK}). */
  html, body { background: #14120f; height: 100%; }
  body { margin: 0; display: flex; align-items: center; justify-content: center; }
  #canvas {
    display: block;
    aspect-ratio: ${GAME.w} / ${GAME.h};
    width: min(100vw, ${GAME.w}px, calc(100vh * ${GAME.w} / ${GAME.h}));
    height: auto;
    max-height: 100vh;
    outline: none;
    border-radius: 12px;
    box-shadow: 0 0 40px #0008;
    touch-action: none;
  }
  #status, #status-splash, #status-progress { max-width: min(100vw, ${GAME.w}px); }
</style>
`;

const HOME = `<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
<title>Ambrelune</title>
<!-- Page d'accueil écrite par ${MARK} : le jeu s'ouvre dans sa propre fenêtre. -->
<style>
  html, body { height: 100%; margin: 0; background: #14120f; color: #fff7ea;
    font-family: system-ui, "Segoe UI", Roboto, sans-serif; }
  body { display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 18px; text-align: center; padding: 24px; box-sizing: border-box; }
  h1 { margin: 0; font-size: clamp(32px, 7vw, 56px); color: #ffdb8a; letter-spacing: 1px; }
  p { margin: 0; max-width: 34rem; line-height: 1.5; color: #d9cdba; }
  button { margin-top: 10px; padding: 18px 42px; font-size: 22px; font-family: inherit;
    color: #14120f; background: #f0c070; border: none; border-radius: 14px; cursor: pointer; }
  button:hover { background: #ffd98f; }
  a { color: #d9cdba; font-size: 15px; }
  small { color: #8d8478; font-size: 13px; }
</style>
</head>
<body>
  <h1>Ambrelune</h1>
  <p>Le jeu s'ouvre dans sa propre fenêtre, à la taille d'un écran de téléphone.
     Le premier chargement prend un moment : tout le jeu se télécharge d'un coup.</p>
  <button id="jouer" type="button">Jouer</button>
  <p><a href="jeu.html">ou jouer dans cet onglet</a></p>
  <small>Sur téléphone, le bouton ouvre le jeu ici même.</small>
<script>
  document.getElementById("jouer").addEventListener("click", function () {
    var small = window.innerWidth < ${GAME.w} * 0.7;
    if (small) { window.location.href = "jeu.html"; return; }
    var left = Math.max(0, Math.round((window.screen.availWidth - ${GAME.w}) / 2));
    var top = Math.max(0, Math.round((window.screen.availHeight - ${GAME.h}) / 2));
    var opened = window.open("jeu.html", "ambrelune",
      "popup=yes,width=${GAME.w},height=${GAME.h},left=" + left + ",top=" + top +
      ",resizable=no,scrollbars=no,menubar=no,toolbar=no,location=no,status=no");
    // Fenêtre refusée (bloqueur) : on joue dans cet onglet plutôt que de ne rien faire.
    if (!opened) { window.location.href = "jeu.html"; }
  });
</script>
</body>
</html>
`;

const file = process.argv[2];
if (!file) {
  console.error("Usage : node tools/web/cadre.mjs <index.html>");
  process.exit(1);
}
const dir = path.dirname(file);
const game = path.join(dir, "jeu.html");
let html = fs.readFileSync(file, "utf8");
if (html.includes('id="jouer"')) {
  // Déjà passé : index.html est la page d'accueil. Le refaire écraserait le jeu avec elle.
  console.log(`${file} : déjà préparé`);
  process.exit(0);
}
if (!html.includes(MARK)) {
  const at = html.indexOf("</head>");
  html = at < 0 ? html + STYLE : html.slice(0, at) + STYLE + html.slice(at);
}
fs.writeFileSync(game, html);
fs.writeFileSync(file, HOME);
console.log(`${game} : le jeu, encadré ${GAME.w}x${GAME.h} · ${file} : page d'accueil`);
