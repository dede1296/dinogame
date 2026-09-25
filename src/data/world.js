// ============ ADVENTURE ZONES ============
export const ZONES = [
  { key: "plains", name: "Plaines Herbeuses", emoji: "🌾", minLevel: 1, families: ["hadrosaur", "ceratopsian"], wins: 3, boss: "Tricératops Alpha", bossIdx: 2 },
  { key: "forest", name: "Forêt Jurassique", emoji: "🌳", minLevel: 2, families: ["raptor", "sauropod"], wins: 3, boss: "Velociraptor Chef de Meute", bossIdx: 1 },
  { key: "marsh", name: "Marais Brumeux", emoji: "🪵", minLevel: 3, families: ["spino", "hadrosaur"], wins: 4, boss: "Spinosaure Ancestral", bossIdx: 5 },
  { key: "desert", name: "Désert Aride", emoji: "🏜️", minLevel: 4, families: ["tyrant", "ceratopsian"], wins: 4, boss: "Carnotaurus Rouge", bossIdx: 11 },
  { key: "volcano", name: "Plaine Volcanique", emoji: "🌋", minLevel: 5, families: ["tyrant", "armored"], wins: 4, boss: "T-Rex de Magma", bossIdx: 0 },
  { key: "coast", name: "Côte Préhistorique", emoji: "🌊", minLevel: 6, families: ["marine", "flyer"], wins: 4, boss: "Mosasaure Abyssal", bossIdx: 18 },
  { key: "mountains", name: "Monts Gelés", emoji: "🏔️", minLevel: 7, families: ["armored", "sauropod"], wins: 4, boss: "Cryolophosaure Titan", bossIdx: 49 },
  { key: "sky", name: "Cieux Éternels", emoji: "☁️", minLevel: 8, families: ["flyer", "raptor"], wins: 4, boss: "Quetzalcoatlus Roi", bossIdx: 32 },
  { key: "jungle", name: "Jungle Perdue", emoji: "🌴", minLevel: 9, families: ["raptor", "tyrant", "spino"], wins: 5, boss: "Giganotosaure Primordial", bossIdx: 22 },
  { key: "apex", name: "Terre des Apex", emoji: "☄️", minLevel: 10, families: ["tyrant", "spino", "marine"], wins: 5, boss: "Le Souverain", bossIdx: 0 },
];

// ============ TRAITS ============
export const TRAITS = [
  { key: "sanguinaire", name: "Sanguinaire", emoji: "🩸", desc: "+20% dégâts critiques, +10% chance de critique" },
  { key: "resistant", name: "Résistant", emoji: "🛡️", desc: "+15% PV max, récupère 5 PV par tour" },
  { key: "ruse", name: "Rusé", emoji: "🧠", desc: "+2 Intelligence, chance d'esquive doublée" },
  { key: "fureur", name: "Fureur", emoji: "😤", desc: "Sous 30% PV : +40% dégâts (mode Rage)" },
  { key: "endurant", name: "Endurant", emoji: "💪", desc: "+1 utilisation à toutes les attaques" },
];

// ============ ITEMS ============
export const ITEMS = {
  heal: { name: "Fougère Curative", emoji: "🌿", desc: "Soigne 40% des PV max", effect: "heal" },
  antidote: { name: "Sève Purifiante", emoji: "💧", desc: "Supprime tous les statuts", effect: "antidote" },
  boost: { name: "Baie Féroce", emoji: "🍇", desc: "+50% dégâts pendant 2 tours", effect: "boost" },
  food: { name: "Viande Séchée", emoji: "🍖", desc: "Nourris ton dino (+35% faim)", effect: "food" },
};
