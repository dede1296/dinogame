// Wild dinos per zone: [species, weight, [minLevel, maxLevel]].
export const ENCOUNTERS = {
  plaines: [
    ["Protoceratops", 30, [2, 4]],
    ["Maiasaura", 24, [2, 4]],
    ["Compsognathus", 18, [2, 3]],
    ["Iguanodon", 14, [3, 5]],
    ["Gallimimus", 14, [3, 5]],
  ],
};

// Chance per step in tall grass.
export const ENCOUNTER_RATE = 0.1;
// Chance that a wild dino is a natural hybrid of the zone's species.
export const HYBRID_RATE = 0.06;
