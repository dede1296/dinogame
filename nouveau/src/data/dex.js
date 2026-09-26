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
// Where to find a species is always told as hearsay, with varied voices ("On dit que…",
// "Un vieux pêcheur raconte…"). Each species keeps its own wording, so the Dinodex does
// not change every time it is opened, but neighbouring entries sound different.

// Where each zone's dinos live, as the end of a sentence.
const ZONES = {
  plaines: "dans les hautes herbes et le long des chemins des Plaines des Fougères",
  grotte: "dans l'obscurité de la Grotte des Échos",
};
// Regions still to explore (see HISTOIRE.md), by family.
const FAMILY_PLACES = {
  raptor: "en meute dans la Forêt Jurassique, au nord des Plaines",
  sauropod: "au-dessus des arbres de la Forêt Jurassique, où l'on voit dépasser de longs cous",
  spino: "dans les eaux troubles du Marais Brumeux",
  hadrosaur: "en troupeau au bord du Marais Brumeux",
  tyrant: "dans les canyons du Désert Aride",
  armored: "sur les rochers brûlants du Désert Aride",
  ceratopsian: "dans les grands espaces, des Plaines jusqu'au Désert Aride",
  marine: "dans les grottes marines de la Côte Préhistorique",
  flyer: "tout là-haut, dans les nids des Cieux Éternels",
};
const SPECIAL_PLACES = {
  Cryolophosaurus: "dans le froid des Monts Gelés",
  Glaciodonte: "endormi sous la glace des Monts Gelés",
  Infernodonte: "dans les flammes de la Plaine Volcanique",
};

// The voices that pass the word around: `{lieu}` is where, `{nom}` the species.
const VOICES = [
  "On dit qu'on en croise {lieu}.",
  "Des rumeurs parlent d'un {nom} aperçu {lieu}.",
  "Un vieux pêcheur de Port-Ambre jure en avoir vu {lieu}.",
  "D'après les randonneurs, il faudrait chercher {lieu}.",
  "Hélène avait griffonné dans son carnet : « {nom} — {lieu} ».",
  "Maïa prétend en avoir suivi la trace {lieu}.",
  "On raconte au village qu'il vit {lieu}.",
  "Le Professeur Roc a entendu dire qu'il se cache {lieu}.",
];

const RARITY = {
  rare: "Espèce rare : ouvre l'œil.",
  epic: "Espèce mystérieuse : très peu l'ont vue.",
  legendary: "Espèce légendaire.",
};

const voiceFor = (name, n) => VOICES[(dexNumber(name) + n) % VOICES.length];
const rumour = (name, place, n = 0) => voiceFor(name, n).replace("{lieu}", place).replace("{nom}", name);

/** Hints on where or how to find a species, as rumours, most useful first. */
export function dexHints(name) {
  const hints = [];
  const zones = Object.entries(ENCOUNTERS).filter(([, list]) => list.some(([n]) => n === name)).map(([z]) => ZONES[z]).filter(Boolean);
  zones.forEach((place, k) => hints.push(rumour(name, place, k)));
  if (STARTERS.some((s) => name.startsWith(s.species))) hints.push("On raconte qu'Hélène en avait confié un œuf au Professeur Roc, au Cabinet de Port-Ambre.");
  if (name === "Triceratops") hints.push("On murmure qu'un Tricératops immense dort sous le grand crâne des Plaines.");
  const sp = DINOS.find((d) => d.name === name);
  if (name === "Indominus" || name === "Titanosaure d'Or") hints.push("Une légende dit qu'un squelette fossile complet pourrait faire revivre cette espèce oubliée.");
  else if (SPECIAL_PLACES[name]) hints.push(rumour(name, SPECIAL_PLACES[name], 3));
  else if (!zones.length && sp && FAMILY_PLACES[sp.family]) hints.push(rumour(name, FAMILY_PLACES[sp.family], 5));
  if (sp?.rarity && RARITY[sp.rarity]) hints.push(RARITY[sp.rarity]);
  return hints.length ? hints : ["Personne n'en a jamais parlé… Explore l'île !"];
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
