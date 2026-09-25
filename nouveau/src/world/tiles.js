// Tile codes used by the maps.
//
// `ground` is the terrain painted on the ground layer; `prop` is an object drawn as a
// sprite on top (trees, rocks…). `solid` blocks movement.

export const TILE = 48;

export const TILES = {
  ".": { ground: "grass" },
  ",": { ground: "grass", prop: "tallgrass", encounter: true },
  ":": { ground: "grass", prop: "flowers" },
  "y": { ground: "grass", prop: "fern" },
  "=": { ground: "path" },
  "s": { ground: "sand" },
  "~": { ground: "water", solid: true },
  "p": { ground: "planks" },
  "o": { ground: "stone" },
  "#": { ground: "cliff", solid: true },
  "T": { ground: "grass", prop: "tree", solid: true },
  "P": { ground: "grass", prop: "pine", solid: true },
  "t": { ground: "grass", prop: "tree", secret: true }, // walkable: a hidden gap between trees
  "b": { ground: "grass", prop: "bush", solid: true },
  "r": { ground: "grass", prop: "rock", solid: true },
  "x": { ground: "grass", prop: "fence", solid: true },
  "_": { ground: "grass", prop: "bones" },
  "f": { ground: "floor" },
  "w": { ground: "wall", solid: true },
  "c": { ground: "carpet" },
};

export function tileAt(rows, x, y) {
  const ch = rows[y]?.[x];
  return ch === undefined ? null : TILES[ch] || TILES["."];
}
