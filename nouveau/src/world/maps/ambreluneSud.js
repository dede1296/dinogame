// Port-Ambre (the harbour village where Chloé arrives) and, to the north,
// the Plaines des Fougères.
import { MapBuilder } from "../mapBuilder.js";

function build() {
  const m = new MapBuilder(44, 74, ".", 11);
  m.forestBorder(2);

  // ---------------- Plaines des Fougères (north, y 0..40)
  // Dense copse in the north-east hiding a secret grove.
  m.rect(33, 0, 11, 11, "T");
  m.blob(38.5, 5, 3.6, 2.8, ".", { noise: 0.12 });
  m.rect(36, 3, 5, 4, ".");
  // Pond with a sandy bank.
  m.blob(9, 19, 6.8, 5.4, "s", { noise: 0.2 });
  m.blob(9, 19, 5.2, 4, "~", { noise: 0.25 });
  // Eastern cliffs, cave mouth at (36,21).
  m.blob(38, 16.5, 5.5, 5, "#", { noise: 0.18 });
  m.rect(35, 19, 5, 3, "#");
  // Tall grass patches (wild dinos).
  for (const [x, y, rx, ry] of [[11, 8, 6, 3.5], [27, 10, 4.5, 3.5], [13, 30, 6, 3.5], [30, 28, 4.5, 4], [27, 37, 4, 2.2], [17, 14, 3, 2]]) {
    m.blob(x, y, rx, ry, ",", { only: ["."] });
  }
  // Decoration.
  m.scatter(3, 2, 38, 38, "T", 0.02);
  m.scatter(3, 2, 38, 38, ":", 0.05);
  m.scatter(3, 2, 38, 38, "y", 0.04);
  m.scatter(3, 2, 38, 38, "r", 0.012);
  m.scatter(3, 2, 38, 38, "b", 0.015);
  m.set(24, 16, "_");

  // ---------------- Port-Ambre (south, y 41..73)
  m.rect(3, 41, 17, 2, "T");
  m.rect(25, 41, 16, 2, "T");
  m.rect(3, 43, 38, 18, ".");
  m.blob(22, 54, 6.5, 3.2, "o", { noise: 0.08 });
  // Gardens.
  m.rect(4, 52, 8, 1, "x");
  m.rect(5, 53, 6, 2, ":");
  m.rect(33, 54, 7, 1, "x");
  m.scatter(3, 43, 38, 17, ":", 0.04);
  m.scatter(3, 43, 38, 17, "b", 0.02);
  // Beach and sea.
  m.rect(0, 61, 44, 13, "s");
  m.blob(22, 76, 40, 11, "~", { noise: 0.06 });
  m.rect(0, 67, 44, 7, "~");

  // ---------------- Roads (drawn last so they cut through everything)
  m.path([[22, 0], [22, 4], [20, 9], [21, 15], [24, 21], [23, 28], [21, 34], [22, 40], [22, 50]], 2, "=");
  m.path([[23, 49], [29, 49], [29, 48]], 1, "=");
  m.path([[16, 54], [8, 54], [8, 51]], 1, "=");
  m.path([[28, 55], [36, 55], [36, 52]], 1, "=");
  m.path([[22, 57], [22, 60]], 2, "=");
  m.rect(22, 61, 2, 11, "p");
  // Path to the cave and to the secret copse entrance.
  m.path([[24, 21], [30, 22], [36, 22]], 1, "=");
  m.path([[28, 6], [32, 5]], 1, ".");
  for (const x of [33, 34, 35]) m.set(x, 5, "t");
  m.rect(20, 1, 2, 4, ".");
  m.rect(3, 36, 3, 4, ".");
  m.rect(37, 43, 3, 4, ".");

  return m.toRows();
}

export const ambreluneSud = {
  id: "ambreluneSud",
  name: "Port-Ambre",
  rows: build(),
  music: "village",
  zones: [
    { name: "Plaines des Fougères", y0: 0, y1: 41, music: "plaines", encounters: "plaines" },
    { name: "Port-Ambre", y0: 41, y1: 74, music: "village" },
  ],
  entities: [
    // Buildings (footprint in tiles; `door` is the tile you walk into).
    { type: "building", kind: "cabinet", x: 26, y: 43, w: 7, h: 5, door: { x: 29, y: 47, to: { map: "cabinet", x: 6, y: 8, dir: "up" } } },
    { type: "building", kind: "house", x: 6, y: 47, w: 5, h: 4, door: { x: 8, y: 50, to: { map: "maison", x: 4, y: 6, dir: "up" } } },
    { type: "building", kind: "harbour", x: 34, y: 48, w: 5, h: 4, door: { x: 36, y: 51, locked: "La capitainerie est fermée. Le capitaine doit être en mer." } },
    { type: "building", kind: "hut", x: 11, y: 57, w: 4, h: 3 },
    { type: "building", kind: "hut", x: 30, y: 57, w: 4, h: 3 },
    { type: "decor", kind: "boat", x: 21, y: 72, w: 4, h: 2, solid: true },
    { type: "decor", kind: "campfire", x: 16, y: 25, w: 1, h: 1, solid: true, script: "feuDeCamp", arg: { x: 16, y: 26, dir: "up", name: "près du feu de camp des Plaines" } },
    { type: "decor", kind: "skull", x: 25, y: 15, w: 3, h: 2, solid: true, script: "crane" },
    { type: "trigger", x: 20, y: 42, w: 5, h: 1, script: "sortieVillage" },

    // Signs.
    { type: "sign", x: 20, y: 60, text: "PORT-AMBRE\nLe dernier port avant la brume." },
    { type: "sign", x: 28, y: 48, text: "LE CABINET\nLaboratoire de paléogénétique — Fondation Varenne." },
    { type: "sign", x: 20, y: 44, text: "↑ Plaines des Fougères\nAttention : dinos sauvages dans les hautes herbes !" },
    { type: "sign", x: 23, y: 22, text: "→ Grotte des Échos\n(Éboulement : passage fermé)" },
    { type: "sign", x: 21, y: 3, text: "↑ Forêt Jurassique" },

    // Obstacles that future abilities will clear.
    { type: "blocker", kind: "boulder", x: 36, y: 22, text: "Un énorme rocher bloque l'entrée de la grotte. Un dino très fort pourrait peut-être le pousser…" },
    { type: "blocker", kind: "log", x: 22, y: 0, w: 2, text: "Un tronc géant barre le chemin de la forêt. Le Professeur Roc saura peut-être quoi faire." },

    // Items on the ground.
    { type: "item", x: 5, y: 12, item: "fougere", qty: 1, flag: "item_p1" },
    { type: "item", x: 30, y: 33, item: "fougere", qty: 2, flag: "item_p2" },
    { type: "item", x: 15, y: 25, item: "ambre", species: "Protoceratops", flag: "item_p3" },
    { type: "item", x: 39, y: 4, item: "journal", page: 1, flag: "journal_1" },
    { type: "item", x: 37, y: 6, item: "ambre", species: "Velociraptor", flag: "item_grove" },
    // Hidden items: found by pressing A while facing the spot.
    { type: "hidden", x: 4, y: 38, item: "fossile", part: "crane", flag: "hidden_p1" },
    { type: "hidden", x: 16, y: 21, item: "baie", qty: 2, flag: "hidden_p2" },
    { type: "hidden", x: 38, y: 45, item: "piece", qty: 20, flag: "hidden_v1" },

    // Characters.
    { type: "npc", id: "pecheur", look: "fisher", x: 23, y: 67, dir: "left", script: "pecheur" },
    { type: "npc", id: "enfant", look: "kid", x: 19, y: 53, dir: "down", script: "enfant", wander: 2 },
    { type: "npc", id: "mamie", look: "elder", x: 12, y: 55, dir: "right", script: "mamie" },
    { type: "npc", id: "maia", look: "maia", x: 23, y: 40, dir: "down", script: "maia", flagHidden: "maia_met" },
    { type: "npc", id: "randonneur", look: "hiker", x: 19, y: 23, dir: "right", script: "randonneur" },
  ],
  start: { x: 22, y: 70, dir: "up" },
};
