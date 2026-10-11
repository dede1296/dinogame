// Range les packs décompressés par erreur dans le projet Godot.
//
//   node tools/ranger-packs.mjs            → liste ce qui n'a rien à faire là (ne touche à rien)
//   node tools/ranger-packs.mjs --ranger   → le déplace dans assets3d_src/packs-deverses/
//
// Pourquoi : un pack dézippé à la racine de Godot/ (ou dans scenes/, tools/) se fait importer par
// Godot à chaque ouverture, alourdit l'export et noie les dossiers du jeu. Le bon geste est de
// dézipper dans assets3d_src/, puis de copier dans le projet seulement ce qu'on utilise.
//
// Ce qui est « du jeu » : tout ce que git suit, plus la liste PROJET ci-dessous. Le reste est
// suspect. Rien n'est supprimé : tout part dans packs-deverses/, avec son LISEZ-MOI.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const RACINE = path.resolve(import.meta.dirname, "..");
const RANGEMENT = path.resolve(RACINE, "../assets3d_src/packs-deverses");
/** Les entrées du projet qui ne sont pas (toutes) suivies par git. */
const PROJET = new Set([
	".godot", "addons", "build", "addons.lnk", "README.md", "project.godot", "export_presets.cfg",
	"ambrelune-godot.code-workspace", "default_bus_layout.tres",
]);
/** Les dossiers du jeu où un pack vient aussi se déverser. */
const DOSSIERS = [".", "scenes", "tools", "assets"];

const suivis = new Set(
	execFileSync("git", ["ls-files"], { cwd: RACINE, encoding: "utf8" })
		.split("\n").filter(Boolean).map((f) => f.split("/")[0] === "" ? f : f),
);

/** Vrai si `relatif` (chemin depuis Godot/) est du jeu : suivi par git, ou dans PROJET. */
function duJeu(relatif) {
	if (PROJET.has(relatif)) return true;
	if (suivis.has(relatif)) return true;
	for (const f of suivis) if (f.startsWith(relatif + "/")) return true;   // dossier du jeu
	return false;
}

const suspects = [];
for (const dossier of DOSSIERS) {
	const absolu = path.join(RACINE, dossier);
	if (!fs.existsSync(absolu)) continue;
	for (const nom of fs.readdirSync(absolu)) {
		if (nom.startsWith(".")) continue;
		const relatif = dossier === "." ? nom : `${dossier}/${nom}`;
		if (duJeu(relatif)) continue;
		if (relatif === "tools/ranger-packs.mjs") continue;   // cet outil lui-même
		if (nom.endsWith(".uid") && duJeu(relatif.slice(0, -4))) continue;   // va avec son script
		suspects.push(relatif);
	}
}

if (suspects.length === 0) {
	console.log("Rien à ranger : le projet ne contient que ses propres dossiers.");
	process.exit(0);
}

const ranger = process.argv.includes("--ranger");
console.log(`${suspects.length} entrée(s) qui ne viennent pas du jeu :`);
for (const relatif of suspects) {
	const absolu = path.join(RACINE, relatif);
	if (!fs.existsSync(absolu)) continue;   // déjà parti avec son .import
	const vide = fs.statSync(absolu).isDirectory() && fs.readdirSync(absolu).length === 0;
	if (!ranger) {
		console.log(`  ${relatif}${vide ? "   (dossier vide)" : ""}`);
		continue;
	}
	if (vide) {
		fs.rmdirSync(absolu);
		console.log(`  supprimé (vide) : ${relatif}`);
		continue;
	}
	fs.mkdirSync(RANGEMENT, { recursive: true });
	let cible = path.join(RANGEMENT, relatif.replace(/\//g, "_"));
	for (let n = 2; fs.existsSync(cible); n++) cible = `${path.join(RANGEMENT, relatif.replace(/\//g, "_"))}-${n}`;
	fs.renameSync(absolu, cible);
	fs.rmSync(absolu + ".import", { force: true });
	console.log(`  rangé : ${relatif}  →  assets3d_src/packs-deverses/${path.basename(cible)}`);
}
if (!ranger) console.log("\nRelance avec --ranger pour les déplacer (rien n'est supprimé, sauf les dossiers vides).");
