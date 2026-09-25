import { DINOS } from "../data/dinos.js";
import { computeStats } from "./stats.js";
import { getTypeMult } from "./types.js";
import { generateName } from "./names.js";

// ============ ENEMY GENERATOR ============
export function generateEnemy(playerStats) {
  const STANDARD_COUNT = DINOS.filter(d => !d.exclusive).length;
  const r = () => Math.floor(Math.random() * STANDARD_COUNT); // normal parts
  const rExcl = () => STANDARD_COUNT + Math.floor(Math.random() * (DINOS.length - STANDARD_COUNT)); // exclusive parts
  // 20% chance per part to be exclusive
  const pick = () => Math.random() < 0.2 ? rExcl() : r();
  let attempts = 0;
  let enemyBuild, enemyStats;
  const playerPower = playerStats.attaque + playerStats.defense + playerStats.vitesse + playerStats.force;
  do {
    enemyBuild = { head: pick(), teeth: pick(), frontLegs: pick(), backLegs: pick(), back: pick(), tail: pick(), color: pick() };
    enemyStats = computeStats(enemyBuild);
    const enemyPower = enemyStats.attaque + enemyStats.defense + enemyStats.vitesse + enemyStats.force;
    if (Math.abs(enemyPower - playerPower) < playerPower * 0.25) break;
    attempts++;
  } while (attempts < 50);
  return { build: enemyBuild, stats: enemyStats, name: generateName(enemyBuild) };
}

// ============ COMBAT ENGINE ============
export function computeHP(stats, trait, hpBonus = 0) {
  let hp = Math.round(40 + stats.defense * 6 + stats.taille * 4) + hpBonus;
  if (trait === "resistant") hp = Math.round(hp * 1.15);
  return hp;
}

// Apply level bonus to stats (10% per level above 1)
export function statsWithLevel(stats, level) {
  const mult = 1 + (level - 1) * 0.1;
  return {
    attaque: stats.attaque * mult,
    defense: stats.defense * mult,
    vitesse: stats.vitesse * mult,
    force: stats.force * mult,
    taille: stats.taille,
    intel: stats.intel * mult,
  };
}

export const BASIC_ATTACKS = [
  { key: "morsure", label: "Morsure", uses: ["attaque"], emoji: "🦷", desc: "plante ses crocs", basePower: 1.0, maxUses: 4 },
  { key: "charge", label: "Charge", uses: ["force", "vitesse"], emoji: "💥", desc: "fonce tête baissée", basePower: 1.1, maxUses: 3 },
  { key: "queue", label: "Coup de queue", uses: ["force"], emoji: "🌀", desc: "balaie de la queue", basePower: 1.0, maxUses: 4 },
  { key: "griffes", label: "Griffes", uses: ["attaque", "vitesse"], emoji: "🗡️", desc: "lacère avec ses griffes", basePower: 1.0, maxUses: 4 },
];

// Special attacks unlocked by specific part families
export const SPECIAL_ATTACKS = {
  // Head specials
  head_tyrant: { key: "morsure_letale", label: "Morsure Létale", uses: ["attaque", "force"], emoji: "💀", desc: "broie avec sa mâchoire monstrueuse", basePower: 1.6, special: true, status: "saigne", cooldown: 4, maxUses: 1 },
  head_ceratopsian: { key: "charge_cornue", label: "Charge Cornue", uses: ["force", "force"], emoji: "🐃", desc: "embroche avec ses cornes", basePower: 1.5, special: true, status: "etourdi", cooldown: 4, maxUses: 2 },
  head_armored: { key: "coup_de_dome", label: "Coup de Dôme", uses: ["force"], emoji: "🪨", desc: "frappe avec son crâne blindé", basePower: 1.4, special: true, status: "etourdi", cooldown: 3, maxUses: 2 },
  head_spino: { key: "morsure_croc", label: "Morsure Crocodile", uses: ["attaque"], emoji: "🐊", desc: "happe avec ses mâchoires d'eau", basePower: 1.5, special: true, status: "saigne", cooldown: 3, maxUses: 2 },
  head_marine: { key: "broyeur", label: "Mâchoires Broyeuses", uses: ["attaque", "force"], emoji: "🌊", desc: "écrase avec ses crocs marins", basePower: 1.6, special: true, status: "saigne", cooldown: 4, maxUses: 1 },
  // Back specials
  back_spino: { key: "voile_intim", label: "Voile Intimidante", uses: ["taille"], emoji: "🔥", desc: "déploie sa voile menaçante", basePower: 0.6, special: true, status: "terrifie", noDamage: false, cooldown: 5, maxUses: 1 },
  back_armored: { key: "armure_pic", label: "Pics Dorsaux", uses: ["defense"], emoji: "⚡", desc: "se hérisse de pointes", basePower: 1.2, special: true, status: "saigne", cooldown: 3, maxUses: 2 },
  // Tail specials
  tail_armored: { key: "massue_caudale", label: "Massue Caudale", uses: ["force", "force"], emoji: "🔨", desc: "fracasse avec sa massue", basePower: 1.7, special: true, status: "etourdi", cooldown: 5, maxUses: 1 },
  tail_sauropod: { key: "fouet_caudal", label: "Fouet Caudal", uses: ["force", "vitesse"], emoji: "💫", desc: "claque sa queue comme un fouet", basePower: 1.4, special: true, cooldown: 3, maxUses: 2 },
  // Back legs specials
  backLegs_raptor: { key: "bond_predateur", label: "Bond Prédateur", uses: ["vitesse", "attaque"], emoji: "🦅", desc: "bondit et frappe", basePower: 1.5, special: true, status: "saigne", cooldown: 4, maxUses: 2 },
};

// Compute actual max uses based on dino stats (endurance bonus)
export function getMaxUses(attack, stats, trait) {
  const base = attack.maxUses || 3;
  const traitBonus = trait === "endurant" ? 1 : 0;
  if (attack.special) return base + traitBonus;
  const enduranceBonus = Math.min(2, Math.floor((stats.taille + stats.force) / 8));
  return base + enduranceBonus + traitBonus;
}

export function getAvailableAttacks(build) {
  const attacks = [...BASIC_ATTACKS];
  const headFam = DINOS[build.head].family;
  const backFam = DINOS[build.back].family;
  const tailFam = DINOS[build.tail].family;
  const backLegsFam = DINOS[build.backLegs].family;

  if (SPECIAL_ATTACKS[`head_${headFam}`]) attacks.push(SPECIAL_ATTACKS[`head_${headFam}`]);
  if (SPECIAL_ATTACKS[`back_${backFam}`]) attacks.push(SPECIAL_ATTACKS[`back_${backFam}`]);
  if (SPECIAL_ATTACKS[`tail_${tailFam}`]) attacks.push(SPECIAL_ATTACKS[`tail_${tailFam}`]);
  if (SPECIAL_ATTACKS[`backLegs_${backLegsFam}`]) attacks.push(SPECIAL_ATTACKS[`backLegs_${backLegsFam}`]);
  return attacks;
}

export const STATUS_EFFECTS = {
  saigne: { label: "Saignement", emoji: "🩸", dmgPerTurn: 4, duration: 3, color: "#cc2020" },
  etourdi: { label: "Étourdi", emoji: "💫", skipTurn: true, duration: 1, color: "#f5c838" },
  terrifie: { label: "Terrifié", emoji: "😱", dmgMult: 0.5, duration: 2, color: "#a838c8" },
};

export function computeAttack(attacker, defender, attackType, extras = {}) {
  const useAvg = attackType.uses.reduce((s, k) => s + attacker.stats[k], 0) / attackType.uses.length;
  let baseDmg = useAvg * 2.1 * (attackType.basePower || 1) + Math.random() * 4;
  const reduction = defender.stats.defense * 0.55;
  const dodgeBonus = (defender.stats.intel || 5) * 0.015;
  // Ruse trait doubles dodge
  const ruseMult = defender.trait === "ruse" ? 2 : 1;
  const speedDodge = Math.random() < Math.max(0, ((defender.stats.vitesse - attacker.stats.vitesse) * 0.035 + dodgeBonus) * ruseMult);
  // Sanguinaire trait boosts crit
  const sangBonus = attacker.trait === "sanguinaire" ? 0.10 : 0;
  const critChance = attacker.stats.attaque * 0.025 + (attacker.stats.intel || 5) * 0.012 + sangBonus;
  const crit = Math.random() < critChance;

  // Damage multipliers
  let dmgMult = 1;
  if (attacker.status?.terrifie) dmgMult *= 0.5;

  // Elemental type
  const attackerType = attacker.type;
  const defenderType = defender.type;
  const typeMult = getTypeMult(attackerType, defenderType);
  dmgMult *= typeMult;

  // Weather
  if (extras.weather?.boosts?.[attackerType]) dmgMult *= extras.weather.boosts[attackerType];

  // Boost item active
  if (attacker.boosted) dmgMult *= 1.5;

  // Rage: Fureur trait below 30% HP
  if (attacker.trait === "fureur" && attacker.hpRatio < 0.3) dmgMult *= 1.4;

  // Combo: attacking again after a different attack
  if (extras.combo) dmgMult *= 1.25;
  if (extras.quizBoost) dmgMult *= 1.25;

  // Defender defending
  if (defender.defending) dmgMult *= 0.3;

  if (speedDodge) return { damage: 0, dodged: true, crit: false, status: null, typeMult };
  let dmg = Math.max(2, Math.round((baseDmg - reduction) * dmgMult + (Math.random() * 4 - 2)));
  // Sanguinaire: +20% crit damage
  const critBonus = attacker.trait === "sanguinaire" ? 2.0 : 1.8;
  if (crit) dmg = Math.round(dmg * critBonus);

  let appliedStatus = null;
  if (attackType.status && Math.random() < 0.7) {
    appliedStatus = attackType.status;
  }

  return { damage: dmg, dodged: false, crit, status: appliedStatus, typeMult };
}

// Tournament tiers - 5 increasing difficulty enemies
export const TOURNAMENT_TIERS = [
  { name: "Apprenti", powerMult: 0.7, color: "#7a8a3a" },
  { name: "Vétéran", powerMult: 0.9, color: "#8a6a3a" },
  { name: "Champion", powerMult: 1.1, color: "#8a4a3a" },
  { name: "Légendaire", powerMult: 1.3, color: "#6a3a7a" },
  { name: "Apex", powerMult: 1.6, color: "#4a4a5a" },
];

// Combat environments
export const ENVIRONMENTS = [
  { key: "jungle", name: "Jungle Crétacée", emoji: "🌴", bg: "linear-gradient(180deg, #5a7a3a 0%, #2a4a1a 100%)", ground: "#3a4a1a" },
  { key: "desert", name: "Désert Aride", emoji: "🏜️", bg: "linear-gradient(180deg, #c89858 0%, #8a6838 100%)", ground: "#7a5828" },
  { key: "marsh", name: "Marais Brumeux", emoji: "🌫️", bg: "linear-gradient(180deg, #5a6a7a 0%, #2a3a4a 100%)", ground: "#3a4a3a" },
  { key: "volcanic", name: "Plaine Volcanique", emoji: "🌋", bg: "linear-gradient(180deg, #6a3a3a 0%, #2a1a1a 100%)", ground: "#4a2828" },
  { key: "coast", name: "Côte Préhistorique", emoji: "🌊", bg: "linear-gradient(180deg, #4a8aaa 0%, #2a4a6a 100%)", ground: "#5a7a8a" },
];
