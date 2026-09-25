import { DINOS } from "../data/dinos.js";

// ============ NAME GENERATOR ============
// Generate a Latin-sounding name from the build's composition
export const NAME_PREFIXES = {
  head: { tyrant: "Tyranno", spino: "Spino", raptor: "Velo", sauropod: "Brachio",
    ceratopsian: "Cerato", armored: "Anky", hadrosaur: "Para", flyer: "Ptero", marine: "Mosa" },
  teeth: { tyrant: "rex", spino: "dens", raptor: "raptor", sauropod: "lithos",
    ceratopsian: "ceros", armored: "saurus", hadrosaur: "lophus", flyer: "don", marine: "saurus" },
  back: { tyrant: "rex", spino: "spinax", raptor: "agilis", sauropod: "magnus",
    ceratopsian: "ceros", armored: "tholos", hadrosaur: "cristus", flyer: "alatus", marine: "natans" },
  tail: { tyrant: "caudus", spino: "natator", raptor: "rapax", sauropod: "longus",
    ceratopsian: "tauros", armored: "claviger", hadrosaur: "cantor", flyer: "volans", marine: "fluctus" },
};

export function generateName(build) {
  const headFam = DINOS[build.head].family;
  const teethFam = DINOS[build.teeth].family;
  const backFam = DINOS[build.back].family;
  const tailFam = DINOS[build.tail].family;
  const prefix = NAME_PREFIXES.head[headFam] || "Dino";
  const mid = NAME_PREFIXES.teeth[teethFam] || "saurus";
  // Use back & tail to add a species name
  const epithet = (NAME_PREFIXES.back[backFam] || "magnus") + "-" + (NAME_PREFIXES.tail[tailFam] || "rex");
  return `${prefix}${mid} ${epithet}`;
}
