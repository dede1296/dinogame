import { DINOS } from "../data/dinos.js";

// ============ ELEMENTAL TYPES ============
// Each dino family has a dominant type. Type chart gives multipliers.
export const FAMILY_TYPES = {
  tyrant: "feu",       // Predator fury
  spino: "eau",        // Amphibious
  raptor: "vent",      // Fast, agile
  sauropod: "terre",   // Massive, grounded
  ceratopsian: "terre",
  armored: "pierre",   // Armored bastion
  hadrosaur: "nature", // Herbivore
  flyer: "vent",
  marine: "eau",
};

// Rock-paper-scissors style type chart. Multipliers: 1.5 strong, 0.7 weak, 1 neutral
export const TYPE_CHART = {
  feu:    { nature: 1.5, vent: 1.5, eau: 0.7, pierre: 0.7 },
  eau:    { feu: 1.5, terre: 1.5, vent: 0.7, nature: 0.7 },
  terre:  { pierre: 1.5, feu: 1.5, vent: 0.7, nature: 0.7 },
  vent:   { nature: 1.5, eau: 1.5, feu: 0.7, pierre: 0.7 },
  pierre: { vent: 1.5, nature: 1.5, eau: 0.7, feu: 0.7 },
  nature: { pierre: 1.5, terre: 1.5, feu: 0.7, vent: 0.7 },
};
export const TYPE_EMOJI = { feu: "🔥", eau: "💧", terre: "🌍", vent: "💨", pierre: "🪨", nature: "🌿" };

export function getBuildType(build) { return FAMILY_TYPES[DINOS[build.head].family] || "terre"; }
export function getTypeMult(attackerType, defenderType) {
  return TYPE_CHART[attackerType]?.[defenderType] || 1;
}

// ============ WEATHER ============
export const WEATHERS = [
  { key: "clear", name: "Soleil", emoji: "☀️", boosts: { feu: 1.15, vent: 1.1 } },
  { key: "rain", name: "Pluie", emoji: "🌧️", boosts: { eau: 1.2, feu: 0.85 } },
  { key: "storm", name: "Orage", emoji: "⛈️", boosts: { vent: 1.2, eau: 1.1 } },
  { key: "fog", name: "Brume", emoji: "🌫️", boosts: {} },
  { key: "snow", name: "Neige", emoji: "❄️", boosts: { eau: 0.9, feu: 0.9, pierre: 1.1 } },
];
