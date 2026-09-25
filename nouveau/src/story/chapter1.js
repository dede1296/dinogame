// Chapter 1, second half: the hybridizer, the Grotte des Échos, the Triceratops Alpha,
// the fallen trunk and the first rival battle with Maïa.

import { DINOS } from "../../../src/data/dinos.js";
import { state } from "../state/game.js";
import { createDino, graft, GRAFT_PARTS, speciesName } from "../battle/dino.js";
import { MOVES } from "../battle/moves.js";
import { ABILITIES, abilityUser, hasAbility } from "../data/abilities.js";
import { JOURNAL } from "../data/items.js";

const ROC = "Prof. Roc";
const MAIA = "Maïa";
const idx = (name) => DINOS.findIndex((d) => d.name.startsWith(name));
const pure = (name) => { const i = idx(name); return { head: i, teeth: i, frontLegs: i, backLegs: i, back: i, tail: i, color: i }; };
const dino = (name, level, nickname) => createDino(pure(name), level, nickname);

// ---------------------------------------------------------------- hybridizer
async function hybrideur(api) {
  const { say, choose, flag, setFlag, save, sound, flash, shake, refreshFollower } = api;
  if (!state.party.length) {
    await say(null, "Une énorme machine couverte de cadrans. Les voyants clignotent faiblement.");
    return;
  }
  if (!flag("hybrideur_vu")) {
    await say(ROC, "Ah, tu t'intéresses à l'hybrideur ! C'est l'œuvre de toute la vie d'Hélène.");
    await say(ROC, "Place un fragment d'ambre dans le réceptacle : la machine lit l'ADN et greffe la partie de ton choix sur ton dino. Une tête, des griffes, une queue…");
    await say(ROC, "Et une greffe peut changer beaucoup de choses : ses attaques, son type… et ce qu'il sait faire en exploration.");
    await say(ROC, "Une tête de cératopsien, par exemple, permet de foncer dans les rochers : c'est la capacité Charge. Des griffes de raptor permettent de trancher : c'est Tranche.");
    setFlag("hybrideur_vu");
  }
  if (!state.amber.length) {
    await say(null, "Le réceptacle est vide. Il te faut un fragment d'ambre : cherche bien dans les Plaines !");
    return;
  }
  sound("machine", { volume: 0.5 });
  await say(null, "L'hybrideur ronronne. Quel dino veux-tu placer dans la capsule ?");
  const who = await choose([...state.party.map((d) => `${d.nickname} (${d.speciesName})`), "Annuler"]);
  if (who >= state.party.length) return;
  const d = state.party[who];

  const options = [...state.amber.map((s) => `Ambre de ${s}`)];
  if (d.origin) options.push("Retirer toutes les greffes");
  const amber = await choose([...options, "Annuler"]);
  if (amber >= options.length) return;
  if (amber === state.amber.length) {
    const c = await choose([`Rendre à ${d.nickname} son corps d'origine`, "Annuler"]);
    if (c !== 0) return;
    for (const part of Object.keys(GRAFT_PARTS)) d.build[part] = d.origin[part];
    graft(d, "head", d.origin.head); // recompute name, HP and moves
    delete d.origin;
    sound("glass", { volume: 0.6 });
    flash(300, 255, 220, 150);
    await say(null, `${d.nickname} a retrouvé son corps d'origine.`);
    refreshFollower();
    save();
    return;
  }
  const species = state.amber[amber], sIdx = idx(species);

  const parts = Object.keys(GRAFT_PARTS);
  const part = parts[await choose([...parts.map((p) => `${GRAFT_PARTS[p]} (actuellement : ${DINOS[d.build[p]].name})`), "Annuler"])];
  if (!part) return;
  if (d.build[part] === sIdx) {
    await say(null, `${d.nickname} a déjà cette partie de ${species}.`);
    return;
  }
  const preview = speciesName({ ...d.build, [part]: sIdx });
  const ok = await choose([`Greffer : ${GRAFT_PARTS[part]} de ${species}`, "Annuler"]);
  if (ok !== 0) return;

  const before = Object.keys(ABILITIES).filter((a) => hasAbility(d, a));
  if (!d.origin) d.origin = { ...d.build };
  sound("latch", { volume: 0.6 });
  await say(null, "La capsule se referme. L'ambre s'illumine…");
  sound("machine", { volume: 0.7 });
  shake(600, 0.006);
  await api.wait(500);
  sound("glass", { volume: 0.7 });
  flash(400, 255, 200, 120);
  const learned = graft(d, part, sIdx);
  await say(null, `Greffe réussie ! ${d.nickname} est maintenant un ${preview}.`);
  for (const l of learned) {
    await say(null, l.replaced ? `${d.nickname} oublie ${MOVES[l.replaced].name} et apprend ${MOVES[l.move].name} !` : `${d.nickname} apprend ${MOVES[l.move].name} !`);
  }
  for (const [id, a] of Object.entries(ABILITIES)) {
    if (!before.includes(id) && hasAbility(d, id)) await say(null, `${a.icon} ${d.nickname} peut maintenant utiliser ${a.name} en exploration ! ${a.desc}`);
  }
  refreshFollower();
  save();
}

// ---------------------------------------------------------------- the boulder
async function rocher(api) {
  const { say, choose, flag, setFlag, save, sound, shake, removeEntity, spawn } = api;
  if (flag("rocher_brise")) return;
  const d = abilityUser(state.party, "charge");
  if (!d) {
    await say(null, "Un énorme rocher bloque l'entrée de la grotte. Il faudrait un dino à la tête très dure pour le pulvériser…");
    await say(null, `(Il faut ${ABILITIES.charge.partName} dans ton équipe. Le Professeur Roc en saura plus.)`);
    return;
  }
  await say(null, "Un énorme rocher bloque l'entrée de la grotte.");
  const c = await choose([`${d.nickname}, Charge !`, "Laisser le rocher"]);
  if (c !== 0) return;
  await say(null, `${d.nickname} gratte le sol, baisse la tête… et fonce !`);
  sound("rock_heavy", { volume: 0.9 });
  sound("rock_0", { volume: 0.8, delay: 0.08 });
  sound("rock_1", { volume: 0.7, delay: 0.25 });
  shake(500, 0.02);
  await removeEntity("rocher", "shatter");
  setFlag("rocher_brise");
  spawn("entreeGrotte", { caveMouth: false });
  save();
  await say(null, "Le rocher vole en éclats ! L'entrée de la Grotte des Échos est ouverte.");
  await say("Chloé", "Un courant d'air froid… On dirait que la grotte respire.");
}

// ---------------------------------------------------------------- grunts
function grunt(id, name, face, teamFn, reward, lines) {
  return async (api) => {
    const { say, flag, setFlag, save, battle, npcFace, hideNpc } = api;
    const done = `${id}_battu`;
    if (flag(done)) return;
    npcFace(id, face);
    for (const l of lines.before) await say(name, l);
    const result = await battle({ trainer: { name, team: teamFn(), reward } });
    if (result !== "win") return;
    for (const l of lines.after) await say(name, l);
    setFlag(done);
    save();
    hideNpc(id);
  };
}

const sbire1 = grunt("sbire1", "Sbire Kraz", "down", () => [dino("Compsognathus", 6), dino("Dilophosaurus", 7)], 80, {
  before: [
    "Halte ! Personne ne passe. Cette grotte appartient à l'Ombre Noire.",
    "Une gamine avec un bébé dino ? Le Masque d'Obsidienne va bien rire. Montre-moi ce qu'il vaut !",
  ],
  after: [
    "Grr… Tu cognes fort pour une gamine.",
    "Peu importe. On a déjà pris presque tout l'ambre de cette grotte. Le Masque aura ce qu'il veut !",
  ],
});

const sbire2 = grunt("sbire2", "Sbire Vesna", "left", () => [dino("Troodon", 8), dino("Ceratosaurus", 8)], 120, {
  before: [
    "Encore toi ? Kraz m'a prévenue. Tu es la petite-fille de la Varenne, c'est ça ?",
    "Ta grand-mère a volé quelque chose qui appartient à l'Ombre Noire. Et toi, tu vas payer à sa place !",
  ],
  after: [
    "Impossible… Bon, j'abandonne cette grotte. De toute façon, la créature du fond est à moitié folle.",
    "On l'a nourrie d'ambre forcé pour la rendre plus forte. Elle ne sait plus qui est son maître. Bonne chance…",
  ],
});

// ---------------------------------------------------------------- the forced hybrid
async function hybrideForce(api) {
  const { say, choose, flag, setFlag, save, battle, sound, shake, removeEntity } = api;
  if (flag("hybride_battu")) return;
  shake(300, 0.008);
  sound("rock_1", { volume: 0.5 });
  await say(null, "Un dino se dresse dans l'ombre. Des veines violettes palpitent sous ses écailles. Il gronde… de douleur, plus que de colère.");
  await say("Chloé", "C'est l'Ombre Noire qui lui a fait ça ? Il faut l'aider !");
  const b = { ...pure("Pachycephalosaurus"), teeth: idx("Velociraptor"), frontLegs: idx("Velociraptor"), tail: idx("Velociraptor") };
  const foe = createDino(b, 8, "Hybride forcé");
  foe.speciesName = "Hybride forcé";
  foe.tint = "#6a3d8a";
  const result = await battle({ trainer: { name: "Hybride forcé", boss: true, team: [foe] } });
  if (result !== "win") return;
  await say(null, "Le dino s'effondre… puis se relève doucement. Les veines violettes pâlissent. Pour la première fois, son regard est calme.");
  await say(null, "Il s'approche de toi et pose sa tête contre ta main.");
  const c = await choose(["L'emmener avec toi", "Le laisser libre"]);
  setFlag("hybride_battu");
  if (c === 0) {
    const d = createDino(b, 8, "Écho");
    d.tint = "#7a5a92";
    if (state.party.length < 4) state.party.push(d);
    else (state.box ||= []).push(d);
    await say(null, state.party.includes(d) ? "Écho rejoint ton équipe !" : "Écho rejoint ton équipe… et part se reposer au Cabinet, car ton équipe est complète.");
  } else {
    await say(null, "Il te regarde une dernière fois, puis disparaît dans les galeries. Il est libre.");
  }
  await removeEntity("hybride", "fade");
  save();
}

// ---------------------------------------------------------------- the Alpha
async function alphaReveil(api) {
  const { say, flag, setFlag, save, battle, sound, shake, flash, removeEntity, spawn, give, giveJournal } = api;
  if (flag("alpha_battu")) return;
  shake(900, 0.012);
  sound("rock_heavy", { volume: 0.7 });
  await say(null, "Le sol tremble. Au centre de la salle, une montagne de muscles et de cornes se redresse lentement.");
  await say(null, "Un Tricératops immense. Des siècles de cicatrices sur la collerette. Ses yeux te jaugent.");
  await say("Chloé", "Le gardien des Plaines… Celui dont parlait grand-mère.");
  const foe = createDino(pure("Triceratops"), 10, "Tricératops Alpha");
  foe.speciesName = "Tricératops Alpha";
  const result = await battle({ trainer: { name: "Tricératops Alpha", boss: true, team: [foe], intro: "Le Tricératops Alpha baisse ses cornes et charge !" } });
  if (result !== "win") return;
  flash(600, 255, 230, 160);
  await say(null, "L'Alpha recule d'un pas. Puis, lentement, il incline sa tête immense devant toi.");
  await say(null, "Entre ses cornes brille un disque d'ambre gravé d'une feuille de fougère.");
  give("sceau_plaines", 1);
  sound("item", { volume: 0.8 });
  await say(null, "Tu reçois le Sceau des Plaines !");
  giveJournal(5);
  await say(null, `Coincée sous le sceau, une page du journal d'Hélène ! « ${JOURNAL[5].title} ».`);
  setFlag("alpha_battu");
  await removeEntity("alpha", "fade");
  spawn("echelleCrane");
  save();
  await say(null, "L'Alpha disparaît dans une galerie. Une échelle de corde pend d'une fissure au plafond : elle mène à l'air libre.");
}

async function alpha(api) {
  return alphaReveil(api);
}

// ---------------------------------------------------------------- ladders
async function echelleHaut({ warp }) {
  await warp({ map: "grotte1", x: 6, y: 4, dir: "down" });
}

async function echelleCrane({ say, warp }) {
  await say(null, "Tu grimpes à l'échelle…");
  await warp({ map: "ambreluneSud", x: 26, y: 17, dir: "down" });
}

// ---------------------------------------------------------------- the trunk and Maïa
function maiaTeam() {
  // Maïa always has the type that beats your first dino.
  const counter = ["Ankylosaurus", "Parasaurolophus", "Pteranodon"][state.flags.starterIndex ?? 0];
  return [dino("Gallimimus", 10, "Fusée"), dino(counter, 11)];
}

async function maiaDefi(api) {
  const { say, setFlag, save, battle, hideNpc } = api;
  await say(MAIA, "Bon. Maintenant qu'on est à égalité… on règle ça. Le premier qui gagne passe devant dans la forêt !");
  const result = await battle({ trainer: { name: "Maïa", team: maiaTeam(), reward: 200 } });
  if (result !== "win") return;
  await say(MAIA, "… T'as gagné. Pour cette fois !");
  await say(MAIA, "Tu sais, mon père dit que ta grand-mère a sauvé le port pendant la grande tempête. Je crois que je comprends pourquoi tout le monde parle d'elle.");
  await say(MAIA, "La Forêt Jurassique, c'est là-haut. On se reverra, Chloé. Et la prochaine fois, je gagne !");
  setFlag("maia_battue");
  save();
  hideNpc("maia2");
}

async function tronc(api) {
  const { say, choose, flag, setFlag, save, sound, shake, removeEntity, spawn, npcFace } = api;
  if (flag("tronc_coupe")) return;
  if (!flag("alpha_battu")) {
    await say(null, "Un tronc géant barre le chemin de la forêt. Il est bien trop lourd pour être poussé.");
    await say(null, "Quelqu'un a gravé une feuille de fougère dans l'écorce… le même symbole que sur le grand crâne des Plaines.");
    return;
  }
  const d = abilityUser(state.party, "tranche");
  npcFace("maia2", "right");
  if (!d) {
    await say(MAIA, "Te voilà ! J'ai tout essayé : pousser, tirer, grimper… Rien à faire. Ce tronc est énorme.");
    await say(MAIA, "Il faudrait le trancher en morceaux. Avec des griffes de raptor, peut-être ?");
    await say(null, `(Il faut ${ABILITIES.tranche.partName} dans ton équipe. Le bosquet secret d'Hélène et l'hybrideur du Cabinet pourraient t'aider.)`);
    return;
  }
  await say(MAIA, `Hé, ${d.nickname} a de sacrées griffes ! Si on s'y met à deux, on peut couper ce tronc.`);
  const c = await choose([`${d.nickname}, Tranche !`, "Pas maintenant"]);
  if (c !== 0) return;
  await say(MAIA, "À trois ! Un… deux… TROIS !");
  sound("slice", { volume: 0.9 });
  sound("chop", { volume: 0.8, delay: 0.2 });
  sound("wood_heavy", { volume: 0.9, delay: 0.55 });
  shake(400, 0.012);
  await removeEntity("tronc", "cut");
  setFlag("tronc_coupe");
  spawn("foret");
  save();
  await say(null, "Le tronc se fend en deux et roule sur le côté. La route de la Forêt Jurassique est ouverte !");
  await maiaDefi(api);
}

async function maiaTronc(api) {
  if (!api.flag("tronc_coupe")) return tronc(api);
  if (!api.flag("maia_battue")) return maiaDefi(api);
}

async function foretJurassique({ say, pushBack }) {
  await say(null, "Devant toi, des fougères géantes et des arbres aussi hauts que des tours. Des cris résonnent au loin.");
  await say(null, "🌿 La Forêt Jurassique — Chapitre 2, bientôt disponible !");
  pushBack();
}

export const CHAPTER1 = {
  hybrideur, rocher, sbire1, sbire2, hybrideForce, alphaReveil, alpha,
  echelleHaut, echelleCrane, tronc, maiaTronc, foretJurassique,
};

// Roc's advice depending on how far Chloé got.
export function rocHint() {
  const f = (k) => !!state.flags[k];
  const charge = abilityUser(state.party, "charge"), tranche = abilityUser(state.party, "tranche");
  if (!f("rocher_brise")) {
    if (charge) return [`${charge.nickname} a une vraie tête de cératopsien : il peut utiliser Charge !`, "Va voir le rocher qui bloque la Grotte des Échos, à l'est des Plaines. Il ne résistera pas."];
    if (state.amber.includes("Protoceratops")) return ["Tu as un fragment de Protoceratops ! Utilise l'hybrideur, la grande machine derrière moi, pour greffer sa tête sur un de tes dinos.", "Avec une tête de cératopsien, ton dino pourra utiliser Charge et pulvériser le rocher de la grotte."];
    return ["Le rocher qui bloque la Grotte des Échos ? Il faudrait un dino avec une tête de cératopsien, comme un Protoceratops.", "Fouille les Plaines : on y trouve de l'ambre… et des Protoceratops sauvages, si tu arrives à en capturer un."];
  }
  if (!f("alpha_battu")) return ["La Grotte des Échos… Hélène y passait des nuits entières. Sois prudente : on dit que l'Ombre Noire y a installé des hommes.", "Repose-toi aux feux de camp : si tu perds un combat, c'est là que tu te réveilleras."];
  if (!f("tronc_coupe")) {
    if (tranche) return [`Le Sceau des Plaines ! Hélène serait si fière…`, `Pour le tronc, ${tranche.nickname} a les griffes qu'il faut : il peut utiliser Tranche !`];
    return ["Le Sceau des Plaines ! Hélène serait si fière…", "Pour le tronc, il faudrait des griffes de raptor. Hélène avait un bosquet secret au nord-est des Plaines… Elle y cachait sûrement de l'ambre.", "Ensuite, l'hybrideur fera le reste : greffe les pattes avant d'un raptor sur un de tes dinos."];
  }
  return ["La route de la Forêt Jurassique est ouverte… Hélène est passée par là, j'en suis sûr.", "Entraîne ton équipe. Ce qui t'attend là-bas est bien plus dangereux que les Plaines."];
}
