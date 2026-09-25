// La Grotte des Échos: a two-level dungeon under the eastern cliffs of the Plains.
// Level 1: entrance, a campfire, the first Ombre Noire grunt, a hole leading down.
// Level 2: a second grunt, the forced hybrid, and the Triceratops Alpha's lair under the great skull.
import { MapBuilder } from "../mapBuilder.js";

const FLOOR = ["n", "g"];

function level1() {
  const m = new MapBuilder(30, 28, "W", 21);
  // Entrance chamber (south) with the campfire.
  m.blob(15, 23.5, 5.5, 3, "n", { noise: 0.15 });
  m.rect(14, 25, 3, 3, "n");
  // Corridor north to the great hall.
  m.path([[15, 21], [14, 18], [12, 16]], 2, "n");
  m.blob(11, 12.5, 7, 4.6, "g", { noise: 0.2 });
  m.blob(7.5, 12, 2.6, 2, "~", { noise: 0.25 });
  // East branch: a dead-end chamber hiding a journal page.
  m.path([[16, 13], [21, 12], [24, 8]], 2, "g");
  m.blob(24.5, 5.5, 3.8, 2.8, "g", { noise: 0.2 });
  // North-west: narrow passage guarded by a grunt, then the way down.
  m.path([[9, 9], [8, 7]], 1, "n");
  m.set(8, 6, "n");
  m.blob(6.5, 3.8, 3.6, 2.4, "n", { noise: 0.15 });
  // Decoration.
  for (const [x, y, ch] of [
    [11, 22, "k"], [19, 23, "k"], [18, 21, "a"], [5, 10, "k"], [16, 10, "a"], [4, 14, "k"], [17, 15, "k"],
    [14, 9, "k"], [27, 5, "a"], [21, 5, "k"], [23, 3, "k"], [9, 3, "a"], [4, 5, "k"], [13, 15, "k"],
  ]) if (FLOOR.includes(m.get(x, y))) m.set(x, y, ch);
  return m.toRows();
}

function level2() {
  const m = new MapBuilder(32, 26, "W", 37);
  // Arrival under the ladder (north-west).
  m.blob(5, 4, 3.2, 2.4, "n", { noise: 0.15 });
  // Winding gravel tunnel east, guarded by the second grunt.
  m.path([[7, 5], [12, 6], [16, 5]], 2, "g");
  m.blob(19, 6, 4.5, 3.2, "n", { noise: 0.18 }); // the forced hybrid's chamber
  m.path([[22, 7], [26, 9], [26, 13]], 2, "g");
  // Rest spot before the lair.
  m.blob(25.5, 14.5, 3, 2, "n", { noise: 0.1 });
  m.path([[24, 16], [20, 18]], 2, "n");
  // The Alpha's lair, under the great skull: a wide round chamber lit from above.
  m.blob(14, 19, 7.5, 4.6, "n", { noise: 0.12 });
  m.blob(9.5, 18, 2.2, 1.6, "~", { noise: 0.2 });
  // A side pocket off the tunnel (hidden fossil).
  m.path([[12, 6], [11, 10]], 1, "g");
  m.blob(10.5, 11.5, 2.2, 1.6, "g", { noise: 0.1 });
  for (const [x, y, ch] of [
    [3, 3, "k"], [7, 3, "a"], [15, 4, "k"], [22, 4, "a"], [17, 8, "k"], [21, 8, "k"], [28, 10, "k"],
    [27, 15, "a"], [8, 20, "k"], [20, 22, "k"], [19, 16, "a"], [7, 16, "k"], [12, 12, "a"],
  ]) if (FLOOR.includes(m.get(x, y))) m.set(x, y, ch);
  return m.toRows();
}

export const grotte1 = {
  id: "grotte1",
  name: "Grotte des Échos",
  cave: true,
  music: "grotte",
  rows: level1(),
  zones: [{ name: "Grotte des Échos", y0: 0, y1: 28, encounters: "grotte", rate: 0.07 }],
  entities: [
    { type: "warp", x: 15, y: 27, to: { map: "ambreluneSud", x: 36, y: 23, dir: "down" } },
    { type: "decor", kind: "campfire", x: 12, y: 23, w: 1, h: 1, solid: true, script: "feuDeCamp", arg: { x: 12, y: 24, dir: "up", name: "près du feu de camp de la grotte" } },
    { type: "npc", id: "sbire1", look: "grunt", x: 8, y: 6, dir: "down", script: "sbire1", flagHidden: "sbire1_battu" },
    { type: "trigger", x: 8, y: 7, w: 1, h: 3, script: "sbire1" },
    { type: "decor", kind: "hole", x: 5, y: 3, w: 1, h: 1, warp: true },
    { type: "warp", x: 5, y: 3, to: { map: "grotte2", x: 5, y: 5, dir: "down" } },
    { type: "item", x: 26, y: 6, item: "journal", page: 3, flag: "journal_3" },
    { type: "item", x: 13, y: 11, item: "fougere", qty: 2, flag: "item_g1" },
    { type: "hidden", x: 5, y: 15, item: "collier", qty: 3, flag: "hidden_g1" },
    { type: "hidden", x: 20, y: 24, item: "piece", qty: 30, flag: "hidden_g2" },
    { type: "sign", x: 17, y: 24, text: "Gravé dans la roche : « H.V. — Ne va pas plus loin sans un compagnon solide. »" },
  ],
  start: { x: 15, y: 26, dir: "up" },
};

export const grotte2 = {
  id: "grotte2",
  name: "Grotte des Échos — Profondeurs",
  cave: true,
  music: "grotte",
  rows: level2(),
  zones: [{ name: "Profondeurs des Échos", y0: 0, y1: 26, encounters: "grotte", rate: 0.07 }],
  entities: [
    { type: "decor", kind: "ladder", x: 5, y: 2, w: 1, h: 1, solid: true, script: "echelleHaut" },
    { type: "npc", id: "sbire2", look: "grunt", x: 12, y: 6, dir: "left", script: "sbire2", flagHidden: "sbire2_battu" },
    { type: "trigger", x: 9, y: 5, w: 2, h: 2, script: "sbire2" },
    { type: "boss", id: "hybride", species: ["Pachycephalosaurus", "Velociraptor"], tint: "#6a3d8a", x: 23, y: 8, dir: "left", script: "hybrideForce", flagHidden: "hybride_battu" },
    { type: "trigger", x: 21, y: 5, w: 2, h: 4, script: "hybrideForce" },
    { type: "item", x: 25, y: 8, item: "journal", page: 4, flag: "journal_4" },
    { type: "hidden", x: 10, y: 12, item: "fossile", part: "colonne", flag: "hidden_g3" },
    { type: "item", x: 27, y: 11, item: "baie", qty: 2, flag: "item_g2" },
    { type: "decor", kind: "campfire", x: 26, y: 14, w: 1, h: 1, solid: true, script: "feuDeCamp", arg: { x: 25, y: 14, dir: "right", name: "près du feu des Profondeurs" } },
    { type: "sign", x: 24, y: 13, text: "Gravé dans la roche : « Le gardien des Plaines ne fait pas de cadeau. Repose-toi, entraîne ton équipe… et seulement ensuite, avance. » — H.V." },
    { type: "boss", id: "alpha", species: ["Triceratops"], big: true, x: 14, y: 18, dir: "right", script: "alpha", flagHidden: "alpha_battu" },
    { type: "trigger", x: 18, y: 17, w: 3, h: 3, script: "alphaReveil" },
    { type: "decor", id: "echelleCrane", kind: "ladder", x: 14, y: 16, w: 1, h: 1, solid: true, script: "echelleCrane", flagShown: "alpha_battu" },
  ],
  start: { x: 5, y: 5, dir: "down" },
};
