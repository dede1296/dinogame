// Dinodex, like the Pokédex: every species is "unseen", "seen" (met in battle or crossed
// on the map) or "caught" (captured or received). Stored in state.dex.

import { DINOS } from "../../../src/data/dinos.js";
import { state } from "../state/game.js";
import { ENCOUNTERS } from "./encounters.js";
import { STARTERS } from "../story/scripts.js";

let place = "";
/** Where Chloé is now (zone name), recorded with each new sighting. */
export const setDexPlace = (name) => { place = name || ""; };

const dex = () => (state.dex ||= { seen: {}, caught: {} });
export const dexNumber = (name) => DINOS.findIndex((d) => d.name === name) + 1;
export const formatNumber = (n) => `#${String(n).padStart(3, "0")}`;

/** Species a dino counts as in the Dinodex (its own species, or its head's for a wild hybrid). */
export function dexSpeciesOf(d) {
  return d.dexSpecies || DINOS[d.build?.head]?.name || null;
}

/** Marks a species as seen (`shiny`: its shiny form was seen); returns true the first time. */
export function markSeen(name, { shiny = false } = {}) {
  if (!name) return false;
  const seen = dex().seen;
  const prev = seen[name];
  seen[name] = { at: prev?.at || Date.now(), place: prev?.place || place, count: (prev?.count || 0) + 1, shiny: !!(prev?.shiny || shiny) };
  return !prev;
}

/** Marks a species as caught (and seen); returns true the first time. */
export function markCaught(name, { shiny = false } = {}) {
  if (!name) return false;
  if (!dex().seen[name]) markSeen(name, { shiny });
  else if (shiny) dex().seen[name].shiny = true;
  const caught = dex().caught;
  const first = !caught[name];
  if (first) caught[name] = { at: Date.now(), place, shiny };
  else if (shiny) caught[name].shiny = true;
  return first;
}

export function dexStatus(name) {
  if (dex().caught[name]) return "caught";
  return dex().seen[name] ? "seen" : "unseen";
}

export const dexInfo = (name) => ({ seen: dex().seen[name] || null, caught: dex().caught[name] || null });

export function dexCounts() {
  return { seen: Object.keys(dex().seen).length, caught: Object.keys(dex().caught).length, total: DINOS.length };
}

/**
 * Older saves had no Dinodex: count the dinos already in the team and at the Cabinet.
 * A grafted starter no longer looks like its species, so the starter choice is used.
 */
export function syncDexWithTeam() {
  const starter = STARTERS[state.flags.starterIndex ?? -1]?.species;
  if (starter && state.flags.starter) markCaught(DINOS.find((d) => d.name.startsWith(starter))?.name);
  for (const d of [...state.party, ...(state.box || [])]) {
    const pure = Object.values(d.build).every((v) => v === d.build.head);
    if (d.dexSpecies || pure) markCaught(dexSpeciesOf(d), { shiny: !!d.shiny });
  }
}

// ---------------------------------------------------------------- hints
const ZONES = {
  plaines: "dans les hautes herbes et le long des chemins des Plaines des Fougères",
  grotte: "dans l'obscurité de la Grotte des Échos",
};
// Rumours about the regions still to explore (see HISTOIRE.md).
const FAMILY_RUMOURS = {
  raptor: "On entend des cris de meute dans la Forêt Jurassique, au nord des Plaines.",
  sauropod: "On aperçoit parfois de longs cous au-dessus des arbres de la Forêt Jurassique.",
  spino: "Un grand chasseur à voile rôderait dans les eaux du Marais Brumeux.",
  hadrosaur: "Des troupeaux paissent au bord du Marais Brumeux.",
  tyrant: "Les canyons du Désert Aride abritent de grands prédateurs.",
  armored: "Les dinos cuirassés aiment les rochers brûlants du Désert Aride.",
  ceratopsian: "Les cornus préfèrent les grands espaces : Plaines, puis Désert Aride.",
  marine: "Il vivrait dans les grottes marines de la Côte Préhistorique.",
  flyer: "Il nicherait tout là-haut, dans les Cieux Éternels.",
};
const SPECIAL = {
  Cryolophosaurus: "Il supporte le froid des Monts Gelés.",
  Glaciodonte: "On dit qu'il dort sous la glace des Monts Gelés.",
  Infernodonte: "Né des flammes de la Plaine Volcanique, raconte la légende.",
  Indominus: "Espèce oubliée : un squelette fossile complet pourrait la faire revivre.",
  "Titanosaure d'Or": "Espèce oubliée : un squelette fossile complet pourrait la faire revivre.",
};
const RARITY = {
  rare: "Espèce rare : ouvre l'œil.",
  epic: "Espèce mystérieuse : très peu l'ont vue.",
  legendary: "Espèce légendaire.",
};

/** Hints on where or how to find a species, most useful first. */
export function dexHints(name) {
  const hints = [];
  const zones = Object.entries(ENCOUNTERS).filter(([, list]) => list.some(([n]) => n === name)).map(([z]) => ZONES[z]).filter(Boolean);
  if (zones.length) hints.push(`Se rencontre ${zones.join(", et ")}.`);
  if (STARTERS.some((s) => name.startsWith(s.species))) hints.push("L'un des trois bébés confiés par le Professeur Roc, au Cabinet.");
  if (name === "Triceratops") hints.push("Le Tricératops Alpha dort sous le grand crâne des Plaines.");
  const sp = DINOS.find((d) => d.name === name);
  if (SPECIAL[name]) hints.push(SPECIAL[name]);
  else if (!zones.length && sp && FAMILY_RUMOURS[sp.family]) hints.push(`On raconte que… ${FAMILY_RUMOURS[sp.family]}`);
  if (sp?.rarity && RARITY[sp.rarity]) hints.push(RARITY[sp.rarity]);
  return hints.length ? hints : ["Personne ne sait encore où le trouver. Explore l'île !"];
}

// ---------------------------------------------------------------- habitats
const HABITAT_NAMES = { plaines: "Plaines des Fougères", grotte: "Grotte des Échos" };

/** Each zone with wild dinos: its species and how many were seen / caught. */
export function dexHabitats() {
  return Object.entries(ENCOUNTERS).map(([id, list]) => {
    const species = [...new Set(list.map(([n]) => DINOS.find((d) => d.name.startsWith(n))?.name).filter(Boolean))];
    return {
      id, name: HABITAT_NAMES[id] || id, species,
      seen: species.filter((n) => dexStatus(n) !== "unseen").length,
      caught: species.filter((n) => dexStatus(n) === "caught").length,
    };
  });
}

// ---------------------------------------------------------------- Professor Roc
// Like Professor Oak's Pokédex evaluations: a reward every 10 species caught.
export const ROC_REWARDS = [
  { at: 10, items: { collier: 5, fougere: 3 } },
  { at: 20, items: { collier: 8, baie: 3 } },
  { at: 30, items: { collier: 10, fougere: 5 }, money: 150 },
  { at: 40, items: { collier: 12, baie: 5 }, money: 250 },
  { at: 50, items: { collier: 15, fougere: 8 }, money: 400 },
  { at: 60, items: { collier: 20, fougere: 10, baie: 10 }, money: 600 },
];
const ROC_COMMENTS = [
  [0, "C'est un bon début. Chaque espèce compte : observe-les bien."],
  [5, "Tu commences à connaître les Plaines. Hélène serait contente."],
  [10, "Déjà une belle collection ! Tu as l'œil, c'est sûr."],
  [20, "Impressionnant. Même Hélène n'en avait pas autant à ses débuts."],
  [35, "Ton Dinodex devient une vraie encyclopédie de l'île !"],
  [50, "Incroyable… Il ne te manque presque plus rien."],
  [65, "Toutes les espèces ! Tu as terminé le Dinodex. Hélène n'y était jamais arrivée."],
];

export const rocComment = (caught) => ROC_COMMENTS.filter(([n]) => caught >= n).at(-1)[1];

/** Rewards reached but not yet given by the Professor. */
export function pendingRocRewards() {
  const done = state.flags.rocDexReward || 0, caught = dexCounts().caught;
  return ROC_REWARDS.filter((r) => r.at > done && r.at <= caught);
}

/** The next reward still to reach, or null. */
export function nextRocReward() {
  return ROC_REWARDS.find((r) => r.at > dexCounts().caught) || null;
}
