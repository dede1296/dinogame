// Exploration abilities (like Pokémon HMs): a dino in the party can use one when it
// carries the right body part — naturally or grafted with the Cabinet's hybridizer.

import { DINOS } from "../../../src/data/dinos.js";

export const ABILITIES = {
  charge: { name: "Charge", icon: "💥", part: "head", families: ["ceratopsian"], partName: "une tête de cératopsien (Protoceratops, Tricératops…)", desc: "Fonce tête baissée : brise les gros rochers." },
  tranche: { name: "Tranche", icon: "🗡️", part: "frontLegs", families: ["raptor"], partName: "des griffes de raptor (Velociraptor…)", desc: "Griffes acérées : tranche les troncs et les ronces." },
};

export function hasAbility(dino, id) {
  const a = ABILITIES[id];
  return a.families.includes(DINOS[dino.build[a.part]]?.family);
}

/** The first party dino able to use the ability, or null. */
export function abilityUser(party, id) {
  return party.find((d) => hasAbility(d, id)) || null;
}
