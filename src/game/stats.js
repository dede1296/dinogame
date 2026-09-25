import { DINOS } from "../data/dinos.js";

// ============ Part contribution helpers ============
// Returns a short text describing what a dino brings to a given part slot
export function describePartContribution(dinoIdx, partKey) {
  const d = DINOS[dinoIdx];
  switch (partKey) {
    case "head":
      return `Taille ${d.head.size}/10 · Morsure ${d.head.bite}/10`;
    case "teeth":
      return `Tranchant ${d.teeth.sharp}/10 · Nombre ${d.teeth.count}/10`;
    case "frontLegs":
      return `Puissance ${d.frontLegs.power}/10 · Allonge ${d.frontLegs.reach}/10`;
    case "backLegs":
      return `Puissance ${d.backLegs.power}/10 · Vitesse ${d.backLegs.speed}/10`;
    case "back":
      return `Armure ${d.back.armor}/10 · Pics ${d.back.spikes}/10`;
    case "tail":
      return `Puissance ${d.tail.power}/10 · Longueur ${d.tail.length}/10`;
    case "color":
      return `Teinte signature`;
    default:
      return "";
  }
}

// Returns which final stats a part contributes to (for the summary)
export function partContributesTo(partKey) {
  switch (partKey) {
    case "head": return ["Attaque", "Défense", "Taille", "Intel."];
    case "teeth": return ["Attaque"];
    case "frontLegs": return ["Vitesse", "Force", "Taille", "Intel."];
    case "backLegs": return ["Vitesse", "Force"];
    case "back": return ["Défense"];
    case "tail": return ["Attaque", "Force", "Taille"];
    case "color": return [];
    default: return [];
  }
}

// Intelligence per family (1-10)
export const FAMILY_INTELLIGENCE = {
  raptor: 9,    // Troodon, Velociraptor - very smart
  tyrant: 7,    // T-Rex - cunning predator
  spino: 6,
  marine: 6,
  ceratopsian: 5,
  hadrosaur: 5,
  flyer: 5,
  armored: 3,
  sauropod: 2,  // small brain, big body
};

// ============ Stats computation ============
export function computeStats(build) {
  const h = DINOS[build.head];
  const t = DINOS[build.teeth];
  const f = DINOS[build.frontLegs];
  const b = DINOS[build.backLegs];
  const bk = DINOS[build.back];
  const tl = DINOS[build.tail];

  const attaque = Math.round((h.head.bite + t.teeth.sharp + tl.tail.power) / 3 * 10) / 10;
  const defense = Math.round((bk.back.armor + bk.back.spikes + h.head.size * 0.5) / 2.5 * 10) / 10;
  const vitesse = Math.round((b.backLegs.speed * 1.5 + f.frontLegs.reach * 0.5) / 2 * 10) / 10;
  const force = Math.round((b.backLegs.power + f.frontLegs.power + tl.tail.power) / 3 * 10) / 10;
  const taille = Math.round((h.head.size + f.frontLegs.reach + tl.tail.length) / 3 * 10) / 10;
  // Intelligence: head family has main influence, front legs (manipulation/coordination) secondary
  const intel = Math.round(((FAMILY_INTELLIGENCE[h.family] || 5) * 0.7 + (FAMILY_INTELLIGENCE[f.family] || 5) * 0.3) * 10) / 10;

  return { attaque, defense, vitesse, force, taille, intel };
}
