// ============ FOSSIL PUZZLE DATA ============
export const FOSSIL_PIECES = [
  { id: "skull", label: "Crâne", x: 62, y: 12, svg: "M72,22 Q67,12 62,16 L62,28 Q67,32 77,32 Q82,32 85,28 L85,16 Q82,12 77,14 Z M67,20 a2,2 0 1,0 0.1,0 M78,20 a2,2 0 1,0 0.1,0" },
  { id: "spine", label: "Colonne", x: 30, y: 18, svg: "M32,22 L62,22 M32,24 L62,24 M37,20 L37,26 M42,20 L42,26 M47,20 L47,26 M52,20 L52,26 M57,20 L57,26" },
  { id: "ribs", label: "Côtes", x: 35, y: 26, svg: "M40,28 Q35,35 38,42 M45,28 Q38,36 42,44 M50,28 Q42,37 46,46 M55,28 Q47,38 50,46" },
  { id: "legs", label: "Pattes", x: 35, y: 44, svg: "M40,46 L40,62 L44,65 M42,46 L42,62 L46,65 M52,46 L52,62 L56,65 M54,46 L54,62 L58,65" },
  { id: "tail", label: "Queue", x: 5, y: 18, svg: "M30,22 Q22,20 15,22 Q10,24 8,28 Q6,30 8,28 M30,24 Q22,22 15,24 Q10,26 8,30" },
];

export const ACHIEVEMENTS = [
  { key: "first_win", name: "Premier Sang", emoji: "🎯", desc: "Gagne ton premier combat", check: s => s.totalWins >= 1 },
  { key: "win_10", name: "Dresseur Aguerri", emoji: "🏅", desc: "Gagne 10 combats", check: s => s.totalWins >= 10 },
  { key: "win_50", name: "Maître de l'Arène", emoji: "👑", desc: "Gagne 50 combats", check: s => s.totalWins >= 50 },
  { key: "level_5", name: "Évolution", emoji: "⭐", desc: "Atteins le niveau 5", check: s => s.level >= 5 },
  { key: "level_10", name: "Légende", emoji: "🌟", desc: "Atteins le niveau 10", check: s => s.level >= 10 },
  { key: "bestiary_10", name: "Paléontologue", emoji: "📚", desc: "Rencontre 10 créatures", check: s => Object.keys(s.bestiary).length >= 10 },
  { key: "save_3", name: "Collectionneur", emoji: "🏛️", desc: "Sauvegarde 3 créations", check: s => s.saved.length >= 3 },
  { key: "zone_3", name: "Explorateur", emoji: "🗺️", desc: "Atteins la 3ème zone", check: s => s.adventureZone >= 2 },
  { key: "boss", name: "Tueur de Boss", emoji: "⚔️", desc: "Bats un boss", check: s => s.bossDefeated },
  { key: "egg_5", name: "Nidificateur", emoji: "🥚", desc: "Collecte 5 œufs", check: s => s.eggs >= 5 },
];


// ============ EQUIPMENT ============
export const EQUIPMENT_LIST = [
  { key: "bone_necklace", name: "Collier d'Os", emoji: "🦴", desc: "+2 ATQ", rarity: "common", bonus: { attaque: 2 } },
  { key: "fossil_scale", name: "Écaille Fossile", emoji: "🪨", desc: "+2 DEF", rarity: "common", bonus: { defense: 2 } },
  { key: "ancient_feather", name: "Plume Ancienne", emoji: "🪶", desc: "+2 VIT", rarity: "common", bonus: { vitesse: 2 } },
  { key: "sharp_claw", name: "Griffe Acérée", emoji: "🗡️", desc: "+2 FRC", rarity: "common", bonus: { force: 2 } },
  { key: "wise_eye", name: "Œil de Sage", emoji: "👁️", desc: "+2 INT", rarity: "common", bonus: { intel: 2 } },
  { key: "amber_charm", name: "Ambre Primordial", emoji: "🟠", desc: "+1.5 ATQ +1.5 DEF", rarity: "rare", bonus: { attaque: 1.5, defense: 1.5 } },
  { key: "raptor_fang", name: "Croc de Raptor", emoji: "🦷", desc: "+2 ATQ +1 VIT", rarity: "rare", bonus: { attaque: 2, vitesse: 1 } },
  { key: "titan_shell", name: "Carapace de Titan", emoji: "🛡️", desc: "+3 DEF", rarity: "rare", bonus: { defense: 3 } },
  { key: "meteor_shard", name: "Éclat de Météorite", emoji: "☄️", desc: "+2 ATQ +2 FRC", rarity: "epic", bonus: { attaque: 2, force: 2 } },
  { key: "crown_apex", name: "Couronne d'Apex", emoji: "👑", desc: "+1.5 à tout", rarity: "epic", bonus: { attaque: 1.5, defense: 1.5, vitesse: 1.5, force: 1.5, intel: 1.5 } },
];

// ============ QUIZ QUESTIONS ============
export const QUIZ_QUESTIONS = [
  { q: "Quel dinosaure avait la morsure la plus puissante ?", a: "Tyrannosaurus Rex", opts: ["Tyrannosaurus Rex", "Giganotosaurus", "Spinosaurus", "Allosaurus"] },
  { q: "Quel dinosaure était couvert de plumes ?", a: "Velociraptor", opts: ["Triceratops", "Velociraptor", "Ankylosaurus", "Brachiosaurus"] },
  { q: "Le Ptéranodon est-il un dinosaure ?", a: "Non, c'est un reptile volant", opts: ["Oui", "Non, c'est un reptile volant", "Non, c'est un oiseau", "Oui, un dinosaure volant"] },
  { q: "Quel dinosaure avait une voile sur le dos ?", a: "Spinosaurus", opts: ["T-Rex", "Stegosaurus", "Spinosaurus", "Triceratops"] },
  { q: "Combien de cornes avait le Triceratops ?", a: "3", opts: ["2", "3", "5", "1"] },
  { q: "Quel dinosaure est surnommé 'Elvisaurus' ?", a: "Cryolophosaurus", opts: ["Dilophosaurus", "Cryolophosaurus", "Oviraptor", "Carnotaurus"] },
  { q: "Quel reptile marin a inspiré le monstre du Loch Ness ?", a: "Plesiosaurus", opts: ["Mosasaurus", "Plesiosaurus", "Spinosaurus", "Ichthyosaure"] },
  { q: "Quel dinosaure avait les plus longues griffes (1 m) ?", a: "Therizinosaurus", opts: ["Velociraptor", "Utahraptor", "Therizinosaurus", "Deinonychus"] },
  { q: "Quel était probablement le plus grand dinosaure ?", a: "Argentinosaurus", opts: ["Diplodocus", "Brachiosaurus", "Argentinosaurus", "Apatosaurus"] },
  { q: "Que signifie 'Maiasaura' ?", a: "Bonne mère", opts: ["Grande dent", "Bonne mère", "Rapide coureur", "Roi du lézard"] },
  { q: "Le Dilophosaurus crachait-il vraiment du venin ?", a: "Non, c'est une invention du film", opts: ["Oui", "Non, c'est une invention du film", "On ne sait pas", "Seulement les mâles"] },
  { q: "Quel dinosaure avait un cerveau de la taille d'une noix ?", a: "Stegosaurus", opts: ["T-Rex", "Stegosaurus", "Diplodocus", "Ankylosaurus"] },
  { q: "Quel animal volant était aussi grand qu'une girafe ?", a: "Quetzalcoatlus", opts: ["Pteranodon", "Archaeopteryx", "Quetzalcoatlus", "Microraptor"] },
  { q: "Où a-t-on découvert le premier dinosaure fossile ?", a: "En Angleterre", opts: ["En Argentine", "En Chine", "En Angleterre", "Aux États-Unis"] },
  { q: "Quel dino avait 4 ailes et pouvait planer ?", a: "Microraptor", opts: ["Archaeopteryx", "Microraptor", "Velociraptor", "Compsognathus"] },
];

// ============ RIVAL ============
export const RIVAL_NAME = "L'Ombre Noire";
export const RIVAL_APPEARANCES = [1, 3, 5, 7, 9]; // zone indices where rival appears
export const RIVAL_DIALOGUES = [
  "Tiens, tiens... Un nouveau venu. Tu ne feras pas long feu.",
  "Encore toi ? Tu es plus tenace que je ne pensais.",
  "Je dois admettre, tu as progressé. Mais pas assez.",
  "Cette fois, je ne retiendrai pas mes coups.",
  "Le combat final. Que le plus fort survive.",
];

// ============ SKIN PATTERNS ============
export const PATTERNS = [
  { key: "none", name: "Uni", emoji: "⬜" },
  { key: "stripes", name: "Rayures", emoji: "🦓" },
  { key: "spots", name: "Taches", emoji: "🐆" },
  { key: "camo", name: "Camouflage", emoji: "🌿" },
];
