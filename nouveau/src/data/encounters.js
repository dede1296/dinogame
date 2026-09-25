// Wild dinos per zone: [species, weight, [minLevel, maxLevel]].
export const ENCOUNTERS = {
  plaines: [
    ["Protoceratops", 30, [2, 4]],
    ["Maiasaura", 24, [2, 4]],
    ["Compsognathus", 18, [2, 3]],
    ["Iguanodon", 14, [3, 5]],
    ["Gallimimus", 14, [3, 5]],
  ],
  grotte: [
    ["Pteranodon", 26, [5, 7]],
    ["Archaeopteryx", 20, [5, 7]],
    ["Troodon", 18, [5, 8]],
    ["Pachycephalosaurus", 16, [6, 8]],
    ["Ankylosaurus", 8, [7, 8]],
    ["Protoceratops", 12, [5, 7]],
  ],
};

// Chance per step in tall grass (kept low: most wild dinos are visible, see map `roamers`).
export const ENCOUNTER_RATE = 0.03;
// Chance that a wild dino is a natural hybrid of the zone's species.
export const HYBRID_RATE = 0.06;
