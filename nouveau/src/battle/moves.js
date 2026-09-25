// Moves and how dinos learn them.
//
// type: "neutre" or one of the elemental types (feu, eau, terre, vent, pierre, nature).
// power: 0 for status moves. accuracy: 0..1. pp: uses per battle.
// effect: { status, chance } inflicts a status; { self|foe: { stat: stages } } changes stats;
//         { heal: fraction } restores HP; crit: higher critical chance; priority: acts first.

export const MOVES = {
  // Neutral basics.
  morsure: { name: "Morsure", type: "neutre", power: 40, accuracy: 1, pp: 25, fx: "bite" },
  coupQueue: { name: "Coup de queue", type: "neutre", power: 40, accuracy: 1, pp: 25, fx: "tail" },
  charge: { name: "Charge", type: "neutre", power: 45, accuracy: 0.95, pp: 20, fx: "charge" },
  griffes: { name: "Griffes", type: "neutre", power: 40, accuracy: 1, pp: 25, crit: true, fx: "claw" },
  rugissement: { name: "Rugissement", type: "neutre", power: 0, accuracy: 1, pp: 20, effect: { foe: { atk: -1 } }, fx: "roar", desc: "Baisse l'attaque de l'adversaire." },
  regardFeroce: { name: "Regard féroce", type: "neutre", power: 0, accuracy: 1, pp: 20, effect: { foe: { def: -1 } }, fx: "roar", desc: "Baisse la défense de l'adversaire." },

  // Feu — tyrant.
  morsureBroyeuse: { name: "Morsure broyeuse", type: "feu", power: 75, accuracy: 0.9, pp: 10, effect: { status: "saigne", chance: 0.3 }, fx: "bite" },
  ragePredateur: { name: "Rage du prédateur", type: "feu", power: 0, accuracy: 1, pp: 10, effect: { self: { atk: 2 } }, fx: "roar", desc: "Augmente beaucoup l'attaque." },
  crocsBrulants: { name: "Crocs brûlants", type: "feu", power: 60, accuracy: 1, pp: 15, fx: "bite" },

  // Eau — spino, marine.
  machoireAquatique: { name: "Mâchoire aquatique", type: "eau", power: 65, accuracy: 0.95, pp: 15, fx: "bite" },
  vagueCaudale: { name: "Vague caudale", type: "eau", power: 55, accuracy: 1, pp: 15, fx: "wave" },
  plongeon: { name: "Plongeon abyssal", type: "eau", power: 90, accuracy: 0.85, pp: 5, fx: "charge" },

  // Terre — sauropod, ceratopsian.
  coupCorne: { name: "Coup de corne", type: "terre", power: 60, accuracy: 0.95, pp: 15, effect: { status: "etourdi", chance: 0.2 }, fx: "charge" },
  pietinement: { name: "Piétinement", type: "terre", power: 70, accuracy: 0.9, pp: 10, fx: "quake" },
  seisme: { name: "Séisme", type: "terre", power: 95, accuracy: 0.9, pp: 5, fx: "quake" },
  fouetCaudal: { name: "Fouet caudal", type: "terre", power: 55, accuracy: 1, pp: 15, fx: "tail" },

  // Vent — raptor, flyer.
  bondGriffu: { name: "Bond griffu", type: "vent", power: 50, accuracy: 1, pp: 20, priority: true, fx: "claw", desc: "Frappe toujours en premier." },
  laceration: { name: "Lacération", type: "vent", power: 65, accuracy: 0.95, pp: 15, crit: true, effect: { status: "saigne", chance: 0.2 }, fx: "claw" },
  tornadeAiles: { name: "Tornade d'ailes", type: "vent", power: 60, accuracy: 0.95, pp: 15, fx: "wind" },
  pique: { name: "Piqué", type: "vent", power: 85, accuracy: 0.85, pp: 5, fx: "charge" },

  // Pierre — armored.
  massue: { name: "Massue", type: "pierre", power: 80, accuracy: 0.85, pp: 10, effect: { status: "etourdi", chance: 0.3 }, fx: "tail" },
  picsDorsaux: { name: "Pics dorsaux", type: "pierre", power: 50, accuracy: 1, pp: 15, effect: { status: "saigne", chance: 0.3 }, fx: "spikes" },
  blindage: { name: "Blindage", type: "pierre", power: 0, accuracy: 1, pp: 10, effect: { self: { def: 2 } }, fx: "shield", desc: "Augmente beaucoup la défense." },
  coupCrane: { name: "Coup de crâne", type: "pierre", power: 70, accuracy: 0.9, pp: 10, fx: "charge" },

  // Nature — hadrosaur.
  criTrompette: { name: "Cri trompette", type: "nature", power: 0, accuracy: 1, pp: 15, effect: { status: "peur", chance: 1 }, fx: "roar", desc: "Effraie l'adversaire : son attaque faiblit." },
  fougeres: { name: "Festin de fougères", type: "nature", power: 0, accuracy: 1, pp: 5, effect: { heal: 0.5 }, fx: "heal", desc: "Récupère la moitié de ses PV." },
  racines: { name: "Fouet de lianes", type: "nature", power: 55, accuracy: 1, pp: 15, fx: "wave" },
  voileMenacante: { name: "Voile menaçante", type: "eau", power: 0, accuracy: 1, pp: 10, effect: { status: "peur", chance: 1 }, fx: "roar", desc: "Effraie l'adversaire : son attaque faiblit." },
};

export const TYPE_COLORS = {
  neutre: "#b9b3a4", feu: "#e8622a", eau: "#3a8fd0", terre: "#b8894a", vent: "#8fd0c8", pierre: "#8a8272", nature: "#5fae44",
};

export const TYPE_NAMES = { neutre: "Neutre", feu: "Feu", eau: "Eau", terre: "Terre", vent: "Vent", pierre: "Pierre", nature: "Nature" };

// What each part teaches, by donor family: [level, move].
// A hybrid learns from all of its parts, which is what makes hybridization interesting.
const LEARN = {
  head: {
    tyrant: [[1, "morsure"], [8, "ragePredateur"], [14, "morsureBroyeuse"]],
    spino: [[1, "morsure"], [7, "machoireAquatique"]],
    raptor: [[1, "morsure"], [6, "regardFeroce"]],
    sauropod: [[1, "charge"], [9, "rugissement"]],
    ceratopsian: [[1, "charge"], [5, "coupCorne"]],
    armored: [[1, "charge"], [7, "coupCrane"]],
    hadrosaur: [[1, "charge"], [5, "criTrompette"]],
    flyer: [[1, "morsure"], [8, "pique"]],
    marine: [[1, "morsure"], [6, "machoireAquatique"], [18, "plongeon"]],
  },
  teeth: {
    tyrant: [[10, "crocsBrulants"]],
    spino: [[12, "crocsBrulants"]],
    marine: [[10, "crocsBrulants"]],
  },
  frontLegs: {
    raptor: [[1, "griffes"], [9, "laceration"]],
    spino: [[4, "griffes"]],
    flyer: [[1, "tornadeAiles"]],
    tyrant: [[3, "rugissement"]],
  },
  backLegs: {
    raptor: [[3, "bondGriffu"]],
    sauropod: [[6, "pietinement"], [20, "seisme"]],
    ceratopsian: [[8, "pietinement"]],
    armored: [[12, "pietinement"]],
    hadrosaur: [[10, "fougeres"]],
    marine: [[4, "vagueCaudale"]],
  },
  back: {
    armored: [[4, "blindage"], [9, "picsDorsaux"]],
    spino: [[5, "voileMenacante"]],
    ceratopsian: [[6, "blindage"]],
  },
  tail: {
    armored: [[1, "coupQueue"], [11, "massue"]],
    sauropod: [[1, "coupQueue"], [7, "fouetCaudal"]],
    marine: [[1, "vagueCaudale"]],
    hadrosaur: [[7, "racines"]],
  },
};

const DEFAULT_TAIL = [[1, "coupQueue"]];

/** Moves a build can know at `level`, ordered by the level they are learned. */
export function learnset(build, dinos) {
  const list = [];
  for (const part of Object.keys(LEARN)) {
    const fam = dinos[build[part]]?.family;
    const entries = LEARN[part][fam] || (part === "tail" ? DEFAULT_TAIL : []);
    for (const [lvl, id] of entries) if (!list.some((e) => e.id === id)) list.push({ level: lvl, id });
  }
  return list.sort((a, b) => a.level - b.level);
}
