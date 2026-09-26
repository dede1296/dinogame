// Exploration abilities (like Pokémon HMs): a dino in the party can use one when it
// carries the right body part — naturally or grafted with the Cabinet's hybridizer.

import { DINOS } from "../../../src/data/dinos.js";
import { state } from "../state/game.js";

// Monture: big enough to carry a rider. Strong hind legs (power 7+) on a land dino,
// except a few that are too small for it, plus some tall runners and grazers.
const RIDE_TOO_SMALL = new Set(["Velociraptor", "Deinonychus", "Pachycephalosaurus", "Fulguroraptor"]);
const RIDE_TALL = new Set(["Gallimimus", "Maiasaura", "Parasaurolophus", "Corythosaurus"]);
const canCarry = (sp) => !["flyer", "marine"].includes(sp.family)
  && (RIDE_TALL.has(sp.name) || (sp.backLegs.power >= 7 && !RIDE_TOO_SMALL.has(sp.name)));

export const ABILITIES = {
  charge: { name: "Charge", icon: "💥", part: "head", families: ["ceratopsian"], partName: "une tête de cératopsien (Protoceratops, Tricératops…)", desc: "Fonce tête baissée : brise les gros rochers." },
  tranche: { name: "Tranche", icon: "🗡️", part: "frontLegs", families: ["raptor"], partName: "des griffes de raptor (Velociraptor…)", desc: "Griffes acérées : tranche les troncs et les ronces." },
  monture: { name: "Monture", icon: "🐾", part: "backLegs", test: canCarry, partName: "de solides pattes arrière (Tricératops, Iguanodon, Gallimimus…)", desc: "Porte Chloé sur son dos : on avance bien plus vite." },
};

export function hasAbility(dino, id) {
  const a = ABILITIES[id];
  const sp = DINOS[dino.build[a.part]];
  if (!sp) return false;
  return a.test ? a.test(sp) : a.families.includes(sp.family);
}

/** The first party dino able to use the ability, or null. */
export function abilityUser(party, id) {
  // Debug "passe-partout": the lead dino can use any ability.
  if (state.flags.debug_pass && party.length) return party.find((d) => hasAbility(d, id)) || party[0];
  return party.find((d) => hasAbility(d, id)) || null;
}
