import React, { useState, useMemo, useRef, useEffect } from "react";
import * as THREE from "three";

// ============ DATA: 50 famous dinosaurs ============
// Each dino has parts with stats. Stats are 1-10.
const DINOS = [
  { name: "Tyrannosaurus Rex", family: "tyrant", era: "Crétacé", head: { size: 10, bite: 10 }, teeth: { sharp: 10, count: 8 }, frontLegs: { power: 2, reach: 2 }, backLegs: { power: 9, speed: 7 }, back: { armor: 4, spikes: 0 }, tail: { power: 8, length: 7 }, color: "#5a3a2e", cry: "roar-deep" },
  { name: "Velociraptor", family: "raptor", era: "Crétacé", head: { size: 4, bite: 6 }, teeth: { sharp: 9, count: 7 }, frontLegs: { power: 6, reach: 6 }, backLegs: { power: 7, speed: 10 }, back: { armor: 2, spikes: 0 }, tail: { power: 4, length: 6 }, color: "#7a5a3a", cry: "screech" },
  { name: "Triceratops", family: "ceratopsian", era: "Crétacé", head: { size: 9, bite: 5 }, teeth: { sharp: 3, count: 5 }, frontLegs: { power: 8, reach: 4 }, backLegs: { power: 8, speed: 4 }, back: { armor: 9, spikes: 7 }, tail: { power: 5, length: 4 }, color: "#6b6b3a", cry: "bellow" },
  { name: "Brachiosaurus", family: "sauropod", era: "Jurassique", head: { size: 3, bite: 2 }, teeth: { sharp: 1, count: 4 }, frontLegs: { power: 9, reach: 10 }, backLegs: { power: 9, speed: 2 }, back: { armor: 3, spikes: 0 }, tail: { power: 6, length: 8 }, color: "#7a8a5a", cry: "low-horn" },
  { name: "Stegosaurus", family: "armored", era: "Jurassique", head: { size: 3, bite: 3 }, teeth: { sharp: 2, count: 4 }, frontLegs: { power: 6, reach: 3 }, backLegs: { power: 7, speed: 3 }, back: { armor: 8, spikes: 10 }, tail: { power: 9, length: 6 }, color: "#5a6a4a", cry: "grunt" },
  { name: "Spinosaurus", family: "spino", era: "Crétacé", head: { size: 9, bite: 9 }, teeth: { sharp: 8, count: 9 }, frontLegs: { power: 7, reach: 7 }, backLegs: { power: 8, speed: 6 }, back: { armor: 6, spikes: 9 }, tail: { power: 8, length: 9 }, color: "#3a4a6a", cry: "hiss-roar" },
  { name: "Allosaurus", family: "tyrant", era: "Jurassique", head: { size: 8, bite: 8 }, teeth: { sharp: 9, count: 8 }, frontLegs: { power: 5, reach: 5 }, backLegs: { power: 8, speed: 8 }, back: { armor: 3, spikes: 0 }, tail: { power: 7, length: 7 }, color: "#6a4a2a", cry: "roar" },
  { name: "Ankylosaurus", family: "armored", era: "Crétacé", head: { size: 5, bite: 4 }, teeth: { sharp: 2, count: 5 }, frontLegs: { power: 7, reach: 3 }, backLegs: { power: 7, speed: 2 }, back: { armor: 10, spikes: 8 }, tail: { power: 10, length: 6 }, color: "#4a4a3a", cry: "grunt-deep" },
  { name: "Diplodocus", family: "sauropod", era: "Jurassique", head: { size: 2, bite: 1 }, teeth: { sharp: 1, count: 3 }, frontLegs: { power: 7, reach: 6 }, backLegs: { power: 8, speed: 3 }, back: { armor: 2, spikes: 1 }, tail: { power: 9, length: 10 }, color: "#7a6a4a", cry: "low-horn" },
  { name: "Parasaurolophus", family: "hadrosaur", era: "Crétacé", head: { size: 5, bite: 3 }, teeth: { sharp: 2, count: 6 }, frontLegs: { power: 4, reach: 4 }, backLegs: { power: 6, speed: 6 }, back: { armor: 2, spikes: 0 }, tail: { power: 4, length: 5 }, color: "#8a6a4a", cry: "trumpet" },
  { name: "Pteranodon", family: "flyer", era: "Crétacé", head: { size: 7, bite: 4 }, teeth: { sharp: 0, count: 0 }, frontLegs: { power: 9, reach: 10 }, backLegs: { power: 3, speed: 4 }, back: { armor: 1, spikes: 0 }, tail: { power: 2, length: 2 }, color: "#9a8a6a", cry: "screech-high" },
  { name: "Carnotaurus", family: "tyrant", era: "Crétacé", head: { size: 6, bite: 7 }, teeth: { sharp: 8, count: 7 }, frontLegs: { power: 1, reach: 1 }, backLegs: { power: 9, speed: 9 }, back: { armor: 4, spikes: 5 }, tail: { power: 6, length: 6 }, color: "#e84040", cry: "roar" },
  { name: "Iguanodon", family: "hadrosaur", era: "Crétacé", head: { size: 5, bite: 4 }, teeth: { sharp: 3, count: 6 }, frontLegs: { power: 7, reach: 6 }, backLegs: { power: 7, speed: 5 }, back: { armor: 3, spikes: 2 }, tail: { power: 5, length: 5 }, color: "#6a7a4a", cry: "bellow" },
  { name: "Compsognathus", family: "raptor", era: "Jurassique", head: { size: 2, bite: 2 }, teeth: { sharp: 6, count: 5 }, frontLegs: { power: 3, reach: 3 }, backLegs: { power: 4, speed: 10 }, back: { armor: 1, spikes: 0 }, tail: { power: 2, length: 4 }, color: "#8a7a3a", cry: "chirp" },
  { name: "Pachycephalosaurus", family: "armored", era: "Crétacé", head: { size: 8, bite: 4 }, teeth: { sharp: 3, count: 5 }, frontLegs: { power: 4, reach: 3 }, backLegs: { power: 7, speed: 6 }, back: { armor: 6, spikes: 3 }, tail: { power: 5, length: 5 }, color: "#7a5a3a", cry: "thud-cry" },
  { name: "Gallimimus", family: "raptor", era: "Crétacé", head: { size: 3, bite: 2 }, teeth: { sharp: 1, count: 0 }, frontLegs: { power: 4, reach: 5 }, backLegs: { power: 6, speed: 10 }, back: { armor: 2, spikes: 0 }, tail: { power: 4, length: 6 }, color: "#9a8a5a", cry: "chirp-loud" },
  { name: "Dilophosaurus", family: "raptor", era: "Jurassique", head: { size: 6, bite: 5 }, teeth: { sharp: 7, count: 7 }, frontLegs: { power: 4, reach: 4 }, backLegs: { power: 7, speed: 8 }, back: { armor: 3, spikes: 4 }, tail: { power: 5, length: 6 }, color: "#5a7a3a", cry: "hiss" },
  { name: "Therizinosaurus", family: "raptor", era: "Crétacé", head: { size: 4, bite: 3 }, teeth: { sharp: 2, count: 4 }, frontLegs: { power: 10, reach: 10 }, backLegs: { power: 7, speed: 4 }, back: { armor: 4, spikes: 6 }, tail: { power: 5, length: 5 }, color: "#6a5a3a", cry: "growl" },
  { name: "Mosasaurus", family: "marine", era: "Crétacé", head: { size: 9, bite: 10 }, teeth: { sharp: 10, count: 10 }, frontLegs: { power: 8, reach: 7 }, backLegs: { power: 8, speed: 9 }, back: { armor: 6, spikes: 2 }, tail: { power: 10, length: 9 }, color: "#2a4a5a", cry: "underwater-roar" },
  { name: "Plesiosaurus", family: "marine", era: "Jurassique", head: { size: 4, bite: 5 }, teeth: { sharp: 7, count: 7 }, frontLegs: { power: 8, reach: 9 }, backLegs: { power: 8, speed: 8 }, back: { armor: 4, spikes: 0 }, tail: { power: 6, length: 7 }, color: "#3a5a6a", cry: "whale-call" },
  { name: "Archaeopteryx", family: "raptor", era: "Jurassique", head: { size: 2, bite: 2 }, teeth: { sharp: 5, count: 4 }, frontLegs: { power: 7, reach: 8 }, backLegs: { power: 4, speed: 7 }, back: { armor: 1, spikes: 0 }, tail: { power: 2, length: 5 }, color: "#7a6a3a", cry: "chirp-melodic" },
  { name: "Microraptor", family: "raptor", era: "Crétacé", head: { size: 2, bite: 2 }, teeth: { sharp: 6, count: 5 }, frontLegs: { power: 6, reach: 8 }, backLegs: { power: 4, speed: 8 }, back: { armor: 1, spikes: 0 }, tail: { power: 3, length: 6 }, color: "#3a3a4a", cry: "chirp" },
  { name: "Giganotosaurus", family: "tyrant", era: "Crétacé", head: { size: 10, bite: 10 }, teeth: { sharp: 10, count: 9 }, frontLegs: { power: 3, reach: 3 }, backLegs: { power: 9, speed: 7 }, back: { armor: 4, spikes: 0 }, tail: { power: 8, length: 8 }, color: "#5a3a3a", cry: "roar-deep" },
  { name: "Utahraptor", family: "raptor", era: "Crétacé", head: { size: 5, bite: 6 }, teeth: { sharp: 9, count: 7 }, frontLegs: { power: 7, reach: 7 }, backLegs: { power: 8, speed: 9 }, back: { armor: 3, spikes: 0 }, tail: { power: 5, length: 6 }, color: "#6a4a3a", cry: "screech" },
  { name: "Deinonychus", family: "raptor", era: "Crétacé", head: { size: 4, bite: 6 }, teeth: { sharp: 9, count: 7 }, frontLegs: { power: 6, reach: 6 }, backLegs: { power: 8, speed: 9 }, back: { armor: 2, spikes: 0 }, tail: { power: 4, length: 6 }, color: "#7a5a2a", cry: "screech" },
  { name: "Apatosaurus", family: "sauropod", era: "Jurassique", head: { size: 3, bite: 2 }, teeth: { sharp: 1, count: 3 }, frontLegs: { power: 9, reach: 8 }, backLegs: { power: 10, speed: 3 }, back: { armor: 3, spikes: 0 }, tail: { power: 9, length: 9 }, color: "#6a5a4a", cry: "low-horn" },
  { name: "Kentrosaurus", family: "armored", era: "Jurassique", head: { size: 3, bite: 3 }, teeth: { sharp: 2, count: 4 }, frontLegs: { power: 5, reach: 3 }, backLegs: { power: 6, speed: 4 }, back: { armor: 7, spikes: 10 }, tail: { power: 8, length: 6 }, color: "#5a5a3a", cry: "grunt" },
  { name: "Euoplocephalus", family: "armored", era: "Crétacé", head: { size: 5, bite: 4 }, teeth: { sharp: 2, count: 5 }, frontLegs: { power: 7, reach: 3 }, backLegs: { power: 7, speed: 2 }, back: { armor: 10, spikes: 7 }, tail: { power: 9, length: 5 }, color: "#4a4a2a", cry: "grunt-deep" },
  { name: "Corythosaurus", family: "hadrosaur", era: "Crétacé", head: { size: 6, bite: 3 }, teeth: { sharp: 2, count: 6 }, frontLegs: { power: 4, reach: 4 }, backLegs: { power: 6, speed: 6 }, back: { armor: 2, spikes: 0 }, tail: { power: 4, length: 5 }, color: "#7a7a4a", cry: "trumpet-low" },
  { name: "Maiasaura", family: "hadrosaur", era: "Crétacé", head: { size: 5, bite: 3 }, teeth: { sharp: 2, count: 6 }, frontLegs: { power: 5, reach: 4 }, backLegs: { power: 6, speed: 5 }, back: { armor: 2, spikes: 0 }, tail: { power: 4, length: 5 }, color: "#8a7a5a", cry: "bellow-soft" },
  { name: "Oviraptor", family: "raptor", era: "Crétacé", head: { size: 3, bite: 4 }, teeth: { sharp: 0, count: 0 }, frontLegs: { power: 5, reach: 5 }, backLegs: { power: 5, speed: 8 }, back: { armor: 2, spikes: 0 }, tail: { power: 3, length: 5 }, color: "#7a5a4a", cry: "chirp-trill" },
  { name: "Troodon", family: "raptor", era: "Crétacé", head: { size: 3, bite: 4 }, teeth: { sharp: 7, count: 6 }, frontLegs: { power: 5, reach: 5 }, backLegs: { power: 6, speed: 9 }, back: { armor: 2, spikes: 0 }, tail: { power: 3, length: 5 }, color: "#5a6a3a", cry: "trill" },
  { name: "Quetzalcoatlus", family: "flyer", era: "Crétacé", head: { size: 9, bite: 5 }, teeth: { sharp: 0, count: 0 }, frontLegs: { power: 10, reach: 10 }, backLegs: { power: 5, speed: 5 }, back: { armor: 1, spikes: 0 }, tail: { power: 2, length: 2 }, color: "#8a6a4a", cry: "screech-deep" },
  { name: "Suchomimus", family: "spino", era: "Crétacé", head: { size: 8, bite: 7 }, teeth: { sharp: 7, count: 9 }, frontLegs: { power: 7, reach: 7 }, backLegs: { power: 8, speed: 6 }, back: { armor: 4, spikes: 5 }, tail: { power: 7, length: 8 }, color: "#5a4a6a", cry: "hiss-roar" },
  { name: "Baryonyx", family: "spino", era: "Crétacé", head: { size: 7, bite: 7 }, teeth: { sharp: 8, count: 8 }, frontLegs: { power: 8, reach: 7 }, backLegs: { power: 7, speed: 6 }, back: { armor: 3, spikes: 2 }, tail: { power: 6, length: 7 }, color: "#4a5a5a", cry: "growl-wet" },
  { name: "Megalosaurus", family: "tyrant", era: "Jurassique", head: { size: 7, bite: 7 }, teeth: { sharp: 8, count: 7 }, frontLegs: { power: 5, reach: 5 }, backLegs: { power: 8, speed: 7 }, back: { armor: 3, spikes: 0 }, tail: { power: 6, length: 6 }, color: "#5a3a2a", cry: "roar" },
  { name: "Ceratosaurus", family: "tyrant", era: "Jurassique", head: { size: 7, bite: 6 }, teeth: { sharp: 8, count: 7 }, frontLegs: { power: 4, reach: 4 }, backLegs: { power: 7, speed: 7 }, back: { armor: 4, spikes: 4 }, tail: { power: 6, length: 6 }, color: "#6a3a2a", cry: "roar" },
  { name: "Yutyrannus", family: "tyrant", era: "Crétacé", head: { size: 8, bite: 8 }, teeth: { sharp: 8, count: 7 }, frontLegs: { power: 4, reach: 4 }, backLegs: { power: 7, speed: 6 }, back: { armor: 4, spikes: 0 }, tail: { power: 6, length: 6 }, color: "#8a8a8a", cry: "roar-muffled" },
  { name: "Sinosauropteryx", family: "raptor", era: "Crétacé", head: { size: 3, bite: 3 }, teeth: { sharp: 5, count: 5 }, frontLegs: { power: 4, reach: 4 }, backLegs: { power: 5, speed: 8 }, back: { armor: 1, spikes: 0 }, tail: { power: 3, length: 7 }, color: "#a06030", cry: "chirp" },
  { name: "Concavenator", family: "tyrant", era: "Crétacé", head: { size: 6, bite: 6 }, teeth: { sharp: 7, count: 7 }, frontLegs: { power: 4, reach: 4 }, backLegs: { power: 7, speed: 7 }, back: { armor: 4, spikes: 7 }, tail: { power: 6, length: 6 }, color: "#7a4a3a", cry: "roar" },
  { name: "Amargasaurus", family: "sauropod", era: "Crétacé", head: { size: 3, bite: 2 }, teeth: { sharp: 1, count: 3 }, frontLegs: { power: 7, reach: 6 }, backLegs: { power: 8, speed: 4 }, back: { armor: 4, spikes: 9 }, tail: { power: 7, length: 8 }, color: "#5a5a6a", cry: "low-horn" },
  { name: "Mamenchisaurus", family: "sauropod", era: "Jurassique", head: { size: 3, bite: 2 }, teeth: { sharp: 1, count: 3 }, frontLegs: { power: 8, reach: 10 }, backLegs: { power: 9, speed: 3 }, back: { armor: 3, spikes: 0 }, tail: { power: 8, length: 9 }, color: "#7a7a5a", cry: "low-horn" },
  { name: "Argentinosaurus", family: "sauropod", era: "Crétacé", head: { size: 3, bite: 2 }, teeth: { sharp: 1, count: 3 }, frontLegs: { power: 10, reach: 9 }, backLegs: { power: 10, speed: 2 }, back: { armor: 4, spikes: 0 }, tail: { power: 9, length: 9 }, color: "#6a6a4a", cry: "low-horn-deep" },
  { name: "Saltasaurus", family: "sauropod", era: "Crétacé", head: { size: 3, bite: 2 }, teeth: { sharp: 1, count: 3 }, frontLegs: { power: 7, reach: 6 }, backLegs: { power: 8, speed: 4 }, back: { armor: 8, spikes: 4 }, tail: { power: 6, length: 7 }, color: "#7a6a5a", cry: "low-horn" },
  { name: "Protoceratops", family: "ceratopsian", era: "Crétacé", head: { size: 6, bite: 4 }, teeth: { sharp: 3, count: 5 }, frontLegs: { power: 5, reach: 3 }, backLegs: { power: 6, speed: 4 }, back: { armor: 5, spikes: 2 }, tail: { power: 4, length: 4 }, color: "#8a7a5a", cry: "grunt" },
  { name: "Styracosaurus", family: "ceratopsian", era: "Crétacé", head: { size: 9, bite: 5 }, teeth: { sharp: 3, count: 5 }, frontLegs: { power: 7, reach: 4 }, backLegs: { power: 7, speed: 5 }, back: { armor: 8, spikes: 9 }, tail: { power: 5, length: 4 }, color: "#7a5a3a", cry: "bellow" },
  { name: "Pentaceratops", family: "ceratopsian", era: "Crétacé", head: { size: 10, bite: 5 }, teeth: { sharp: 3, count: 5 }, frontLegs: { power: 8, reach: 4 }, backLegs: { power: 8, speed: 4 }, back: { armor: 9, spikes: 6 }, tail: { power: 5, length: 4 }, color: "#7a6a3a", cry: "bellow-deep" },
  { name: "Edmontosaurus", family: "hadrosaur", era: "Crétacé", head: { size: 6, bite: 4 }, teeth: { sharp: 2, count: 7 }, frontLegs: { power: 6, reach: 5 }, backLegs: { power: 7, speed: 6 }, back: { armor: 3, spikes: 0 }, tail: { power: 5, length: 6 }, color: "#7a7a4a", cry: "trumpet" },
  { name: "Acrocanthosaurus", family: "tyrant", era: "Crétacé", head: { size: 9, bite: 9 }, teeth: { sharp: 9, count: 8 }, frontLegs: { power: 4, reach: 4 }, backLegs: { power: 8, speed: 7 }, back: { armor: 5, spikes: 6 }, tail: { power: 7, length: 7 }, color: "#5a4a3a", cry: "roar" },
  { name: "Cryolophosaurus", family: "tyrant", era: "Jurassique", head: { size: 6, bite: 6 }, teeth: { sharp: 7, count: 7 }, frontLegs: { power: 4, reach: 4 }, backLegs: { power: 7, speed: 7 }, back: { armor: 3, spikes: 4 }, tail: { power: 6, length: 6 }, color: "#6a6a7a", cry: "roar-cold" },
  // ===== EXCLUSIVE DINOS (indices 50-64) — only obtainable via capture =====
  { name: "Indominus", family: "tyrant", era: "Hybride", exclusive: true, rarity: "legendary", head: { size: 10, bite: 10 }, teeth: { sharp: 10, count: 9 }, frontLegs: { power: 5, reach: 5 }, backLegs: { power: 9, speed: 9 }, back: { armor: 7, spikes: 5 }, tail: { power: 8, length: 7 }, color: "#e8e8e8", cry: "roar" },
  { name: "Dino Fantôme", family: "raptor", era: "Mystère", exclusive: true, rarity: "epic", head: { size: 5, bite: 7 }, teeth: { sharp: 8, count: 6 }, frontLegs: { power: 3, reach: 6 }, backLegs: { power: 6, speed: 10 }, back: { armor: 1, spikes: 2 }, tail: { power: 4, length: 8 }, color: "#b8a8d8", cry: "howl" },
  { name: "Titanocristal", family: "sauropod", era: "Mystère", exclusive: true, rarity: "epic", head: { size: 8, bite: 3 }, teeth: { sharp: 2, count: 4 }, frontLegs: { power: 10, reach: 8 }, backLegs: { power: 10, speed: 3 }, back: { armor: 10, spikes: 8 }, tail: { power: 9, length: 10 }, color: "#58d8e8", cry: "rumble" },
  { name: "Pyroraptor", family: "raptor", era: "Crétacé", exclusive: true, rarity: "rare", head: { size: 4, bite: 7 }, teeth: { sharp: 8, count: 6 }, frontLegs: { power: 5, reach: 7 }, backLegs: { power: 6, speed: 10 }, back: { armor: 2, spikes: 3 }, tail: { power: 5, length: 6 }, color: "#e85020", cry: "screech" },
  { name: "Noctosaurus", family: "flyer", era: "Mystère", exclusive: true, rarity: "epic", head: { size: 5, bite: 5 }, teeth: { sharp: 4, count: 3 }, frontLegs: { power: 3, reach: 10 }, backLegs: { power: 3, speed: 8 }, back: { armor: 2, spikes: 1 }, tail: { power: 3, length: 4 }, color: "#2a1a3a", cry: "screech" },
  { name: "Venomjaw", family: "spino", era: "Hybride", exclusive: true, rarity: "legendary", head: { size: 8, bite: 9 }, teeth: { sharp: 10, count: 8 }, frontLegs: { power: 6, reach: 7 }, backLegs: { power: 7, speed: 8 }, back: { armor: 4, spikes: 6 }, tail: { power: 7, length: 7 }, color: "#38a848", cry: "howl" },
  { name: "Glaciodonte", family: "armored", era: "Mystère", exclusive: true, rarity: "rare", head: { size: 7, bite: 5 }, teeth: { sharp: 4, count: 5 }, frontLegs: { power: 8, reach: 4 }, backLegs: { power: 7, speed: 3 }, back: { armor: 10, spikes: 8 }, tail: { power: 8, length: 5 }, color: "#a0d0e8", cry: "bellow" },
  { name: "Ombrecorne", family: "ceratopsian", era: "Mystère", exclusive: true, rarity: "epic", head: { size: 9, bite: 6 }, teeth: { sharp: 5, count: 6 }, frontLegs: { power: 9, reach: 5 }, backLegs: { power: 8, speed: 5 }, back: { armor: 8, spikes: 7 }, tail: { power: 6, length: 5 }, color: "#3a2848", cry: "bellow-deep" },
  { name: "Infernodonte", family: "tyrant", era: "Hybride", exclusive: true, rarity: "legendary", head: { size: 10, bite: 10 }, teeth: { sharp: 10, count: 10 }, frontLegs: { power: 5, reach: 4 }, backLegs: { power: 9, speed: 7 }, back: { armor: 6, spikes: 8 }, tail: { power: 8, length: 8 }, color: "#c82020", cry: "roar" },
  { name: "Aquaspino", family: "spino", era: "Hybride", exclusive: true, rarity: "rare", head: { size: 7, bite: 7 }, teeth: { sharp: 7, count: 6 }, frontLegs: { power: 5, reach: 6 }, backLegs: { power: 6, speed: 7 }, back: { armor: 4, spikes: 5 }, tail: { power: 7, length: 8 }, color: "#2060a0", cry: "whale" },
  { name: "Tempêtaile", family: "hadrosaur", era: "Mystère", exclusive: true, rarity: "rare", head: { size: 6, bite: 4 }, teeth: { sharp: 3, count: 7 }, frontLegs: { power: 6, reach: 5 }, backLegs: { power: 7, speed: 8 }, back: { armor: 5, spikes: 3 }, tail: { power: 9, length: 9 }, color: "#8858a8", cry: "trumpet" },
  { name: "Astérodon", family: "sauropod", era: "Hybride", exclusive: true, rarity: "legendary", head: { size: 8, bite: 4 }, teeth: { sharp: 3, count: 5 }, frontLegs: { power: 10, reach: 9 }, backLegs: { power: 10, speed: 4 }, back: { armor: 8, spikes: 6 }, tail: { power: 10, length: 10 }, color: "#e8a020", cry: "rumble" },
  { name: "Spectrodon", family: "marine", era: "Mystère", exclusive: true, rarity: "epic", head: { size: 7, bite: 8 }, teeth: { sharp: 9, count: 7 }, frontLegs: { power: 4, reach: 8 }, backLegs: { power: 5, speed: 9 }, back: { armor: 3, spikes: 2 }, tail: { power: 6, length: 9 }, color: "#48c8a8", cry: "whale" },
  { name: "Fulguroraptor", family: "raptor", era: "Hybride", exclusive: true, rarity: "epic", head: { size: 5, bite: 8 }, teeth: { sharp: 9, count: 7 }, frontLegs: { power: 6, reach: 8 }, backLegs: { power: 7, speed: 10 }, back: { armor: 3, spikes: 4 }, tail: { power: 6, length: 7 }, color: "#e8d020", cry: "screech" },
  { name: "Titanosaure d'Or", family: "armored", era: "Légendaire", exclusive: true, rarity: "legendary", head: { size: 9, bite: 6 }, teeth: { sharp: 5, count: 6 }, frontLegs: { power: 10, reach: 6 }, backLegs: { power: 9, speed: 4 }, back: { armor: 10, spikes: 10 }, tail: { power: 10, length: 8 }, color: "#d4af37", cry: "rumble" },
];

const PARTS = [
  { key: "head", label: "Tête", icon: "◐" },
  { key: "teeth", label: "Dents", icon: "△" },
  { key: "frontLegs", label: "Pattes avant", icon: "⌒" },
  { key: "backLegs", label: "Pattes arrière", icon: "⌐" },
  { key: "back", label: "Dos", icon: "≋" },
  { key: "tail", label: "Queue", icon: "～" },
  { key: "color", label: "Couleur", icon: "●" },
];

// ============ AUDIO ENGINE v2 — distinctive cries per family ============

function makeNoise(ctx, duration) {
  const buf = ctx.createBuffer(1, ctx.sampleRate * duration, ctx.sampleRate);
  const d = buf.getChannelData(0);
  for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  const src = ctx.createBufferSource();
  src.buffer = buf;
  return src;
}

function makeReverb(ctx, duration, decay) {
  const rate = ctx.sampleRate;
  const length = rate * duration;
  const impulse = ctx.createBuffer(2, length, rate);
  for (let ch = 0; ch < 2; ch++) {
    const d = impulse.getChannelData(ch);
    for (let i = 0; i < length; i++) {
      d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, decay);
    }
  }
  const conv = ctx.createConvolver();
  conv.buffer = impulse;
  return conv;
}

function makeDistortion(ctx, amount) {
  const ws = ctx.createWaveShaper();
  const n = 2048;
  const curve = new Float32Array(n);
  const k = amount;
  for (let i = 0; i < n; i++) {
    const x = (i * 2) / n - 1;
    curve[i] = ((3 + k) * x * 20 * Math.PI / 180) / (Math.PI + k * Math.abs(x));
  }
  ws.curve = curve;
  ws.oversample = "4x";
  return ws;
}

// ---------- Individual cry generators ----------

function cryRoar(ctx, t0, sendWet, sendDry, p) {
  // Deep, gritty, formant-shaped roar. Scales with head/bite/sharp/tailPow.
  const { headSize, bite, sharp, tailPow, cryType } = p;
  const baseFreq = 55 + (10 - headSize) * 9; // 55-145 Hz
  const duration = 1.2 + headSize * 0.15 + tailPow * 0.04;
  const isDeep = cryType.includes("deep");
  const isCold = cryType.includes("cold");
  const isMuffled = cryType.includes("muffled");
  const finalFreq = isDeep ? baseFreq * 0.55 : baseFreq * 0.75;

  // Main body: detuned sawtooths for thickness
  const osc1 = ctx.createOscillator(); osc1.type = "sawtooth";
  const osc2 = ctx.createOscillator(); osc2.type = "sawtooth";
  osc1.frequency.setValueAtTime(baseFreq * 1.4, t0);
  osc1.frequency.exponentialRampToValueAtTime(finalFreq, t0 + duration * 0.9);
  osc2.frequency.setValueAtTime(baseFreq * 1.4 * 1.01, t0); // slight detune
  osc2.frequency.exponentialRampToValueAtTime(finalFreq * 1.01, t0 + duration * 0.9);

  // Sub-bass rumble
  const sub = ctx.createOscillator(); sub.type = "sine";
  sub.frequency.setValueAtTime(baseFreq * 0.5, t0);
  sub.frequency.linearRampToValueAtTime(baseFreq * 0.35, t0 + duration);

  // Formant filters (throat/mouth resonance)
  const formant1 = ctx.createBiquadFilter();
  formant1.type = "bandpass"; formant1.Q.value = 6;
  formant1.frequency.value = 350 + bite * 25;
  const formant2 = ctx.createBiquadFilter();
  formant2.type = "bandpass"; formant2.Q.value = 4;
  formant2.frequency.value = 1100;

  // Distortion for aggression
  const dist = makeDistortion(ctx, 10 + sharp * 2);

  // Growl tremolo (amplitude wobble)
  const lfo = ctx.createOscillator();
  lfo.frequency.value = 6 + sharp * 0.4;
  const lfoGain = ctx.createGain();
  lfoGain.gain.value = 0.25;
  const tremolo = ctx.createGain();
  tremolo.gain.value = 0.75;
  lfo.connect(lfoGain);
  lfoGain.connect(tremolo.gain);

  // Breath noise layer
  const noise = makeNoise(ctx, duration);
  const breathFilter = ctx.createBiquadFilter();
  breathFilter.type = "highpass"; breathFilter.frequency.value = 1800;
  const breathGain = ctx.createGain();
  breathGain.gain.setValueAtTime(0, t0);
  breathGain.gain.linearRampToValueAtTime(0.05, t0 + 0.08);
  breathGain.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  // Muffled (underwater) lowpass
  const muffle = ctx.createBiquadFilter();
  muffle.type = "lowpass";
  muffle.frequency.value = isMuffled ? 700 : isCold ? 3000 : 8000;
  muffle.Q.value = 1;

  // Master envelope
  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(0.4, t0 + 0.1);
  env.gain.setValueAtTime(0.4, t0 + duration * 0.65);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  // Wiring
  osc1.connect(dist); osc2.connect(dist);
  dist.connect(formant1); formant1.connect(formant2); formant2.connect(tremolo);
  sub.connect(tremolo);
  tremolo.connect(muffle);
  noise.connect(breathFilter); breathFilter.connect(muffle);
  muffle.connect(env);
  sendDry(env); sendWet(env, isMuffled ? 0.6 : 0.2);

  osc1.start(t0); osc1.stop(t0 + duration);
  osc2.start(t0); osc2.stop(t0 + duration);
  sub.start(t0); sub.stop(t0 + duration);
  lfo.start(t0); lfo.stop(t0 + duration);
  noise.start(t0); noise.stop(t0 + duration);
  return duration;
}

function cryScreech(ctx, t0, sendWet, sendDry, p) {
  const { sharp, headSize, speed, cryType } = p;
  const isHigh = cryType.includes("high");
  const isDeep = cryType.includes("deep");
  const baseFreq = isDeep ? 400 : isHigh ? 1200 : 700 + sharp * 40;
  const duration = 0.5 + speed * 0.04;

  // Main squeal
  const osc = ctx.createOscillator();
  osc.type = "sawtooth";
  osc.frequency.setValueAtTime(baseFreq * 0.5, t0);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 1.4, t0 + duration * 0.3);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.8, t0 + duration);

  // Harmonic shimmer
  const osc2 = ctx.createOscillator();
  osc2.type = "square";
  osc2.frequency.setValueAtTime(baseFreq * 1.51, t0);
  osc2.frequency.exponentialRampToValueAtTime(baseFreq * 2.4, t0 + duration * 0.4);

  // Opening noise burst (air)
  const noise = makeNoise(ctx, 0.15);
  const noiseFilter = ctx.createBiquadFilter();
  noiseFilter.type = "bandpass";
  noiseFilter.frequency.value = 3000;
  noiseFilter.Q.value = 2;
  const noiseEnv = ctx.createGain();
  noiseEnv.gain.setValueAtTime(0.3, t0);
  noiseEnv.gain.exponentialRampToValueAtTime(0.001, t0 + 0.12);

  // Harsh distortion
  const dist = makeDistortion(ctx, 20 + sharp);

  // Bandpass for piercing quality
  const bp = ctx.createBiquadFilter();
  bp.type = "bandpass";
  bp.frequency.value = baseFreq * 1.2;
  bp.Q.value = 3;

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(0.35, t0 + 0.02);
  env.gain.setValueAtTime(0.35, t0 + duration * 0.5);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  osc.connect(dist); osc2.connect(dist);
  dist.connect(bp);
  bp.connect(env);
  noise.connect(noiseFilter); noiseFilter.connect(noiseEnv); noiseEnv.connect(env);

  sendDry(env); sendWet(env, 0.2);

  osc.start(t0); osc.stop(t0 + duration);
  osc2.start(t0); osc2.stop(t0 + duration);
  noise.start(t0); noise.stop(t0 + 0.15);
  return duration;
}

function cryTrumpet(ctx, t0, sendWet, sendDry, p) {
  // Brass-like resonant tone (Parasaurolophus famous cry). Clean harmonics.
  const { headSize, tailPow, cryType } = p;
  const isLow = cryType.includes("low") || cryType.includes("horn");
  const isSoft = cryType.includes("soft");
  const baseFreq = isLow ? 70 + (10 - headSize) * 8 : 150 + (10 - headSize) * 12;
  const duration = isLow ? 2.2 + headSize * 0.15 : 1.4 + tailPow * 0.06;

  // Harmonic series (like a trombone)
  const harmonics = [1, 2, 3, 4, 5, 6];
  const gains = [1.0, 0.5, 0.4, 0.25, 0.15, 0.08];
  const oscs = harmonics.map((h, i) => {
    const o = ctx.createOscillator();
    o.type = i === 0 ? "sine" : "triangle";
    o.frequency.setValueAtTime(baseFreq * h * 0.9, t0);
    o.frequency.exponentialRampToValueAtTime(baseFreq * h, t0 + 0.15);
    o.frequency.setValueAtTime(baseFreq * h, t0 + duration * 0.7);
    o.frequency.exponentialRampToValueAtTime(baseFreq * h * 0.95, t0 + duration);
    return { osc: o, gain: gains[i], h };
  });

  // Slight vibrato
  const vib = ctx.createOscillator();
  vib.frequency.value = 5;
  const vibGain = ctx.createGain();
  vibGain.gain.value = baseFreq * 0.015;
  vib.connect(vibGain);
  oscs.forEach(({ osc }) => vibGain.connect(osc.frequency));

  // Resonant bandpass (horn body)
  const resonance = ctx.createBiquadFilter();
  resonance.type = "bandpass";
  resonance.frequency.value = baseFreq * 2.5;
  resonance.Q.value = 3;

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(isSoft ? 0.25 : 0.4, t0 + 0.25); // slow attack like brass
  env.gain.setValueAtTime(isSoft ? 0.25 : 0.4, t0 + duration * 0.75);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  const mix = ctx.createGain();
  oscs.forEach(({ osc, gain }) => {
    const g = ctx.createGain();
    g.gain.value = gain;
    osc.connect(g);
    g.connect(mix);
  });
  mix.connect(resonance);
  resonance.connect(env);
  sendDry(env); sendWet(env, 0.35);

  oscs.forEach(({ osc }) => { osc.start(t0); osc.stop(t0 + duration); });
  vib.start(t0); vib.stop(t0 + duration);
  return duration;
}

function cryHiss(ctx, t0, sendWet, sendDry, p) {
  const { sharp, headSize, cryType } = p;
  const hasRoar = cryType.includes("roar");
  const duration = 1.0 + headSize * 0.08;

  // Main hiss: filtered noise
  const noise = makeNoise(ctx, duration);
  const bp = ctx.createBiquadFilter();
  bp.type = "bandpass";
  bp.frequency.setValueAtTime(2500 + sharp * 200, t0);
  bp.frequency.linearRampToValueAtTime(1800, t0 + duration);
  bp.Q.value = 4;

  // Slight pitched growl under if it's a hiss-roar
  let roarOsc = null, roarEnv = null;
  if (hasRoar) {
    roarOsc = ctx.createOscillator();
    roarOsc.type = "sawtooth";
    roarOsc.frequency.value = 80 + (10 - headSize) * 8;
    roarEnv = ctx.createGain();
    roarEnv.gain.setValueAtTime(0, t0);
    roarEnv.gain.linearRampToValueAtTime(0.2, t0 + 0.2);
    roarEnv.gain.exponentialRampToValueAtTime(0.001, t0 + duration);
    const roarFilter = ctx.createBiquadFilter();
    roarFilter.type = "lowpass";
    roarFilter.frequency.value = 600;
    roarOsc.connect(roarFilter);
    roarFilter.connect(roarEnv);
  }

  // Amplitude tremolo for snake-like quality
  const lfo = ctx.createOscillator();
  lfo.frequency.value = 4;
  const lfoGain = ctx.createGain();
  lfoGain.gain.value = 0.08;
  const trem = ctx.createGain();
  trem.gain.value = 0.22;
  lfo.connect(lfoGain);
  lfoGain.connect(trem.gain);

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(0.22, t0 + 0.05);
  env.gain.setValueAtTime(0.22, t0 + duration * 0.8);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  noise.connect(bp); bp.connect(trem); trem.connect(env);
  if (roarEnv) roarEnv.connect(env);
  sendDry(env); sendWet(env, 0.2);

  noise.start(t0); noise.stop(t0 + duration);
  lfo.start(t0); lfo.stop(t0 + duration);
  if (roarOsc) { roarOsc.start(t0); roarOsc.stop(t0 + duration); }
  return duration;
}

function cryChirps(ctx, t0, sendWet, sendDry, p) {
  const { sharp, speed, headSize, cryType } = p;
  const isMelodic = cryType.includes("melodic");
  const isTrill = cryType.includes("trill");
  const isLoud = cryType.includes("loud");
  const chirpCount = isTrill ? 6 : 3 + Math.floor(speed / 3);
  const chirpDur = 0.08 + sharp * 0.01;
  const gap = isMelodic ? 0.14 : 0.1;
  const baseFreq = 800 + (10 - headSize) * 60;
  const notes = isMelodic ? [1, 1.2, 1.5, 1.2, 1, 0.8] : [1, 1.15, 0.95, 1.1];

  for (let i = 0; i < chirpCount; i++) {
    const start = t0 + i * gap;
    const noteFreq = baseFreq * notes[i % notes.length];

    const osc = ctx.createOscillator();
    osc.type = "triangle";
    osc.frequency.setValueAtTime(noteFreq * 0.7, start);
    osc.frequency.exponentialRampToValueAtTime(noteFreq * 1.2, start + chirpDur * 0.5);
    osc.frequency.exponentialRampToValueAtTime(noteFreq, start + chirpDur);

    const osc2 = ctx.createOscillator();
    osc2.type = "sine";
    osc2.frequency.setValueAtTime(noteFreq * 2, start);
    osc2.frequency.exponentialRampToValueAtTime(noteFreq * 2.4, start + chirpDur);
    const g2 = ctx.createGain();
    g2.gain.value = 0.3;

    const env = ctx.createGain();
    env.gain.setValueAtTime(0, start);
    env.gain.linearRampToValueAtTime(isLoud ? 0.35 : 0.22, start + 0.01);
    env.gain.exponentialRampToValueAtTime(0.001, start + chirpDur);

    osc.connect(env);
    osc2.connect(g2); g2.connect(env);
    sendDry(env); sendWet(env, 0.3);
    osc.start(start); osc.stop(start + chirpDur);
    osc2.start(start); osc2.stop(start + chirpDur);
  }
  return chirpCount * gap + chirpDur;
}

function cryBellow(ctx, t0, sendWet, sendDry, p) {
  const { headSize, tailPow, cryType } = p;
  const isDeep = cryType.includes("deep");
  const isSoft = cryType.includes("soft");
  const baseFreq = isDeep ? 80 + (10 - headSize) * 7 : 130 + (10 - headSize) * 10;
  const duration = 1.3 + tailPow * 0.08;

  const osc1 = ctx.createOscillator();
  osc1.type = "sawtooth";
  osc1.frequency.setValueAtTime(baseFreq * 0.85, t0);
  osc1.frequency.exponentialRampToValueAtTime(baseFreq, t0 + 0.2);
  osc1.frequency.setValueAtTime(baseFreq, t0 + duration * 0.7);
  osc1.frequency.exponentialRampToValueAtTime(baseFreq * 0.7, t0 + duration);

  const osc2 = ctx.createOscillator();
  osc2.type = "triangle";
  osc2.frequency.setValueAtTime(baseFreq * 1.5, t0);
  osc2.frequency.exponentialRampToValueAtTime(baseFreq * 1.2, t0 + duration);

  const formant = ctx.createBiquadFilter();
  formant.type = "bandpass";
  formant.frequency.value = 500;
  formant.Q.value = 3;

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(isSoft ? 0.28 : 0.42, t0 + 0.15);
  env.gain.setValueAtTime(isSoft ? 0.28 : 0.42, t0 + duration * 0.7);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  osc1.connect(formant); osc2.connect(formant);
  formant.connect(env);
  sendDry(env); sendWet(env, 0.25);
  osc1.start(t0); osc1.stop(t0 + duration);
  osc2.start(t0); osc2.stop(t0 + duration);
  return duration;
}

function cryGrunt(ctx, t0, sendWet, sendDry, p) {
  const { headSize, tailPow, armor, cryType } = p;
  const isDeep = cryType.includes("deep");
  const isThud = cryType.includes("thud");
  const baseFreq = isDeep ? 60 + (10 - headSize) * 5 : 100 + (10 - headSize) * 6;
  const duration = 0.5 + tailPow * 0.04;

  // Percussive thud at start if thud-cry
  if (isThud) {
    const thud = ctx.createOscillator();
    thud.type = "sine";
    thud.frequency.setValueAtTime(80, t0);
    thud.frequency.exponentialRampToValueAtTime(30, t0 + 0.1);
    const thudEnv = ctx.createGain();
    thudEnv.gain.setValueAtTime(0.6, t0);
    thudEnv.gain.exponentialRampToValueAtTime(0.001, t0 + 0.12);
    thud.connect(thudEnv);
    sendDry(thudEnv); sendWet(thudEnv, 0.3);
    thud.start(t0); thud.stop(t0 + 0.12);
  }

  const startOffset = isThud ? 0.08 : 0;
  const osc = ctx.createOscillator();
  osc.type = "sawtooth";
  osc.frequency.setValueAtTime(baseFreq * 1.2, t0 + startOffset);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.7, t0 + startOffset + duration);

  const dist = makeDistortion(ctx, 15);
  const lp = ctx.createBiquadFilter();
  lp.type = "lowpass";
  lp.frequency.value = 1200;

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0 + startOffset);
  env.gain.linearRampToValueAtTime(0.38, t0 + startOffset + 0.03);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + startOffset + duration);

  osc.connect(dist); dist.connect(lp); lp.connect(env);
  sendDry(env); sendWet(env, 0.15);
  osc.start(t0 + startOffset); osc.stop(t0 + startOffset + duration);
  return duration + startOffset;
}

function cryWhaleCall(ctx, t0, sendWet, sendDry, p) {
  const { headSize, cryType } = p;
  const isUnderwater = cryType.includes("underwater");
  const duration = isUnderwater ? 1.8 + headSize * 0.1 : 2.5 + headSize * 0.12;

  const osc = ctx.createOscillator();
  osc.type = "sine";
  const baseFreq = 180 + (10 - headSize) * 12;

  // Cetacean-style glissando
  osc.frequency.setValueAtTime(baseFreq * 0.7, t0);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 1.3, t0 + duration * 0.3);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.9, t0 + duration * 0.6);
  osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.5, t0 + duration);

  // Harmonic
  const osc2 = ctx.createOscillator();
  osc2.type = "triangle";
  osc2.frequency.setValueAtTime(baseFreq * 1.5, t0);
  osc2.frequency.exponentialRampToValueAtTime(baseFreq * 2, t0 + duration * 0.3);
  osc2.frequency.exponentialRampToValueAtTime(baseFreq, t0 + duration);
  const g2 = ctx.createGain(); g2.gain.value = 0.2;

  // Vibrato
  const vib = ctx.createOscillator();
  vib.frequency.value = 4.5;
  const vibGain = ctx.createGain();
  vibGain.gain.value = baseFreq * 0.04;
  vib.connect(vibGain);
  vibGain.connect(osc.frequency);

  // Lowpass if underwater (muffled)
  const lp = ctx.createBiquadFilter();
  lp.type = "lowpass";
  lp.frequency.value = isUnderwater ? 900 : 3500;

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(0.35, t0 + 0.3);
  env.gain.setValueAtTime(0.35, t0 + duration * 0.75);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  osc.connect(lp); osc2.connect(g2); g2.connect(lp);
  lp.connect(env);
  sendDry(env); sendWet(env, isUnderwater ? 0.7 : 0.5);

  osc.start(t0); osc.stop(t0 + duration);
  osc2.start(t0); osc2.stop(t0 + duration);
  vib.start(t0); vib.stop(t0 + duration);
  return duration;
}

function cryGrowl(ctx, t0, sendWet, sendDry, p) {
  const { headSize, tailPow, cryType } = p;
  const isWet = cryType.includes("wet");
  const baseFreq = 70 + (10 - headSize) * 7;
  const duration = 0.9 + tailPow * 0.04;

  const osc = ctx.createOscillator();
  osc.type = "sawtooth";
  osc.frequency.setValueAtTime(baseFreq, t0);
  osc.frequency.linearRampToValueAtTime(baseFreq * 0.7, t0 + duration);

  const dist = makeDistortion(ctx, 18);
  const lp = ctx.createBiquadFilter();
  lp.type = "lowpass";
  lp.frequency.value = isWet ? 800 : 1500;

  // Gurgle wobble
  const lfo = ctx.createOscillator();
  lfo.frequency.value = isWet ? 12 : 7;
  const lfoGain = ctx.createGain();
  lfoGain.gain.value = baseFreq * 0.15;
  lfo.connect(lfoGain);
  lfoGain.connect(osc.frequency);

  // Wet bubbles layer
  if (isWet) {
    const noise = makeNoise(ctx, duration);
    const noiseBP = ctx.createBiquadFilter();
    noiseBP.type = "bandpass"; noiseBP.frequency.value = 500; noiseBP.Q.value = 8;
    const noiseEnv = ctx.createGain();
    noiseEnv.gain.setValueAtTime(0.12, t0);
    noiseEnv.gain.exponentialRampToValueAtTime(0.001, t0 + duration);
    noise.connect(noiseBP); noiseBP.connect(noiseEnv);
    const wetOut = noiseEnv;
    sendDry(wetOut); sendWet(wetOut, 0.3);
    noise.start(t0); noise.stop(t0 + duration);
  }

  const env = ctx.createGain();
  env.gain.setValueAtTime(0, t0);
  env.gain.linearRampToValueAtTime(0.35, t0 + 0.08);
  env.gain.exponentialRampToValueAtTime(0.001, t0 + duration);

  osc.connect(dist); dist.connect(lp); lp.connect(env);
  sendDry(env); sendWet(env, 0.25);

  osc.start(t0); osc.stop(t0 + duration);
  lfo.start(t0); lfo.stop(t0 + duration);
  return duration;
}

// ---------- Main dispatcher ----------

// ============ AMBIENT MUSIC ============
const JP_NOTES = [[0.0,587,1.3,0.9],[0.0,330,1.0,0.4],[1.0,440,1.0,0.4],[1.0,294,1.0,0.4],[1.5,587,0.2,0.9],[1.75,554,0.2,0.9],[2.0,587,1.3,0.9],[2.0,330,1.0,0.4],[3.0,440,1.0,0.4],[3.0,294,1.0,0.4],[3.5,587,0.2,0.9],[3.75,554,0.2,0.9],[4.0,587,0.8,0.9],[4.0,330,1.0,0.4],[4.75,659,0.2,0.9],[5.0,659,0.8,0.9],[5.0,330,1.0,0.4],[5.75,784,0.2,0.9],[6.0,784,1.3,0.9],[6.0,330,1.0,0.4],[7.0,220,0.5,0.4],[7.5,740,0.2,0.9],[7.5,277,0.5,0.4],[7.75,587,0.2,0.9],[8.0,659,0.8,0.9],[8.0,330,0.8,0.4],[8.75,554,0.2,0.9],[9.0,440,0.5,0.9],[9.0,220,0.5,0.4],[9.5,740,0.2,0.9],[9.5,294,0.5,0.4],[9.75,587,0.2,0.9],[10.0,659,1.3,0.9],[10.0,330,1.0,0.4],[11.0,220,0.5,0.4],[11.5,880,0.2,0.9],[11.5,294,0.5,0.4],[11.75,587,0.2,0.9],[12.0,784,0.8,0.9],[12.0,247,1.0,0.4],[12.75,740,0.2,0.9],[13.0,740,0.8,0.9],[13.0,277,1.0,0.4],[13.75,659,0.2,0.9],[14.0,659,1.3,0.9],[14.0,247,0.8,0.4],[15.0,220,1.0,0.4],[15.5,587,0.2,0.9],[15.75,554,0.2,0.9],[16.0,587,1.3,0.9],[16.0,294,0.5,0.4],[16.5,370,0.5,0.4],[17.0,440,0.5,0.4],[17.0,294,0.5,0.4],[17.5,587,0.2,0.9],[17.5,330,0.5,0.4],[17.75,554,0.2,0.9],[18.0,587,1.3,0.9],[18.0,294,0.5,0.4],[18.5,392,0.5,0.4],[19.0,440,0.5,0.4],[19.0,294,0.5,0.4],[19.5,587,0.2,0.9],[19.5,330,0.5,0.4],[19.75,554,0.2,0.9],[20.0,587,0.8,0.9],[20.0,294,0.5,0.4],[20.5,370,0.5,0.4],[20.75,659,0.2,0.9],[21.0,659,0.8,0.9],[21.0,294,0.5,0.4],[21.5,220,0.5,0.4],[21.75,784,0.2,0.9],[22.0,784,1.3,0.9],[22.0,247,0.5,0.4],[22.5,330,0.5,0.4],[23.0,440,0.5,0.4],[23.0,220,0.5,0.4],[23.5,740,0.2,0.9],[23.5,294,0.5,0.4],[23.75,587,0.2,0.9],[24.0,659,0.8,0.9],[24.0,330,0.5,0.4],[24.5,220,0.5,0.4],[24.75,554,0.2,0.9],[25.0,440,0.5,0.9],[25.5,740,0.2,0.9],[25.5,220,0.5,0.4],[25.75,587,0.2,0.9],[26.0,659,1.3,0.9],[26.0,330,0.5,0.4],[26.5,220,0.5,0.4],[27.5,880,0.2,0.9],[27.5,220,0.5,0.4],[27.75,587,0.2,0.9],[28.0,784,0.8,0.9],[28.0,247,0.5,0.4],[28.5,392,0.5,0.4],[28.75,740,0.2,0.9],[29.0,740,0.8,0.9],[29.0,220,0.5,0.4],[29.5,370,0.5,0.4],[29.75,659,0.2,0.9],[30.0,659,1.8,0.9],[30.0,196,0.5,0.4],[30.5,330,0.5,0.4],[31.0,277,0.5,0.4],[31.5,440,0.5,0.4],[32.0,370,0.8,0.4],[32.0,247,0.8,0.4],[32.5,622,0.2,0.9],[32.75,554,0.2,0.9],[33.0,622,0.5,0.9],[33.0,247,0.8,0.4],[33.5,494,0.2,0.9],[33.75,659,0.2,0.9],[34.0,659,0.5,0.9],[34.0,247,0.8,0.4],[34.5,740,0.5,0.9],[35.0,740,0.5,0.9],[35.0,247,0.8,0.4],[35.5,554,0.5,0.9],[36.0,370,0.8,0.4],[36.0,247,0.8,0.4],[36.5,622,0.2,0.9],[36.75,554,0.2,0.9],[37.0,622,0.5,0.9],[37.0,247,0.8,0.4],[37.5,494,0.2,0.9],[37.75,740,0.2,0.9],[38.0,784,0.5,0.9],[38.0,262,0.8,0.4],[38.5,880,0.5,0.9],[39.0,659,0.8,0.9],[39.0,220,0.8,0.4],[40.0,370,0.5,0.4],[40.5,740,0.2,0.9],[40.5,220,0.5,0.4],[40.75,659,0.2,0.9],[41.0,740,0.5,0.9],[41.0,330,0.5,0.4],[41.5,587,0.2,0.9],[41.5,220,0.5,0.4],[41.75,880,0.2,0.9],[42.0,880,0.5,0.9],[42.0,277,0.5,0.4],[42.5,740,0.5,0.9],[42.5,220,0.5,0.4],[43.0,1109,0.5,0.9],[43.0,277,0.5,0.4],[43.5,554,0.5,0.9],[43.5,220,0.5,0.4],[44.0,494,1.0,0.2],[44.0,330,0.5,0.4],[44.5,1175,0.2,0.9],[44.5,294,0.5,0.4],[44.75,1109,0.2,0.9],[45.0,1175,0.5,0.9],[45.0,330,0.5,0.4],[45.5,587,0.2,0.9],[45.5,185,0.5,0.4],[45.75,784,0.2,0.9],[46.0,784,0.5,0.9],[46.0,392,0.5,0.4],[46.5,740,0.5,0.9],[46.5,196,0.5,0.4],[47.0,659,0.8,0.9],[47.0,330,0.5,0.4],[47.5,220,0.5,0.4],[48.0,587,1.3,0.4],[48.0,73,0.5,0.2],[48.5,110,0.5,0.2],[49.0,185,0.5,0.2],[49.5,587,0.2,0.4],[49.5,110,0.5,0.2],[49.75,554,0.2,0.4],[50.0,587,1.3,0.4],[50.0,73,0.5,0.2],[50.5,110,0.5,0.2],[51.0,185,0.5,0.2],[51.5,587,0.2,0.4],[51.5,110,0.5,0.2],[51.75,554,0.2,0.4],[52.0,587,0.7,0.5],[52.0,370,0.7,0.5],[52.5,110,0.8,0.2],[52.75,659,0.2,0.5],[52.75,392,0.2,0.5],[53.0,659,0.7,0.5],[53.0,392,0.7,0.5],[53.5,110,0.5,0.2],[53.75,784,0.2,0.5],[53.75,494,0.2,0.5],[54.0,784,1.3,0.5],[54.0,494,1.3,0.5],[54.5,110,0.5,0.2],[55.0,220,0.5,0.2],[55.5,740,0.2,0.4],[55.5,147,0.5,0.2],[55.75,587,0.2,0.4],[56.0,659,0.7,0.5],[56.0,392,0.7,0.5],[56.5,220,0.5,0.2],[56.75,554,0.2,0.4],[57.0,440,0.5,0.4],[57.0,110,0.8,0.2],[57.5,740,0.2,0.5],[57.5,370,0.2,0.5],[57.75,587,0.2,0.4],[58.0,659,1.3,0.5],[58.0,392,1.3,0.5],[58.5,220,0.5,0.2],[59.0,110,0.8,0.2],[59.5,880,0.2,0.4],[59.75,587,0.2,0.4],[60.0,784,0.7,0.5],[60.0,494,0.8,0.5],[60.75,740,0.2,0.4],[61.0,740,0.7,0.5],[61.0,440,0.8,0.5],[61.75,659,0.2,0.4],[62.0,659,1.3,0.5],[62.0,392,1.8,0.5],[62.5,147,0.5,0.2],[63.0,247,0.5,0.2],[63.5,784,0.2,0.4],[63.5,330,0.5,0.2],[63.75,659,0.2,0.4],[64.0,1175,0.8,0.5],[64.75,1109,0.2,0.5],[65.0,1109,0.8,0.5],[65.75,988,0.2,0.5],[66.0,988,0.8,0.5],[66.5,220,0.5,0.2],[67.0,1109,0.5,0.5],[67.0,659,0.5,0.5],[67.5,587,0.2,0.4],[67.5,55,0.5,0.2],[67.75,554,0.2,0.4],[68.0,587,0.5,0.5],[68.0,370,0.5,0.5],[68.5,440,0.5,0.5],[69.0,392,0.5,0.5],[69.5,587,0.2,0.4],[69.75,554,0.2,0.4],[70.0,587,0.5,0.5],[70.0,370,0.5,0.5],[70.5,440,0.5,0.5],[71.0,392,0.5,0.5],[71.5,587,0.2,0.4],[71.75,554,0.2,0.4],[72.0,554,0.2,0.5],[72.0,370,0.8,0.5],[72.25,587,0.7,0.4],[73.0,440,0.5,0.5],[73.0,294,0.5,0.5],[73.5,294,0.5,0.5],[74.0,523,1.3,0.5],[75.0,440,0.8,0.5],[75.0,110,0.8,0.5],[75.5,587,0.2,0.4],[75.75,554,0.2,0.4],[76.0,587,0.5,0.5],[76.0,370,0.5,0.5],[76.5,440,0.5,0.5],[77.0,392,0.5,0.5],[77.5,587,0.2,0.4],[77.75,554,0.2,0.4],[78.0,587,0.5,0.5],[78.0,370,0.5,0.5],[78.5,440,0.5,0.5],[79.0,392,0.5,0.5],[79.5,587,0.2,0.4],[79.75,554,0.2,0.4],[80.0,554,0.2,0.5],[80.0,370,0.8,0.5],[80.25,587,0.7,0.4],[81.0,440,0.5,0.5],[81.0,294,0.5,0.5],[81.5,294,0.5,0.5],[82.0,587,0.8,0.5],[83.0,554,0.5,0.5],[83.5,1175,0.2,0.4],[83.75,1109,0.2,0.4],[84.0,1175,0.5,0.7],[84.0,587,0.5,0.7],[84.5,880,0.5,0.7],[84.5,440,0.5,0.7],[85.0,784,0.5,0.7],[85.0,392,0.5,0.7],[85.5,1175,0.2,0.7],[85.5,587,0.2,0.7],[85.75,1109,0.2,0.7],[85.75,554,0.2,0.7],[86.0,1175,0.5,0.7],[86.0,587,0.5,0.7],[86.5,880,0.5,0.7],[86.5,440,0.5,0.7],[87.0,784,0.5,0.7],[87.0,392,0.5,0.7],[87.5,1175,0.2,0.7],[87.5,587,0.2,0.7],[87.75,1109,0.2,0.7],[87.75,554,0.2,0.7],[88.0,1109,0.2,0.7],[88.0,554,0.2,0.7],[88.25,1175,0.7,0.7],[88.25,587,0.7,0.7],[89.0,880,0.5,0.7],[89.0,440,0.5,0.7],[89.5,587,0.5,0.7],[89.5,294,0.5,0.7],[90.0,1046,1.3,0.7],[90.0,523,1.3,0.7],[91.0,220,0.8,0.5],[91.0,110,0.8,0.5],[91.5,1175,0.2,0.7],[91.5,587,0.2,0.7],[91.75,1109,0.2,0.7],[91.75,554,0.2,0.7],[92.0,1175,0.5,0.7],[92.0,587,0.5,0.7],[92.5,880,0.5,0.7],[92.5,440,0.5,0.7],[93.0,784,0.5,0.7],[93.0,392,0.5,0.7],[93.5,1175,0.2,0.7],[93.5,587,0.2,0.7],[93.75,1109,0.2,0.7],[93.75,554,0.2,0.7],[94.0,1175,0.5,0.7],[94.0,587,0.5,0.7],[94.5,880,0.5,0.7],[94.5,440,0.5,0.7],[95.0,784,0.5,0.7],[95.0,392,0.5,0.7],[95.5,1175,0.2,0.7],[95.5,587,0.2,0.7],[95.75,1109,0.2,0.7],[95.75,554,0.2,0.7],[96.0,1109,0.2,0.7],[96.0,554,0.2,0.7],[96.25,1175,0.7,0.7],[96.25,587,0.7,0.7],[97.0,880,0.5,0.7],[97.0,440,0.5,0.7],[97.5,587,0.5,0.7],[97.5,294,0.5,0.7],[98.0,1175,0.8,0.7],[98.0,587,0.8,0.7],[98.5,147,0.5,0.5],[98.5,73,0.5,0.5],[99.0,1109,0.8,0.7],[99.0,554,0.8,0.7],[99.5,220,0.5,0.5],[99.5,110,0.5,0.5],[100.0,1175,3.8,0.7],[100.0,294,0.5,0.9],[100.5,277,0.2,0.5],[100.75,294,0.2,0.5],[101.0,294,0.5,0.5],[101.5,277,0.2,0.5],[101.75,294,0.2,0.5],[102.0,294,0.5,0.5],[102.5,277,0.2,0.5],[102.75,294,0.2,0.5],[103.0,294,0.5,0.5],[103.0,147,0.5,0.6],[103.5,147,0.5,0.5],[104.0,147,1.8,0.4],[104.5,247,0.2,0.2],[104.75,220,0.2,0.2],[105.0,247,0.5,0.2],[105.5,196,0.2,0.2],[105.75,262,0.2,0.2],[106.0,262,0.5,0.4],[106.0,165,0.8,0.4],[106.5,294,0.5,0.2],[107.0,294,0.5,0.4],[107.0,185,0.8,0.4],[107.5,220,0.5,0.2],[108.0,147,1.8,0.4],[108.5,247,0.2,0.2],[108.75,220,0.2,0.2],[109.0,247,0.5,0.2],[109.5,196,0.2,0.2],[109.75,294,0.2,0.2],[110.0,311,0.5,0.5],[110.0,208,0.5,0.5],[110.5,349,0.5,0.2],[111.0,262,0.8,0.5],[112.0,116,0.2,0.4],[112.25,175,0.2,0.4],[112.5,587,0.2,0.4],[112.5,294,0.2,0.4],[112.75,523,0.2,0.4],[112.75,175,0.2,0.4],[113.0,587,0.5,0.4],[113.0,116,0.2,0.4],[113.25,175,0.2,0.4],[113.5,466,0.2,0.4],[113.5,294,0.2,0.4],[113.75,698,0.2,0.4],[113.75,175,0.2,0.4],[114.0,698,0.5,0.4],[114.0,147,0.2,0.4],[114.25,220,0.2,0.4],[114.5,587,0.5,0.4],[114.5,349,0.2,0.4],[114.75,220,0.2,0.4],[115.0,880,0.5,0.4],[115.0,147,0.2,0.4],[115.25,220,0.2,0.4],[115.5,440,0.5,0.4],[115.5,294,0.2,0.4],[115.75,349,0.2,0.4],[116.0,466,0.5,0.5],[116.5,932,0.2,0.2],[116.75,880,0.2,0.2],[117.0,932,0.5,0.2],[117.5,466,0.2,0.2],[117.75,622,0.2,0.2],[118.0,622,0.5,0.5],[118.0,392,0.5,0.5],[118.5,698,0.5,0.2],[119.0,523,0.8,0.5],[120.0,587,1.4,0.2],[120.0,73,0.3,0.4],[120.25,110,0.3,0.4],[120.55,185,0.3,0.4],[120.8,220,0.3,0.4],[121.1,294,0.3,0.4],[121.35,370,0.3,0.4],[121.65,587,0.3,0.2],[121.9,554,0.3,0.2],[122.2,587,1.4,0.2],[122.2,73,0.3,0.4],[122.45,110,0.3,0.4],[122.75,185,0.3,0.4],[123.0,220,0.3,0.4],[123.25,294,0.3,0.4],[123.55,370,0.3,0.4],[123.8,587,0.3,0.2],[124.1,554,0.3,0.2],[124.35,587,0.8,0.2],[124.35,73,0.3,0.4],[124.65,110,0.3,0.4],[124.9,185,0.3,0.4],[125.2,659,0.3,0.2],[125.2,220,0.3,0.4],[125.45,659,0.8,0.2],[125.45,147,0.3,0.4],[125.75,196,0.3,0.4],[126.0,220,0.3,0.4],[126.25,784,0.3,0.2],[126.25,294,0.3,0.4],[126.55,784,1.6,0.2],[126.55,73,0.3,0.4],[126.8,98,0.3,0.4],[127.1,147,0.3,0.4],[127.35,165,0.3,0.4],[127.65,220,0.3,0.4],[127.9,294,0.8,0.4],[128.2,740,0.3,0.2],[128.45,587,0.3,0.2],[128.75,659,0.8,0.4],[128.75,277,1.9,0.4],[129.55,554,0.3,0.2],[129.8,440,0.6,0.2],[130.35,740,0.3,0.2],[130.65,587,0.3,0.2],[130.9,659,1.4,0.4],[130.9,294,1.4,0.4],[132.55,880,0.3,0.4],[132.55,277,0.5,0.4],[132.8,587,0.3,0.2],[133.1,784,0.8,0.4],[133.1,247,0.9,0.4],[133.9,740,0.3,0.2],[134.2,740,0.8,0.4],[134.2,277,0.9,0.4],[135.0,659,0.3,0.2],[135.25,659,1.4,0.4],[135.25,294,0.9,0.4],[136.35,330,0.9,0.4],[136.35,220,0.9,0.4],[136.9,1175,0.3,0.1],[136.9,587,0.3,0.9],[137.2,1109,0.3,0.1],[137.2,554,0.3,0.9],[137.45,1175,0.5,0.1],[137.45,73,0.3,0.2],[137.75,110,0.3,0.2],[138.0,880,0.5,0.1],[138.0,185,0.3,0.2],[138.25,220,0.3,0.2],[138.55,784,0.5,0.1],[138.55,196,0.9,0.2],[139.1,1175,0.3,0.1],[139.35,1109,0.3,0.1],[139.65,1175,0.5,0.1],[139.65,147,0.3,0.2],[139.9,220,0.3,0.2],[140.2,880,0.5,0.1],[140.2,294,0.3,0.2],[140.45,440,0.3,0.2],[140.75,784,0.5,0.1],[140.75,392,0.9,0.2],[141.25,1175,0.3,0.1],[141.55,1109,0.3,0.1],[141.8,1109,0.3,0.1],[141.8,294,0.3,0.2],[142.1,1175,0.8,0.1],[142.1,370,0.3,0.2],[142.35,440,0.3,0.2],[142.65,587,0.3,0.2],[142.9,880,0.5,0.1],[143.45,587,0.5,0.1],[144.0,1046,1.4,0.9],[144.0,220,0.9,0.2],[145.1,440,0.9,0.2],[145.1,220,0.9,0.2],[145.65,1175,0.3,0.1],[145.9,1109,0.3,0.1],[146.2,1175,0.5,0.1],[146.2,370,0.9,0.2],[146.75,880,0.5,0.1],[147.25,784,0.5,0.1],[147.25,330,0.9,0.2],[147.8,1175,0.3,0.1],[148.1,1109,0.3,0.1],[148.35,1175,0.5,0.9],[148.35,220,0.9,0.2],[148.9,880,0.5,0.1],[149.45,784,0.5,0.9],[149.45,196,0.9,0.2],[150.0,1175,0.3,0.1],[150.25,1109,0.3,0.1],[150.55,1109,0.3,0.9],[150.55,220,1.9,0.2],[150.8,1175,0.8,0.1],[151.65,880,0.5,0.1],[152.2,587,0.5,0.1],[152.2,392,0.1,0.6],[152.3,587,0.1,0.6],[152.45,784,0.1,0.6],[152.6,1175,0.1,0.6],[152.75,1175,1.9,0.9],[152.75,494,1.9,0.2],[154.35,554,0.1,0.6],[154.5,659,0.1,0.6],[154.65,880,0.1,0.6],[154.75,1109,0.1,0.6],[154.9,1109,1.9,0.9],[154.9,554,1.9,0.9],[157.1,1175,4.0,0.1],[157.1,73,0.5,0.6],[157.65,110,0.5,0.6],[158.2,147,0.5,0.6],[158.75,185,0.5,0.6],[159.25,220,0.5,0.6],[159.8,294,0.5,0.6],[160.35,370,0.5,0.6],[160.9,440,0.5,0.6],[161.45,1175,4.0,0.2],[161.45,587,4.0,0.6],[165.8,233,1.0,0.8],[165.8,116,0.6,0.9],[166.55,116,0.6,1.0],[166.95,233,0.2,0.8],[166.95,147,0.2,0.8],[167.15,233,0.2,0.8],[167.15,147,0.2,0.8],[167.3,233,1.0,0.8],[167.3,147,1.0,0.8],[167.7,116,0.2,0.9],[167.9,116,0.2,0.9],[168.05,116,0.4,0.9],[168.45,233,0.1,0.8],[168.45,87,0.4,0.9],[168.8,233,1.0,0.8],[168.8,116,0.6,0.9],[169.55,116,0.6,1.0],[169.95,233,0.2,0.8],[169.95,147,0.2,0.8],[170.15,233,0.2,0.8],[170.15,147,0.2,0.8],[170.3,233,1.0,0.8],[170.3,147,1.0,0.8],[170.7,116,0.2,0.9],[170.9,116,0.2,0.9],[171.05,116,0.4,0.9],[171.45,233,0.1,0.8],[171.45,87,0.4,0.9],[171.8,233,2.8,0.6],[171.8,116,1.0,0.9],[172.2,466,0.1,0.6],[172.2,233,0.1,0.9],[172.55,698,0.8,0.9],[172.55,349,0.8,0.9],[172.95,116,0.2,0.9],[173.15,116,0.2,0.9],[173.3,523,0.1,0.6],[173.3,116,0.6,0.9],[173.7,784,0.8,0.9],[173.7,392,0.8,0.9],[174.05,116,0.4,0.9],[174.45,784,0.1,0.6],[174.45,116,0.4,0.9],[174.65,880,0.1,0.6],[174.65,440,0.1,0.9],[174.8,932,0.6,0.9],[174.8,466,0.6,0.9],[175.4,932,0.2,0.6],[175.4,466,0.2,0.9],[175.55,880,0.4,0.9],[175.55,440,0.4,0.9],[175.95,698,0.4,0.6],[175.95,349,0.4,0.9],[176.3,784,1.3,0.9],[176.3,392,1.3,0.9],[177.8,587,0.6,0.6],[177.8,196,0.6,0.9],[178.2,932,0.4,0.6],[178.2,466,0.4,0.9],[178.55,880,0.4,0.6],[178.55,175,0.6,0.9],[178.95,698,0.4,0.6],[178.95,349,0.4,0.9],[179.3,740,0.6,0.6],[179.3,147,0.6,0.9],[179.9,587,0.2,0.6],[179.9,294,0.2,0.9],[180.05,784,0.2,0.6],[180.05,196,0.6,0.9],[180.25,880,0.2,0.6],[180.25,440,0.2,0.9],[180.45,932,0.4,0.6],[180.45,466,0.4,0.9],[180.8,466,1.0,0.9],[180.8,233,1.0,0.9],[181.95,523,0.2,0.6],[181.95,78,0.4,0.9],[182.15,587,0.2,0.6],[182.15,294,0.2,0.9],[182.3,587,0.6,0.6],[182.3,110,0.6,0.9],[182.9,659,0.1,0.6],[182.9,330,0.1,0.9],[182.95,587,0.1,0.6],[182.95,294,0.1,0.9],[183.05,554,0.6,0.6],[183.05,55,0.6,0.9],[183.8,233,2.8,0.6],[183.8,116,1.0,0.9],[184.2,466,0.1,0.6],[184.2,233,0.1,0.9],[184.55,698,0.8,0.9],[184.55,349,0.8,0.9],[184.95,116,0.2,0.9],[185.15,116,0.2,0.9],[185.3,523,0.1,0.6],[185.3,116,0.6,0.9],[185.7,784,0.8,0.9],[185.7,392,0.8,0.9],[185.9,116,0.2,0.9],[186.05,116,0.4,0.9],[186.45,784,0.2,0.6],[186.45,116,0.4,0.9],[186.65,880,0.2,0.6],[186.65,440,0.2,0.9],[186.8,932,0.6,0.9],[186.8,466,0.6,0.9],[187.4,932,0.2,0.6],[187.4,466,0.2,0.9],[187.55,880,0.4,0.9],[187.55,440,0.4,0.9],[187.95,698,0.4,0.6],[187.95,349,0.4,0.9],[188.3,784,1.3,0.9],[188.3,392,1.3,0.9],[189.8,587,0.6,0.6],[189.8,196,0.6,0.9],[190.2,932,0.4,0.6],[190.2,466,0.4,0.9],[190.55,880,0.4,0.6],[190.55,175,0.6,0.9],[190.95,698,0.4,0.6],[190.95,349,0.4,0.9],[191.3,740,0.6,0.6],[191.3,110,0.6,0.9],[191.9,587,0.2,0.6],[191.9,294,0.2,0.9],[192.05,784,0.2,0.6],[192.05,131,0.6,0.9],[192.25,880,0.2,0.6],[192.25,440,0.2,0.9],[192.45,932,0.4,0.6],[192.45,466,0.4,0.9],[192.8,587,0.4,0.6],[192.8,294,0.4,0.9],[193.2,440,0.2,0.9],[193.2,196,0.2,0.9],[193.4,784,0.1,0.6],[193.4,392,0.1,0.9],[193.55,784,0.4,0.6],[193.55,392,0.4,0.9],[193.95,587,0.2,0.9],[193.95,294,0.2,0.9],[194.15,880,0.1,0.6],[194.15,440,0.1,0.9],[194.3,880,1.3,0.9],[194.3,440,1.3,0.9],[194.7,147,0.6,0.9],[195.45,147,0.4,0.9],[195.8,466,0.4,0.6],[195.8,294,0.4,0.6],[196.2,932,0.4,0.6],[196.2,294,0.6,0.6],[196.55,1046,0.4,0.6],[196.95,932,0.2,0.6],[196.95,294,0.4,0.6],[197.15,880,0.2,0.6],[197.3,932,0.4,0.6],[197.3,349,0.4,0.6],[197.7,880,0.4,0.6],[197.7,349,0.6,0.6],[198.05,784,0.6,0.6],[198.45,466,0.4,0.6],[198.45,294,0.4,0.6],[198.8,466,0.4,0.6],[198.8,262,0.4,0.6],[199.2,784,0.4,0.6],[199.2,349,0.6,0.6],[199.55,1046,0.4,0.6],[199.95,523,0.2,0.6],[199.95,349,0.4,0.6],[200.15,932,0.2,0.6],[200.3,932,0.8,0.6],[200.3,262,0.4,0.6],[200.7,262,0.4,0.6],[201.05,880,0.6,0.6],[201.05,262,0.6,0.6],[201.8,440,0.4,0.6],[201.8,294,0.4,0.6],[202.2,1175,0.4,0.6],[202.2,330,0.6,0.6],[202.55,1175,0.4,0.6],[202.95,587,0.2,0.6],[202.95,330,0.4,0.6],[203.15,1046,0.2,0.6],[203.3,988,0.8,0.6],[203.3,392,0.4,0.6],[203.7,440,0.4,0.6],[203.7,294,0.4,0.6],[204.05,880,0.6,0.6],[204.05,330,0.2,0.6],[204.25,440,0.2,0.6],[204.25,294,0.2,0.6],[204.45,440,0.4,0.6],[204.45,294,0.4,0.6],[204.8,220,1.3,0.4],[205.2,880,0.4,0.6],[205.55,880,0.4,0.6],[205.95,440,0.2,0.6],[206.15,784,0.2,0.6],[206.3,740,0.8,0.6],[207.05,659,0.6,0.6],[208.2,1175,0.4,0.6],[208.55,1175,0.4,0.6],[208.95,587,0.2,0.6],[209.15,1046,0.2,0.6],[209.3,988,0.8,0.6],[209.3,147,1.3,0.4],[210.05,880,0.6,0.6],[210.8,349,1.3,0.4],[210.8,233,1.3,0.4],[211.2,554,0.4,0.6],[211.55,622,0.4,0.6],[211.95,554,0.2,0.6],[212.15,523,0.2,0.6],[212.3,554,0.4,0.6],[212.3,233,1.3,0.4],[212.7,523,0.4,0.6],[213.05,466,0.6,0.6],[213.8,311,1.3,0.4],[213.8,208,1.3,0.4],[214.2,466,0.4,0.6],[214.55,622,0.4,0.6],[214.95,311,0.2,0.6],[215.15,554,0.2,0.6],[215.3,554,0.8,0.6],[215.3,311,0.8,0.6],[216.05,523,0.6,0.6],[217.2,523,0.4,0.6],[217.55,698,0.4,0.6],[217.95,523,0.2,0.6],[218.15,932,0.2,0.6],[218.3,932,0.4,0.6],[218.7,880,0.4,0.6],[219.05,784,0.6,0.6],[220.2,1046,0.4,0.6],[220.55,1046,0.4,0.6],[220.95,523,0.2,0.6],[221.15,932,0.2,0.6],[221.3,880,0.6,0.9],[221.3,466,0.6,0.9],[222.05,784,0.4,0.9],[222.05,392,0.4,0.9],[222.45,698,0.1,0.9],[222.45,349,0.1,0.9],[222.65,784,0.1,0.9],[222.65,392,0.1,0.9],[222.8,880,0.2,0.9],[222.8,440,0.2,0.9],[223.0,784,0.2,0.6],[223.0,392,0.2,0.9],[223.2,740,0.1,0.6],[223.2,370,0.1,0.9],[223.4,659,0.1,0.6],[223.4,330,0.1,0.9],[223.55,587,0.1,0.6],[223.55,294,0.1,0.9],[223.95,440,0.1,0.9],[223.95,196,0.1,0.9],[224.5,587,0.2,0.6],[224.5,294,0.2,0.9],[224.7,554,0.1,0.6],[224.7,277,0.1,0.9],[224.9,494,0.1,0.6],[224.9,247,0.1,0.9],[225.05,440,0.2,0.6],[225.05,220,0.2,0.9],[225.25,784,0.1,0.6],[225.25,392,0.1,0.9],[225.45,740,0.1,0.6],[225.45,370,0.1,0.9],[225.65,659,0.1,0.6],[225.65,330,0.1,0.9],[225.8,587,0.1,0.6],[225.8,294,0.1,0.9],[226.0,440,0.1,0.6],[226.0,220,0.1,0.9],[226.2,587,0.1,0.6],[226.2,294,0.1,0.9],[226.4,392,0.1,0.6],[226.4,196,0.1,0.9],[226.55,440,0.1,0.6],[226.55,220,0.1,0.9],[226.95,587,0.1,0.9],[226.95,294,0.1,0.9],[227.3,587,0.2,0.6],[227.3,294,0.2,0.9],[227.5,659,0.2,0.6],[227.5,330,0.2,0.9],[227.7,740,0.2,0.9],[227.7,294,0.2,0.9],[227.9,784,0.2,0.9],[227.9,330,0.2,0.9],[228.05,880,0.2,0.9],[228.05,370,0.2,0.9],[228.25,988,0.2,0.9],[228.25,392,0.2,0.9],[228.45,880,0.4,0.6],[228.45,440,0.4,0.9],[228.8,233,2.8,0.7],[228.8,116,1.0,0.9],[229.2,466,0.1,0.9],[229.2,233,0.1,0.9],[229.55,698,0.8,0.9],[229.55,349,0.8,0.9],[229.95,116,0.2,0.9],[230.15,116,0.2,0.9],[230.3,523,0.1,0.9],[230.3,116,0.6,0.9],[230.7,784,0.8,0.9],[230.7,392,0.8,0.9],[231.05,116,0.4,0.9],[231.45,784,0.2,0.9],[231.45,116,0.4,0.9],[231.65,880,0.2,0.9],[231.65,440,0.2,0.9],[231.8,932,0.6,0.9],[231.8,466,0.6,0.9],[232.4,932,0.2,0.9],[232.4,466,0.2,0.9],[232.55,880,0.4,0.9],[232.55,440,0.4,0.9],[232.95,698,0.4,0.9],[232.95,349,0.4,0.9],[233.3,784,1.3,0.9],[233.3,392,1.3,0.9],[234.8,587,0.6,0.7],[234.8,196,0.6,0.9],[235.2,932,0.4,0.9],[235.2,466,0.4,0.9],[235.55,880,0.4,0.9],[235.55,175,0.6,0.9],[235.95,698,0.4,0.9],[235.95,349,0.4,0.9],[236.3,740,0.6,0.9],[236.3,147,0.6,0.9],[236.9,587,0.2,0.9],[236.9,294,0.2,0.9],[237.05,784,0.2,0.9],[237.05,196,0.6,0.9],[237.25,880,0.2,0.9],[237.25,440,0.2,0.9],[237.45,932,0.4,0.9],[237.45,466,0.4,0.9],[237.8,466,1.0,0.9],[237.8,233,1.0,0.9],[238.2,156,0.1,0.9],[238.55,78,0.6,1.0],[238.95,622,0.2,0.6],[238.95,311,0.2,0.9],[239.15,784,0.2,0.6],[239.15,392,0.2,0.9],[239.3,880,1.3,0.9],[239.3,440,1.3,0.9],[239.7,110,0.1,0.9],[240.05,466,0.6,0.6],[240.05,55,0.6,1.0],[240.8,175,0.4,0.6],[240.8,104,1.0,0.9],[241.2,277,0.1,0.6],[241.55,415,0.6,0.6],[241.55,277,0.6,0.6],[241.95,139,0.4,0.9],[242.3,311,0.4,0.6],[242.3,139,1.0,0.9],[242.7,466,0.6,0.6],[242.7,311,0.6,0.6],[243.45,466,0.2,0.6],[243.45,139,0.4,0.9],[243.65,523,0.2,0.6],[243.8,554,0.6,0.6],[243.8,233,0.6,0.9],[244.4,554,0.2,0.6],[244.55,523,0.4,0.6],[244.55,208,0.6,0.9],[244.95,415,0.4,0.6],[245.3,466,1.3,0.6],[245.3,185,0.6,0.9],[246.05,185,0.4,0.9],[246.45,185,0.2,0.9],[246.65,185,0.2,0.9],[246.8,349,0.6,0.7],[246.8,233,0.6,0.9],[247.2,554,0.4,0.6],[247.55,523,0.4,0.6],[247.55,208,0.6,0.9],[247.95,415,0.4,0.6],[248.3,440,0.6,0.6],[248.3,175,0.6,0.9],[248.9,349,0.2,0.6],[249.05,466,0.2,0.6],[249.05,233,0.4,0.9],[249.25,523,0.2,0.6],[249.45,554,0.1,0.6],[249.45,233,0.4,0.9],[249.8,659,1.3,0.7],[249.8,330,1.3,0.7],[250.2,247,0.1,0.9],[250.4,185,0.1,0.9],[250.55,220,0.1,0.9],[250.75,165,0.1,0.9],[250.95,110,0.1,0.9],[251.3,659,0.2,0.7],[251.3,330,0.2,0.7],[251.5,740,1.0,0.7],[251.5,370,1.0,0.7],[251.7,185,0.1,0.9],[252.05,247,0.8,1.0],[252.65,740,0.2,0.7],[252.65,370,0.2,0.7],[252.8,740,0.2,0.7],[252.8,370,0.2,0.7],[253.0,880,0.6,0.7],[253.0,165,0.1,0.9],[253.2,147,0.1,0.9],[253.4,220,0.1,0.9],[253.55,880,0.6,0.7],[253.55,294,0.6,0.9],[254.15,294,0.2,0.9],[254.3,880,1.3,0.7],[254.3,262,0.4,0.9],[254.7,392,0.6,0.9],[255.45,392,0.2,0.9],[255.65,440,0.2,0.9],[255.8,466,2.2,0.7],[255.8,311,2.2,0.7],[256.2,1244,0.4,0.7],[256.2,622,0.4,0.7],[256.55,1397,0.4,0.7],[256.55,78,2.1,0.6],[256.95,1244,0.2,0.7],[256.95,622,0.2,0.7],[257.15,1175,0.2,0.7],[257.15,587,0.2,0.7],[257.3,1244,0.4,0.7],[257.3,622,0.4,0.7],[257.7,1175,0.4,0.7],[257.7,587,0.4,0.7],[258.05,1046,0.6,0.7],[258.05,392,0.4,0.7],[258.45,466,0.4,0.7],[258.45,311,0.4,0.7],[258.8,466,1.0,0.7],[258.8,311,1.0,0.7],[259.2,1244,0.4,0.7],[259.2,622,0.4,0.7],[259.55,1397,0.4,0.7],[259.55,78,0.6,0.6],[259.95,1244,0.2,0.7],[259.95,415,0.4,0.7],[260.15,1175,0.2,0.7],[260.15,587,0.2,0.7],[260.3,1244,0.4,0.7],[260.3,415,1.3,0.7],[260.7,932,0.4,0.7],[260.7,116,0.2,0.6],[260.9,208,0.1,0.6],[260.9,104,0.2,0.6],[261.05,1046,0.6,0.7],[261.05,78,0.1,0.6],[261.45,104,0.1,0.6],[261.45,52,0.1,0.6],[261.8,131,1.0,0.6],[262.2,262,0.1,0.9],[262.2,131,0.1,0.9],[262.55,392,0.6,0.9],[262.55,196,0.6,0.9],[262.95,131,0.2,0.6],[263.15,131,0.2,0.6],[263.3,294,0.1,0.9],[263.3,147,0.1,0.9],[263.7,440,0.6,0.9],[263.7,220,0.6,0.9],[264.45,440,0.2,0.7],[264.45,220,0.2,0.9],[264.65,494,0.2,0.7],[264.65,247,0.2,0.9],[264.8,523,0.6,0.9],[264.8,262,0.6,0.9],[265.2,110,0.4,0.6],[265.4,523,0.2,0.7],[265.4,262,0.2,0.9],[265.55,494,0.4,0.9],[265.55,247,0.4,0.9],[265.95,392,0.4,0.7],[265.95,196,0.4,0.9],[266.3,392,1.3,0.9],[266.3,196,1.3,0.9],[266.7,87,0.2,0.6],[266.9,87,0.2,0.6],[267.05,87,0.2,0.6],[267.25,87,0.2,0.6],[267.45,87,0.4,0.6],[267.8,87,0.4,1.0],[268.2,698,0.4,0.6],[268.55,659,0.4,0.6],[268.95,523,0.4,0.6],[269.3,554,0.6,0.6],[269.9,440,0.2,0.6],[270.05,587,0.2,0.6],[270.25,659,0.2,0.6],[270.45,698,0.1,0.6],[270.8,208,0.4,0.6],[270.8,139,0.4,0.6],[271.0,370,0.2,0.6],[271.2,349,0.1,0.6],[271.4,311,0.2,0.6],[271.55,277,0.2,0.6],[271.75,208,0.6,0.6],[271.95,104,0.4,0.6],[272.3,208,0.4,0.6],[272.3,139,0.4,0.6],[272.5,554,0.2,0.6],[272.7,523,0.1,0.6],[272.9,466,0.1,0.6],[273.05,415,0.2,0.6],[273.25,740,0.1,0.6],[273.45,698,0.1,0.6],[273.65,622,0.1,0.6],[273.8,262,0.4,0.6],[273.8,175,0.4,0.6],[274.0,523,0.1,0.6],[274.2,698,0.1,0.6],[274.4,523,0.1,0.6],[274.55,523,0.4,0.8],[274.95,698,0.4,0.8],[275.3,131,0.4,0.6],[275.5,523,0.1,0.6],[275.7,698,0.1,0.6],[275.9,523,0.1,0.6],[276.05,698,0.1,0.8],[276.45,262,0.4,0.6],[276.45,175,0.4,0.6],[276.8,196,0.6,0.6],[277.0,523,0.2,0.6],[277.2,494,0.1,0.6],[277.4,440,0.1,0.6],[277.55,494,0.2,0.6],[277.75,523,0.2,0.6],[277.95,587,0.2,0.6],[278.15,659,0.2,0.7],[278.3,698,0.2,0.7],[278.5,659,0.1,0.7],[278.7,587,0.1,0.7],[278.9,659,0.1,0.7],[279.05,698,0.2,0.9],[279.25,784,0.2,0.9],[279.45,880,0.2,0.9],[279.65,988,0.2,0.9],[279.8,1046,4.0,0.9],[279.8,659,4.0,0.9],[280.0,349,0.2,0.6],[280.2,330,0.2,0.6],[280.4,294,0.2,0.6],[280.55,262,0.4,0.6],[280.95,392,0.4,0.6],[281.5,349,0.2,0.6],[281.7,330,0.2,0.6],[281.9,294,0.2,0.6],[282.05,262,0.4,0.6],[283.0,349,0.2,0.6],[283.2,330,0.2,0.6],[283.4,294,0.2,0.6],[283.55,262,0.4,0.6],[283.95,392,0.2,0.6],[284.15,392,0.2,0.6],[284.3,1046,1.3,0.9],[284.3,698,1.3,0.9],[284.7,349,0.2,0.6],[284.9,330,0.2,0.6],[285.05,294,0.2,0.6],[285.25,262,0.2,0.6],[285.45,247,0.2,0.6],[285.65,220,0.2,0.6],[285.8,196,0.4,0.6],[286.2,1046,0.4,1.0],[286.2,523,0.4,1.0],[286.55,392,0.6,0.9],[287.3,294,0.4,0.9],[287.7,440,0.6,0.9],[288.45,440,0.2,0.9],[288.65,494,0.2,0.9],[288.8,523,1.3,0.9],[289.0,494,0.2,0.2],[289.0,87,0.2,0.2],[289.2,466,0.2,0.2],[289.2,131,0.2,0.2],[289.4,440,0.2,0.2],[289.4,98,0.2,0.2],[289.55,415,0.2,0.2],[289.55,139,0.2,0.2],[289.75,392,0.2,0.2],[289.75,104,0.2,0.2],[289.95,370,0.2,0.2],[289.95,156,0.2,0.2],[290.15,349,0.2,0.2],[290.15,116,0.2,0.2],[290.3,262,0.2,0.9],[290.3,131,0.2,0.9],[290.5,523,0.2,0.9],[290.5,262,0.2,0.9],[290.7,659,0.2,0.9],[290.7,330,0.2,0.9],[290.9,740,0.2,0.9],[290.9,370,0.2,0.9],[291.05,1046,0.4,1.0],[291.05,523,0.4,1.0]];

let musicCtx = null;
let musicNodes = [];
let musicPlaying = false;
let musicTimer = null;

function startMusic(mood) {
  stopMusic();
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return;
  try {
    musicCtx = new AC();
    if (musicCtx.state === "suspended") musicCtx.resume();
    const master = musicCtx.createGain();
    master.gain.value = 0.18;
    master.connect(musicCtx.destination);
    musicPlaying = true;

    if (mood === "battle") {
      // Tense battle: pulsing Dm chord
      const now = musicCtx.currentTime;
      [73.4, 87.3, 110, 146.8].forEach((freq, i) => {
        const osc = musicCtx.createOscillator();
        const gain = musicCtx.createGain();
        osc.type = i < 2 ? "sawtooth" : "triangle";
        osc.frequency.value = freq;
        gain.gain.value = 0.15;
        const filt = musicCtx.createBiquadFilter();
        filt.type = "lowpass"; filt.frequency.value = 300 + i * 80;
        osc.connect(filt).connect(gain).connect(master);
        osc.start(now); musicNodes.push(osc);
        const pulse = () => {
          if (!musicPlaying) return;
          gain.gain.setValueAtTime(0.25, musicCtx.currentTime);
          gain.gain.setTargetAtTime(0.05, musicCtx.currentTime + 0.2, 0.5);
          setTimeout(pulse, 1800 + i * 200);
        };
        setTimeout(pulse, 1000);
      });
    } else {
      // MIDI theme playback — robust scheduler
      const LOOK_AHEAD = 4.0; // schedule 4 seconds ahead
      const SCHEDULE_INTERVAL = 1500; // check every 1.5s
      let cursor = 0; // current note index
      let startTime = musicCtx.currentTime;

      const scheduleAhead = () => {
        if (!musicPlaying || !musicCtx) return;
        const now = musicCtx.currentTime;
        const horizon = now + LOOK_AHEAD;

        while (cursor < JP_NOTES.length) {
          const [t, freq, dur, vel] = JP_NOTES[cursor];
          const when = startTime + t;
          if (when > horizon) break; // too far ahead, wait
          if (when >= now - 0.05) { // skip notes in the past
            const osc = musicCtx.createOscillator();
            const gain = musicCtx.createGain();
            osc.type = freq > 400 ? "triangle" : "sine";
            osc.frequency.value = freq;
            const filt = musicCtx.createBiquadFilter();
            filt.type = "lowpass";
            filt.frequency.value = Math.min(2000, freq * 3);
            filt.Q.value = 0.5;
            const attackT = Math.min(0.08, dur * 0.15);
            const releaseT = Math.min(0.3, dur * 0.3);
            gain.gain.setValueAtTime(0, when);
            gain.gain.linearRampToValueAtTime(vel * 0.4, when + attackT);
            gain.gain.setTargetAtTime(vel * 0.25, when + attackT, dur * 0.3);
            gain.gain.setTargetAtTime(0.001, when + dur - releaseT, releaseT * 0.5);
            osc.connect(filt).connect(gain).connect(master);
            osc.start(when);
            osc.stop(when + dur + 0.1);
          }
          cursor++;
        }

        // Loop if we've reached the end
        if (cursor >= JP_NOTES.length) {
          const totalDur = JP_NOTES[JP_NOTES.length - 1][0] + JP_NOTES[JP_NOTES.length - 1][2] + 1.5;
          startTime = startTime + totalDur;
          cursor = 0;
        }

        musicTimer = setTimeout(scheduleAhead, SCHEDULE_INTERVAL);
      };
      scheduleAhead();
    }
  } catch(e) {}
}

function stopMusic() {
  musicPlaying = false;
  if (musicTimer) { clearTimeout(musicTimer); musicTimer = null; }
  musicNodes.forEach(n => { try { n.stop(); } catch(e) {} });
  musicNodes = [];
  if (musicCtx) { try { musicCtx.close(); } catch(e) {} musicCtx = null; }
}

// ============ SOUND EFFECTS ============
function playSfx(type) {
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return;
  try {
    const ctx = new AC();
    if (ctx.state === "suspended") ctx.resume();
    const now = ctx.currentTime;

    if (type === "hit") {
      // Short thwack: noise burst + low thud
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sawtooth";
      osc.frequency.setValueAtTime(200, now);
      osc.frequency.exponentialRampToValueAtTime(60, now + 0.08);
      gain.gain.setValueAtTime(0.3, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
      osc.connect(gain).connect(ctx.destination);
      osc.start(now); osc.stop(now + 0.12);
    } else if (type === "crit") {
      // Louder crunch: distorted hit + high ring
      const osc1 = ctx.createOscillator();
      const osc2 = ctx.createOscillator();
      const gain = ctx.createGain();
      osc1.type = "square"; osc1.frequency.value = 150;
      osc2.type = "sawtooth"; osc2.frequency.value = 800;
      osc2.frequency.exponentialRampToValueAtTime(200, now + 0.15);
      gain.gain.setValueAtTime(0.35, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
      osc1.connect(gain); osc2.connect(gain); gain.connect(ctx.destination);
      osc1.start(now); osc1.stop(now + 0.1);
      osc2.start(now); osc2.stop(now + 0.2);
    } else if (type === "dodge") {
      // Whoosh: filtered noise sweep
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sine";
      osc.frequency.setValueAtTime(400, now);
      osc.frequency.exponentialRampToValueAtTime(1200, now + 0.15);
      gain.gain.setValueAtTime(0.15, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
      osc.connect(gain).connect(ctx.destination);
      osc.start(now); osc.stop(now + 0.2);
    } else if (type === "victory") {
      // Ascending arpeggio
      [523, 659, 784, 1047].forEach((freq, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "triangle";
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0, now + i * 0.12);
        gain.gain.linearRampToValueAtTime(0.2, now + i * 0.12 + 0.05);
        gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.12 + 0.3);
        osc.connect(gain).connect(ctx.destination);
        osc.start(now + i * 0.12); osc.stop(now + i * 0.12 + 0.3);
      });
    } else if (type === "lastbreath") {
      // Dramatic low chord
      [110, 138, 165].forEach((freq) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sawtooth";
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0.25, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
        osc.connect(gain).connect(ctx.destination);
        osc.start(now); osc.stop(now + 0.6);
      });
    } else if (type === "defeat") {
      // Descending sad notes
      [400, 350, 280].forEach((freq, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sine";
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0.15, now + i * 0.2);
        gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.2 + 0.25);
        osc.connect(gain).connect(ctx.destination);
        osc.start(now + i * 0.2); osc.stop(now + i * 0.2 + 0.25);
      });
    }
    setTimeout(() => ctx.close(), 1500);
  } catch(e) {}
}

// ============ HAPTIC FEEDBACK ============
// ============ DINO ROAR ============
function playRoar(family) {
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return;
  try {
    const ctx = new AC();
    const now = ctx.currentTime;
    const master = ctx.createGain();
    master.gain.value = 0.3;
    master.connect(ctx.destination);

    if (family === "tyrant" || family === "armored") {
      // Deep rumbling roar
      const osc = ctx.createOscillator();
      osc.type = "sawtooth";
      osc.frequency.setValueAtTime(90, now);
      osc.frequency.exponentialRampToValueAtTime(55, now + 0.8);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.4, now);
      g.gain.linearRampToValueAtTime(0.6, now + 0.15);
      g.gain.exponentialRampToValueAtTime(0.01, now + 1.2);
      const filt = ctx.createBiquadFilter();
      filt.type = "lowpass"; filt.frequency.value = 200;
      osc.connect(filt).connect(g).connect(master);
      osc.start(now); osc.stop(now + 1.3);
      // Sub-rumble
      const sub = ctx.createOscillator();
      sub.type = "sine"; sub.frequency.value = 35;
      const sg = ctx.createGain();
      sg.gain.setValueAtTime(0.3, now);
      sg.gain.exponentialRampToValueAtTime(0.01, now + 1.5);
      sub.connect(sg).connect(master);
      sub.start(now); sub.stop(now + 1.5);
    } else if (family === "raptor" || family === "spino") {
      // High-pitched screech
      const osc = ctx.createOscillator();
      osc.type = "sawtooth";
      osc.frequency.setValueAtTime(800, now);
      osc.frequency.exponentialRampToValueAtTime(1200, now + 0.1);
      osc.frequency.exponentialRampToValueAtTime(600, now + 0.5);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0, now);
      g.gain.linearRampToValueAtTime(0.35, now + 0.05);
      g.gain.exponentialRampToValueAtTime(0.01, now + 0.7);
      const filt = ctx.createBiquadFilter();
      filt.type = "bandpass"; filt.frequency.value = 900; filt.Q.value = 3;
      osc.connect(filt).connect(g).connect(master);
      osc.start(now); osc.stop(now + 0.8);
    } else if (family === "sauropod" || family === "hadrosaur") {
      // Long low-frequency call (like a foghorn)
      const osc = ctx.createOscillator();
      osc.type = "triangle";
      osc.frequency.setValueAtTime(100, now);
      osc.frequency.linearRampToValueAtTime(130, now + 0.5);
      osc.frequency.linearRampToValueAtTime(80, now + 1.5);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0, now);
      g.gain.linearRampToValueAtTime(0.4, now + 0.3);
      g.gain.setValueAtTime(0.4, now + 1.0);
      g.gain.exponentialRampToValueAtTime(0.01, now + 2.0);
      osc.connect(g).connect(master);
      osc.start(now); osc.stop(now + 2.1);
    } else if (family === "flyer") {
      // Pteranodon shriek
      const osc = ctx.createOscillator();
      osc.type = "square";
      osc.frequency.setValueAtTime(1500, now);
      osc.frequency.exponentialRampToValueAtTime(2000, now + 0.08);
      osc.frequency.exponentialRampToValueAtTime(800, now + 0.4);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.15, now);
      g.gain.exponentialRampToValueAtTime(0.01, now + 0.5);
      const filt = ctx.createBiquadFilter();
      filt.type = "highpass"; filt.frequency.value = 600;
      osc.connect(filt).connect(g).connect(master);
      osc.start(now); osc.stop(now + 0.6);
    } else if (family === "marine") {
      // Underwater bellow
      const osc = ctx.createOscillator();
      osc.type = "sine";
      osc.frequency.setValueAtTime(60, now);
      osc.frequency.linearRampToValueAtTime(90, now + 0.5);
      osc.frequency.linearRampToValueAtTime(45, now + 1.8);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.3, now);
      g.gain.exponentialRampToValueAtTime(0.01, now + 2.0);
      const filt = ctx.createBiquadFilter();
      filt.type = "lowpass"; filt.frequency.value = 150;
      osc.connect(filt).connect(g).connect(master);
      osc.start(now); osc.stop(now + 2.1);
    } else {
      // Generic growl
      const osc = ctx.createOscillator();
      osc.type = "sawtooth";
      osc.frequency.setValueAtTime(150, now);
      osc.frequency.exponentialRampToValueAtTime(80, now + 0.6);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.3, now);
      g.gain.exponentialRampToValueAtTime(0.01, now + 0.8);
      const filt = ctx.createBiquadFilter();
      filt.type = "lowpass"; filt.frequency.value = 300;
      osc.connect(filt).connect(g).connect(master);
      osc.start(now); osc.stop(now + 0.9);
    }
    setTimeout(() => ctx.close(), 3000);
  } catch(e) {}
}

function vibrate(pattern) {
  try { if (navigator.vibrate) navigator.vibrate(pattern); } catch(e) {}
}

function playCry(build) {
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return;
  const ctx = new AC();
  // Resume if suspended (iOS Safari)
  if (ctx.state === "suspended") ctx.resume();

  const headD = DINOS[build.head];
  const teethD = DINOS[build.teeth];
  const tailD = DINOS[build.tail];
  const backLegsD = DINOS[build.backLegs];
  const backDorsalD = DINOS[build.back];

  const cryType = headD.cry;
  const params = {
    headSize: headD.head.size,
    bite: headD.head.bite,
    sharp: teethD.teeth.sharp,
    teethN: teethD.teeth.count,
    tailPow: tailD.tail.power,
    speed: backLegsD.backLegs.speed,
    armor: backDorsalD.back.armor,
    cryType,
  };

  // Master routing: dry + wet (reverb) buses
  const master = ctx.createGain();
  master.gain.value = 0.55;
  master.connect(ctx.destination);

  const isUnderwater = cryType.includes("underwater") || cryType.includes("whale");
  const isCold = cryType.includes("cold");
  const reverb = makeReverb(ctx,
    isUnderwater ? 3.5 : isCold ? 2.5 : 1.4,
    isUnderwater ? 2.5 : 2);
  reverb.connect(master);

  const sendDry = (node) => node.connect(master);
  const sendWet = (node, amount) => {
    const g = ctx.createGain();
    g.gain.value = amount;
    node.connect(g);
    g.connect(reverb);
  };

  const t0 = ctx.currentTime + 0.02;
  let duration;

  if (cryType.includes("chirp") || cryType.includes("trill")) {
    duration = cryChirps(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("screech")) {
    duration = cryScreech(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("trumpet") || cryType.includes("horn")) {
    duration = cryTrumpet(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("hiss")) {
    duration = cryHiss(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("bellow")) {
    duration = cryBellow(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("grunt") || cryType.includes("thud")) {
    duration = cryGrunt(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("whale") || cryType.includes("underwater")) {
    duration = cryWhaleCall(ctx, t0, sendWet, sendDry, params);
  } else if (cryType.includes("growl")) {
    duration = cryGrowl(ctx, t0, sendWet, sendDry, params);
  } else {
    duration = cryRoar(ctx, t0, sendWet, sendDry, params);
  }

  setTimeout(() => { try { ctx.close(); } catch (e) {} }, (duration + 3) * 1000);
}


// ============ DINO SVG (parametric) ============
// ============ PIXEL ART SPRITE SYSTEM ============
// Sprite encoding: each character represents one pixel
// . = transparent
// o = outline (very dark)    b = body base        d = dark shading
// l = light highlight        u = belly (lighter)  w = eye white
// p = pupil (black)          t = teeth/bone       m = mouth (dark red)
// s = spike/plate accent     c = claw (cream)     h = horn
// f = feather accent

function makePalette(color) {
  return {
    ".": null,
    o: shadeColor(color, -65),      // outline dark
    b: color,                         // base
    d: shadeColor(color, -30),        // dark shade
    l: shadeColor(color, 28),         // light
    u: shadeColor(color, 50),         // belly (lightest)
    w: "#f0ece0",                     // white
    p: "#0d0604",                     // pupil
    t: "#eadbaa",                     // teeth
    m: "#4a1010",                     // mouth
    c: "#d8c880",                     // claws
    s: shadeColor(color, 35),         // semi-light
    h: shadeColor(color, 60),         // highlight (brighter)
    f: shadeColor(color, -15),        // shadow
    g: shadeColor(color, 45),         // mid-highlight
    e: shadeColor(color, -45),        // deep shadow
  };
}

function Sprite({ data, x, y, palette, flipX }) {
  const rects = [];
  let idx = 0;
  for (let r = 0; r < data.length; r++) {
    const row = data[r];
    for (let c = 0; c < row.length; c++) {
      const ch = row[c];
      const col = palette[ch];
      if (!col) continue;
      const px = flipX ? x + (row.length - 1 - c) : x + c;
      const py = y + r;
      // Main pixel
      rects.push(<rect key={idx++} x={px} y={py} width={1.06} height={1.06} rx={0.08} fill={col} />);
      // Highlight sub-pixel (top edge)
      if (ch !== 'o' && ch !== '.') {
        rects.push(<rect key={idx++} x={px + 0.05} y={py} width={0.95} height={0.35}
          fill={shadeColor(col, 18)} rx={0.06} opacity={0.5} />);
      }
      // Shadow sub-pixel (bottom edge)
      if (ch !== 'o' && ch !== '.') {
        rects.push(<rect key={idx++} x={px + 0.05} y={py + 0.7} width={0.95} height={0.36}
          fill={shadeColor(col, -15)} rx={0.06} opacity={0.35} />);
      }
    }
  }
  return <>{rects}</>;
}

// ============ HEAD SPRITES (facing right) ============
const HEAD_SPRITES = {
  tyrant: [
    "....ooooooo...",
    "...ohlllllhoo.",
    "..ohlllllllhbo",
    "..ohlwwpllhbbo",
    "..ohlwwplfbbbo",
    ".ohbbbbbbfbbeo",
    ".ohbbbbbbfbbeo",
    ".obbbbbbffbbeo",
    ".ommmmmmmmmmmo",
    "..ooooooooooo.",
  ],
  spino: [
    "...oooooo........",
    "..ohlllhbo.......",
    ".ohlwwpllbooo....",
    ".ohlwwplfbbbbooo.",
    ".ohbbbbbbfbbbbbeo",
    ".obbbbbbbffbbbbeo",
    ".ommmmmmmmmmmmmmo",
    "..ooooooooooooooo",
  ],
  raptor: [
    ".....eeee....",
    "....oefbhfo..",
    "...ohllfbhfo.",
    "..ohlwwpfbbbo",
    "..ohlwwpfbbbo",
    "..ohbbbbbfbeo",
    "..ommmmmmmmoo",
    "...oooooooo..",
  ],
  sauropod: [
    "...ooooo.",
    "..ohlllho",
    "..ohwwpfo",
    "..ohbbfeo",
    "..ommmmmo",
    "...ooooo.",
  ],
  ceratopsian: [
    "hh.....hh.......",
    ".hh.s.hh........",
    "...shs..........",
    "..sssss.........",
    ".sssssss.ooooo..",
    "ssssssssohllhbo.",
    ".sssssssobwplfbo",
    "..sssssohbbbfeo.",
    "...sssobbbbfeo..",
    "....ssoommmmmoo.",
    "......ooooooo...",
  ],
  armored: [
    "....ssssss....",
    "...ssdsdsdss..",
    "..sssssssssso.",
    ".ohbbbbbbbbheo",
    ".ohlwwpbbbbheo",
    ".ohlwwpbbbfbeo",
    ".obbbbbbbbfbeo",
    ".ommmmmmmmmmoo",
    "..oooooooooo..",
  ],
  hadrosaur: [
    "....sss.........",
    "...sglgs........",
    "...sglgs........",
    "....soooo.......",
    ".....ohbboooooo.",
    "....ohbbbbbbbheo",
    "...ohlwwpbbbbheo",
    "...ohlwwpbbbfbeo",
    "..obbbbbbbbffbeo",
    "..ommmmmmmmmmmmo",
    "...ooooooooooo..",
  ],
  flyer: [
    "...ss...................",
    "..ssss..................",
    ".sslss..................",
    "sslssoooo...............",
    ".ssohllhbooooooo........",
    "..ohlwwpfbbbbbbbooo.....",
    "..ohbbbbbbbbbbbbbbboo...",
    "..ooooooooooooooooooooo.",
  ],
  marine: [
    "....oooooo.......",
    "...ohlllhbo......",
    "..ohlwwpfbboo....",
    "..ohlwwpffbbboo..",
    ".ohbbbbbbfbbbbbbo",
    ".obbbbbbbbbbbbbbbo",
    ".ommmmmmmmmmmmmmmo",
    "..oooooooooooooo..",
  ],
};

// Head origin offsets (where the neck attaches, from top-left of sprite)
const HEAD_NECK_OFFSET = {
  tyrant: { x: 1, y: 6 },
  spino: { x: 1, y: 4 },
  raptor: { x: 2, y: 5 },
  sauropod: { x: 2, y: 3 },
  ceratopsian: { x: 10, y: 6 },
  armored: { x: 1, y: 4 },
  hadrosaur: { x: 4, y: 6 },
  flyer: { x: 3, y: 6 },
  marine: { x: 1, y: 4 },
};

// ============ BODY SPRITE (shared, 28x14) ============
const BODY_SPRITE = [
  "..........ooooooooooo..........",
  ".......ooohllllllllhoooo.......",
  ".....oohhllllllllllllhhoo.....",
  "....ohhllllllllllllllllhho...",
  "...ohlllllllllllhhlllllllho..",
  "..ohlllllllhhhhhhhhllllllfeo.",
  "..ohlllhhhhhhhhhhhhhhhllffeo.",
  "..ohhhhhhhhhhhhhbbbbhhhhffeo.",
  "..ohhhhhhbbbbbbbbbbbbbbhffeo.",
  ".ohbbbbbbbbbbuuuuuuuuubbbfeo",
  ".ohbbbbbbuuuuuuguuuuuuubbfeo",
  ".ohbbbuuuuuuugggguuuuuuubfeo",
  "..obuuuuuuuuuuuuuuuuuuuufoo.",
  "...oouuuuuuuuuuuuuuuuuuoo...",
  ".....oouuuuuuuuuuuuuuoo.....",
  "........ooooooooooooooo.......",
];

// ============ LEG SPRITES ============
const LEG_SPRITES = {
  bipedBig: [  // tyrant
    "ohho",
    "ohbo",
    "obbo",
    "obbfo",
    "obbeo",
    ".obfo",
    ".obeo",
    "obbbeo",
    "oocccoo",
  ],
  bipedFast: [  // raptor
    ".obo",
    ".obo",
    ".obbo",
    "..obo",
    "..obbo",
    "ooccoo",
  ],
  bipedHadro: [
    "obbo",
    "obbo",
    "obbo",
    ".obbo",
    ".obbo",
    "obbbbo",
    "ooooo",
  ],
  quadColumn: [  // sauropod/ceratopsian/armored front or back
    "ohbfo",
    "ohbfo",
    "ohbfo",
    "obfeo",
    "obfeo",
    "oooooo",
  ],
  wing: [
    "...oooooooooo",
    "..obbbbbbbbbo",
    ".obbbbbbbbboo",
    "obbbbbbbbbboo",
    "obbbbbbbbbbo.",
    ".obbbbbbbboo.",
    "..oooooooooo.",
  ],
  flipper: [
    "obbbbbbo",
    "obbbbbbo",
    ".oobbbo.",
    "...ooo..",
  ],
  armTiny: [  // T-Rex little arms
    "ob",
    "ob",
    "oc",
  ],
  armClawed: [  // raptor, spino, therizino
    ".ob.",
    ".ob.",
    "obbo",
    "ocbo",
    "occo",
  ],
  armMedium: [  // generic
    ".ob.",
    ".ob.",
    "obbo",
    "oboo",
  ],
};

// ============ DORSAL FEATURES ============
function renderDorsal(family, spikes, armor, x, y, width, palette) {
  const parts = [];
  if (family === "spino") {
    // tall sail
    const sailH = 9 + Math.floor(spikes / 2);
    const sailData = [];
    for (let i = 0; i < sailH; i++) {
      const w = width - Math.floor(Math.abs(i - sailH / 2) * 1.2);
      const pad = Math.floor((width - w) / 2);
      const row = ".".repeat(pad) + (i === 0 ? "o".repeat(w) : "o" + "s".repeat(w - 2) + "o") + ".".repeat(pad);
      sailData.push(row.padEnd(width, "."));
    }
    parts.push(<Sprite key="sail" data={sailData} x={x} y={y - sailH} palette={palette} />);
  } else if (family === "armored" && spikes >= 6) {
    // stego plates
    const nPlates = 5;
    for (let i = 0; i < nPlates; i++) {
      const px = x + 2 + i * Math.floor((width - 4) / nPlates);
      const plateData = [
        "..ooo..",
        ".olllo.",
        "olllllo",
        "oslslso",
        "oooooo.",
      ];
      parts.push(<Sprite key={`plate-${i}`} data={plateData} x={px} y={y - 5} palette={palette} />);
    }
  } else if (family === "armored") {
    // anky bumps
    for (let i = 0; i < 6; i++) {
      const px = x + 2 + i * Math.floor((width - 4) / 6);
      parts.push(<Sprite key={`bump-${i}`} data={["ooo", "odlo", "oooo"]} x={px} y={y - 2} palette={palette} />);
    }
  } else if (family === "sauropod" && spikes > 4) {
    // amarga twin spines
    for (let i = 0; i < 5; i++) {
      const px = x + 5 + i * 3;
      parts.push(<rect key={`s-${i}`} x={px} y={y - 4} width={1.1} height={4} rx={0.2} fill={palette.o} />);
    }
  } else if (spikes > 4) {
    // generic spikes along back
    const n = Math.min(8, 3 + Math.floor(spikes / 1.5));
    for (let i = 0; i < n; i++) {
      const px = x + 2 + i * Math.floor((width - 4) / n);
      const h = 1 + Math.floor(spikes / 3);
      parts.push(<Sprite key={`sp-${i}`} data={Array.from({ length: h }, (_, j) => (j === h - 1 ? "ooo" : "." + "o" + "."))} x={px} y={y - h} palette={palette} />);
    }
  }
  return parts;
}

// ============ TAIL ============
function renderTail(family, power, length, startX, startY, palette, dorsalSpikes) {
  const thickness = 2 + Math.floor(power / 3);
  const tailLen = 10 + Math.floor(length * 1.5);
  const parts = [];

  // Curved tail using a pixel curve
  const points = [];
  for (let i = 0; i <= tailLen; i++) {
    const t = i / tailLen;
    let tx, ty;
    if (family === "sauropod") {
      // long, droops down at end
      tx = startX - i;
      ty = startY + Math.floor(t * t * 6);
    } else if (family === "marine") {
      tx = startX - i;
      ty = startY + Math.floor(Math.sin(t * 2) * 2);
    } else if (family === "flyer") {
      tx = startX - Math.floor(i * 0.4);
      ty = startY + Math.floor(t * 2);
      if (i > 6) break;
    } else {
      // biped/quad default: lifted, gently curved
      tx = startX - i;
      ty = startY - Math.floor(Math.sin(t * Math.PI) * 3);
    }
    points.push({ x: tx, y: ty });
  }

  // Draw tail segments
  points.forEach((pt, i) => {
    const t = i / points.length;
    const thick = family === "sauropod"
      ? Math.max(1, thickness - Math.floor(t * thickness))
      : family === "raptor"
        ? Math.max(1, thickness - Math.floor(t * 2))
        : thickness;
    for (let dy = 0; dy < thick; dy++) {
      const isEdge = dy === 0 || dy === thick - 1;
      parts.push(
        <rect key={`tail-${i}-${dy}`} x={pt.x} y={pt.y + dy} width={1.02} height={1.02}
          fill={isEdge ? palette.o : palette.b} rx={0.2} />
      );
    }
  });

  // Tail tip ornament
  const tip = points[points.length - 1];
  if (tip) {
    if (family === "armored" && dorsalSpikes >= 4) {
      // thagomizer - 4 spikes
      const thago = [
        "h.h.h.h",
        "h.h.h.h",
        "ooooooo",
      ];
      parts.push(<Sprite key="thago" data={thago} x={tip.x - 3} y={tip.y - 2} palette={palette} />);
    } else if (family === "armored") {
      // club
      const club = [
        ".ooo.",
        "odddo",
        "ohhdo",
        "odddo",
        ".ooo.",
      ];
      parts.push(<Sprite key="club" data={club} x={tip.x - 4} y={tip.y - 1} palette={palette} />);
    } else if (family === "marine") {
      // paddle
      const paddle = [
        "..oo.",
        ".obbo",
        "obbbbo",
        ".obbo",
        "..oo.",
      ];
      parts.push(<Sprite key="paddle" data={paddle} x={tip.x - 3} y={tip.y - 2} palette={palette} />);
    }
  }

  return parts;
}

// ============ TEETH in mouth ============
function renderTeeth(family, count, sharp, mouthX, mouthY, mouthW, palette) {
  if (count === 0 || family === "flyer") return null;
  const teeth = [];
  const n = Math.min(mouthW - 1, Math.max(2, count + 2));
  const fangSize = sharp > 7 ? 2 : 1;
  for (let i = 0; i < n; i++) {
    const x = mouthX + Math.floor(i * (mouthW / n)) + 1;
    // upper teeth
    teeth.push(<rect key={`u-${i}`} x={x} y={mouthY} width={1} height={fangSize} fill={palette.t} rx={0.1} />);
    // lower teeth (alternating for sharpness)
    if (sharp > 5 && i % 2 === 1) {
      teeth.push(<rect key={`l-${i}`} x={x} y={mouthY + 2} width={1} height={fangSize} fill={palette.t} rx={0.1} />);
    }
  }
  return teeth;
}

// ============ MAIN DINO COMPONENT ============
// ============ 3D VOXEL DINO (Three.js) ============
function collectDinoPixels(build) {
  const color = build.customColor || DINOS[build.color]?.color || "#888";
  const palette = makePalette(color);
  const pixels = [];

  const addSprite = (data, offX, offY, z) => {
    for (let r = 0; r < data.length; r++) {
      for (let c = 0; c < data[r].length; c++) {
        const ch = data[r][c];
        const col = palette[ch];
        if (col) pixels.push({ x: offX + c, y: offY + r, z, color: col });
      }
    }
  };

  const headD = DINOS[build.head];
  const teethD = DINOS[build.teeth];
  const backD = DINOS[build.back];
  const frontD = DINOS[build.frontLegs];
  const backLegsD = DINOS[build.backLegs];
  const tailD = DINOS[build.tail];

  const bipedFams = ["tyrant", "spino", "raptor", "hadrosaur"];
  const quadFams = ["sauropod", "ceratopsian", "armored"];
  const posture = bipedFams.includes(backLegsD.family) ? "biped"
    : quadFams.includes(backLegsD.family) ? "quad"
    : backLegsD.family === "flyer" ? "flyer" : "marine";

  const bodyX = 18, bodyY = 20, bodyW = 31, bodyH = 16;

  // Body (thick: 3 layers)
  addSprite(BODY_SPRITE, bodyX, bodyY, -1);
  addSprite(BODY_SPRITE, bodyX, bodyY, 0);
  addSprite(BODY_SPRITE, bodyX, bodyY, 1);

  // ===== DORSAL FEATURES (sail, plates, spikes) =====
  const dorsalFamily = backD.family;
  const dorsalSpikes = backD.stats?.force || 5;
  if (dorsalFamily === "spino") {
    // Tall sail on back
    const sailH = 9 + Math.floor(dorsalSpikes / 2);
    for (let i = 0; i < sailH; i++) {
      const w = bodyW - 8 - Math.floor(Math.abs(i - sailH / 2) * 1.5);
      const sx = bodyX + 4 + Math.floor((bodyW - 8 - w) / 2);
      for (let c = 0; c < w; c++) {
        const col = (i === 0 || c === 0 || c === w - 1) ? palette.o : palette.s;
        pixels.push({ x: sx + c, y: bodyY - sailH + i, z: 0, color: col });
      }
    }
  } else if (dorsalFamily === "armored" && dorsalSpikes >= 6) {
    // Stego plates
    for (let p = 0; p < 5; p++) {
      const px = bodyX + 3 + p * 5;
      for (let dy = 0; dy < 4; dy++) {
        const w = dy < 2 ? 3 : 5;
        const sx = px - Math.floor(w / 2);
        for (let c = 0; c < w; c++) {
          const col = (dy === 0 || c === 0 || c === w - 1) ? palette.o : palette.l;
          pixels.push({ x: sx + c, y: bodyY - 4 + dy, z: 0, color: col });
        }
      }
    }
  } else if (dorsalFamily === "armored") {
    // Anky bumps
    for (let p = 0; p < 6; p++) {
      const px = bodyX + 2 + p * 4;
      pixels.push({ x: px, y: bodyY - 1, z: 0, color: palette.d });
      pixels.push({ x: px + 1, y: bodyY - 1, z: 0, color: palette.l });
      pixels.push({ x: px, y: bodyY - 2, z: 0, color: palette.o });
    }
  } else if (dorsalSpikes > 4) {
    // Generic spikes
    const n = Math.min(7, 3 + Math.floor(dorsalSpikes / 2));
    for (let i = 0; i < n; i++) {
      const px = bodyX + 3 + i * Math.floor((bodyW - 6) / n);
      const h = 2 + Math.floor(dorsalSpikes / 4);
      for (let dy = 0; dy < h; dy++) {
        pixels.push({ x: px, y: bodyY - h + dy, z: 0, color: dy === 0 ? palette.o : palette.s });
      }
    }
  }

  // ===== HEAD =====
  const headSprite = HEAD_SPRITES[headD.family] || HEAD_SPRITES.tyrant;
  const headOff = HEAD_NECK_OFFSET[headD.family] || { x: 1, y: 5 };
  const neckLen = headD.family === "sauropod" ? 16 : headD.family === "flyer" ? 6 : 7;
  const neckAngle = headD.family === "sauropod" && posture === "quad" ? -1.1 : -0.55;
  const neckStartX = bodyX + bodyW - 4;
  const neckStartY = bodyY + 2;
  const neckEndX = Math.floor(neckStartX + Math.cos(neckAngle) * neckLen);
  const neckEndY = Math.floor(neckStartY + Math.sin(neckAngle) * neckLen);
  const headX = neckEndX - headOff.x;
  const headY = neckEndY - headOff.y;

  // Neck (thicker, 3 layers)
  const nSteps = Math.max(Math.abs(neckEndX - neckStartX), Math.abs(neckEndY - neckStartY));
  for (let s = 0; s <= nSteps; s++) {
    const t = s / Math.max(1, nSteps);
    const nx = Math.round(neckStartX + (neckEndX - neckStartX) * t);
    const ny = Math.round(neckStartY + (neckEndY - neckStartY) * t);
    for (let z = -1; z <= 1; z++) {
      pixels.push({ x: nx, y: ny, z, color: z === 0 ? palette.b : palette.o });
      pixels.push({ x: nx, y: ny + 1, z, color: z === 0 ? palette.b : palette.o });
    }
  }

  // Head sprite (3 layers)
  addSprite(headSprite, headX, headY, -1);
  addSprite(headSprite, headX, headY, 0);
  addSprite(headSprite, headX, headY, 1);

  // ===== TEETH =====
  const teethCount = teethD.teeth?.count || 0;
  const teethSharp = teethD.teeth?.sharp || 0;
  if (teethCount > 0 && headD.family !== "flyer") {
    // Find mouth row in head sprite (row with 'm')
    let mouthRow = -1, mouthStartC = 99, mouthEndC = 0;
    headSprite.forEach((row, r) => {
      for (let c = 0; c < row.length; c++) {
        if (row[c] === 'm') {
          if (mouthRow === -1) mouthRow = r;
          mouthStartC = Math.min(mouthStartC, c);
          mouthEndC = Math.max(mouthEndC, c);
        }
      }
    });
    if (mouthRow >= 0) {
      const mw = mouthEndC - mouthStartC;
      const n = Math.min(mw, Math.max(2, teethCount + 1));
      const fangH = teethSharp > 7 ? 2 : 1;
      for (let i = 0; i < n; i++) {
        const tx = headX + mouthStartC + Math.floor(i * mw / n) + 1;
        const ty = headY + mouthRow - 1;
        for (let fh = 0; fh < fangH; fh++) {
          pixels.push({ x: tx, y: ty + fh, z: 0, color: palette.t });
          pixels.push({ x: tx, y: ty + fh, z: 1, color: palette.t });
        }
      }
    }
  }

  // ===== LEGS (4 legs: 2 front, 2 back) =====
  let frontLeg, backLeg;
  if (posture === "biped") {
    frontLeg = frontD.family === "tyrant" ? LEG_SPRITES.armTiny
      : (frontD.family === "raptor" || frontD.family === "spino") ? LEG_SPRITES.armClawed
      : LEG_SPRITES.armMedium;
    backLeg = backLegsD.family === "raptor" ? LEG_SPRITES.bipedFast
      : backLegsD.family === "hadrosaur" ? LEG_SPRITES.bipedHadro
      : LEG_SPRITES.bipedBig;
  } else if (posture === "quad") {
    frontLeg = LEG_SPRITES.quadColumn;
    backLeg = LEG_SPRITES.quadColumn;
  } else if (posture === "flyer") {
    frontLeg = LEG_SPRITES.wing;
    backLeg = LEG_SPRITES.armMedium;
  } else {
    frontLeg = LEG_SPRITES.flipper;
    backLeg = LEG_SPRITES.flipper;
  }

  const legY = bodyY + bodyH - 2;
  // Front legs: z=2 and z=-2
  addSprite(frontLeg, bodyX + bodyW - (frontLeg[0]?.length || 4) - 2, legY, 2);
  addSprite(frontLeg, bodyX + bodyW - (frontLeg[0]?.length || 4) - 2, legY, -2);
  // Back legs: z=3 and z=-3
  addSprite(backLeg, bodyX + 1, legY, 3);
  addSprite(backLeg, bodyX + 1, legY, -3);

  // ===== TAIL (procedural) =====
  const tailLen = 8 + Math.floor((tailD.tail?.length || 5) * 1.2);
  for (let i = 0; i < tailLen; i++) {
    const t = i / tailLen;
    const tx = bodyX - i + 2;
    const ty = bodyY + Math.floor(bodyH / 2) + Math.floor(t * t * 4);
    const thick = Math.max(1, Math.floor((1 - t) * 3));
    for (let j = 0; j < thick; j++) {
      const col = j === 0 ? palette.h : j === thick - 1 ? palette.f : palette.b;
      pixels.push({ x: tx, y: ty + j, z: 0, color: col });
      if (thick > 1) {
        pixels.push({ x: tx, y: ty + j, z: -1, color: palette.o });
        pixels.push({ x: tx, y: ty + j, z: 1, color: palette.o });
      }
    }
    // Armored tail club
    if (tailD.family === "armored" && t > 0.85) {
      for (let z = -1; z <= 1; z++) {
        pixels.push({ x: tx, y: ty - 1, z, color: palette.d });
        pixels.push({ x: tx, y: ty + thick, z, color: palette.d });
      }
    }
  }

  return pixels;
}

function DinoArt3D({ build }) {
  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || typeof THREE === "undefined") return;

    const w = 400, h = 260;
    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
    renderer.setSize(w, h, false); // false = don't override CSS styles
    renderer.setClearColor(0x141810, 1);

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(30, w / h, 1, 500);
    camera.position.set(0, -5, 80);
    camera.lookAt(0, 0, 0);

    scene.add(new THREE.AmbientLight(0xffffff, 0.5));
    const sun = new THREE.DirectionalLight(0xffffff, 1);
    sun.position.set(5, 10, 15);
    scene.add(sun);

    // Collect pixels from all sprites
    const pixels = collectDinoPixels(build);
    const colorMap = {};
    pixels.forEach(p => {
      if (!colorMap[p.color]) colorMap[p.color] = [];
      colorMap[p.color].push(p);
    });

    const group = new THREE.Group();
    const box = new THREE.BoxGeometry(0.85, 0.85, 0.85);

    Object.entries(colorMap).forEach(([hex, pts]) => {
      const mat = new THREE.MeshLambertMaterial({ color: new THREE.Color(hex) });
      const inst = new THREE.InstancedMesh(box, mat, pts.length);
      const obj = new THREE.Object3D();
      pts.forEach((p, i) => {
        obj.position.set(p.x - 38, -(p.y - 28), p.z);
        obj.updateMatrix();
        inst.setMatrixAt(i, obj.matrix);
      });
      inst.instanceMatrix.needsUpdate = true;
      group.add(inst);
    });

    scene.add(group);

    let rotY = 0;
    let dragging = false;
    let lastX = 0;
    let af;

    const loop = () => {
      if (!dragging) rotY += 0.006;
      group.rotation.y = rotY;
      renderer.render(scene, camera);
      af = requestAnimationFrame(loop);
    };
    loop();

    const onDown = (e) => { dragging = true; lastX = (e.touches?.[0] || e).clientX; };
    const onMove = (e) => { if (!dragging) return; const x = (e.touches?.[0] || e).clientX; rotY += (x - lastX) * 0.01; lastX = x; };
    const onUp = () => { dragging = false; };

    canvas.addEventListener("mousedown", onDown);
    canvas.addEventListener("touchstart", onDown, { passive: true });
    window.addEventListener("mousemove", onMove);
    window.addEventListener("touchmove", onMove, { passive: true });
    window.addEventListener("mouseup", onUp);
    window.addEventListener("touchend", onUp);

    return () => {
      cancelAnimationFrame(af);
      canvas.removeEventListener("mousedown", onDown);
      canvas.removeEventListener("touchstart", onDown);
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("touchmove", onMove);
      window.removeEventListener("mouseup", onUp);
      window.removeEventListener("touchend", onUp);
      renderer.dispose();
    };
  }, [build.head, build.teeth, build.frontLegs, build.backLegs, build.back, build.tail, build.color, build.customColor]);

  if (typeof THREE === "undefined") {
    return <div style={{ padding: "20px", textAlign: "center", opacity: 0.5 }}>3D non disponible</div>;
  }

  return <canvas ref={canvasRef} width={400} height={260} style={{ width: "100%", height: "auto", display: "block", borderRadius: "8px" }} />;
}

function DinoArt({ build, animating = true, crying = false, pattern = "none" }) {
  const headD = DINOS[build.head];
  const teethD = DINOS[build.teeth];
  const frontD = DINOS[build.frontLegs];
  const backLegsD = DINOS[build.backLegs];
  const backDorsalD = DINOS[build.back];
  const tailD = DINOS[build.tail];
  const color = build.customColor || DINOS[build.color].color;
  const palette = makePalette(color);

  const bipedFams = ["tyrant", "spino", "raptor", "hadrosaur"];
  const quadFams = ["sauropod", "ceratopsian", "armored"];
  const posture = bipedFams.includes(backLegsD.family) ? "biped"
    : quadFams.includes(backLegsD.family) ? "quad"
    : backLegsD.family === "flyer" ? "flyer"
    : "marine";

  // Body anchor
  const bodyX = 18;
  const bodyY = 20;
  const bodyW = 28;
  const bodyH = 14;

  // Head placement (end of neck, upper right)
  const headSprite = HEAD_SPRITES[headD.family] || HEAD_SPRITES.tyrant;
  const headOff = HEAD_NECK_OFFSET[headD.family] || { x: 1, y: 5 };
  const neckLen = headD.family === "sauropod" ? 16 : headD.family === "flyer" ? 6 : 7;
  const neckAngle = headD.family === "sauropod" && posture === "quad" ? -1.1 : -0.55;
  const neckStartX = bodyX + bodyW - 4;
  const neckStartY = bodyY + 2;
  const neckEndX = Math.floor(neckStartX + Math.cos(neckAngle) * neckLen);
  const neckEndY = Math.floor(neckStartY + Math.sin(neckAngle) * neckLen);
  const headX = neckEndX - headOff.x;
  const headY = neckEndY - headOff.y;

  // Neck pixels (line)
  const neckPixels = [];
  const steps = Math.max(Math.abs(neckEndX - neckStartX), Math.abs(neckEndY - neckStartY));
  for (let s = 0; s <= steps; s++) {
    const t = s / Math.max(1, steps);
    const nx = Math.round(neckStartX + (neckEndX - neckStartX) * t);
    const ny = Math.round(neckStartY + (neckEndY - neckStartY) * t);
    const nthick = headD.family === "sauropod" ? 2 : headD.family === "flyer" ? 2 : 3;
    for (let dy = 0; dy < nthick; dy++) {
      const isEdge = dy === 0 || dy === nthick - 1;
      neckPixels.push(
        <rect key={`neck-${s}-${dy}`} x={nx} y={ny + dy} width={1.02} height={1.02}
          fill={isEdge ? palette.o : palette.b} rx={0.2} />
      );
    }
  }

  // Leg selection
  let backLegSprite, frontLegSprite;
  if (posture === "biped") {
    frontLegSprite = frontD.family === "tyrant" ? LEG_SPRITES.armTiny
      : (frontD.family === "raptor" || frontD.family === "spino") ? LEG_SPRITES.armClawed
      : LEG_SPRITES.armMedium;
    backLegSprite = backLegsD.family === "raptor" ? LEG_SPRITES.bipedFast
      : backLegsD.family === "hadrosaur" ? LEG_SPRITES.bipedHadro
      : LEG_SPRITES.bipedBig;
  } else if (posture === "quad") {
    frontLegSprite = LEG_SPRITES.quadColumn;
    backLegSprite = LEG_SPRITES.quadColumn;
  } else if (posture === "flyer") {
    frontLegSprite = LEG_SPRITES.wing;
    backLegSprite = LEG_SPRITES.armMedium;
  } else {
    frontLegSprite = LEG_SPRITES.flipper;
    backLegSprite = LEG_SPRITES.flipper;
  }

  const idleAnims = ["breathe", "idle-look", "idle-bounce"];
  const idleIdx = (build.head + build.teeth + build.tail) % idleAnims.length;
  const breathe = animating ? idleAnims[idleIdx] : "";

  return (
    <svg viewBox="0 0 80 54" className="w-full h-full" shapeRendering="geometricPrecision"
      style={{ imageRendering: "auto", filter: `drop-shadow(0 6px 0 rgba(25,40,28,0.25)) drop-shadow(0 1px 3px rgba(0,0,0,0.35))${Object.values(build).some(idx => DINOS[idx]?.exclusive) ? " drop-shadow(0 0 8px rgba(196,168,56,0.6))" : ""}` }}>
      <defs>
        <pattern id="pat-stripes" patternUnits="userSpaceOnUse" width="3" height="3" patternTransform="rotate(45)">
          <rect width="1.5" height="3" fill="rgba(0,0,0,0.25)" />
        </pattern>
        <pattern id="pat-spots" patternUnits="userSpaceOnUse" width="5" height="5">
          <circle cx="2.5" cy="2.5" r="1.3" fill="rgba(0,0,0,0.22)" />
        </pattern>
        <pattern id="pat-camo" patternUnits="userSpaceOnUse" width="8" height="6">
          <ellipse cx="2" cy="2" rx="2.5" ry="1.5" fill="rgba(0,0,0,0.15)" />
          <ellipse cx="6" cy="4" rx="2" ry="1.8" fill="rgba(0,0,0,0.2)" />
        </pattern>
        {/* Smooth filter: slight blur to soften pixel edges */}
        <filter id="smooth" x="-5%" y="-5%" width="110%" height="110%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="0.15" />
        </filter>
        {/* Glow filter for rare/high friendship dinos */}
        <filter id="glowGold" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="1.2" result="blur" />
          <feFlood floodColor="#e8a020" floodOpacity="0.5" />
          <feComposite in2="blur" operator="in" />
          <feMerge>
            <feMergeNode />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        <filter id="glowPurple" x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="1.2" result="blur" />
          <feFlood floodColor="#9050d0" floodOpacity="0.5" />
          <feComposite in2="blur" operator="in" />
          <feMerge>
            <feMergeNode />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
        {/* Body highlight gradient */}
        <linearGradient id="bodyShine" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="rgba(255,248,230,0.1)" />
          <stop offset="50%" stopColor="rgba(255,255,255,0)" />
          <stop offset="100%" stopColor="rgba(0,0,0,0.08)" />
        </linearGradient>
      </defs>
      <style>{`
        @keyframes breathing {
          0%, 100% { transform: translateY(0) scale(1); }
          50% { transform: translateY(0.3px) scale(1.01); }
        }
        @keyframes tailSwish {
          0%, 100% { transform: rotate(0deg); }
          50% { transform: rotate(2deg); }
        }
        @keyframes cryShake {
          0%, 100% { transform: translateY(0) rotate(0); }
          20% { transform: translateY(-1px) rotate(-3deg); }
          60% { transform: translateY(-0.5px) rotate(-2deg); }
        }
        @keyframes idleLook {
          0%, 70%, 100% { transform: translateY(0) rotate(0); }
          75% { transform: translateY(-0.3px) rotate(1.5deg); }
          85% { transform: translateY(-0.3px) rotate(1.5deg); }
          90% { transform: translateY(0) rotate(0); }
        }
        @keyframes idleBounce {
          0%, 85%, 100% { transform: translateY(0) scale(1); }
          88% { transform: translateY(-1.5px) scale(1.02); }
          92% { transform: translateY(0.3px) scale(0.99); }
        }
        @keyframes dinoWalk {
          0%, 100% { transform: translateX(0) translateY(0); }
          25% { transform: translateX(2px) translateY(-0.5px); }
          50% { transform: translateX(0) translateY(0); }
          75% { transform: translateX(-2px) translateY(-0.5px); }
        }
        @keyframes footprintFade {
          0% { opacity: 0.3; }
          100% { opacity: 0; }
        }
        @keyframes victoryDance {
          0%, 100% { transform: translateY(0) rotate(0) scale(1); }
          15% { transform: translateY(-8px) rotate(-5deg) scale(1.1); }
          30% { transform: translateY(0) rotate(3deg) scale(1.05); }
          45% { transform: translateY(-6px) rotate(-3deg) scale(1.08); }
          60% { transform: translateY(0) rotate(2deg) scale(1); }
          75% { transform: translateY(-3px) rotate(-1deg) scale(1.03); }
        }
        .breathe { animation: breathing 2.4s ease-in-out infinite; transform-origin: center; }
        .idle-look { animation: idleLook 5s ease-in-out infinite; transform-origin: 60% 50%; }
        .idle-bounce { animation: idleBounce 4s ease-in-out infinite; transform-origin: center bottom; }
        .cry-shake { animation: cryShake 0.6s ease-out; transform-origin: 70% 60%; }
      `}</style>

      {/* Ground shadow */}
      <ellipse cx={40} cy={52} rx={20} ry={3} fill="rgba(0,0,0,0.12)">
        <animate attributeName="rx" values="19;21;19" dur="2.4s" repeatCount="indefinite" />
      </ellipse>

      <g className={crying ? "cry-shake" : breathe}>
        {/* Aura for rare/high friendship dinos */}
        {(() => {
          const hasLeg = Object.values(build).some(idx => DINOS[idx]?.rarity === "legendary");
          const hasEpic = Object.values(build).some(idx => DINOS[idx]?.rarity === "epic");
          if (hasLeg) return <ellipse cx={40} cy={30} rx={22} ry={18} fill="none" stroke="#e8a020" strokeWidth={0.4} opacity={0.4} filter="url(#glowGold)"><animate attributeName="rx" values="20;24;20" dur="2.5s" repeatCount="indefinite" /><animate attributeName="opacity" values="0.3;0.6;0.3" dur="2.5s" repeatCount="indefinite" /></ellipse>;
          if (hasEpic) return <ellipse cx={40} cy={30} rx={20} ry={16} fill="none" stroke="#9050d0" strokeWidth={0.3} opacity={0.3} filter="url(#glowPurple)"><animate attributeName="rx" values="18;22;18" dur="3s" repeatCount="indefinite" /><animate attributeName="opacity" values="0.2;0.5;0.2" dur="3s" repeatCount="indefinite" /></ellipse>;
          return null;
        })()}
        {/* Tail - rendered first so body overlaps */}
        {renderTail(tailD.family, tailD.tail.power, tailD.tail.length,
          bodyX + 2, bodyY + 8, palette, backDorsalD.back.spikes)}

        {/* Back legs */}
        {posture === "quad" ? (
          <>
            <Sprite data={backLegSprite} x={bodyX + 20} y={bodyY + bodyH - 2} palette={palette} />
          </>
        ) : posture === "biped" ? (
          <Sprite data={backLegSprite} x={bodyX + 15} y={bodyY + bodyH - 2} palette={palette} />
        ) : posture === "flyer" ? (
          <Sprite data={backLegSprite} x={bodyX + 16} y={bodyY + bodyH - 1} palette={palette} />
        ) : (
          <Sprite data={backLegSprite} x={bodyX + 20} y={bodyY + bodyH - 2} palette={palette} />
        )}

        {/* Body */}
        <Sprite data={BODY_SPRITE} x={bodyX} y={bodyY} palette={palette} />
        {/* Pattern overlay on body */}
        {pattern && pattern !== "none" && (
          <rect x={bodyX + 3} y={bodyY + 2} width={bodyW - 6} height={bodyH - 4} rx={2}
            fill={`url(#pat-${pattern})`} />
        )}
        {/* Body shine highlight */}
        <rect x={bodyX + 3} y={bodyY + 1} width={bodyW - 6} height={bodyH - 2} rx={2}
          fill="url(#bodyShine)" opacity={0.6} />

        {/* Dorsal feature */}
        {renderDorsal(backDorsalD.family, backDorsalD.back.spikes, backDorsalD.back.armor,
          bodyX + 4, bodyY + 1, bodyW - 8, palette)}

        {/* Front legs/arms */}
        {posture === "quad" ? (
          <Sprite data={frontLegSprite} x={bodyX + 4} y={bodyY + bodyH - 2} palette={palette} />
        ) : posture === "biped" ? (
          <Sprite data={frontLegSprite} x={bodyX + 18} y={bodyY + 7} palette={palette} />
        ) : posture === "flyer" ? (
          <Sprite data={frontLegSprite} x={bodyX - 4} y={bodyY + 2} palette={palette} />
        ) : (
          <Sprite data={frontLegSprite} x={bodyX + 3} y={bodyY + bodyH - 3} palette={palette} />
        )}

        {/* Neck */}
        {neckPixels}

        {/* Head */}
        <Sprite data={headSprite} x={headX} y={headY} palette={palette} />

        {/* Teeth inside head mouth area */}
        {renderTeeth(headD.family, teethD.teeth.count, teethD.teeth.sharp,
          headX + headOff.x + 2, headY + headSprite.length - 3,
          headSprite[0].length - headOff.x - 4, palette)}
      </g>
    </svg>
  );
}

function shadeColor(hex, percent) {
  const num = parseInt(hex.replace("#", ""), 16);
  const r = Math.max(0, Math.min(255, (num >> 16) + percent));
  const g = Math.max(0, Math.min(255, ((num >> 8) & 0xff) + percent));
  const b = Math.max(0, Math.min(255, (num & 0xff) + percent));
  return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
}

// ============ Part contribution helpers ============
// Returns a short text describing what a dino brings to a given part slot
function describePartContribution(dinoIdx, partKey) {
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
function partContributesTo(partKey) {
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
const FAMILY_INTELLIGENCE = {
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
function computeStats(build) {
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

// ============ Main App ============
// ============ ELEMENTAL TYPES ============
// Each dino family has a dominant type. Type chart gives multipliers.
const FAMILY_TYPES = {
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
const TYPE_CHART = {
  feu:    { nature: 1.5, vent: 1.5, eau: 0.7, pierre: 0.7 },
  eau:    { feu: 1.5, terre: 1.5, vent: 0.7, nature: 0.7 },
  terre:  { pierre: 1.5, feu: 1.5, vent: 0.7, nature: 0.7 },
  vent:   { nature: 1.5, eau: 1.5, feu: 0.7, pierre: 0.7 },
  pierre: { vent: 1.5, nature: 1.5, eau: 0.7, feu: 0.7 },
  nature: { pierre: 1.5, terre: 1.5, feu: 0.7, vent: 0.7 },
};
const TYPE_EMOJI = { feu: "🔥", eau: "💧", terre: "🌍", vent: "💨", pierre: "🪨", nature: "🌿" };

function getBuildType(build) { return FAMILY_TYPES[DINOS[build.head].family] || "terre"; }
function getTypeMult(attackerType, defenderType) {
  return TYPE_CHART[attackerType]?.[defenderType] || 1;
}

// ============ WEATHER ============
const WEATHERS = [
  { key: "clear", name: "Soleil", emoji: "☀️", boosts: { feu: 1.15, vent: 1.1 } },
  { key: "rain", name: "Pluie", emoji: "🌧️", boosts: { eau: 1.2, feu: 0.85 } },
  { key: "storm", name: "Orage", emoji: "⛈️", boosts: { vent: 1.2, eau: 1.1 } },
  { key: "fog", name: "Brume", emoji: "🌫️", boosts: {} },
  { key: "snow", name: "Neige", emoji: "❄️", boosts: { eau: 0.9, feu: 0.9, pierre: 1.1 } },
];

// ============ ADVENTURE ZONES ============
const ZONES = [
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
const TRAITS = [
  { key: "sanguinaire", name: "Sanguinaire", emoji: "🩸", desc: "+20% dégâts critiques, +10% chance de critique" },
  { key: "resistant", name: "Résistant", emoji: "🛡️", desc: "+15% PV max, récupère 5 PV par tour" },
  { key: "ruse", name: "Rusé", emoji: "🧠", desc: "+2 Intelligence, chance d'esquive doublée" },
  { key: "fureur", name: "Fureur", emoji: "😤", desc: "Sous 30% PV : +40% dégâts (mode Rage)" },
  { key: "endurant", name: "Endurant", emoji: "💪", desc: "+1 utilisation à toutes les attaques" },
];

// ============ ITEMS ============
const ITEMS = {
  heal: { name: "Fougère Curative", emoji: "🌿", desc: "Soigne 40% des PV max", effect: "heal" },
  antidote: { name: "Sève Purifiante", emoji: "💧", desc: "Supprime tous les statuts", effect: "antidote" },
  boost: { name: "Baie Féroce", emoji: "🍇", desc: "+50% dégâts pendant 2 tours", effect: "boost" },
  food: { name: "Viande Séchée", emoji: "🍖", desc: "Nourris ton dino (+35% faim)", effect: "food" },
};

// ============ ACHIEVEMENTS ============
// ============ PALEO ENCYCLOPEDIA ============
const DINO_FACTS = {
  "Tyrannosaurus Rex": { size: "12m", weight: "8t", diet: "Carnivore", era: "Crétacé sup. (68-66 Ma)", loc: "Amérique du Nord", facts: ["Sa morsure est la plus puissante de tous les animaux terrestres : 6 tonnes de pression", "Ses minuscules bras pouvaient soulever 200 kg chacun", "Son odorat était aussi développé que celui d'un vautour"] },
  "Velociraptor": { size: "2m", weight: "15kg", diet: "Carnivore", era: "Crétacé sup. (75-71 Ma)", loc: "Mongolie", facts: ["Il était entièrement couvert de plumes", "Sa griffe rétractile mesurait 6.5 cm et servait à poignarder", "Il avait la taille d'un dindon, pas d'un humain comme au cinéma"] },
  "Triceratops": { size: "9m", weight: "12t", diet: "Herbivore", era: "Crétacé sup. (68-66 Ma)", loc: "Amérique du Nord", facts: ["Ses 3 cornes pouvaient mesurer 1 mètre", "Sa collerette osseuse servait à réguler sa température", "On a trouvé des fossiles avec des marques de morsure de T-Rex"] },
  "Brachiosaurus": { size: "26m", weight: "56t", diet: "Herbivore", era: "Jurassique sup. (154-150 Ma)", loc: "Amérique du Nord, Afrique", facts: ["Il pouvait lever la tête à 13 mètres de hauteur", "Son cœur pesait environ 200 kg pour pomper le sang jusqu'au cerveau", "Il avalait des pierres (gastrolithes) pour broyer les plantes dans son estomac"] },
  "Stegosaurus": { size: "9m", weight: "5t", diet: "Herbivore", era: "Jurassique sup. (155-150 Ma)", loc: "Amérique du Nord", facts: ["Son cerveau faisait la taille d'une noix (80g) pour un corps de 5 tonnes", "Ses plaques dorsales étaient remplies de vaisseaux sanguins pour réguler sa chaleur", "Sa queue armée de pointes s'appelle un thagomizer"] },
  "Spinosaurus": { size: "15m", weight: "7t", diet: "Piscivore", era: "Crétacé (99-93 Ma)", loc: "Afrique du Nord", facts: ["C'est le plus grand carnivore terrestre jamais découvert, plus grand que le T-Rex", "Il vivait en semi-aquatique et chassait les poissons comme un crocodile", "Sa voile dorsale pouvait atteindre 1.8 m de haut"] },
  "Allosaurus": { size: "9m", weight: "2t", diet: "Carnivore", era: "Jurassique sup. (155-145 Ma)", loc: "Amérique du Nord", facts: ["C'était le prédateur dominant du Jurassique, 80 millions d'années avant le T-Rex", "Il chassait probablement en embuscade et utilisait sa mâchoire comme une hache", "On a trouvé des traces de morsures d'Allosaurus sur des os de Stegosaurus"] },
  "Ankylosaurus": { size: "8m", weight: "6t", diet: "Herbivore", era: "Crétacé sup. (68-66 Ma)", loc: "Amérique du Nord", facts: ["Même ses paupières étaient blindées avec des plaques osseuses", "Sa massue caudale pouvait briser les os d'un T-Rex d'un seul coup", "Son armure était faite d'ostéodermes fusionnés à la peau"] },
  "Diplodocus": { size: "27m", weight: "15t", diet: "Herbivore", era: "Jurassique sup. (154-152 Ma)", loc: "Amérique du Nord", facts: ["Sa queue de 14 m pouvait claquer comme un fouet supersonique", "Il ne mâchait pas sa nourriture, il arrachait les feuilles et les avalait", "Malgré sa taille, il était relativement léger grâce à ses os creux"] },
  "Parasaurolophus": { size: "10m", weight: "2.5t", diet: "Herbivore", era: "Crétacé sup. (76-73 Ma)", loc: "Amérique du Nord", facts: ["Sa crête creuse de 1.8 m amplifiait ses cris comme un trombone géant", "Il pouvait marcher sur 2 ou 4 pattes selon la situation", "Les scientifiques ont reconstitué le son de sa crête : un grondement grave"] },
  "Pteranodon": { size: "7m envergure", weight: "25kg", diet: "Piscivore", era: "Crétacé sup. (86-84 Ma)", loc: "Amérique du Nord", facts: ["Ce n'est PAS un dinosaure mais un reptile volant (ptérosaure)", "Il planait au-dessus des océans et plongeait pour attraper des poissons", "Sa crête osseuse servait de gouvernail et de stabilisateur en vol"] },
  "Carnotaurus": { size: "8m", weight: "1.5t", diet: "Carnivore", era: "Crétacé sup. (72-69 Ma)", loc: "Argentine", facts: ["Ses bras étaient encore plus petits et inutiles que ceux du T-Rex", "Ses cornes au-dessus des yeux sont uniques chez les dinosaures carnivores", "C'était un sprinter : il pouvait atteindre 56 km/h"] },
  "Iguanodon": { size: "10m", weight: "4t", diet: "Herbivore", era: "Crétacé inf. (140-110 Ma)", loc: "Europe", facts: ["C'est l'un des tout premiers dinosaures découverts en 1825", "Son pouce en forme de poignard servait à se défendre", "On a d'abord cru que son pouce était une corne de nez !"] },
  "Compsognathus": { size: "1m", weight: "3kg", diet: "Carnivore", era: "Jurassique sup. (150 Ma)", loc: "Europe", facts: ["Un des plus petits dinosaures connus, de la taille d'une poule", "Il chassait des lézards et des insectes", "Son fossile en Allemagne est l'un des mieux conservés au monde"] },
  "Pachycephalosaurus": { size: "5m", weight: "450kg", diet: "Herbivore", era: "Crétacé sup. (70-66 Ma)", loc: "Amérique du Nord", facts: ["Son dôme crânien avait 25 cm d'épaisseur d'os solide", "Il se battait probablement en donnant des coups de tête comme les béliers", "Des études récentes montrent qu'il chargeait peut-être flanc contre flanc"] },
  "Gallimimus": { size: "6m", weight: "440kg", diet: "Omnivore", era: "Crétacé sup. (70 Ma)", loc: "Mongolie", facts: ["Il pouvait courir jusqu'à 60 km/h, comme une autruche géante", "Son bec édenté filtrait peut-être l'eau pour attraper des petits animaux", "Son nom signifie 'qui imite la poule'"] },
  "Dilophosaurus": { size: "6m", weight: "400kg", diet: "Carnivore", era: "Jurassique inf. (193 Ma)", loc: "Amérique du Nord", facts: ["Il n'avait PAS de collerette ni de venin — c'est une invention du film", "Ses deux crêtes osseuses servaient à la parade nuptiale", "C'était l'un des tout premiers grands dinosaures prédateurs"] },
  "Therizinosaurus": { size: "10m", weight: "5t", diet: "Herbivore", era: "Crétacé sup. (70 Ma)", loc: "Mongolie", facts: ["Ses griffes de 70 cm sont les plus longues de tous les animaux", "Malgré ses griffes terrifiantes, il était herbivore et mangeait des plantes", "Il est apparenté aux raptors malgré son look complètement différent"] },
  "Mosasaurus": { size: "17m", weight: "15t", diet: "Carnivore", era: "Crétacé sup. (82-66 Ma)", loc: "Océans mondiaux", facts: ["Ce n'est pas un dinosaure mais un lézard marin géant", "Il avait une double rangée de dents au palais pour empêcher les proies de s'échapper", "Il régnait sur les océans comme le T-Rex sur la terre"] },
  "Plesiosaurus": { size: "3.5m", weight: "500kg", diet: "Piscivore", era: "Jurassique (199 Ma)", loc: "Europe", facts: ["Ce n'est pas un dinosaure mais un reptile marin", "Il a inspiré la légende du monstre du Loch Ness", "Son long cou lui permettait d'attraper des poissons par surprise"] },
  "Archaeopteryx": { size: "50cm", weight: "1kg", diet: "Carnivore", era: "Jurassique sup. (150 Ma)", loc: "Allemagne", facts: ["C'est le chaînon entre les dinosaures et les oiseaux modernes", "Il avait des plumes mais aussi des dents et des griffes aux ailes", "Son fossile est l'un des plus importants de l'histoire de la paléontologie"] },
  "Microraptor": { size: "80cm", weight: "1kg", diet: "Carnivore", era: "Crétacé inf. (120 Ma)", loc: "Chine", facts: ["Il avait 4 ailes et pouvait planer d'arbre en arbre", "Ses plumes irisées brillaient en bleu-noir comme celles d'un corbeau", "C'est la preuve que les dinosaures à plumes pouvaient voler"] },
  "Giganotosaurus": { size: "13m", weight: "8t", diet: "Carnivore", era: "Crétacé (99-97 Ma)", loc: "Argentine", facts: ["Légèrement plus grand que le T-Rex mais avec une mâchoire moins puissante", "Il chassait probablement en groupe les titanosaures géants", "Son cerveau était en forme de banane et plus petit que celui du T-Rex"] },
  "Utahraptor": { size: "7m", weight: "500kg", diet: "Carnivore", era: "Crétacé inf. (135-130 Ma)", loc: "Amérique du Nord", facts: ["C'est le plus grand raptor connu, 3× la taille du Velociraptor de JP", "Ses griffes de 24 cm pouvaient éventrer de grandes proies", "Il est apparu 60 millions d'années AVANT le Velociraptor"] },
  "Deinonychus": { size: "3.4m", weight: "80kg", diet: "Carnivore", era: "Crétacé inf. (115-108 Ma)", loc: "Amérique du Nord", facts: ["Son nom signifie 'griffe terrible' en grec", "C'est lui qui a inspiré les raptors de Jurassic Park, pas le Velociraptor", "Sa découverte a révolutionné l'image des dinosaures comme animaux actifs"] },
  "Apatosaurus": { size: "21m", weight: "20t", diet: "Herbivore", era: "Jurassique sup. (152-151 Ma)", loc: "Amérique du Nord", facts: ["Autrefois appelé Brontosaure (le nom a été rétabli en 2015)", "Sa queue claquait comme un fouet pour effrayer les prédateurs", "Un bébé Apatosaurus grandissait de 5 tonnes par an"] },
  "Kentrosaurus": { size: "5m", weight: "1.5t", diet: "Herbivore", era: "Jurassique sup. (155-150 Ma)", loc: "Tanzanie", facts: ["Cousin du Stégosaure mais avec des épines au lieu de plaques", "Ses épines dorsales et caudales étaient redoutables en défense", "Il vivait en troupeaux dans les plaines africaines"] },
  "Euoplocephalus": { size: "6m", weight: "2t", diet: "Herbivore", era: "Crétacé sup. (76-70 Ma)", loc: "Amérique du Nord", facts: ["Un vrai char blindé : même ses paupières étaient des plaques d'os", "Sa massue caudale pesait 30 kg et servait de masse d'arme", "Il avait des narines compliquées qui réchauffaient l'air avant les poumons"] },
  "Corythosaurus": { size: "9m", weight: "4t", diet: "Herbivore", era: "Crétacé sup. (77-75 Ma)", loc: "Amérique du Nord", facts: ["Sa crête en forme de casque grec résonnait pour communiquer", "On a trouvé des fossiles avec la peau encore préservée", "Il vivait en immenses troupeaux dans les forêts côtières"] },
  "Maiasaura": { size: "9m", weight: "3t", diet: "Herbivore", era: "Crétacé sup. (77-75 Ma)", loc: "Amérique du Nord", facts: ["Son nom signifie 'bonne mère lézard'", "Premier dinosaure prouvé à prendre soin de ses bébés après l'éclosion", "On a trouvé des nids avec des bébés de différents âges ensemble"] },
  "Oviraptor": { size: "2m", weight: "35kg", diet: "Omnivore", era: "Crétacé sup. (75 Ma)", loc: "Mongolie", facts: ["Accusé à tort de voler des œufs — il couvait les siens !", "Son bec puissant broyait des coquillages et des noix", "Un fossile le montre mort en protégeant son nid d'une tempête de sable"] },
  "Troodon": { size: "2.4m", weight: "50kg", diet: "Carnivore", era: "Crétacé sup. (77-66 Ma)", loc: "Amérique du Nord", facts: ["Considéré comme le dinosaure le plus intelligent (ratio cerveau/corps)", "Ses grands yeux suggèrent qu'il chassait la nuit", "Ses dents étaient dentelées comme un couteau à steak"] },
  "Quetzalcoatlus": { size: "11m envergure", weight: "250kg", diet: "Carnivore", era: "Crétacé sup. (70-66 Ma)", loc: "Amérique du Nord", facts: ["Un des plus grands animaux volants de tous les temps, grand comme une girafe", "Il pouvait parcourir 16000 km sans se poser, comme un avion", "Il marchait sur ses ailes repliées au sol, comme une chauve-souris géante"] },
  "Suchomimus": { size: "11m", weight: "4t", diet: "Piscivore", era: "Crétacé inf. (121-112 Ma)", loc: "Niger", facts: ["Son museau de crocodile attrapait les poissons dans les rivières", "Cousin du Spinosaure mais sans la grande voile dorsale", "Ses griffes de 30 cm servaient à harponner les poissons"] },
  "Baryonyx": { size: "9m", weight: "2t", diet: "Piscivore", era: "Crétacé inf. (130-125 Ma)", loc: "Angleterre", facts: ["Son nom signifie 'griffe lourde' à cause de sa griffe de 30 cm", "On a trouvé des écailles de poisson fossilisées dans son estomac", "Découvert par un chasseur de fossiles amateur en 1983"] },
  "Megalosaurus": { size: "9m", weight: "1.4t", diet: "Carnivore", era: "Jurassique moy. (166 Ma)", loc: "Europe", facts: ["Premier dinosaure scientifiquement nommé en 1824", "Pendant 100 ans, TOUS les grands théropodes étaient classés comme Megalosaurus", "Son nom signifie 'grand lézard' en grec"] },
  "Ceratosaurus": { size: "6m", weight: "700kg", diet: "Carnivore", era: "Jurassique sup. (153-148 Ma)", loc: "Amérique du Nord", facts: ["Sa petite corne nasale le distingue de tous les autres théropodes", "Il avait des ostéodermes (plaques osseuses) le long du dos", "Il coexistait avec l'Allosaurus mais était plus petit et plus rare"] },
  "Yutyrannus": { size: "9m", weight: "1.4t", diet: "Carnivore", era: "Crétacé inf. (125 Ma)", loc: "Chine", facts: ["Plus grand dinosaure connu entièrement couvert de plumes", "Preuve que même les grands tyrannosaures avaient des plumes", "Ses plumes mesuraient jusqu'à 20 cm et servaient d'isolation thermique"] },
  "Sinosauropteryx": { size: "1m", weight: "1kg", diet: "Carnivore", era: "Crétacé inf. (125 Ma)", loc: "Chine", facts: ["Premier dinosaure dont on a reconstitué la vraie couleur : roux et blanc", "Sa queue avait des rayures alternées oranges et blanches", "Il avait un 'masque de bandit' sombre autour des yeux pour réduire l'éblouissement"] },
  "Concavenator": { size: "6m", weight: "500kg", diet: "Carnivore", era: "Crétacé inf. (130 Ma)", loc: "Espagne", facts: ["Il avait une bosse triangulaire bizarre sur le dos, comme un aileron de requin", "Des indices de proto-plumes ont été trouvés sur ses bras", "C'est un dinosaure européen, découvert en Espagne en 2010"] },
  "Amargasaurus": { size: "10m", weight: "2.6t", diet: "Herbivore", era: "Crétacé inf. (129 Ma)", loc: "Argentine", facts: ["Double rangée d'épines de 60 cm le long du cou et du dos", "Ces épines portaient peut-être une voile de peau colorée pour la parade", "C'est l'un des sauropodes les plus reconnaissables visuellement"] },
  "Mamenchisaurus": { size: "26m", weight: "25t", diet: "Herbivore", era: "Jurassique sup. (160-145 Ma)", loc: "Chine", facts: ["Son cou de 11 mètres est le plus long de tous les dinosaures", "Son cou avait 19 vertèbres (un humain en a 7)", "Il ne pouvait probablement pas lever la tête très haut malgré son cou géant"] },
  "Argentinosaurus": { size: "35m", weight: "80t", diet: "Herbivore", era: "Crétacé sup. (96-92 Ma)", loc: "Argentine", facts: ["Probablement le plus grand dinosaure ayant jamais existé : 80 tonnes", "Une seule de ses vertèbres mesurait 1.59 m de haut", "Un bébé Argentinosaurus pesait 5 kg à la naissance et 80 tonnes adulte"] },
  "Saltasaurus": { size: "12m", weight: "7t", diet: "Herbivore", era: "Crétacé sup. (70 Ma)", loc: "Argentine", facts: ["Sauropode inhabituel : sa peau était couverte de plaques osseuses défensives", "Il vivait en troupeaux et pondait ses œufs en groupe", "C'est un des rares grands herbivores avec une armure naturelle"] },
  "Protoceratops": { size: "1.8m", weight: "80kg", diet: "Herbivore", era: "Crétacé sup. (74 Ma)", loc: "Mongolie", facts: ["On a trouvé un fossile montrant un combat mortel entre lui et un Velociraptor", "Sa collerette osseuse était peut-être colorée pour la parade", "Il a probablement inspiré les légendes de griffons en Asie centrale"] },
  "Styracosaurus": { size: "5.5m", weight: "3t", diet: "Herbivore", era: "Crétacé sup. (75 Ma)", loc: "Amérique du Nord", facts: ["6 longues pointes jaillissaient de sa collerette, parfaites pour intimider", "Sa corne nasale mesurait 60 cm", "Il vivait en troupeaux et les mâles se battaient probablement pour les femelles"] },
  "Pentaceratops": { size: "8m", weight: "5t", diet: "Herbivore", era: "Crétacé sup. (76-73 Ma)", loc: "Amérique du Nord", facts: ["Son crâne de 3 m est un des plus grands de tout le règne animal", "Son nom signifie 'face à 5 cornes' mais il n'en avait que 3 vraies", "Les 2 'cornes' supplémentaires sont en fait des pointes des joues"] },
  "Edmontosaurus": { size: "13m", weight: "4t", diet: "Herbivore", era: "Crétacé sup. (73-66 Ma)", loc: "Amérique du Nord", facts: ["Il vivait en troupeaux immenses de milliers d'individus comme les bisons", "On a trouvé un fossile momifié avec la peau encore intacte", "Certains avaient une crête charnue comme un coq géant"] },
  "Acrocanthosaurus": { size: "11m", weight: "6t", diet: "Carnivore", era: "Crétacé inf. (116-110 Ma)", loc: "Amérique du Nord", facts: ["Ses épines dorsales soutenaient une bosse musclée comme un bison", "Il était le prédateur apex de son époque, avant le T-Rex", "On a trouvé ses empreintes à côté de celles de sauropodes géants"] },
  "Cryolophosaurus": { size: "6.5m", weight: "500kg", diet: "Carnivore", era: "Jurassique inf. (194-188 Ma)", loc: "Antarctique", facts: ["Premier grand dinosaure découvert en Antarctique", "Surnommé 'Elvisaurus' à cause de sa crête qui ressemble à la coiffure d'Elvis", "L'Antarctique était une forêt tempérée à son époque"] },
  "Indominus": { size: "15m", weight: "?", diet: "Carnivore", era: "Hybride artificiel", loc: "Laboratoire", facts: ["Hybride créé en laboratoire à partir de multiples ADN", "Capable de camoufler sa signature thermique", "Son intelligence dépasse celle de tout dinosaure naturel"] },
  "Dino Fantôme": { size: "?", weight: "?", diet: "Inconnu", era: "Mystère", loc: "Dimension spectrale", facts: ["Apparaît et disparaît sans laisser de traces", "Capable de traverser la matière solide", "Certains pensent qu'il est l'esprit d'un dinosaure disparu"] },
  "Titanocristal": { size: "20m", weight: "30t", diet: "Minéralivore", era: "Mystère", loc: "Grottes profondes", facts: ["Son corps est partiellement cristallisé, ce qui le rend extrêmement résistant", "Il se nourrit de minéraux et de cristaux souterrains", "Sa peau réfracte la lumière en arc-en-ciel"] },
  "Pyroraptor": { size: "2.5m", weight: "50kg", diet: "Carnivore", era: "Crétacé sup. (70 Ma)", loc: "France", facts: ["Découvert après un incendie de forêt qui a révélé ses fossiles", "Son nom signifie 'voleur de feu' à cause de cette découverte", "C'est un des rares dinosaures découverts en France"] },
  "Noctosaurus": { size: "4m envergure", weight: "5kg", diet: "Piscivore", era: "Mystère", loc: "Cieux nocturnes", facts: ["Ses yeux géants lui permettent de voir dans l'obscurité totale", "Il chasse exclusivement la nuit, guidé par l'écholocation", "Ses ailes bioluminescentes brillent dans le noir"] },
  "Venomjaw": { size: "12m", weight: "5t", diet: "Carnivore", era: "Hybride", loc: "Jungles toxiques", facts: ["Sa morsure injecte un venin paralysant unique", "Ses crochets sont creux comme ceux d'un serpent", "Il peut sentir une proie à 5 km grâce à ses capteurs chimiques"] },
  "Glaciodonte": { size: "8m", weight: "4t", diet: "Herbivore", era: "Mystère", loc: "Glaciers éternels", facts: ["Son sang contient un antigel naturel qui lui permet de survivre à -50°C", "Sa fourrure de glace repousse les prédateurs", "Il peut congeler l'eau autour de lui pour se créer une armure"] },
  "Ombrecorne": { size: "7m", weight: "5t", diet: "Herbivore", era: "Mystère", loc: "Forêts obscures", facts: ["Ses cornes absorbent la lumière, créant des zones d'ombre autour de lui", "Quasiment invisible dans les forêts denses", "Sa collerette émet des ondes infrarouges pour communiquer en silence"] },
  "Infernodonte": { size: "14m", weight: "9t", diet: "Carnivore", era: "Hybride", loc: "Volcans actifs", facts: ["Sa peau est recouverte de plaques de basalte refroidi", "Il peut nager dans la lave grâce à sa peau ignifugée", "Ses rugissements provoquent des micro-séismes"] },
  "Aquaspino": { size: "13m", weight: "6t", diet: "Piscivore", era: "Hybride", loc: "Abysses marines", facts: ["Sa voile dorsale fonctionne comme un sonar sous-marin", "Il peut rester en apnée pendant 2 heures", "Ses nageoires sont d'anciennes pattes transformées par l'évolution"] },
  "Tempêtaile": { size: "9m envergure", weight: "150kg", diet: "Carnivore", era: "Mystère", loc: "Nuages d'orage", facts: ["Ses ailes génèrent de l'électricité statique en vol", "Il vit en permanence dans les nuages d'orage", "Un seul battement d'aile peut déclencher un éclair"] },
  "Astérodon": { size: "30m", weight: "60t", diet: "Herbivore", era: "Hybride", loc: "Cratères d'impact", facts: ["Né dans un cratère d'astéroïde, son ADN contient des minéraux extraterrestres", "Ses os sont renforcés d'iridium, le métal des météorites", "Il brille doucement dans le noir grâce à la radioactivité naturelle"] },
  "Spectrodon": { size: "3m", weight: "40kg", diet: "Énergivore", era: "Mystère", loc: "Entre les dimensions", facts: ["Il existe simultanément dans plusieurs dimensions", "Son corps est partiellement transparent et change de couleur", "Personne ne sait exactement ce qu'il mange"] },
  "Fulguroraptor": { size: "4m", weight: "120kg", diet: "Carnivore", era: "Hybride", loc: "Plaines orageuses", facts: ["Sa vitesse dépasse les 120 km/h pendant de courtes pointes", "Son plumage conduit l'électricité sans le blesser", "Il peut charger ses griffes d'électricité pour paralyser ses proies"] },
  "Titanosaure d'Or": { size: "35m", weight: "90t", diet: "Herbivore", era: "Légendaire", loc: "Temple caché", facts: ["Le plus rare de tous les dinosaures, un seul spécimen a jamais été aperçu", "Ses écailles dorées sont en réalité un alliage organique inconnu de la science", "On raconte que le voir porte chance pour 1000 ans"] },
};

function getDinoFacts(dinoName) {
  if (DINO_FACTS[dinoName]) return DINO_FACTS[dinoName];
  // Partial match fallback
  for (const [key, val] of Object.entries(DINO_FACTS)) {
    if (dinoName.includes(key.split(" ")[0]) || key.includes(dinoName.split(" ")[0])) return val;
  }
  return null;
}


// ============ FOSSIL PUZZLE DATA ============
const FOSSIL_PIECES = [
  { id: "skull", label: "Crâne", x: 62, y: 12, svg: "M72,22 Q67,12 62,16 L62,28 Q67,32 77,32 Q82,32 85,28 L85,16 Q82,12 77,14 Z M67,20 a2,2 0 1,0 0.1,0 M78,20 a2,2 0 1,0 0.1,0" },
  { id: "spine", label: "Colonne", x: 30, y: 18, svg: "M32,22 L62,22 M32,24 L62,24 M37,20 L37,26 M42,20 L42,26 M47,20 L47,26 M52,20 L52,26 M57,20 L57,26" },
  { id: "ribs", label: "Côtes", x: 35, y: 26, svg: "M40,28 Q35,35 38,42 M45,28 Q38,36 42,44 M50,28 Q42,37 46,46 M55,28 Q47,38 50,46" },
  { id: "legs", label: "Pattes", x: 35, y: 44, svg: "M40,46 L40,62 L44,65 M42,46 L42,62 L46,65 M52,46 L52,62 L56,65 M54,46 L54,62 L58,65" },
  { id: "tail", label: "Queue", x: 5, y: 18, svg: "M30,22 Q22,20 15,22 Q10,24 8,28 Q6,30 8,28 M30,24 Q22,22 15,24 Q10,26 8,30" },
];

const ACHIEVEMENTS = [
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
const EQUIPMENT_LIST = [
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
const QUIZ_QUESTIONS = [
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
const RIVAL_NAME = "L'Ombre Noire";
const RIVAL_APPEARANCES = [1, 3, 5, 7, 9]; // zone indices where rival appears
const RIVAL_DIALOGUES = [
  "Tiens, tiens... Un nouveau venu. Tu ne feras pas long feu.",
  "Encore toi ? Tu es plus tenace que je ne pensais.",
  "Je dois admettre, tu as progressé. Mais pas assez.",
  "Cette fois, je ne retiendrai pas mes coups.",
  "Le combat final. Que le plus fort survive.",
];

// ============ SKIN PATTERNS ============
const PATTERNS = [
  { key: "none", name: "Uni", emoji: "⬜" },
  { key: "stripes", name: "Rayures", emoji: "🦓" },
  { key: "spots", name: "Taches", emoji: "🐆" },
  { key: "camo", name: "Camouflage", emoji: "🌿" },
];

// ============ NAME GENERATOR ============
// Generate a Latin-sounding name from the build's composition
const NAME_PREFIXES = {
  head: { tyrant: "Tyranno", spino: "Spino", raptor: "Velo", sauropod: "Brachio",
    ceratopsian: "Cerato", armored: "Anky", hadrosaur: "Para", flyer: "Ptero", marine: "Mosa" },
  teeth: { tyrant: "rex", spino: "dens", raptor: "raptor", sauropod: "lithos",
    ceratopsian: "ceros", armored: "saurus", hadrosaur: "lophus", flyer: "don", marine: "saurus" },
  back: { tyrant: "rex", spino: "spinax", raptor: "agilis", sauropod: "magnus",
    ceratopsian: "ceros", armored: "tholos", hadrosaur: "cristus", flyer: "alatus", marine: "natans" },
  tail: { tyrant: "caudus", spino: "natator", raptor: "rapax", sauropod: "longus",
    ceratopsian: "tauros", armored: "claviger", hadrosaur: "cantor", flyer: "volans", marine: "fluctus" },
};

function generateName(build) {
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

// ============ ENEMY GENERATOR ============
function generateEnemy(playerStats) {
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
function computeHP(stats, trait, hpBonus = 0) {
  let hp = Math.round(40 + stats.defense * 6 + stats.taille * 4) + hpBonus;
  if (trait === "resistant") hp = Math.round(hp * 1.15);
  return hp;
}

// Apply level bonus to stats (10% per level above 1)
function statsWithLevel(stats, level) {
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

const BASIC_ATTACKS = [
  { key: "morsure", label: "Morsure", uses: ["attaque"], emoji: "🦷", desc: "plante ses crocs", basePower: 1.0, maxUses: 4 },
  { key: "charge", label: "Charge", uses: ["force", "vitesse"], emoji: "💥", desc: "fonce tête baissée", basePower: 1.1, maxUses: 3 },
  { key: "queue", label: "Coup de queue", uses: ["force"], emoji: "🌀", desc: "balaie de la queue", basePower: 1.0, maxUses: 4 },
  { key: "griffes", label: "Griffes", uses: ["attaque", "vitesse"], emoji: "🗡️", desc: "lacère avec ses griffes", basePower: 1.0, maxUses: 4 },
];

// Special attacks unlocked by specific part families
const SPECIAL_ATTACKS = {
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
function getMaxUses(attack, stats, trait) {
  const base = attack.maxUses || 3;
  const traitBonus = trait === "endurant" ? 1 : 0;
  if (attack.special) return base + traitBonus;
  const enduranceBonus = Math.min(2, Math.floor((stats.taille + stats.force) / 8));
  return base + enduranceBonus + traitBonus;
}

function getAvailableAttacks(build) {
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

const STATUS_EFFECTS = {
  saigne: { label: "Saignement", emoji: "🩸", dmgPerTurn: 4, duration: 3, color: "#cc2020" },
  etourdi: { label: "Étourdi", emoji: "💫", skipTurn: true, duration: 1, color: "#f5c838" },
  terrifie: { label: "Terrifié", emoji: "😱", dmgMult: 0.5, duration: 2, color: "#a838c8" },
};

function computeAttack(attacker, defender, attackType, extras = {}) {
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
const TOURNAMENT_TIERS = [
  { name: "Apprenti", powerMult: 0.7, color: "#7a8a3a" },
  { name: "Vétéran", powerMult: 0.9, color: "#8a6a3a" },
  { name: "Champion", powerMult: 1.1, color: "#8a4a3a" },
  { name: "Légendaire", powerMult: 1.3, color: "#6a3a7a" },
  { name: "Apex", powerMult: 1.6, color: "#4a4a5a" },
];

// Combat environments
const ENVIRONMENTS = [
  { key: "jungle", name: "Jungle Crétacée", emoji: "🌴", bg: "linear-gradient(180deg, #5a7a3a 0%, #2a4a1a 100%)", ground: "#3a4a1a" },
  { key: "desert", name: "Désert Aride", emoji: "🏜️", bg: "linear-gradient(180deg, #c89858 0%, #8a6838 100%)", ground: "#7a5828" },
  { key: "marsh", name: "Marais Brumeux", emoji: "🌫️", bg: "linear-gradient(180deg, #5a6a7a 0%, #2a3a4a 100%)", ground: "#3a4a3a" },
  { key: "volcanic", name: "Plaine Volcanique", emoji: "🌋", bg: "linear-gradient(180deg, #6a3a3a 0%, #2a1a1a 100%)", ground: "#4a2828" },
  { key: "coast", name: "Côte Préhistorique", emoji: "🌊", bg: "linear-gradient(180deg, #4a8aaa 0%, #2a4a6a 100%)", ground: "#5a7a8a" },
];




// ============ PERSISTENCE LAYER ============
const STORAGE_KEY = "cabinet-de-chloe-v1";
const hasStorage = (() => {
  try {
    if (typeof window === "undefined" || !window.localStorage) return false;
    window.localStorage.setItem("__test", "1");
    window.localStorage.removeItem("__test");
    return true;
  } catch (e) { return false; }
})();

function loadSave() {
  if (!hasStorage) return null;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch (e) { return null; }
}

function writeSave(data) {
  if (!hasStorage) return;
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch (e) {}
}

export default function DinoBuilder() {
  // Load saved data once at startup
  const savedData = useMemo(() => loadSave() || {}, []);

  const [build, setBuild] = useState(savedData.build || {
    head: 0, teeth: 0, frontLegs: 0, backLegs: 0, back: 0, tail: 0, color: 0,
  });
  const [activePart, setActivePart] = useState("head");
  const [crying, setCrying] = useState(false);
  const [name, setName] = useState(savedData.name || "Mon Hybride");
  const [saved, setSaved] = useState(savedData.saved || []);
  const [view, setView] = useState("splash"); // splash | build | gallery | battle | bestiary | adventure | book
  const [showSplash, setShowSplash] = useState(true);
  const [enemy, setEnemy] = useState(null);
  const [battleState, setBattleState] = useState({ playerHP: 100, enemyHP: 100, log: [], turn: "player", finished: false, winner: null });
  const [attackAnim, setAttackAnim] = useState(null); // {who: "player"|"enemy", type: "attack"|"hit"}
  const [floatingDmg, setFloatingDmg] = useState(null);
  const [screenFlash, setScreenFlash] = useState(null);
  const [lightningBolt, setLightningBolt] = useState(false);
  const [dustPuffs, setDustPuffs] = useState(0);
  const [viewTransition, setViewTransition] = useState(null); // {from, to}
  const [gyroTilt, setGyroTilt] = useState({ x: 0, y: 0 });
  const [screenShake, setScreenShake] = useState(false);
  const logRef = useRef(null);
  const [level, setLevel] = useState(savedData.level || 1);
  const [xp, setXp] = useState(savedData.xp || 0);
  const [tournament, setTournament] = useState(null); // {tier: 0-4, wins: 0}
  const [bestiary, setBestiary] = useState(savedData.bestiary || {});
  const [environment, setEnvironment] = useState(ENVIRONMENTS[0]);
  const [playerStatus, setPlayerStatus] = useState(null); // {type, turnsLeft}
  const [enemyStatus, setEnemyStatus] = useState(null);
  const [playerCooldowns, setPlayerCooldowns] = useState({}); // {attackKey: turnsLeft}
  const [enemyCooldowns, setEnemyCooldowns] = useState({});
  const [playerUsesLeft, setPlayerUsesLeft] = useState({});
  const [enemyUsesLeft, setEnemyUsesLeft] = useState({});
  const [confirmFlee, setConfirmFlee] = useState(false);
  const [defending, setDefending] = useState(false); // player defending this turn
  const [lastAttackKey, setLastAttackKey] = useState(null); // for combos
  const [weather, setWeather] = useState(WEATHERS[0]);
  const [playerBoostTurns, setPlayerBoostTurns] = useState(0);
  const [currentZoneKey, setCurrentZoneKey] = useState(null);
  const [currentZoneWins, setCurrentZoneWins] = useState(0);
  const [isBossFight, setIsBossFight] = useState(false);
  const [lastHatch, setLastHatch] = useState(null);
  const [gatheredThisLevel, setGatheredThisLevel] = useState(0);
  const [gatheredAtLevel, setGatheredAtLevel] = useState(1);
  const [confirmReset, setConfirmReset] = useState(false);
  const [confirmDeleteId, setConfirmDeleteId] = useState(null);
  const [showIdCard, setShowIdCard] = useState(false);
  const [galleryCount, setGalleryCount] = useState(6);
  const gallerySentinelRef = useRef(null);
  const [lastEnemyData, setLastEnemyData] = useState(null); // for retry
  const [inventory, setInventory] = useState(savedData.inventory || { heal: 3, antidote: 2, boost: 2, food: 5 });
  const [trait, setTrait] = useState(savedData.trait || null); // Sanguinaire / Resistant / Ruse
  const [eggs, setEggs] = useState(savedData.eggs || 0);
  const [unlockedColors, setUnlockedColors] = useState(savedData.unlockedColors || []);
  const [permaBonus, setPermaBonus] = useState(savedData.permaBonus || { attaque: 0, defense: 0, vitesse: 0, force: 0, intel: 0, hp: 0 });
  const [adventureZone, setAdventureZone] = useState(savedData.adventureZone || 0);
  const [zoneWinsMap, setZoneWinsMap] = useState(savedData.zoneWinsMap || {});
  const [totalWins, setTotalWins] = useState(savedData.totalWins || 0);
  const [achievements, setAchievements] = useState(savedData.achievements || {});
  const [combatsFought, setCombatsFought] = useState(savedData.combatsFought || 0);
  const [equipment, setEquipment] = useState(savedData.equipment || null);
  const [ownedEquipment, setOwnedEquipment] = useState(savedData.ownedEquipment || []);
  const [unlockedExclusives, setUnlockedExclusives] = useState(savedData.unlockedExclusives || []); // dino indices
  const [friendship, setFriendship] = useState(savedData.friendship || 0); // 0-500 points, 100 per heart
  const [arenaRank, setArenaRank] = useState(savedData.arenaRank || 0); // 0-4 (Bronze→Diamond)
  const [arenaStreak, setArenaStreak] = useState(0);
  const [shopCoins, setShopCoins] = useState(savedData.shopCoins || 0);
  const [showShop, setShowShop] = useState(false);
  const [aiNaming, setAiNaming] = useState(null); // "loading" | { name, desc }
  const [aiStory, setAiStory] = useState(null); // string
  const [aiAdvice, setAiAdvice] = useState(null); // string
  const [runner, setRunner] = useState(null); // { score, obstacles, dinoY, jumping, active }

  // ====== AI (Claude in Claude) ======
  // ====== AI — API with fast timeout + local fallback ======
  const callClaude = async (prompt) => {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 3000);
      const res = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 300,
          messages: [{ role: "user", content: prompt }],
        }),
        signal: controller.signal,
      });
      clearTimeout(timeout);
      if (!res.ok) return "";
      const data = await res.json();
      return data.content?.[0]?.text || "";
    } catch (e) { return ""; }
  };

  // --- Local name generator (offline fallback) ---
  const localNameGen = (parts) => {
    const prefixes = ["Méga","Ultra","Proto","Néo","Paléo","Pyro","Cryo","Aqua","Aéro","Géo","Ombra","Nocto","Fulgur","Titan","Spectro"];
    const infixes = parts.map(p => {
      const n = (p || "").toLowerCase();
      if (n.length < 4) return n;
      const start = n.slice(0, Math.ceil(n.length * 0.4));
      return start;
    }).filter(s => s.length > 1);
    const suffixes = ["don","raptor","saure","tops","corne","griffe","aile","croc","donte","rex"];
    const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
    const base = infixes.length >= 2
      ? infixes[0] + infixes[Math.floor(Math.random() * (infixes.length - 1)) + 1]
      : pick(prefixes).toLowerCase() + (infixes[0] || "dino");
    const capitalized = base.charAt(0).toUpperCase() + base.slice(1) + pick(suffixes);

    const traits = [
      "Féroce et imprévisible, il charge sans hésiter.",
      "Sa ruse n'a d'égale que sa vitesse fulgurante.",
      "Un colosse au cœur tendre... sauf en combat.",
      "Il rugit si fort que la terre tremble sous ses pattes.",
      "Mystérieux et insaisissable, il apparaît quand on ne l'attend pas.",
      "Sa loyauté envers son dresseur est légendaire.",
      "Patient comme un prédateur, il attend le moment parfait pour frapper.",
      "Son regard perçant glace le sang de ses adversaires.",
    ];
    return { name: capitalized, desc: pick(traits) };
  };

  // --- Local story generator (offline fallback) ---
  const localStoryGen = (dinoName, zoneName, bossName) => {
    const intros = [
      `Le combat contre ${bossName} fut le plus intense que ${zoneName} ait jamais connu.`,
      `Dans les profondeurs de ${zoneName}, ${bossName} attendait, tapi dans l'ombre.`,
      `L'affrontement avec ${bossName} résonna à travers toute ${zoneName}.`,
      `${bossName} poussa un dernier rugissement en voyant Chloé et ${dinoName} approcher.`,
    ];
    const middles = [
      `${dinoName} esquiva une attaque dévastatrice et contre-attaqua avec une puissance inouïe.`,
      `Chloé cria "Maintenant !" et ${dinoName} déchaîna toute sa fureur.`,
      `Le sol trembla quand les deux titans s'affrontèrent dans un duel épique.`,
      `Une lumière aveuglante jaillit quand ${dinoName} porta le coup final.`,
    ];
    const endings = [
      `La victoire était totale. ${zoneName} était libérée.`,
      `${bossName} s'inclina, vaincu. La légende de ${dinoName} venait de grandir.`,
      `Chloé sourit. Son ${dinoName} était devenu plus fort que jamais.`,
      `Un nouveau chapitre s'ouvrait. L'aventure continuait.`,
    ];
    const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
    return `${pick(intros)} ${pick(middles)} ${pick(endings)}`;
  };

  // --- Local advice generator (offline fallback) ---
  const localAdviceGen = (pType, enemyType, stats) => {
    const typeAdvice = {
      "feu>nature": "Ton type feu est super efficace ! Attaque avec tes spéciales feu pour un maximum de dégâts.",
      "eau>feu": "Avantage de type eau contre feu. Profites-en avec des attaques puissantes !",
      "nature>eau": "Type nature contre eau, c'est parfait. Lance tes spéciales sans hésiter.",
      "terre>feu": "La terre résiste au feu. Utilise ta défense et contre-attaque.",
      "feu>feu": "Même type ! Pas d'avantage. Mise sur tes stats les plus fortes.",
      "eau>eau": "Combat miroir. Ta vitesse et ton intelligence feront la différence.",
    };
    const key1 = `${pType}>${enemyType}`;
    if (typeAdvice[key1]) return typeAdvice[key1];

    const mult = TYPE_CHART[pType]?.[enemyType] || 1;
    if (mult > 1) return `Ton type ${pType} est super efficace contre ${enemyType} ! Privilégie les attaques spéciales pour maximiser les dégâts.`;
    if (mult < 1) return `Attention, ton type ${pType} est faible contre ${enemyType}. Joue défensif, utilise des objets, et attends le bon moment pour une attaque critique.`;

    if (stats.vitesse > 7) return "Ta vitesse est ton atout. Attaque en premier et enchaîne les combos avant qu'il ne puisse réagir.";
    if (stats.defense > 7) return "Ta défense est solide. Joue en défense, soigne-toi avec des fougères, et use-le à petit feu.";
    if (stats.attaque > 7) return "Ton attaque est dévastatrice. Frappe fort dès le premier tour avec tes spéciales les plus puissantes.";
    return "Combat équilibré. Varie tes attaques pour déclencher des combos et garde tes objets pour le bon moment.";
  };

  // --- Main AI functions (try API, fallback to local) ---
  const generateAiName = async () => {
    setAiNaming("loading");
    const parts = ["head","teeth","frontLegs","backLegs","back","tail"].map(k => DINOS[build[k]]?.name).filter(Boolean);
    const type = getBuildType(build);

    // Try API first
    const prompt = `Tu es un paléontologue créatif. Invente UN nom unique et cool pour un dinosaure hybride composé de : ${parts.join(", ")}. Type : ${type}. Réponds avec SEULEMENT le format JSON sans backticks : {"name":"LeNom","desc":"Une phrase de personnalité"}`;
    const raw = await callClaude(prompt);
    let result;
    try {
      const clean = raw.replace(/```json|```/g, "").trim();
      result = JSON.parse(clean);
    } catch {
      // Fallback local
      result = localNameGen(parts);
    }
    setAiNaming(result);
    setName(result.name);
    setTimeout(() => setAiNaming(null), 4000);
  };

  const generateAiStory = async (zoneName, bossName) => {
    const prompt = `Tu es un narrateur de jeu pour enfants. Écris un court paragraphe (3 phrases max, 50 mots max) racontant la victoire de Chloé et son dino "${name}" contre le boss "${bossName}" dans la zone "${zoneName}". Style épique et fun. Réponds SEULEMENT avec le texte narratif, rien d'autre.`;
    const text = await callClaude(prompt);
    setAiStory(text || localStoryGen(name, zoneName, bossName));
    setTimeout(() => setAiStory(null), 8000);
  };

  const generateAiAdvice = async (enemyName, enemyType) => {
    const pType = getBuildType(build);
    const prompt = `Tu es un conseiller tactique dans un jeu de dinos. Le joueur a un dino de type ${pType} avec les stats ATQ=${Math.round(playerStatsLeveled.attaque)} DEF=${Math.round(playerStatsLeveled.defense)} VIT=${Math.round(playerStatsLeveled.vitesse)}. Il va combattre "${enemyName}" de type ${enemyType}. Donne UN conseil tactique court (2 phrases max, 30 mots max). Réponds SEULEMENT avec le conseil.`;
    const text = await callClaude(prompt);
    setAiAdvice(text || localAdviceGen(pType, enemyType, playerStatsLeveled));
  };

  // ====== RUNNER MINI-GAME ======
  const startRunner = () => {
    setRunner({ score: 0, obstacles: [], dinoY: 0, jumping: false, active: true, started: Date.now(), speed: 1.5, lastObsTime: 0 });
  };

  useEffect(() => {
    if (!runner?.active) return;
    const interval = setInterval(() => {
      setRunner(prev => {
        if (!prev || !prev.active) return prev;
        const elapsed = (Date.now() - prev.started) / 1000;
        const speed = 1.5 + elapsed * 0.12; // Slow acceleration
        let newObs = prev.obstacles.map(o => ({ ...o, x: o.x - speed * 0.6 })).filter(o => o.x > -10);

        // Spawn obstacles with minimum spacing (1.5s between each)
        const timeSinceLastObs = Date.now() - (prev.lastObsTime || 0);
        let newLastObsTime = prev.lastObsTime;
        if (timeSinceLastObs > 1500 && Math.random() < 0.03 + elapsed * 0.001) {
          newObs.push({ x: 110, h: 5 + Math.random() * 7, id: Date.now() });
          newLastObsTime = Date.now();
        }

        // Collision — forgiving hitbox
        const dinoX = 18;
        const dinoBottom = prev.dinoY;
        const hit = newObs.some(o => o.x > dinoX - 2 && o.x < dinoX + 4 && dinoBottom < o.h * 0.8);
        if (hit) {
          playSfx("defeat");
          vibrate(200);
          const xpReward = Math.min(30, Math.floor(prev.score / 3));
          setXp(x => x + xpReward);
          setShopCoins(c => Math.min(999, c + Math.min(5, Math.floor(prev.score / 15))));
          return { ...prev, active: false, finalScore: prev.score, xpReward };
        }

        // Jump physics — longer, higher arc
        let newY = prev.dinoY;
        if (prev.jumping) {
          const jumpT = (Date.now() - prev.jumpStart) / 700; // 700ms jump
          if (jumpT < 1) {
            newY = Math.sin(jumpT * Math.PI) * 38; // Higher jump
          } else {
            newY = 0;
            return { ...prev, dinoY: 0, jumping: false, obstacles: newObs, score: prev.score + 1, speed, lastObsTime: newLastObsTime };
          }
        }
        return { ...prev, dinoY: newY, obstacles: newObs, score: prev.score + 1, speed, lastObsTime: newLastObsTime };
      });
    }, 50);
    return () => clearInterval(interval);
  }, [runner?.active]);
  const [musicOn, setMusicOn] = useState(true);

  // Music: only switch between ambient and battle, not on every view change
  const musicMood = (view === "battle" && enemy) ? "battle" : "ambient";
  const musicMoodRef = useRef("none");
  useEffect(() => {
    if (!musicOn || view === "splash") { stopMusic(); musicMoodRef.current = "none"; return; }
    if (musicMood !== musicMoodRef.current) {
      musicMoodRef.current = musicMood;
      startMusic(musicMood);
    }
  }, [musicMood, musicOn]);
  const [bugHunt, setBugHunt] = useState(null); // { bugs: [{x,y,caught}], timeLeft }
  const [showTypeChart, setShowTypeChart] = useState(false);
  const [selectedDex, setSelectedDex] = useState(null); // bestiary detail modal
  const [showDnaLab, setShowDnaLab] = useState(false);
  const [fossilPuzzle, setFossilPuzzle] = useState(null);
  const fossilBonePositions = useMemo(() => {
    if (!fossilPuzzle?.dinoReward) return [];
    const totalCells = 36;
    const seed = fossilPuzzle.dinoReward.split("").reduce((a, c) => a + c.charCodeAt(0), 0);
    const positions = [];
    const used = new Set();
    let s = seed;
    while (positions.length < 5) {
      s = (s * 1103515245 + 12345) & 0x7fffffff;
      const idx = s % totalCells;
      if (!used.has(idx)) { used.add(idx); positions.push(idx); }
    }
    return positions;
  }, [fossilPuzzle?.dinoReward]);
  const [selectedMapZone, setSelectedMapZone] = useState(null); // zone index
  const [dinoViewAngle, setDinoViewAngle] = useState(0);
  const [dino3D, setDino3D] = useState(false);
  const [eggHatching, setEggHatching] = useState(null); // hatching animation state
  const [lastBreathAvailable, setLastBreathAvailable] = useState(false);

  const ARENA_RANKS = [
    { name: "Bronze", color: "#cd7f32", icon: "🥉", minStreak: 0 },
    { name: "Argent", color: "#c0c0c0", icon: "🥈", minStreak: 3 },
    { name: "Or", color: "#ffd700", icon: "🥇", minStreak: 6 },
    { name: "Platine", color: "#e5e4e2", icon: "💎", minStreak: 10 },
    { name: "Diamant", color: "#b9f2ff", icon: "👑", minStreak: 15 },
  ];
  const friendshipHearts = Math.min(5, Math.floor(friendship / 100));
  const friendshipBonus = {
    dodge: friendshipHearts >= 2 ? 0.05 : 0,
    extraAttack: friendshipHearts >= 3,
    critBonus: friendshipHearts >= 4 ? 0.1 : 0,
    aura: friendshipHearts >= 5,
  };

  const SHOP_ITEMS = [
    { key: "color_neon", name: "Couleur Néon", cost: 30, type: "color", value: "#39ff14", emoji: "🟢" },
    { key: "color_rose", name: "Rose Bonbon", cost: 30, type: "color", value: "#ff69b4", emoji: "🩷" },
    { key: "color_galaxy", name: "Violet Galaxie", cost: 50, type: "color", value: "#7b2fbe", emoji: "🟣" },
    { key: "heal_pack", name: "Pack Fougères ×3", cost: 15, type: "item", value: "heal", qty: 3, emoji: "🌿" },
    { key: "boost_pack", name: "Pack Baies ×3", cost: 20, type: "item", value: "boost", qty: 3, emoji: "🍇" },
    { key: "egg_buy", name: "Œuf Mystère", cost: 60, type: "egg", emoji: "🥚" },
    { key: "antidote_pack", name: "Pack Sèves ×3", cost: 15, type: "item", value: "antidote", qty: 3, emoji: "💧" },
    { key: "food_pack", name: "Pack Viande ×5", cost: 10, type: "item", value: "food", qty: 5, emoji: "🍖" },
  ];
  const [captureOffer, setCaptureOffer] = useState(null);
  const [captureAnim, setCaptureAnim] = useState(null); // {phase, partKey, dinoName}
  const [quizActive, setQuizActive] = useState(null); // {question, answered, correct, boost}
  const [quizBoost, setQuizBoost] = useState(false);
  const [rivalDefeated, setRivalDefeated] = useState(savedData.rivalDefeated || 0);
  const [pattern, setPattern] = useState(savedData.pattern || "none");

  // Tamagotchi care system
  const [careHunger, setCareHunger] = useState(savedData.careHunger ?? 100);
  const [careHappiness, setCareHappiness] = useState(savedData.careHappiness ?? 100);
  const [careEnergy, setCareEnergy] = useState(savedData.careEnergy ?? 100);
  const [playMiniGame, setPlayMiniGame] = useState(null); // {taps, target, timeLeft, active}
  const [sleepCooldown, setSleepCooldown] = useState(0);
  const [careAnim, setCareAnim] = useState(null);
  const [touchReaction, setTouchReaction] = useState(null); // {type, emoji}
  const [attackAnimSvg, setAttackAnimSvg] = useState(null); // "bite"|"claw"|"charge"|"tail"
  const [fedToday, setFedToday] = useState(savedData.fedToday || 0); // free feeds used

  // Care mood
  const careMood = useMemo(() => {
    const avg = (careHunger + careHappiness + careEnergy) / 3;
    if (avg >= 80) return { emoji: "😄", label: "Forme parfaite", color: "#f8c840", bonus: true };
    if (avg >= 50) return { emoji: "🙂", label: "En forme", color: "#e8a020", bonus: false };
    if (avg >= 20) return { emoji: "😐", label: "Fatigué", color: "#e87830", bonus: false };
    return { emoji: "😢", label: "Épuisé", color: "#cc2020", bonus: false };
  }, [careHunger, careHappiness, careEnergy]);

  // Care bonuses for combat
  const careBonus = useMemo(() => ({
    hpMult: careHunger >= 70 ? 1.15 : careHunger < 20 ? 0.85 : 1.0,
    xpMult: careHappiness >= 70 ? 1.1 : 1.0,
    statMult: careEnergy >= 70 ? 1.1 : careEnergy < 20 ? 0.8 : 1.0,
    perfect: careHunger >= 80 && careHappiness >= 80 && careEnergy >= 80,
    canSpecial: careHunger >= 20 && careHappiness >= 20 && careEnergy >= 20,
  }), [careHunger, careHappiness, careEnergy]);

  // Decrease gauges gradually every 30s while app is open (same rate as before, just smoother)
  const tickRef = useRef(0);
  useEffect(() => {
    const interval = setInterval(() => {
      setCareHunger(h => Math.max(0, Math.round((h - 0.8) * 10) / 10));
      setCareHappiness(h => Math.max(0, Math.round((h - 0.5) * 10) / 10));
      setCareEnergy(e => Math.max(0, Math.round((e - 0.6) * 10) / 10));
      tickRef.current += 1;
      if (tickRef.current % 10 === 0) { // every 5 min (10 × 30s)
        setSleepCooldown(c => Math.max(0, c - 1));
      }
    }, 30 * 1000); // 30 seconds
    return () => clearInterval(interval);
  }, []);

  // Care actions
  const feedDino = () => {
    const foodCount = inventory.food || 0;
    if (fedToday >= 3 && foodCount <= 0) return;
    if (fedToday < 3) {
      setFedToday(fedToday + 1);
    } else {
      setInventory(prev => ({ ...prev, food: (prev.food || 0) - 1 }));
    }
    // Feed gives MORE than bug hunt: faim + bonheur + amitié
    setCareHunger(Math.min(100, careHunger + 40));
    setCareHappiness(Math.min(100, careHappiness + 15));
    setFriendship(f => f + 10);
    setCareAnim("feed");
    setTimeout(() => setCareAnim(null), 1200);
  };

  const sleepDino = () => {
    if (sleepCooldown > 0) return;
    setCareEnergy(Math.min(100, careEnergy + 40));
    setSleepCooldown(3);
    setCareAnim("sleep");
    setTimeout(() => setCareAnim(null), 1500);
  };

  const playTapsRef = useRef(0);
  const [tapBurst, setTapBurst] = useState(0); // increments on each tap for visual

  const startPlayMiniGame = () => {
    playTapsRef.current = 0;
    setPlayMiniGame({ taps: 0, target: 15, active: true, started: Date.now() });
  };

  const finishPlay = (taps, target) => {
    const bonus = taps >= target ? 40 : Math.min(40, Math.round((taps / target) * 40));
    setCareHappiness(h => Math.min(100, h + bonus));
    setFriendship(f => f + 8);
    setPlayMiniGame(prev => prev ? { ...prev, taps, active: false, result: bonus } : null);
    setCareAnim("play");
    setTimeout(() => { setCareAnim(null); setPlayMiniGame(null); }, 1500);
  };

  const tapPlay = () => {
    if (!playMiniGame || !playMiniGame.active) return;
    playTapsRef.current += 1;
    const newTaps = playTapsRef.current;
    // Visual burst on every tap
    setTapBurst(b => b + 1);
    const elapsed = (Date.now() - playMiniGame.started) / 1000;
    if (elapsed >= 5 || newTaps >= playMiniGame.target) {
      finishPlay(newTaps, playMiniGame.target);
    } else {
      setPlayMiniGame({ ...playMiniGame, taps: newTaps });
    }
  };

  // Timer for play mini-game (5s timeout)
  useEffect(() => {
    if (!playMiniGame?.active) return;
    const timer = setTimeout(() => {
      if (playMiniGame?.active) {
        finishPlay(playTapsRef.current, playMiniGame.target);
      }
    }, 5000);
    return () => clearTimeout(timer);
  }, [playMiniGame?.started]);

  // Bug hunt mini-game
  const startBugHunt = () => {
    const bugs = Array.from({ length: 5 }).map((_, i) => ({
      id: i, x: 10 + Math.random() * 70, y: 15 + Math.random() * 55, caught: false,
    }));
    setBugHunt({ bugs, caught: 0, active: true, started: Date.now() });
  };

  const catchBug = (bugId) => {
    setBugHunt(prev => {
      if (!prev || !prev.active) return prev;
      const newBugs = prev.bugs.map(b => b.id === bugId ? { ...b, caught: true } : b);
      const caught = newBugs.filter(b => b.caught).length;
      if (caught >= 5) {
        // Bug hunt: only faim, less than feeding, no bonheur
        setCareHunger(h => Math.min(100, h + 25));
        setFriendship(f => f + 5);
        setTimeout(() => setBugHunt(null), 1200);
        return { ...prev, bugs: newBugs, caught, active: false, result: 25 };
      }
      return { ...prev, bugs: newBugs, caught };
    });
  };

  useEffect(() => {
    if (!bugHunt?.active) return;
    const timer = setTimeout(() => {
      setBugHunt(prev => {
        if (!prev || !prev.active) return prev;
        const caught = prev.bugs.filter(b => b.caught).length;
        const bonus = caught * 5;
        setCareHunger(h => Math.min(100, h + bonus));
        setFriendship(f => f + caught);
        setTimeout(() => setBugHunt(null), 1200);
        return { ...prev, active: false, result: bonus };
      });
    }, 4000);
    return () => clearTimeout(timer);
  }, [bugHunt?.started]);

  // Boss dialogues
  const BOSS_DIALOGUES = {
    "Tricératops Alpha": { before: "Tu oses défier le roi des plaines ?!", after: "Impossible... mes cornes n'ont jamais échoué..." },
    "Velociraptor Chef de Meute": { before: "Ma meute te mettra en pièces !", after: "Tu es plus rusé que je ne pensais..." },
    "Spinosaure Ancestral": { before: "Les marais sont MON territoire !", after: "Ces eaux gardent mes secrets... pour l'instant." },
    "Carnotaurus Rouge": { before: "Le sable sera ta tombe !", after: "Le désert ne t'a pas vaincu... cette fois." },
    "T-Rex de Magma": { before: "JE SUIS LE FEU INCARNÉ !", after: "Le volcan gronde encore... je reviendrai." },
    "Mosasaure Abyssal": { before: "Nul ne ressort de mes abysses vivant.", after: "Les profondeurs te craignent maintenant..." },
    "Cryolophosaure Titan": { before: "Le froid éternel sera ton linceul.", after: "Le gel fond devant ta puissance..." },
    "Quetzalcoatlus Roi": { before: "Le ciel m'appartient, vermisseau !", after: "Tu as conquis les cieux... respect." },
    "Giganotosaure Primordial": { before: "Je suis l'ancêtre de tous les prédateurs !", after: "La jungle s'incline devant toi." },
    "Le Souverain": { before: "Aucun hybride ne m'a jamais vaincu. Tu seras le dernier à essayer.", after: "Tu es... le nouveau Souverain. Le monde préhistorique est à toi." },
  };

  // Auto-scroll combat log
  useEffect(() => {
    if (logRef.current) logRef.current.scrollTop = logRef.current.scrollHeight;
  });

  // Holographic card — touch/mouse tracking on the card itself
  const cardRef = useRef(null);
  const onCardMove = (e) => {
    const card = cardRef.current;
    if (!card) return;
    const rect = card.getBoundingClientRect();
    const cx = e.touches ? e.touches[0].clientX : e.clientX;
    const cy = e.touches ? e.touches[0].clientY : e.clientY;
    setGyroTilt({
      x: Math.max(-1, Math.min(1, ((cx - rect.left) / rect.width - 0.5) * 2.5)),
      y: Math.max(-1, Math.min(1, ((cy - rect.top) / rect.height - 0.5) * 2.5)),
    });
  };

  // Virtual scrolling: load more gallery cards when sentinel visible
  useEffect(() => {
    if (view !== "gallery" || !gallerySentinelRef.current) return;
    const obs = new IntersectionObserver(entries => {
      if (entries[0]?.isIntersecting && galleryCount < saved.length) {
        setGalleryCount(c => Math.min(saved.length, c + 4));
      }
    }, { threshold: 0.1 });
    obs.observe(gallerySentinelRef.current);
    return () => obs.disconnect();
  }, [view, galleryCount, saved.length]);

  // Reset gallery count when switching to gallery
  useEffect(() => {
    if (view === "gallery") setGalleryCount(6);
  }, [view]);

  const [evolutionPending, setEvolutionPending] = useState(null);
  const [preCombatScreen, setPreCombatScreen] = useState(null);
  const [cutscene, setCutscene] = useState(null); // {lines, current, emoji}

  const ZONE_EVENTS = {
    forest: { emoji: "🌋", lines: [
      "Le sol tremble sous tes pieds...",
      "Au loin, le volcan gronde.",
      "Des empreintes géantes mènent dans la forêt.",
      "L'aventure commence !"
    ]},
    marsh: { emoji: "🦕", lines: [
      "Un troupeau de Brachiosaures traverse le chemin !",
      "Leurs pas font trembler la terre...",
      "Ils disparaissent dans la brume des marais."
    ]},
    volcano: { emoji: "🌋", lines: [
      "Le volcan entre en éruption !",
      "Le ciel devient rouge sang...",
      "Des roches en fusion pleuvent autour de toi !",
      "Ton dino rugit de défi !"
    ]},
    glacier: { emoji: "❄️", lines: [
      "La température chute brutalement.",
      "Un blizzard se lève...",
      "Dans la glace, tu aperçois un dino congelé.",
      "Ses yeux... sont-ils ouverts ?!"
    ]},
    sky: { emoji: "⚡", lines: [
      "L'orage éclate !",
      "Un éclair frappe le sommet de la montagne.",
      "Dans la lumière, une silhouette ailée immense.",
      "Le Roi du Ciel t'a repéré."
    ]},
    abyss: { emoji: "🌊", lines: [
      "Les eaux s'agitent violemment !",
      "Quelque chose d'ÉNORME se déplace sous la surface...",
      "Un tentacule surgit... non, c'est un aileron !",
    ]},
    summit: { emoji: "👑", lines: [
      "Tu as atteint le sommet de l'île.",
      "Un trône de pierre... et dessus, une ombre.",
      "Le Souverain se lève lentement.",
      "\"Aucun hybride ne m'a jamais vaincu.\"",
      "\"Tu seras le dernier à essayer.\"",
    ]},
  };
  const [victoryAnim, setVictoryAnim] = useState(false);
  const [battleResultScreen, setBattleResultScreen] = useState(null); // {winner, xp, coins, enemy}
  const [notifications, setNotifications] = useState({});
  const [pendingBossZone, setPendingBossZone] = useState(null);

  // Start boss with quiz first
  const startBossQuiz = (zoneIdx) => {
    const q = QUIZ_QUESTIONS[Math.floor(Math.random() * QUIZ_QUESTIONS.length)];
    const shuffled = [...q.opts].sort(() => Math.random() - 0.5);
    setQuizActive({ ...q, opts: shuffled, answered: false, correct: false });
    setPendingBossZone(zoneIdx);
  };

  const answerQuiz = (answer) => {
    const correct = answer === quizActive.a;
    setQuizActive({ ...quizActive, answered: true, correct });
    setQuizBoost(correct);
    setTimeout(() => {
      setQuizActive(null);
      if (pendingBossZone !== null) {
        startZoneBattle(pendingBossZone, true);
        setPendingBossZone(null);
      }
    }, 1500);
  };

  // Save on any change
  useEffect(() => {
    writeSave({
      build, name, saved, level, xp, bestiary, inventory, trait, eggs,
      unlockedColors, adventureZone, totalWins, achievements, combatsFought, permaBonus, zoneWinsMap,
      equipment, ownedEquipment, rivalDefeated, pattern,
      careHunger, careHappiness, careEnergy, fedToday,
      friendship, arenaRank, shopCoins, unlockedExclusives,
    });
  }, [build, name, saved, level, xp, bestiary, inventory, trait, eggs,
      unlockedColors, adventureZone, totalWins, achievements, combatsFought, permaBonus, zoneWinsMap,
      equipment, ownedEquipment, rivalDefeated, pattern,
      careHunger, careHappiness, careEnergy, fedToday,
      friendship, arenaRank, shopCoins, unlockedExclusives]);

  const xpForNextLevel = level * 50;

  const stats = useMemo(() => computeStats(build), [build]);

  const STANDARD_DINO_COUNT = DINOS.filter(d => !d.exclusive).length;
  const randomize = () => {
    const r = () => Math.floor(Math.random() * STANDARD_DINO_COUNT);
    const newBuild = { head: r(), teeth: r(), frontLegs: r(), backLegs: r(), back: r(), tail: r(), color: r(), customColor: null };
    setBuild(newBuild);
    setName(generateName(newBuild));
    // New dino = fresh stats
    setLevel(1); setXp(0); setTotalWins(0);
    setFriendship(0);
    setCareHunger(100); setCareHappiness(100); setCareEnergy(100);
    setTrait(null); setEquipment(null); setPattern("none");
    setPermaBonus({ attaque: 0, defense: 0, vitesse: 0, force: 0, intel: 0, hp: 0 });
  };

  const save = () => {
    const dinoData = {
      name, build: { ...build }, stats: { ...stats }, id: Date.now(),
      level, xp, totalWins: totalWins, friendship,
      careHunger, careHappiness, careEnergy,
      trait, equipment, pattern,
      permaBonus: { ...permaBonus },
    };
    // Update existing dino with same name, or create new
    const existingIdx = saved.findIndex(s => s.name === name);
    if (existingIdx >= 0) {
      const updated = [...saved];
      updated[existingIdx] = { ...dinoData, id: saved[existingIdx].id };
      setSaved(updated);
    } else {
      setSaved([...saved, dinoData]);
    }
  };

  // ====== BATTLE FUNCTIONS ======
  // Trait gives visible stat bonuses on top of combat effects
  const TRAIT_STAT_BONUS = {
    sanguinaire: { attaque: 1.5, defense: 0, vitesse: 0, force: 0.5, intel: 0 },
    resistant: { attaque: 0, defense: 1.5, vitesse: 0, force: 0.5, intel: 0 },
    ruse: { attaque: 0, defense: 0, vitesse: 0.5, force: 0, intel: 2.0 },
    fureur: { attaque: 0.5, defense: 0, vitesse: 0, force: 1.5, intel: 0 },
    endurant: { attaque: 0.5, defense: 0.5, vitesse: 0.5, force: 0.5, intel: 0.5 },
  };
  const traitBonus = trait ? TRAIT_STAT_BONUS[trait] || {} : {};

  // Stat cap: stats can't exceed this until you level up
  // Level 1: cap 4, level 5: cap 8, level 10: cap 13, level 12+: uncapped
  const statCap = Math.min(15, 3 + level);

  // Equipment bonus
  const equipBonus = equipment ? (EQUIPMENT_LIST.find(e => e.key === equipment)?.bonus || {}) : {};

  const playerStatsLeveled = useMemo(() => {
    const base = statsWithLevel(stats, level);
    const tb = trait ? (TRAIT_STAT_BONUS[trait] || {}) : {};
    const eb = equipment ? (EQUIPMENT_LIST.find(e => e.key === equipment)?.bonus || {}) : {};
    const cap = Math.min(15, 3 + level);
    const cm = careBonus.statMult;
    return {
      attaque: Math.min(cap, (base.attaque + (permaBonus.attaque || 0) + (tb.attaque || 0) + (eb.attaque || 0)) * cm),
      defense: Math.min(cap, (base.defense + (permaBonus.defense || 0) + (tb.defense || 0) + (eb.defense || 0)) * cm),
      vitesse: Math.min(cap, (base.vitesse + (permaBonus.vitesse || 0) + (tb.vitesse || 0) + (eb.vitesse || 0)) * cm),
      force: Math.min(cap, (base.force + (permaBonus.force || 0) + (tb.force || 0) + (eb.force || 0)) * cm),
      taille: base.taille,
      intel: Math.min(cap, (base.intel + (permaBonus.intel || 0) + (tb.intel || 0) + (eb.intel || 0)) * cm),
    };
  }, [stats, level, permaBonus, trait, equipment, careBonus.statMult]);
  const availableAttacks = useMemo(() => getAvailableAttacks(build), [build]);

  const startBattle = (tier = null) => {
    const baseEnemy = generateEnemy(playerStatsLeveled);
    // Always scale enemy to player's level (for free fight: same level; for tournament: tier mult on top)
    let enemyStats = statsWithLevel(baseEnemy.stats, level);
    let enemyLevel = level;
    let tierInfo = null;

    if (tier !== null) {
      tierInfo = TOURNAMENT_TIERS[tier];
      const mult = tierInfo.powerMult;
      enemyStats = {
        attaque: enemyStats.attaque * mult,
        defense: enemyStats.defense * mult,
        vitesse: enemyStats.vitesse * mult,
        force: enemyStats.force * mult,
        taille: enemyStats.taille,
        intel: enemyStats.intel * mult,
      };
      enemyLevel = Math.max(1, Math.round(level * mult));
    }

    const newEnv = ENVIRONMENTS[Math.floor(Math.random() * ENVIRONMENTS.length)];
    setEnvironment(newEnv);
    const newWeather = WEATHERS[Math.floor(Math.random() * WEATHERS.length)];
    setWeather(newWeather);
    setDefending(false);
    setLastAttackKey(null);
    setPlayerBoostTurns(0);
    setLastBreathAvailable(false);

    const newEnemy = { ...baseEnemy, stats: enemyStats, level: enemyLevel, tier: tierInfo };
    const playerHP = Math.round(computeHP(playerStatsLeveled, trait, permaBonus.hp || 0) * careBonus.hpMult);
    const enemyHP = computeHP(enemyStats, null);
    setEnemy(newEnemy);
    setLastEnemyData(JSON.parse(JSON.stringify(newEnemy)));
    setPlayerStatus(null);
    setEnemyStatus(null);
    setPlayerCooldowns({});
    setEnemyCooldowns({});
    // Initialize uses left for each attack
    const playerAttacks = getAvailableAttacks(build);
    const initialPlayerUses = {};
    playerAttacks.forEach(a => { initialPlayerUses[a.key] = getMaxUses(a, playerStatsLeveled, trait); });
    setPlayerUsesLeft(initialPlayerUses);
    const enemyAttacks = getAvailableAttacks(baseEnemy.build);
    const initialEnemyUses = {};
    enemyAttacks.forEach(a => { initialEnemyUses[a.key] = getMaxUses(a, enemyStats, null); });
    setEnemyUsesLeft(initialEnemyUses);
    setBattleState({
      playerHP, playerMaxHP: playerHP,
      enemyHP, enemyMaxHP: enemyHP,
      log: [
        `${newEnv.emoji} ${newEnv.name}.`,
        tierInfo ? `🏟️ Adversaire ${tierInfo.name} : ${newEnemy.name} (Niv ${enemyLevel}) !` : `🌋 Un ${newEnemy.name} sauvage apparaît !`,
      ],
      turn: "player",
      finished: false,
      winner: null,
    });
    // Show pre-combat screen
    setPreCombatScreen({ name: newEnemy.name, build: newEnemy.build, level: enemyLevel });
    setView("battle");
    try { playRoar(DINOS[build.head]?.family || "tyrant"); } catch(e) {}
    setTimeout(() => setPreCombatScreen(null), 2000);
  };

  const startTournament = () => {
    setTournament({ tier: 0, wins: 0 });
    startBattle(0);
  };

  // Start a zone battle (adventure mode). If boss=true, generate a boss-level enemy.
  const resetGame = () => {
    // Clear storage
    if (hasStorage) {
      try { window.localStorage.removeItem(STORAGE_KEY); } catch (e) {}
    }
    // Reset all states
    setBuild({ head: 0, teeth: 0, frontLegs: 0, backLegs: 0, back: 0, tail: 0, color: 0, customColor: null });
    setName("Mon Hybride");
    setSaved([]);
    setLevel(1);
    setXp(0);
    setBestiary({});
    setInventory({ heal: 3, antidote: 2, boost: 2, food: 5 });
    setTrait(null);
    setEggs(0);
    setUnlockedColors([]);
    setPermaBonus({ attaque: 0, defense: 0, vitesse: 0, force: 0, intel: 0, hp: 0 });
    setAdventureZone(0);
    setZoneWinsMap({});
    setEquipment(null);
    setOwnedEquipment([]);
    setPattern("none");
    setRivalDefeated(0);
    setQuizBoost(false);
    setCaptureOffer(null);
    setEvolutionPending(null);
    setPreCombatScreen(null);
    setCareHunger(100);
    setCareHappiness(100);
    setCareEnergy(100);
    setFedToday(0);
    setSleepCooldown(0);
    setFriendship(0);
    setArenaRank(0);
    setArenaStreak(0);
    setShopCoins(0);
    setTotalWins(0);
    setAchievements({});
    setCombatsFought(0);
    setEnemy(null);
    setTournament(null);
    setGatheredThisLevel(0);
    setGatheredAtLevel(1);
    setConfirmReset(false);
    setView("build");
  };

  const startZoneBattle = (zoneIdx, boss = false) => {
    const zone = ZONES[zoneIdx];
    // Pick a dino from the zone's families for theming
    const familyPool = zone.families;
    const dinosInFamily = DINOS.map((d, i) => ({ d, i })).filter(x => familyPool.includes(x.d.family));
    const baseEnemy = generateEnemy(playerStatsLeveled);
    // Override parts to fit the zone theme
    if (dinosInFamily.length > 0) {
      const pick = () => dinosInFamily[Math.floor(Math.random() * dinosInFamily.length)].i;
      if (boss && zone.bossIdx !== undefined) {
        // Boss: ALL parts = the exact named dino (looks like its name)
        const bIdx = zone.bossIdx;
        baseEnemy.build.head = bIdx;
        baseEnemy.build.teeth = bIdx;
        baseEnemy.build.frontLegs = bIdx;
        baseEnemy.build.backLegs = bIdx;
        baseEnemy.build.back = bIdx;
        baseEnemy.build.tail = bIdx;
        baseEnemy.build.color = bIdx;
      } else {
        // Regular: head + 2 random parts from zone families
        baseEnemy.build.head = pick();
        const extraParts = ["teeth", "backLegs", "back", "tail"];
        const shuffled = extraParts.sort(() => Math.random() - 0.5);
        baseEnemy.build[shuffled[0]] = pick();
        baseEnemy.build[shuffled[1]] = pick();
      }
      baseEnemy.stats = computeStats(baseEnemy.build);
      if (!boss) baseEnemy.name = generateName(baseEnemy.build);
    }

    // Scale
    const bossMult = boss ? 1.4 : 1.0;
    let enemyStats = statsWithLevel(baseEnemy.stats, level);
    enemyStats = {
      attaque: enemyStats.attaque * bossMult,
      defense: enemyStats.defense * bossMult,
      vitesse: enemyStats.vitesse * bossMult,
      force: enemyStats.force * bossMult,
      taille: enemyStats.taille,
      intel: enemyStats.intel * bossMult,
    };

    const enemyLevel = Math.round(level * bossMult);
    const newEnv = ENVIRONMENTS.find(e => e.key === zone.key) || ENVIRONMENTS[zoneIdx % ENVIRONMENTS.length];
    setEnvironment(newEnv);
    const newWeather = WEATHERS[Math.floor(Math.random() * WEATHERS.length)];
    setWeather(newWeather);
    setDefending(false);
    setLastAttackKey(null);
    setPlayerBoostTurns(0);
    setLastBreathAvailable(false);
    setCurrentZoneKey(zone.key);
    setIsBossFight(boss);

    // Rival encounter: appears on last exploration fight before boss in specific zones
    const currentWins = zoneWinsMap[zone.key] || 0;
    const isRivalZone = RIVAL_APPEARANCES.includes(zoneIdx);
    const rivalAppearanceIdx = RIVAL_APPEARANCES.indexOf(zoneIdx);
    const isRivalFight = !boss && isRivalZone && currentWins === zone.wins - 1 && rivalDefeated <= rivalAppearanceIdx;
    
    if (isRivalFight) {
      // Override enemy to be the Rival
      const rivalPower = 1.2 + rivalAppearanceIdx * 0.15;
      baseEnemy.name = RIVAL_NAME;
      baseEnemy.build = { head: 57, teeth: 50, frontLegs: 55, backLegs: 63, back: 58, tail: 61, color: 54 }; // all exclusive parts
      baseEnemy.stats = computeStats(baseEnemy.build);
      enemyStats = {
        attaque: baseEnemy.stats.attaque * rivalPower,
        defense: baseEnemy.stats.defense * rivalPower,
        vitesse: baseEnemy.stats.vitesse * rivalPower,
        force: baseEnemy.stats.force * rivalPower,
        taille: baseEnemy.stats.taille,
        intel: baseEnemy.stats.intel * rivalPower,
      };
    }

    const newEnemy = {
      ...baseEnemy,
      name: boss ? zone.boss : isRivalFight ? RIVAL_NAME : baseEnemy.name,
      stats: enemyStats,
      level: enemyLevel,
      tier: boss ? { name: "BOSS", powerMult: bossMult, color: "#cc2020" } : null,
    };
    const playerHP = Math.round(computeHP(playerStatsLeveled, trait, permaBonus.hp || 0) * careBonus.hpMult);
    const enemyHP = computeHP(enemyStats, null);
    setEnemy(newEnemy);
    setLastEnemyData(JSON.parse(JSON.stringify(newEnemy)));
    setPlayerStatus(null);
    setEnemyStatus(null);
    setPlayerCooldowns({});
    setEnemyCooldowns({});
    const playerAttacks = getAvailableAttacks(build);
    const initialPlayerUses = {};
    playerAttacks.forEach(a => { initialPlayerUses[a.key] = getMaxUses(a, playerStatsLeveled, trait); });
    setPlayerUsesLeft(initialPlayerUses);
    const enemyAttacks = getAvailableAttacks(baseEnemy.build);
    const initialEnemyUses = {};
    enemyAttacks.forEach(a => { initialEnemyUses[a.key] = getMaxUses(a, enemyStats, null); });
    setEnemyUsesLeft(initialEnemyUses);

    const rivalDialogue = isRivalFight ? RIVAL_DIALOGUES[Math.min(rivalAppearanceIdx, RIVAL_DIALOGUES.length - 1)] : null;

    setBattleState({
      playerHP, playerMaxHP: playerHP,
      enemyHP, enemyMaxHP: enemyHP,
      log: [
        `${newEnv.emoji} ${zone.name} · ${newWeather.emoji} ${newWeather.name}`,
        boss ? `👑 BOSS : ${zone.boss} apparaît !` : isRivalFight ? `🦇 ${RIVAL_NAME} : "${rivalDialogue}"` : `🌿 Un ${newEnemy.name} surgit !`,
        ...(boss && BOSS_DIALOGUES[zone.boss] ? [`💬 "${BOSS_DIALOGUES[zone.boss].before}"`] : []),
      ],
      turn: "player",
      finished: false,
      winner: null,
      isAdventure: true,
      isBoss: boss,
      isRival: isRivalFight,
      zoneIdx,
    });
    setPreCombatScreen({ name: newEnemy.name, build: newEnemy.build, level: newEnemy.level || level });
    setView("battle");
    try { playRoar(DINOS[build.head]?.family || "tyrant"); } catch(e) {}
    setTimeout(() => setPreCombatScreen(null), 2000);
  };

  const playerAttack = (attackType) => {
    if (battleState.finished || battleState.turn !== "player" || attackAnim) return;
    if (attackType.cooldown && playerCooldowns[attackType.key] > 0) return; // can't use, on cooldown
    if ((playerUsesLeft[attackType.key] || 0) <= 0) return; // no uses left
    // Decrement uses immediately
    setPlayerUsesLeft({ ...playerUsesLeft, [attackType.key]: (playerUsesLeft[attackType.key] || 0) - 1 });

    // Check if player is stunned
    if (playerStatus?.type === "etourdi") {
      // Tick down cooldowns even when stunned
      const newPlayerCooldowns = {};
      Object.entries(playerCooldowns).forEach(([k, v]) => {
        if (v - 1 > 0) newPlayerCooldowns[k] = v - 1;
      });
      setPlayerCooldowns(newPlayerCooldowns);
      setBattleState({
        ...battleState,
        log: [...battleState.log, `💫 Tu es étourdi et passes ton tour !`],
        turn: "enemy",
      });
      setPlayerStatus(playerStatus.turnsLeft > 1 ? { ...playerStatus, turnsLeft: playerStatus.turnsLeft - 1 } : null);
      setTimeout(() => doEnemyTurn(battleState.playerHP, battleState.enemyHP), 800);
      return;
    }

    const player = {
      stats: playerStatsLeveled,
      name,
      status: { [playerStatus?.type]: true },
      trait,
      type: getBuildType(build),
      boosted: playerBoostTurns > 0,
      hpRatio: battleState.playerHP / battleState.playerMaxHP,
      defending,
    };
    const enemyData = {
      stats: enemy.stats,
      name: enemy.name,
      status: { [enemyStatus?.type]: true },
      type: getBuildType(enemy.build),
      defending: false,
    };
    const combo = lastAttackKey !== null && lastAttackKey !== attackType.key;
    const result = computeAttack(player, enemyData, attackType, { weather, combo, quizBoost });
    setLastAttackKey(attackType.key);

    // Trigger animations
    setAttackAnim({ who: "player", type: "attack", attackKey: attackType.key, special: attackType.special });
    if (attackType.special) {
      try { playCry(build); } catch (e) {}
    }

    setTimeout(() => setAttackAnim({ who: "enemy", type: "hit", attackKey: attackType.key }), 400);
    setTimeout(() => setAttackAnim(null), 900);

    if (!result.dodged) {
      setTimeout(() => {
        setFloatingDmg({ who: "enemy", value: result.damage, crit: result.crit });
        setScreenFlash("white");
        setTimeout(() => setScreenFlash(null), 120);
        playSfx(result.crit ? "crit" : "hit");
        vibrate(result.crit ? 200 : 50);
        if (result.crit) {
          setScreenShake(true); setTimeout(() => setScreenShake(false), 300);
          setLightningBolt(true); setTimeout(() => setLightningBolt(false), 350);
        }
      }, 350);
      setTimeout(() => setFloatingDmg(null), 1100);
    } else {
      setTimeout(() => playSfx("dodge"), 350);
    }

    setTimeout(() => {
      const newEnemyHP = Math.max(0, battleState.enemyHP - result.damage);
      const logEntry = result.dodged
        ? `${attackType.emoji} Tu ${attackType.desc}... ${enemy.name} esquive !`
        : `${attackType.emoji} ${attackType.special ? "✨ " : ""}Tu ${attackType.desc} ! ${result.crit ? "💢 CRITIQUE ! " : ""}-${result.damage} PV`;
      let newLog = [...battleState.log, logEntry];

      // Pokémon-style type effectiveness messages
      if (!result.dodged && result.typeMult > 1) {
        newLog.push(`💥 C'est super efficace !`);
      } else if (!result.dodged && result.typeMult < 1) {
        newLog.push(`🔻 Ce n'est pas très efficace...`);
      }

      // Apply status from special attack
      let newEnemyStatus = enemyStatus;
      if (result.status && !enemyStatus) {
        newEnemyStatus = { type: result.status, turnsLeft: STATUS_EFFECTS[result.status].duration };
        newLog.push(`${STATUS_EFFECTS[result.status].emoji} ${enemy.name} est ${STATUS_EFFECTS[result.status].label.toLowerCase()} !`);
        setEnemyStatus(newEnemyStatus);
      }

      // Update player cooldowns: tick down all, then apply new cooldown if special was used
      const newPlayerCooldowns = {};
      Object.entries(playerCooldowns).forEach(([k, v]) => {
        if (v - 1 > 0) newPlayerCooldowns[k] = v - 1;
      });
      if (attackType.cooldown) {
        newPlayerCooldowns[attackType.key] = attackType.cooldown;
      }
      setPlayerCooldowns(newPlayerCooldowns);

      // Apply bleeding damage at end of attacker's turn
      let bleedExtra = 0;
      if (newEnemyStatus?.type === "saigne") {
        bleedExtra = STATUS_EFFECTS.saigne.dmgPerTurn;
        newLog.push(`🩸 ${enemy.name} saigne (-${bleedExtra} PV)`);
      }
      const enemyHPAfterBleed = Math.max(0, newEnemyHP - bleedExtra);

      // Tick down enemy status
      if (newEnemyStatus) {
        const remaining = newEnemyStatus.turnsLeft - 1;
        setEnemyStatus(remaining > 0 ? { ...newEnemyStatus, turnsLeft: remaining } : null);
      }

      if (enemyHPAfterBleed === 0) {
        finishBattle("player", newLog, 0, battleState.playerHP);
        return;
      }

      setBattleState({
        ...battleState,
        enemyHP: enemyHPAfterBleed,
        log: newLog,
        turn: "enemy",
      });

      setTimeout(() => doEnemyTurn(battleState.playerHP, enemyHPAfterBleed, newLog), 900);
    }, 700);
  };

  const doEnemyTurn = (currentPlayerHP, currentEnemyHP, prevLog) => {
    const log = prevLog || battleState.log;

    // Check if enemy is stunned
    if (enemyStatus?.type === "etourdi") {
      const newEnemyCooldowns = {};
      Object.entries(enemyCooldowns).forEach(([k, v]) => {
        if (v - 1 > 0) newEnemyCooldowns[k] = v - 1;
      });
      setEnemyCooldowns(newEnemyCooldowns);
      const newLog = [...log, `💫 ${enemy.name} est étourdi et passe son tour !`];
      setEnemyStatus(enemyStatus.turnsLeft > 1 ? { ...enemyStatus, turnsLeft: enemyStatus.turnsLeft - 1 } : null);
      setBattleState({ ...battleState, playerHP: currentPlayerHP, enemyHP: currentEnemyHP, log: newLog, turn: "player" });
      return;
    }

    const allEnemyAttacks = getAvailableAttacks(enemy.build);
    // Filter out specials currently on cooldown OR with no uses left
    let enemyAttacks = allEnemyAttacks.filter(a => !(a.cooldown && enemyCooldowns[a.key] > 0))
      .filter(a => (enemyUsesLeft[a.key] || 0) > 0);
    // Fallback: if nothing available, allow basic attacks even if exhausted (struggle)
    if (enemyAttacks.length === 0) {
      enemyAttacks = allEnemyAttacks.filter(a => !a.special);
    }
    // Smart AI attack selection (scales with arena rank)
    const aiSmartness = Math.min(0.9, 0.3 + arenaRank * 0.15); // 30% at Bronze, 90% at Diamond
    let enemyAttack;
    if (Math.random() < aiSmartness && enemyAttacks.length > 1) {
      // Score each attack
      const eType = getBuildType(enemy.build);
      const pType = getBuildType(build);
      const eHpPct = currentEnemyHP / battleState.enemyMaxHP;
      const scored = enemyAttacks.map(a => {
        let score = a.power || 5;
        // Prefer type-advantaged attacks
        const typeMult = getTypeMult(eType, pType);
        if (typeMult > 1) score *= 1.3;
        // Prefer specials when they'll deal more
        if (a.special && a.power > 7) score *= 1.4;
        // Prefer defense/heal when low HP
        if (eHpPct < 0.3 && a.key === "defense") score *= 2.5;
        // Combo bonus: prefer different from last enemy attack
        if (battleState.lastEnemyAttack && a.key !== battleState.lastEnemyAttack) score *= 1.2;
        // High damage finishing moves when player is low
        if (currentPlayerHP / battleState.playerMaxHP < 0.25 && a.power >= 8) score *= 1.5;
        return { attack: a, score };
      });
      scored.sort((a, b) => b.score - a.score);
      // Pick top 1-2 weighted by score
      enemyAttack = scored[0].attack;
    } else {
      enemyAttack = enemyAttacks[Math.floor(Math.random() * enemyAttacks.length)];
    }
    // Decrement enemy uses
    if ((enemyUsesLeft[enemyAttack.key] || 0) > 0) {
      setEnemyUsesLeft({ ...enemyUsesLeft, [enemyAttack.key]: enemyUsesLeft[enemyAttack.key] - 1 });
    }
    const player = {
      stats: playerStatsLeveled,
      name,
      status: { [playerStatus?.type]: true },
      trait,
      type: getBuildType(build),
      hpRatio: currentPlayerHP / battleState.playerMaxHP,
      defending,
    };
    const enemyData = {
      stats: enemy.stats,
      name: enemy.name,
      status: { [enemyStatus?.type]: true },
      type: getBuildType(enemy.build),
      hpRatio: currentEnemyHP / battleState.enemyMaxHP,
    };
    const enemyResult = computeAttack(enemyData, player, enemyAttack, { weather });

    setAttackAnim({ who: "enemy", type: "attack", attackKey: enemyAttack.key, special: enemyAttack.special });
    setTimeout(() => setAttackAnim({ who: "player", type: "hit", attackKey: enemyAttack.key }), 400);
    setTimeout(() => setAttackAnim(null), 900);

    if (!enemyResult.dodged) {
      setTimeout(() => {
        setFloatingDmg({ who: "player", value: enemyResult.damage, crit: enemyResult.crit });
        setScreenFlash("red");
        setTimeout(() => setScreenFlash(null), 120);
        playSfx(enemyResult.crit ? "crit" : "hit");
        vibrate(enemyResult.crit ? [100, 50, 100] : 80);
        if (enemyResult.crit) {
          setScreenShake(true); setTimeout(() => setScreenShake(false), 300);
          setLightningBolt(true); setTimeout(() => setLightningBolt(false), 350);
        }
      }, 350);
      setTimeout(() => setFloatingDmg(null), 1100);
    } else {
      setTimeout(() => playSfx("dodge"), 350);
    }

    setTimeout(() => {
      const newPlayerHP = Math.max(0, currentPlayerHP - enemyResult.damage);
      const enemyLogEntry = enemyResult.dodged
        ? `${enemyAttack.emoji} ${enemy.name} ${enemyAttack.desc}... tu esquives !`
        : `${enemyAttack.emoji} ${enemyAttack.special ? "✨ " : ""}${enemy.name} ${enemyAttack.desc} ! ${enemyResult.crit ? "💢 CRITIQUE ! " : ""}-${enemyResult.damage} PV`;
      let newLog = [...log, enemyLogEntry];

      if (!enemyResult.dodged && enemyResult.typeMult > 1) {
        newLog.push(`💥 C'est super efficace !`);
      } else if (!enemyResult.dodged && enemyResult.typeMult < 1) {
        newLog.push(`🔻 Ce n'est pas très efficace...`);
      }

      let newPlayerStatus = playerStatus;
      if (enemyResult.status && !playerStatus) {
        newPlayerStatus = { type: enemyResult.status, turnsLeft: STATUS_EFFECTS[enemyResult.status].duration };
        newLog.push(`${STATUS_EFFECTS[enemyResult.status].emoji} Tu es ${STATUS_EFFECTS[enemyResult.status].label.toLowerCase()} !`);
        setPlayerStatus(newPlayerStatus);
      }

      // Update enemy cooldowns
      const newEnemyCooldowns = {};
      Object.entries(enemyCooldowns).forEach(([k, v]) => {
        if (v - 1 > 0) newEnemyCooldowns[k] = v - 1;
      });
      if (enemyAttack.cooldown) {
        newEnemyCooldowns[enemyAttack.key] = enemyAttack.cooldown;
      }
      setEnemyCooldowns(newEnemyCooldowns);

      // Counter-attack if defending (50% of base attack damage)
      let counterDmg = 0;
      if (defending && !enemyResult.dodged) {
        counterDmg = Math.max(2, Math.round(playerStatsLeveled.attaque * 1.2 - enemy.stats.defense * 0.3));
        newLog.push(`⚡ Contre-attaque ! -${counterDmg} PV à ${enemy.name}`);
      }

      let bleedExtra = 0;
      if (newPlayerStatus?.type === "saigne") {
        bleedExtra = STATUS_EFFECTS.saigne.dmgPerTurn;
        newLog.push(`🩸 Tu saignes (-${bleedExtra} PV)`);
      }
      const playerHPAfterBleed = Math.max(0, newPlayerHP - bleedExtra);

      if (newPlayerStatus) {
        const remaining = newPlayerStatus.turnsLeft - 1;
        setPlayerStatus(remaining > 0 ? { ...newPlayerStatus, turnsLeft: remaining } : null);
      }

      if (playerHPAfterBleed === 0) {
        const enemyAfterCounter = Math.max(0, currentEnemyHP - counterDmg);
        finishBattle("enemy", newLog, enemyAfterCounter, 0);
      } else {
        const enemyAfterCounter = Math.max(0, currentEnemyHP - counterDmg);
        if (enemyAfterCounter === 0 && counterDmg > 0) {
          newLog.push(`🏆 Contre-attaque fatale ! ${enemy.name} est vaincu !`);
          finishBattle("player", newLog, 0, playerHPAfterBleed);
          return;
        }
        // End-of-enemy-turn ticks: reset defense, tick boost, trait effects
        let finalPlayerHP = playerHPAfterBleed;
        const finalLog2 = [...newLog];
        // Resistant: regenerate 5 HP per turn
        if (trait === "resistant" && finalPlayerHP < battleState.playerMaxHP) {
          const heal = Math.min(5, battleState.playerMaxHP - finalPlayerHP);
          finalPlayerHP += heal;
          if (heal > 0) finalLog2.push(`🛡️ Régénération : +${heal} PV`);
        }
        // Fureur log when crossing the 30% threshold
        if (trait === "fureur" && finalPlayerHP / battleState.playerMaxHP < 0.3 && playerHPAfterBleed / battleState.playerMaxHP >= 0.3) {
          finalLog2.push(`😤 FUREUR ! Tes dégâts sont boostés !`);
        }
        // Tick boost
        if (playerBoostTurns > 0) {
          const rem = playerBoostTurns - 1;
          setPlayerBoostTurns(rem);
          if (rem === 0) finalLog2.push(`🍇 L'effet de la Baie Féroce se dissipe.`);
        }
        // Reset defending
        if (defending) setDefending(false);
        setBattleState({ ...battleState, playerHP: finalPlayerHP, enemyHP: enemyAfterCounter, log: finalLog2, turn: "player", lastEnemyAttack: enemyAttack.key });
      }
    }, 700);
  };

  const finishBattle = (winner, log, eHP, pHP) => {
    let finalLog = [...log];
    let xpGain = 0;

    setCombatsFought(combatsFought + 1);

    if (winner === "player") {
      xpGain = Math.round((20 + (enemy.stats.attaque + enemy.stats.defense) * 1.5 + (enemy.tier ? enemy.tier.powerMult * 15 : 0)) * careBonus.xpMult);
      finalLog.push(`🏆 ${enemy.name} est vaincu ! +${xpGain} XP`);
      setTotalWins(totalWins + 1);

      // Friendship
      setFriendship(f => f + 15);

      // Arena streak & rank
      const newStreak = arenaStreak + 1;
      setArenaStreak(newStreak);
      const nextRank = ARENA_RANKS.findIndex(r => newStreak < r.minStreak) - 1;
      const newRank = nextRank >= 0 ? Math.max(arenaRank, nextRank) : ARENA_RANKS.length - 1;
      if (newRank > arenaRank) {
        setArenaRank(newRank);
        finalLog.push(`🏅 Rang ${ARENA_RANKS[newRank].icon} ${ARENA_RANKS[newRank].name} atteint !`);
      }

      // Shop coins (capped)
      const coins = Math.min(5, Math.max(1, Math.round(xpGain * 0.08)));
      setShopCoins(c => Math.min(999, c + coins));
      finalLog.push(`💰 +${coins} pièces`);

      // Boss drops egg
      if (battleState.isBoss) {
        setEggs(eggs + 1);
        finalLog.push(`🥚 Tu récupères un œuf rare !`);
        // Boss defeat dialogue
        if (enemy.name && BOSS_DIALOGUES[enemy.name]?.after) {
          finalLog.push(`💬 ${enemy.name} : "${BOSS_DIALOGUES[enemy.name].after}"`);
        }
        // Generate AI story for this boss defeat
        if (battleState.zoneIdx !== undefined) {
          const zone = ZONES[battleState.zoneIdx];
          if (zone) generateAiStory(zone.name, enemy.name);
        }
        if (battleState.zoneIdx !== undefined) {
          const zone = ZONES[battleState.zoneIdx];
          setAchievements({ ...achievements, [`zone_${zone.key}_done`]: true, bossDefeated: true });
          if (battleState.zoneIdx >= adventureZone) {
            setAdventureZone(battleState.zoneIdx + 1);
            // Trigger cutscene for next zone
            const nextZone = ZONES[battleState.zoneIdx + 1];
            if (nextZone && ZONE_EVENTS[nextZone.key]) {
              const evt = ZONE_EVENTS[nextZone.key];
              setTimeout(() => setCutscene({ lines: evt.lines, current: 0, emoji: evt.emoji }), 1000);
            }
          }
        }
      }

      // Track zone wins for adventure (non-boss)
      if (battleState.isAdventure && !battleState.isBoss && battleState.zoneIdx !== undefined) {
        const zone = ZONES[battleState.zoneIdx];
        const currentWins = (zoneWinsMap[zone.key] || 0) + 1;
        setZoneWinsMap({ ...zoneWinsMap, [zone.key]: currentWins });
        if (currentWins >= zone.wins) {
          finalLog.push(`🔓 Boss de ${zone.name} débloqué !`);
        } else {
          finalLog.push(`🌿 Zone ${zone.name} : ${currentWins}/${zone.wins} combats`);
        }
      }

      // Rival defeated
      if (battleState.isRival) {
        setRivalDefeated(rivalDefeated + 1);
        finalLog.push(`🦇 ${RIVAL_NAME} est vaincu ! Il reviendra plus fort...`);
      }

      setBestiary(prev => {
        const key = enemy.name;
        const existing = prev[key] || { build: enemy.build, defeated: 0, encounters: 0 };
        return { ...prev, [key]: { ...existing, defeated: existing.defeated + 1, encounters: existing.encounters + 1, lastTier: enemy.tier?.name } };
      });

      let newXp = xp + xpGain;
      let newLevel = level;
      while (newXp >= newLevel * 50) {
        newXp -= newLevel * 50;
        newLevel += 1;
        finalLog.push(`⭐ NIVEAU ${newLevel} ATTEINT ! Stats améliorées.`);
        // Evolution at milestone levels
        if ([5, 10, 15].includes(newLevel)) {
          setEvolutionPending(newLevel);
          finalLog.push(`🧬 ÉVOLUTION ! Tu peux changer 1 partie gratuitement !`);
        }
        // Every level: random item bonus
        const rollItem = Math.random();
        const itemKey = rollItem < 0.4 ? "heal" : rollItem < 0.75 ? "boost" : "antidote";
        setInventory(prev => ({
          ...prev,
          [itemKey]: Math.min(5, (prev[itemKey] || 0) + 1),
        }));
        const itemInfo = ITEMS[itemKey];
        finalLog.push(`🎁 Niveau atteint : +1 ${itemInfo.emoji} ${itemInfo.name}`);
        // Every 3 levels: full restock
        if (newLevel % 3 === 0) {
          setInventory(prev => ({
            ...prev,
            heal: Math.min(5, (prev.heal || 0) + 2),
            antidote: Math.min(5, (prev.antidote || 0) + 1),
            boost: Math.min(5, (prev.boost || 0) + 2),
            food: Math.min(10, (prev.food || 0) + 3),
          }));
          finalLog.push(`🎁 Bonus palier : inventaire réapprovisionné !`);
        }
      }
      setXp(newXp);
      setLevel(newLevel);

      // Boss guaranteed drops
      if (battleState.isBoss) {
        setInventory(prev => ({
          ...prev,
          heal: Math.min(5, (prev.heal || 0) + 2),
          antidote: Math.min(5, (prev.antidote || 0) + 1),
          boost: Math.min(5, (prev.boost || 0) + 1),
          food: Math.min(10, (prev.food || 0) + 3),
        }));
        finalLog.push(`🎁 Butin du boss : +2🌿 +1💧 +1🍇 +3🍖`);
      } else {
        // Regular win: 40% chance to find an item
        if (Math.random() < 0.4) {
          const rollItem = Math.random();
          const itemKey = rollItem < 0.5 ? "heal" : rollItem < 0.8 ? "boost" : "antidote";
          setInventory(prev => ({
            ...prev,
            [itemKey]: Math.min(5, (prev[itemKey] || 0) + 1),
          }));
          const itemInfo = ITEMS[itemKey];
          finalLog.push(`🌿 Tu trouves en cueillant : +1 ${itemInfo.emoji} ${itemInfo.name}`);
        }
      }

      // Equipment drop (15% common, 5% rare, 1% epic)
      const lootRoll = Math.random();
      if (lootRoll < 0.21) {
        const pool = lootRoll < 0.01 ? EQUIPMENT_LIST.filter(e => e.rarity === "epic")
          : lootRoll < 0.06 ? EQUIPMENT_LIST.filter(e => e.rarity === "rare")
          : EQUIPMENT_LIST.filter(e => e.rarity === "common");
        const drop = pool[Math.floor(Math.random() * pool.length)];
        if (drop && !ownedEquipment.includes(drop.key)) {
          setOwnedEquipment([...ownedEquipment, drop.key]);
          const rarLabel = drop.rarity === "epic" ? "ÉPIQUE" : drop.rarity === "rare" ? "RARE" : "";
          finalLog.push(`${drop.emoji} Loot ${rarLabel}: ${drop.name} (${drop.desc})`);
        }
      }

      // Food drop (40% chance, 1-2 food)
      if (Math.random() < 0.4) {
        const foodQty = Math.random() < 0.3 ? 2 : 1;
        setInventory(prev => ({ ...prev, food: Math.min(10, (prev.food || 0) + foodQty) }));
        finalLog.push(`🍖 +${foodQty} Viande Séchée`);
      }

      // Fossil discovery (15% chance, not on boss)
      if (!battleState.isBoss && Math.random() < 0.15) {
        const exclusives = DINOS.filter(d => d.exclusive);
        const reward = exclusives[Math.floor(Math.random() * exclusives.length)];
        finalLog.push(`🦴 Tu as trouvé des fragments de fossile !`);
        setTimeout(() => setFossilPuzzle({ pieces: [], dinoReward: reward?.name || "Dino Mystère" }), 1500);
      }

      // Capture offer (30% chance)
      if (Math.random() < 0.3) {
        const parts = ["head", "teeth", "frontLegs", "backLegs", "back", "tail"];
        const partKey = parts[Math.floor(Math.random() * parts.length)];
        setCaptureOffer({ partKey, dinoIdx: enemy.build[partKey], dinoName: DINOS[enemy.build[partKey]].name });
        const partLabel = PARTS.find(p => p.key === partKey)?.label || partKey;
        finalLog.push(`🧬 Tu peux capturer : ${partLabel} de ${DINOS[enemy.build[partKey]].name}`);
      } else {
        setCaptureOffer(null);
      }

      // Victory animation
      setVictoryAnim(true);
      playSfx("victory");
      vibrate([50, 30, 50, 30, 100]);
      setTimeout(() => setVictoryAnim(false), 2000);
      const coinsGained = Math.min(5, Math.max(1, Math.round(xpGain * 0.08)));
      setTimeout(() => setBattleResultScreen({ winner: "player", xp: xpGain, coins: coinsGained, enemyName: enemy.name }), 800);

      if (tournament) {
        const nextTier = tournament.tier + 1;
        if (nextTier >= TOURNAMENT_TIERS.length) {
          finalLog.push(`👑 TOURNOI REMPORTÉ ! Tu es le maître de l'arène !`);
          setTournament(null);
        } else {
          finalLog.push(`🏟️ Prochain combat : ${TOURNAMENT_TIERS[nextTier].name}`);
          setTournament({ ...tournament, tier: nextTier, wins: tournament.wins + 1 });
        }
      }
    } else {
      finalLog.push(`💀 Tu es vaincu... ${enemy.name} t'a eu.`);
      playSfx("defeat");
      vibrate([200, 100, 200]);
      setArenaStreak(0);
      setTimeout(() => setBattleResultScreen({ winner: "enemy", xp: 0, coins: 0, enemyName: enemy.name }), 800);
      setBestiary(prev => {
        const key = enemy.name;
        const existing = prev[key] || { build: enemy.build, defeated: 0, encounters: 0 };
        return { ...prev, [key]: { ...existing, encounters: existing.encounters + 1 } };
      });
      if (tournament) {
        finalLog.push(`Tournoi terminé. Victoires : ${tournament.wins}/${TOURNAMENT_TIERS.length}`);
        setTournament(null);
      }
    }

    setBattleState({
      ...battleState,
      playerHP: pHP,
      enemyHP: eHP,
      log: finalLog,
      finished: true,
      winner,
      xpGain,
    });
  };

  const retryBattle = () => {
    if (!lastEnemyData) return;
    const e = lastEnemyData;
    setDefending(false);
    setLastAttackKey(null);
    setPlayerBoostTurns(0);
    const playerHP = Math.round(computeHP(playerStatsLeveled, trait, permaBonus.hp || 0) * careBonus.hpMult);
    const enemyHP = computeHP(e.stats, null);
    setEnemy(e);
    setPlayerStatus(null);
    setEnemyStatus(null);
    setPlayerCooldowns({});
    setEnemyCooldowns({});
    setConfirmFlee(false);
    const playerAttacks = getAvailableAttacks(build);
    const initialPlayerUses = {};
    playerAttacks.forEach(a => { initialPlayerUses[a.key] = getMaxUses(a, playerStatsLeveled, trait); });
    setPlayerUsesLeft(initialPlayerUses);
    const enemyAttacks = getAvailableAttacks(e.build);
    const initialEnemyUses = {};
    enemyAttacks.forEach(a => { initialEnemyUses[a.key] = getMaxUses(a, e.stats, null); });
    setEnemyUsesLeft(initialEnemyUses);
    setBattleState({
      playerHP, playerMaxHP: playerHP,
      enemyHP, enemyMaxHP: enemyHP,
      log: [`🔄 Revanche contre ${e.name} !`],
      turn: "player",
      finished: false,
      winner: null,
      isAdventure: battleState.isAdventure,
      isBoss: battleState.isBoss,
      zoneIdx: battleState.zoneIdx,
    });
  };

  const continueTournament = () => {
    if (tournament) startBattle(tournament.tier);
  };

  // Compute transform for the attacker based on attack type
  const getAttackTransform = (isPlayer) => {
    if (!attackAnim) return "";
    // For player (no flip): positive X goes right (toward enemy).
    // For enemy (wrapped in scaleX(-1)): positive X in local coords = visually LEFT (toward player) after the flip.
    // So BOTH use positive X to go toward the opponent.
    const forward = 1;
    if ((isPlayer && attackAnim.who === "player" && attackAnim.type === "attack")
        || (!isPlayer && attackAnim.who === "enemy" && attackAnim.type === "attack")) {
      const k = attackAnim.attackKey;
      // Bite-type: lunge all the way to the enemy
      if (k === "morsure" || k === "morsure_letela" || k === "morsure_letale" || k === "morsure_croc" || k === "broyeur") {
        return `translateX(${90 * forward}px) scale(1.15)`;
      }
      // Charge-type: massive charge
      if (k === "charge" || k === "charge_cornue" || k === "coup_de_dome") {
        return `translateX(${110 * forward}px) scale(1.1)`;
      }
      // Tail-type: stay back but big rotation
      if (k === "queue" || k === "fouet_caudal" || k === "massue_caudale") {
        return `rotate(${forward * 18}deg) translateX(${30 * forward}px) scale(1.05)`;
      }
      // Claws/bond: jump forward
      if (k === "griffes" || k === "bond_predateur") {
        return `translate(${85 * forward}px, -20px) scale(1.12)`;
      }
      // Spikes/sail: puff up (stays in place, intimidation)
      if (k === "armure_pic" || k === "voile_intim") {
        return `scale(1.3)`;
      }
      // Default attack
      return `translateX(${80 * forward}px) scale(1.08)`;
    }
    // Hit: recoil AWAY from attacker (opposite direction of "toward opponent")
    // Player recoils to the LEFT (-X in local), enemy recoils to the RIGHT visually
    // (which, in enemy's flipped local coords, is -X too).
    if ((isPlayer && attackAnim.who === "player" && attackAnim.type === "hit")
        || (!isPlayer && attackAnim.who === "enemy" && attackAnim.type === "hit")) {
      return `translateX(-25px) rotate(-4deg)`;
    }
    return "";
  };

  // Particle effect overlay for attacks
  const getAttackEffect = () => {
    if (!attackAnim) return null;
    const isPlayer = attackAnim.who === "player";
    const xPos = isPlayer ? "55%" : "25%";

    // Impact dust particles on HIT
    if (attackAnim.type === "hit") {
      return (
        <>
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={`dust-${i}`} style={{
              position: "absolute",
              top: `${35 + (i % 3) * 12}%`,
              left: `${parseInt(xPos) + (i - 3) * 5}%`,
              width: `${3 + i % 3}px`,
              height: `${3 + i % 3}px`,
              background: ["#f0ece0", "#e8a020", "#ff8888"][i % 3],
              borderRadius: "50%",
              pointerEvents: "none",
              zIndex: 15,
              animation: `dustPuff ${0.4 + i * 0.08}s ease-out forwards`,
              opacity: 0.8,
            }} />
          ))}
        </>
      );
    }

    if (attackAnim.type !== "attack") return null;
    const k = attackAnim.attackKey;
    const baseStyle = {
      position: "absolute",
      top: "45%",
      left: xPos,
      fontSize: "36px",
      pointerEvents: "none",
      zIndex: 15,
      animation: "effectPop 0.55s ease-out forwards",
      filter: "drop-shadow(0 0 8px rgba(255,216,56,0.8))",
    };
    // Sparkle particles around the emoji
    const sparkles = Array.from({ length: 4 }).map((_, i) => (
      <div key={`sp-${i}`} style={{
        position: "absolute",
        top: `${40 + (i - 2) * 8}%`,
        left: `${parseInt(xPos) + (i - 2) * 6}%`,
        width: "4px", height: "4px",
        background: "#f0b830",
        borderRadius: "50%",
        pointerEvents: "none",
        zIndex: 14,
        animation: `sparkle ${0.5 + i * 0.1}s ease-out ${i * 0.05}s forwards`,
      }} />
    ));
    let emoji = "💥";
    let svgOverlay = null;
    if (k === "morsure" || k === "morsure_letale" || k === "morsure_croc" || k === "broyeur") {
      emoji = "🦷";
      // Jaw clamp SVG
      svgOverlay = (
        <svg style={{ position: "absolute", top: "25%", left: `${parseInt(xPos) - 8}%`, width: "16%", height: "30%", zIndex: 16, pointerEvents: "none" }}
          viewBox="0 0 40 50">
          <path d="M5,25 L10,5 L15,22 L20,2 L25,22 L30,5 L35,25" fill="none" stroke="#f0ece0" strokeWidth="2.5" strokeLinecap="round"
            opacity="0" style={{ animation: "fadeIn 0.15s ease-out 0.1s forwards" }} />
          <path d="M5,25 L10,45 L15,28 L20,48 L25,28 L30,45 L35,25" fill="none" stroke="#f0ece0" strokeWidth="2.5" strokeLinecap="round"
            opacity="0" style={{ animation: "fadeIn 0.15s ease-out 0.2s forwards" }} />
        </svg>
      );
    } else if (k === "griffes" || k === "bond_predateur") {
      emoji = "🗡️";
      // Claw slash lines
      svgOverlay = (
        <svg style={{ position: "absolute", top: "20%", left: `${parseInt(xPos) - 10}%`, width: "20%", height: "40%", zIndex: 16, pointerEvents: "none" }}
          viewBox="0 0 40 50">
          {[0,1,2].map(i => (
            <line key={i} x1={5 + i * 8} y1={5} x2={25 + i * 5} y2={45}
              stroke={i === 1 ? "#ff4444" : "#ffaaaa"} strokeWidth="2" strokeLinecap="round"
              opacity="0" style={{ animation: `fadeIn 0.1s ease-out ${0.05 + i * 0.06}s forwards` }} />
          ))}
        </svg>
      );
    } else if (k === "charge" || k === "charge_cornue" || k === "coup_de_dome") {
      emoji = k === "coup_de_dome" ? "💫" : "💥";
      // Impact shockwave circles
      svgOverlay = (
        <svg style={{ position: "absolute", top: "30%", left: `${parseInt(xPos) - 6}%`, width: "12%", height: "20%", zIndex: 16, pointerEvents: "none" }}
          viewBox="0 0 40 40">
          {[0,1,2].map(i => (
            <circle key={i} cx="20" cy="20" r={8 + i * 6} fill="none"
              stroke="rgba(248,200,64,0.6)" strokeWidth="1.5"
              opacity="0" style={{ animation: `dustPuff ${0.4 + i * 0.15}s ease-out ${i * 0.08}s forwards` }} />
          ))}
        </svg>
      );
    } else if (k === "queue" || k === "fouet_caudal" || k === "massue_caudale") {
      emoji = k === "massue_caudale" ? "🔨" : "🌀";
      // Tail sweep arc
      svgOverlay = (
        <svg style={{ position: "absolute", top: "30%", left: `${parseInt(xPos) - 12}%`, width: "24%", height: "25%", zIndex: 16, pointerEvents: "none" }}
          viewBox="0 0 60 40">
          <path d="M10,35 Q30,5 55,20" fill="none" stroke="rgba(248,200,64,0.7)" strokeWidth="3" strokeLinecap="round"
            strokeDasharray="50" strokeDashoffset="50" style={{ animation: "dashIn 0.3s ease-out 0.1s forwards" }} />
        </svg>
      );
    } else if (k === "voile_intim" || k === "armure_pic") {
      emoji = k === "voile_intim" ? "🔥" : "⚡";
    }
    return (
      <>
        <div style={{ ...baseStyle, fontSize: "42px" }}>{emoji}</div>
        {svgOverlay}
        {sparkles}
      </>
    );
  };

  // Get glow filter for active attack
  const getAttackFilter = (isPlayer) => {
    if (!attackAnim) return "";
    const attacking = (isPlayer && attackAnim.who === "player" && attackAnim.type === "attack")
      || (!isPlayer && attackAnim.who === "enemy" && attackAnim.type === "attack");
    const hit = (isPlayer && attackAnim.who === "player" && attackAnim.type === "hit")
      || (!isPlayer && attackAnim.who === "enemy" && attackAnim.type === "hit");
    if (hit) return "brightness(1.8) saturate(0)";
    if (attacking && attackAnim.special) return "drop-shadow(0 0 12px rgba(255,216,56,0.9)) brightness(1.1)";
    if (attacking) return "drop-shadow(0 0 6px rgba(245,236,210,0.6))";
    return "";
  };


  // Pokémon-style HP bar color
  const hpBarColor = (pct) => {
    if (pct > 50) return "linear-gradient(90deg, #28884a 0%, #e8a020 50%, #f8c840 100%)";
    if (pct > 25) return "linear-gradient(90deg, #b8a020 0%, #e8d040 50%, #f0e060 100%)";
    return "linear-gradient(90deg, #a02020 0%, #e04040 50%, #f06060 100%)";
  };
  const hpBarShadow = (pct) => {
    if (pct > 50) return "0 0 6px rgba(104,245,168,0.5)";
    if (pct > 25) return "0 0 6px rgba(232,208,64,0.5)";
    return "0 0 6px rgba(240,96,96,0.5)";
  };

  return (
    <div style={{
      minHeight: "100vh",
      background: `
        radial-gradient(ellipse at top, #2a9d8f 0%, #1d7a6f 45%, #141810 100%),
        linear-gradient(180deg, #1d7a6f 0%, #141810 100%)
      `,
      backgroundBlendMode: "multiply",
      fontFamily: "system-ui, -apple-system, sans-serif",
      color: "#f0ece0",
      paddingBottom: "70px",
      position: "relative",
    }}>
      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(6px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes shimmer {
          0%, 100% { opacity: 0.85; }
          50% { opacity: 1; }
        }
        @keyframes pulse {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.04); }
        }
        @keyframes eggShake {
          0%, 100% { transform: rotate(0deg); }
          25% { transform: rotate(-3deg); }
          75% { transform: rotate(3deg); }
        }
        @keyframes confettiFall {
          0% { transform: translateY(-10px) rotate(0deg); opacity: 1; }
          100% { transform: translateY(120px) rotate(720deg); opacity: 0; }
        }
        @keyframes lightning {
          0% { opacity: 1; filter: brightness(3); }
          30% { opacity: 0.7; }
          60% { opacity: 1; filter: brightness(2); }
          100% { opacity: 0; }
        }
        @keyframes dustPuff {
          0% { transform: scale(0.3) translateY(0); opacity: 0.35; }
          60% { transform: scale(1.3) translateY(-5px); opacity: 0.15; }
          100% { transform: scale(2) translateY(-10px); opacity: 0; }
        }
        @keyframes cinematicZoom {
          0% { transform: scale(1); filter: blur(0); opacity: 1; }
          60% { transform: scale(2.5); filter: blur(6px); opacity: 0.4; }
          100% { transform: scale(3.5); filter: blur(12px); opacity: 0; }
        }
        @keyframes cinematicReveal {
          0% { transform: scale(0.7); filter: blur(8px); opacity: 0; }
          60% { transform: scale(1.04); filter: blur(1px); opacity: 0.9; }
          100% { transform: scale(1); filter: blur(0); opacity: 1; }
        }
        @keyframes floatUp {
          0% { transform: translateY(0); opacity: 0; }
          10% { opacity: 0.6; }
          90% { opacity: 0.3; }
          100% { transform: translateY(-105vh); opacity: 0; }
        }
        @keyframes dashIn {
          to { stroke-dashoffset: 0; }
        }
        @keyframes sparkle {
          0% { transform: scale(0) rotate(0); opacity: 0; }
          50% { transform: scale(1) rotate(180deg); opacity: 1; }
          100% { transform: scale(0) rotate(360deg); opacity: 0; }
        }
        @keyframes impactBurst {
          0% { transform: scale(0.3); opacity: 1; }
          100% { transform: scale(2.5); opacity: 0; }
        }
        @keyframes dustPuff {
          0% { transform: translateY(0) scale(0.5); opacity: 0.6; }
          100% { transform: translateY(-15px) scale(1.5); opacity: 0; }
        }
        @keyframes splashIn {
          0% { transform: scale(0.5); opacity: 0; }
          60% { transform: scale(1.05); opacity: 1; }
          100% { transform: scale(1); opacity: 1; }
        }
        .view-enter { animation: cinematicReveal 0.4s ease-out; }
        button { transition: transform 0.12s ease-out, box-shadow 0.15s ease-out, filter 0.15s; border-radius: 10px; }
        button:not(:disabled):active { transform: scale(0.96); }
        button:not(:disabled):hover { filter: brightness(1.08); }
        .card-raised {
          box-shadow: 0 4px 16px rgba(0,0,0,0.25), inset 0 1px 0 rgba(255,248,230,0.05);
          border-radius: 14px;
        }
        .card-parchment {
          background: rgba(255,248,230,0.04);
          backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
          box-shadow: 0 4px 20px rgba(0,0,0,0.25), inset 0 1px 0 rgba(255,248,230,0.07);
          border-radius: 16px;
        }
        .shimmer-gold { animation: shimmer 2.5s ease-in-out infinite; }
      `}</style>

      {/* Vignette */}
      <div style={{
        position: "fixed", inset: 0, pointerEvents: "none", zIndex: 99,
        background: "radial-gradient(ellipse at center, transparent 60%, rgba(10,12,25,0.35) 100%)",
      }} />



      {/* Contextual overlay per view */}
      <div style={{
        position: "fixed", inset: 0, pointerEvents: "none", zIndex: 1, opacity: 0.15,
        transition: "background 0.5s ease-out",
        background: view === "build"
          ? "radial-gradient(circle at 20% 80%, rgba(200,152,88,0.3), transparent 50%), radial-gradient(circle at 80% 20%, rgba(60,90,70,0.25), transparent 50%)"
          : view === "adventure"
            ? "radial-gradient(circle at 30% 20%, rgba(120,160,90,0.25), transparent 55%), radial-gradient(circle at 70% 80%, rgba(60,90,120,0.2), transparent 50%)"
            : view === "battle"
              ? "radial-gradient(circle at 50% 0%, rgba(200,56,56,0.25), transparent 60%), radial-gradient(circle at 50% 100%, rgba(80,20,20,0.3), transparent 50%)"
              : view === "gallery"
                ? "radial-gradient(circle at 50% 50%, rgba(212,175,55,0.15), transparent 65%)"
                : view === "bestiary"
                  ? "radial-gradient(circle at 30% 60%, rgba(140,80,40,0.2), transparent 55%), radial-gradient(circle at 75% 30%, rgba(100,60,20,0.18), transparent 50%)"
                  : "radial-gradient(circle at 50% 20%, rgba(200,152,88,0.25), transparent 60%)",
      }} />

      {/* Header */}
      {/* Type chart modal */}
      {showTypeChart && (
        <div onClick={() => setShowTypeChart(false)} style={{
          position: "fixed", inset: 0, zIndex: 220,
          background: "rgba(0,0,0,0.85)",
          display: "flex", alignItems: "center", justifyContent: "center",
          padding: "12px",
        }}>
          <div onClick={e => e.stopPropagation()} style={{
            background: "linear-gradient(135deg, #141810, #0e120a)",
            border: "2px solid #e8a020",
            borderRadius: "12px",
            padding: "16px",
            maxWidth: "340px", width: "100%",
          }}>
            <div style={{ textAlign: "center", fontSize: "14px", fontWeight: 900, color: "#e8a020", marginBottom: "10px", letterSpacing: "2px" }}>
              TABLEAU DES TYPES
            </div>
            <div style={{ fontSize: "9px", opacity: 0.75, textAlign: "center", marginBottom: "8px" }}>
              ×1.5 = super efficace · ×0.7 = peu efficace
            </div>
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "10px" }}>
              <thead>
                <tr>
                  <th style={{ padding: "4px", borderBottom: "1px solid #2a2820" }}>ATQ ↓ / DEF →</th>
                  {Object.keys(TYPE_EMOJI).map(t => (
                    <th key={t} style={{ padding: "4px", borderBottom: "1px solid #2a2820" }}>{TYPE_EMOJI[t]}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {Object.keys(TYPE_EMOJI).map(atk => (
                  <tr key={atk}>
                    <td style={{ padding: "4px", fontWeight: 700, borderRight: "1px solid #2a2820" }}>{TYPE_EMOJI[atk]} {atk}</td>
                    {Object.keys(TYPE_EMOJI).map(def => {
                      const mult = TYPE_CHART[atk]?.[def] || 1;
                      return (
                        <td key={def} style={{
                          padding: "4px", textAlign: "center",
                          color: mult > 1 ? "#f8c840" : mult < 1 ? "#ff8888" : "#888",
                          fontWeight: mult !== 1 ? 700 : 400,
                          background: mult > 1 ? "rgba(104,245,168,0.1)" : mult < 1 ? "rgba(255,136,136,0.1)" : "transparent",
                        }}>
                          {mult === 1 ? "—" : `×${mult}`}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Encyclopedia detail modal */}
      {selectedDex && (
        <div onClick={() => setSelectedDex(null)} style={{
          position: "fixed", inset: 0, zIndex: 220,
          background: "rgba(0,0,0,0.88)",
          display: "flex", alignItems: "center", justifyContent: "center",
          padding: "16px",
        }}>
          <div onClick={e => e.stopPropagation()} style={{
            width: "100%", maxWidth: "340px",
            background: "linear-gradient(145deg, #1a2818 0%, #141810 100%)",
            border: "2px solid #e8a020",
            borderRadius: "16px",
            padding: "16px",
            maxHeight: "85vh",
            overflowY: "auto",
          }}>
            {/* Dino art */}
            <div style={{ width: "120px", margin: "0 auto 10px" }}>
              <DinoArt build={selectedDex.build} />
            </div>
            <div style={{ textAlign: "center", marginBottom: "12px" }}>
              <div style={{ fontSize: "18px", fontWeight: 900, color: "#e8a020" }}>{selectedDex.name}</div>
              {selectedDex.build?.head !== undefined && (
                <div style={{ fontSize: "10px", opacity: 0.65, marginTop: "2px" }}>
                  Espèce dominante : {DINOS[selectedDex.build.head]?.name || "?"}
                </div>
              )}
              <div style={{ fontSize: "10px", opacity: 0.75, marginTop: "2px" }}>{selectedDex.encounters}× rencontré · {selectedDex.defeated}× vaincu</div>
            </div>
            {/* Real facts - lookup by head dino species name */}
            {(() => {
              const headName = selectedDex.build?.head !== undefined ? DINOS[selectedDex.build.head]?.name : null;
              const facts = getDinoFacts(headName || selectedDex.name) || getDinoFacts(selectedDex.name);
              if (!facts) return (
                <div style={{ fontSize: "10px", opacity: 0.65, textAlign: "center", padding: "10px" }}>
                  Hybride unique — pas de correspondance dans les registres fossiles.
                  <div style={{ marginTop: "6px", fontSize: "9px" }}>
                    Composé de : {["head","teeth","frontLegs","backLegs","back","tail"].map(pk => 
                      DINOS[selectedDex.build?.[pk]]?.name
                    ).filter(Boolean).filter((v,i,a) => a.indexOf(v) === i).join(", ")}
                  </div>
                </div>
              );
              return (
                <>
                  {/* Size comparison */}
                  <div style={{ padding: "10px", background: "rgba(0,0,0,0.3)", borderRadius: "10px", marginBottom: "8px" }}>
                    <div style={{ fontSize: "9px", opacity: 0.65, letterSpacing: "1px", marginBottom: "6px" }}>FICHE SCIENTIFIQUE</div>
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "4px", fontSize: "10px" }}>
                      <div>📏 <strong>{facts.size}</strong></div>
                      <div>⚖️ <strong>{facts.weight}</strong></div>
                      <div>🍖 <strong>{facts.diet}</strong></div>
                      <div>🌍 <strong style={{ fontSize: "9px" }}>{facts.loc}</strong></div>
                    </div>
                    <div style={{ fontSize: "9px", marginTop: "4px", opacity: 0.75 }}>
                      🕐 {facts.era}
                    </div>
                  </div>
                  {/* Timeline bar */}
                  <div style={{ padding: "6px 10px", background: "rgba(0,0,0,0.2)", borderRadius: "8px", marginBottom: "8px" }}>
                    <div style={{ fontSize: "8px", opacity: 0.65, marginBottom: "3px" }}>FRISE CHRONOLOGIQUE</div>
                    <div style={{ display: "flex", height: "12px", borderRadius: "6px", overflow: "hidden", border: "1px solid #2a2820" }}>
                      <div style={{ flex: 1, background: "#8a3030", textAlign: "center", fontSize: "6px", lineHeight: "12px" }}>Trias</div>
                      <div style={{ flex: 1, background: facts.era.includes("Jurassique") ? "#e8a020" : "#3a5828", textAlign: "center", fontSize: "6px", lineHeight: "12px" }}>Jurassique</div>
                      <div style={{ flex: 1, background: facts.era.includes("Crétacé") ? "#e8a020" : "#28483a", textAlign: "center", fontSize: "6px", lineHeight: "12px" }}>Crétacé</div>
                    </div>
                  </div>
                  {/* Fun facts */}
                  <div style={{ padding: "8px 10px", background: "rgba(0,0,0,0.2)", borderRadius: "8px" }}>
                    <div style={{ fontSize: "9px", opacity: 0.65, letterSpacing: "1px", marginBottom: "6px" }}>LE SAVAIS-TU ?</div>
                    {facts.facts.map((f, i) => (
                      <div key={i} style={{ fontSize: "10px", marginBottom: "4px", lineHeight: 1.4, paddingLeft: "14px", position: "relative" }}>
                        <span style={{ position: "absolute", left: 0 }}>🦴</span> {f}
                      </div>
                    ))}
                  </div>
                  {/* Size comparison with human */}
                  <div style={{ marginTop: "8px", textAlign: "center", padding: "8px", background: "rgba(0,0,0,0.2)", borderRadius: "8px" }}>
                    <div style={{ fontSize: "8px", opacity: 0.65, marginBottom: "4px" }}>COMPARAISON DE TAILLE</div>
                    <div style={{ display: "flex", alignItems: "flex-end", justifyContent: "center", gap: "12px", height: "50px" }}>
                      <div style={{ textAlign: "center" }}>
                        <div style={{ fontSize: "18px" }}>🧑</div>
                        <div style={{ fontSize: "7px", opacity: 0.65 }}>1.7m</div>
                      </div>
                      <div style={{ textAlign: "center" }}>
                        <div style={{ fontSize: `${Math.min(40, Math.max(12, parseFloat(facts.size) * 3))}px` }}>🦕</div>
                        <div style={{ fontSize: "7px", opacity: 0.65 }}>{facts.size}</div>
                      </div>
                    </div>
                  </div>
                </>
              );
            })()}
          </div>
        </div>
      )}

      {/* Fossil dig mini-game — 8x8 grid */}
      {fossilPuzzle && (() => {
        const gridSize = 6;
        const totalCells = gridSize * gridSize;
        const maxTaps = 20;
        const tapsUsed = fossilPuzzle.taps || 0;
        const found = fossilPuzzle.pieces || [];
        const complete = found.length >= 5;
        const bonePositions = fossilBonePositions;

        return (
        <div onClick={() => { if (complete || tapsUsed >= maxTaps) setFossilPuzzle(null); }} style={{
          position: "fixed", inset: 0, zIndex: 220,
          background: "rgba(0,0,0,0.92)",
          display: "flex", alignItems: "center", justifyContent: "center",
          padding: "16px",
        }}>
          <div onClick={e => e.stopPropagation()} style={{
            width: "100%", maxWidth: "340px",
            background: "linear-gradient(145deg, #2a2418 0%, #141810 100%)",
            border: "2px solid #c8a060",
            borderRadius: "16px",
            padding: "16px",
          }}>
            <div style={{ textAlign: "center", marginBottom: "8px" }}>
              <div style={{ fontSize: "14px", fontWeight: 900, color: "#c8a060", letterSpacing: "2px" }}>⛏ FOUILLES PALÉO</div>
              <div style={{ fontSize: "9px", opacity: 0.65 }}>Trouve les 5 os ! ({maxTaps - tapsUsed} taps restants)</div>
            </div>

            {/* Progress bar */}
            <div style={{ display: "flex", gap: "4px", justifyContent: "center", marginBottom: "8px" }}>
              {[0,1,2,3,4].map(i => (
                <div key={i} style={{
                  width: "24px", height: "24px", borderRadius: "6px",
                  background: i < found.length ? "rgba(232,160,32,0.3)" : "rgba(255,248,230,0.05)",
                  border: `1px solid ${i < found.length ? "#e8a020" : "#2a2820"}`,
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: "14px",
                }}>{i < found.length ? "🦴" : "?"}</div>
              ))}
            </div>

            {/* 8x8 dig grid */}
            <div style={{
              display: "grid",
              gridTemplateColumns: `repeat(${gridSize}, 1fr)`,
              gap: "2px",
              background: "#1a1610",
              padding: "4px",
              borderRadius: "8px",
              border: "1px solid #2a2418",
            }}>
              {Array.from({ length: totalCells }).map((_, idx) => {
                const dug = fossilPuzzle.dugCells?.includes(idx);
                const hasBone = bonePositions.includes(idx);
                const boneFound = dug && hasBone;
                const boneIdx = bonePositions.indexOf(idx);
                const boneLabels = ["Crâne", "Colonne", "Côtes", "Pattes", "Queue"];
                return (
                  <div key={idx}
                    onClick={(e) => {
                      e.stopPropagation();
                      if (dug || complete || tapsUsed >= maxTaps) return;
                      const newDug = [...(fossilPuzzle.dugCells || []), idx];
                      const newFound = hasBone ? [...found, boneIdx] : found;
                      const newTaps = tapsUsed + 1;
                      if (hasBone) {
                        playSfx("crit");
                        vibrate([30, 20, 50]);
                      } else {
                        playSfx("hit");
                        vibrate(15);
                      }
                      setFossilPuzzle({ ...fossilPuzzle, dugCells: newDug, pieces: newFound, taps: newTaps });
                      // Complete?
                      if (newFound.length >= 5) {
                        const exclIdx = DINOS.findIndex(d => d.name === fossilPuzzle.dinoReward);
                        if (exclIdx >= 0) {
                          setUnlockedExclusives(prev => prev.includes(exclIdx) ? prev : [...prev, exclIdx]);
                        }
                        setTimeout(() => { playSfx("victory"); vibrate([50,30,50,30,100]); }, 300);
                      }
                    }}
                    style={{
                      aspectRatio: "1", borderRadius: "3px",
                      background: boneFound
                        ? "linear-gradient(135deg, #c8a060, #e8c080)"
                        : dug
                          ? "linear-gradient(145deg, #1a1008, #2a1c0c)" // Dark earth = clearly dug
                          : `linear-gradient(145deg, hsl(${30+(idx*7)%10},${20+idx%8}%,${22+(idx*3)%5}%), hsl(${28+(idx*5)%10},${18+idx%6}%,${26+(idx*2)%4}%))`,
                      cursor: dug || complete ? "default" : "pointer",
                      display: "flex", alignItems: "center", justifyContent: "center",
                      fontSize: boneFound ? "18px" : "11px",
                      color: boneFound ? "#1a1610" : "#5a4a30",
                      fontWeight: 700,
                      border: boneFound
                        ? "2px solid #e8a020"
                        : dug
                          ? "1px solid #0a0a06"  // Very dark border = depth
                          : "1px solid rgba(80,60,30,0.4)",
                      boxShadow: dug && !boneFound
                        ? "inset 0 2px 6px rgba(0,0,0,0.6)"  // Inset shadow = hole
                        : boneFound
                          ? "0 0 8px rgba(232,160,32,0.4)"
                          : "0 1px 2px rgba(0,0,0,0.3)",
                      transition: "all 0.15s",
                      position: "relative",
                      overflow: "hidden",
                    }}
                  >
                    {boneFound ? "🦴" : ""}
                    {/* Dig texture for empty dug cells */}
                    {dug && !hasBone && (
                      <div style={{
                        position: "absolute", inset: 0,
                        background: "radial-gradient(ellipse at center, #150e06 30%, #1e1508 100%)",
                        opacity: 0.8,
                      }} />
                    )}
                    {/* Pick mark for undig cells */}
                    {!dug && !complete && (
                      <span style={{ opacity: 0.2, fontSize: "14px" }}>⛏</span>
                    )}
                    {/* Nearby bone hint */}
                    {dug && !hasBone && (() => {
                      const row = Math.floor(idx / gridSize);
                      const col = idx % gridSize;
                      let adj = 0;
                      bonePositions.forEach(bp => {
                        const br = Math.floor(bp / gridSize);
                        const bc = bp % gridSize;
                        if (Math.abs(br - row) <= 1 && Math.abs(bc - col) <= 1) adj++;
                      });
                      return adj > 0 ? (
                        <span style={{
                          position: "relative", zIndex: 1,
                          color: adj >= 2 ? "#e8a020" : "#a08040",
                          fontSize: "13px", fontWeight: 900,
                          textShadow: "0 1px 2px rgba(0,0,0,0.8)",
                        }}>{adj}</span>
                      ) : null;
                    })()}
                  </div>
                );
              })}
            </div>

            {/* Result */}
            {complete && (
              <div onClick={() => setFossilPuzzle(null)} style={{
                textAlign: "center", marginTop: "10px", padding: "12px",
                background: "rgba(232,160,32,0.1)", borderRadius: "10px",
                border: "1px solid #e8a020", cursor: "pointer",
                animation: "splashIn 0.5s ease-out",
              }}>
                <div style={{ fontSize: "18px", color: "#e8a020", fontWeight: 900 }}>🎉 FOSSILE COMPLET !</div>
                <div style={{ fontSize: "12px", marginTop: "4px" }}>
                  <strong style={{ color: "#c888e8" }}>{fossilPuzzle.dinoReward}</strong> débloqué ★
                </div>
              </div>
            )}
            {tapsUsed >= maxTaps && !complete && (
              <div onClick={() => setFossilPuzzle(null)} style={{
                textAlign: "center", marginTop: "10px", padding: "12px",
                background: "rgba(200,40,40,0.1)", borderRadius: "10px",
                border: "1px solid #cc3030", cursor: "pointer",
              }}>
                <div style={{ fontSize: "14px", color: "#cc3030", fontWeight: 700 }}>Plus de taps !</div>
                <div style={{ fontSize: "10px", opacity: 0.65, marginTop: "4px" }}>
                  {found.length}/5 os trouvés. Retente ta chance au prochain fossile !
                </div>
              </div>
            )}
          </div>
        </div>
        );
      })()}

      {/* Battle result screen — Victory */}
      {battleResultScreen?.winner === "player" && (
        <div onClick={() => setBattleResultScreen(null)} style={{
          position: "fixed", inset: 0, zIndex: 245,
          background: "radial-gradient(ellipse at 50% 40%, rgba(40,80,30,0.95), rgba(10,14,8,0.98))",
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
          cursor: "pointer",
        }}>
          {/* Confetti */}
          {Array.from({ length: 20 }).map((_, i) => (
            <div key={`conf${i}`} style={{
              position: "absolute",
              top: "-5%",
              left: `${5 + (i * 13) % 90}%`,
              width: `${4 + i % 4}px`, height: `${4 + i % 4}px`,
              borderRadius: i % 3 === 0 ? "50%" : "1px",
              background: ["#e8a020", "#c888e8", "#48a848", "#f8c840", "#68a8f5"][i % 5],
              animation: `confettiFall ${2 + i * 0.2}s ease-in ${i * 0.15}s infinite`,
              opacity: 0.8,
            }} />
          ))}
          <div style={{ textAlign: "center", animation: "splashIn 0.5s ease-out" }}>
            {/* Dino dancing */}
            <div style={{
              width: "140px", margin: "0 auto 12px",
              animation: "dinoWalk 0.4s ease-in-out infinite",
              filter: "drop-shadow(0 0 20px rgba(232,160,32,0.4))",
            }}>
              <DinoArt build={build} pattern={pattern} />
            </div>
            <div style={{
              fontSize: "28px", fontWeight: 900, letterSpacing: "6px",
              background: "linear-gradient(180deg, #f8f0d0, #e8a020)",
              WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
              backgroundClip: "text",
              marginBottom: "6px",
            }}>
              VICTOIRE
            </div>
            <div style={{ fontSize: "11px", opacity: 0.85, marginBottom: "16px" }}>
              {battleResultScreen.enemyName} est vaincu !
            </div>
            {/* Rewards */}
            <div style={{
              display: "flex", gap: "20px", justifyContent: "center",
              padding: "12px 20px",
              background: "rgba(232,160,32,0.08)",
              border: "1px solid rgba(232,160,32,0.2)",
              borderRadius: "12px",
            }}>
              <div style={{ textAlign: "center" }}>
                <div style={{ fontSize: "22px" }}>⭐</div>
                <div style={{ fontSize: "14px", fontWeight: 900, color: "#e8a020" }}>+{battleResultScreen.xp}</div>
                <div style={{ fontSize: "8px", opacity: 0.65 }}>XP</div>
              </div>
              <div style={{ textAlign: "center" }}>
                <div style={{ fontSize: "22px" }}>💰</div>
                <div style={{ fontSize: "14px", fontWeight: 900, color: "#f8c840" }}>+{battleResultScreen.coins}</div>
                <div style={{ fontSize: "8px", opacity: 0.65 }}>Pièces</div>
              </div>
            </div>
            <div style={{ fontSize: "10px", opacity: 0.4, marginTop: "20px", animation: "pulse 2s infinite" }}>
              Toucher pour continuer
            </div>
          </div>
        </div>
      )}

      {/* Battle result screen — Defeat */}
      {battleResultScreen?.winner === "enemy" && (
        <div onClick={() => setBattleResultScreen(null)} style={{
          position: "fixed", inset: 0, zIndex: 245,
          background: "radial-gradient(ellipse at 50% 60%, rgba(80,20,20,0.95), rgba(14,8,8,0.98))",
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
          cursor: "pointer",
        }}>
          <div style={{ textAlign: "center", animation: "splashIn 0.6s ease-out" }}>
            {/* Dino falling */}
            <div style={{
              width: "120px", margin: "0 auto 16px",
              transform: "rotate(15deg)",
              opacity: 0.5,
              filter: "grayscale(0.6) drop-shadow(0 8px 16px rgba(0,0,0,0.8))",
            }}>
              <DinoArt build={build} crying={true} pattern={pattern} />
            </div>
            <div style={{
              fontSize: "28px", fontWeight: 900, letterSpacing: "6px",
              color: "#cc3030",
              textShadow: "0 0 20px rgba(200,40,40,0.4), 0 2px 4px rgba(0,0,0,0.5)",
              marginBottom: "8px",
            }}>
              DÉFAITE
            </div>
            <div style={{ fontSize: "11px", opacity: 0.75, marginBottom: "24px" }}>
              {battleResultScreen.enemyName} t'a vaincu...
            </div>
            <div style={{
              padding: "12px 24px",
              background: "rgba(200,40,40,0.15)",
              border: "1px solid rgba(200,40,40,0.3)",
              borderRadius: "10px",
              fontSize: "12px", fontWeight: 700, color: "#f08080",
              animation: "pulse 1.5s infinite",
            }}>
              ⚔ TOUCHER POUR LA REVANCHE
            </div>
          </div>
        </div>
      )}

      {/* AI naming result toast */}
      {aiNaming && aiNaming !== "loading" && (
        <div style={{
          position: "fixed", top: "80px", left: "50%", transform: "translateX(-50%)",
          zIndex: 250, background: "rgba(200,136,232,0.15)", border: "1px solid #c888e8",
          borderRadius: "12px", padding: "12px 20px", textAlign: "center",
          backdropFilter: "blur(12px)", animation: "cinematicReveal 0.3s ease-out",
          maxWidth: "300px",
        }}>
          <div style={{ fontSize: "16px", fontWeight: 900, color: "#c888e8" }}>✨ {aiNaming.name}</div>
          <div style={{ fontSize: "10px", opacity: 0.85, marginTop: "4px" }}>{aiNaming.desc}</div>
        </div>
      )}

      {/* AI story overlay */}
      {aiStory && (
        <div onClick={() => setAiStory(null)} style={{
          position: "fixed", inset: 0, zIndex: 240,
          background: "rgba(0,0,0,0.88)",
          display: "flex", alignItems: "center", justifyContent: "center",
          padding: "30px", cursor: "pointer",
        }}>
          <div style={{ textAlign: "center", animation: "cinematicReveal 0.5s ease-out", maxWidth: "300px" }}>
            <div style={{ fontSize: "30px", marginBottom: "12px" }}>📖</div>
            <div style={{ fontSize: "14px", color: "#f0ece0", lineHeight: 1.7, fontStyle: "italic" }}>
              {aiStory}
            </div>
            <div style={{ fontSize: "9px", opacity: 0.4, marginTop: "16px" }}>Toucher pour continuer</div>
          </div>
        </div>
      )}

      {/* AI advice overlay */}
      {aiAdvice && (
        <div onClick={() => setAiAdvice(null)} style={{
          position: "fixed", bottom: "90px", left: "50%", transform: "translateX(-50%)",
          zIndex: 250, background: "rgba(232,160,32,0.12)", border: "1px solid #e8a020",
          borderRadius: "12px", padding: "12px 16px", textAlign: "center",
          backdropFilter: "blur(12px)", animation: "cinematicReveal 0.3s ease-out",
          maxWidth: "300px", cursor: "pointer",
        }}>
          <div style={{ fontSize: "11px", fontWeight: 700, color: "#e8a020", marginBottom: "4px" }}>🧠 Conseil tactique</div>
          <div style={{ fontSize: "10px", lineHeight: 1.5 }}>{aiAdvice}</div>
        </div>
      )}

      {/* Runner mini-game overlay */}
      {runner && (
        <div
          onClick={() => {
            if (runner.active && !runner.jumping) {
              setRunner(prev => prev ? { ...prev, jumping: true, jumpStart: Date.now() } : null);
            } else if (!runner.active) {
              setRunner(null);
            }
          }}
          style={{
            position: "fixed", inset: 0, zIndex: 230,
            background: "rgba(0,0,0,0.95)",
            display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
            cursor: "pointer",
          }}
        >
          {runner.active ? (
            <>
              <div style={{ fontSize: "12px", fontWeight: 900, color: "#e8a020", marginBottom: "8px", letterSpacing: "2px" }}>
                SCORE : {runner.score}
              </div>
              <svg viewBox="0 0 100 40" style={{ width: "100%", maxWidth: "360px", background: "linear-gradient(180deg, #1a2818 0%, #1a2010 70%, #2a3018 100%)", borderRadius: "10px", border: "1px solid #2a2820" }}>
                {/* Ground */}
                <line x1="0" y1="33" x2="100" y2="33" stroke="#4a4828" strokeWidth="0.5" />
                <rect x="0" y="33" width="100" height="7" fill="#22280e" />
                {/* Ground details */}
                {[10,25,45,60,80].map((x,i) => (
                  <circle key={`g${i}`} cx={x} cy="34" r="0.5" fill="#3a3820" opacity="0.5" />
                ))}
                {/* Dino — faces RIGHT */}
                <text x="18" y={31 - runner.dinoY * 0.65} fontSize="9" textAnchor="middle"
                  style={{ transform: "scaleX(-1)", transformOrigin: "18px 27px" }}>🦖</text>
                {/* Shadow under dino */}
                <ellipse cx="18" cy="33" rx={runner.dinoY > 5 ? 3 : 4} ry="1"
                  fill="rgba(0,0,0,0.2)" opacity={runner.dinoY > 5 ? 0.3 : 0.5} />
                {/* Obstacles — rocks with warning */}
                {runner.obstacles.map(o => (
                  <g key={o.id}>
                    <rect x={o.x} y={33 - o.h * 0.45} width="3.5" height={o.h * 0.45}
                      fill="#7a4020" rx="0.8" />
                    <rect x={o.x + 0.5} y={33 - o.h * 0.45 + 1} width="2.5" height={o.h * 0.3}
                      fill="#9a5830" rx="0.5" opacity="0.5" />
                    {/* Warning indicator for far obstacles */}
                    {o.x > 70 && (
                      <text x={o.x} y={33 - o.h * 0.45 - 3} fontSize="3" fill="#e8a020" opacity="0.6">⚠</text>
                    )}
                  </g>
                ))}
                {/* Speed lines */}
                {[12, 20, 28].map((y,i) => (
                  <line key={`sp${i}`} x1={2 + i * 2} y1={y} x2={5 + i * 3} y2={y}
                    stroke="rgba(240,236,224,0.08)" strokeWidth="0.4" />
                ))}
              </svg>
              <div style={{ fontSize: "10px", opacity: 0.5, marginTop: "10px", animation: "pulse 1s infinite" }}>
                👆 TAP POUR SAUTER
              </div>
            </>
          ) : (
            <div style={{ textAlign: "center", animation: "cinematicReveal 0.3s" }}>
              <div style={{ fontSize: "40px", marginBottom: "8px" }}>💀</div>
              <div style={{ fontSize: "16px", fontWeight: 900, color: "#e8a020" }}>Score : {runner.finalScore}</div>
              <div style={{ fontSize: "11px", marginTop: "6px", color: "#48a848" }}>
                +{runner.xpReward} XP · +{Math.min(5, Math.floor((runner.finalScore || 0) / 15))} 💰
              </div>
              <div style={{ fontSize: "9px", opacity: 0.5, marginTop: "12px" }}>Toucher pour fermer</div>
            </div>
          )}
        </div>
      )}

      {/* Cutscene overlay */}
      {cutscene && (
        <div
          onClick={() => {
            if (cutscene.current < cutscene.lines.length - 1) {
              setCutscene({ ...cutscene, current: cutscene.current + 1 });
            } else {
              setCutscene(null);
            }
          }}
          style={{
            position: "fixed", inset: 0, zIndex: 235,
            background: "rgba(0,0,0,0.92)",
            display: "flex", alignItems: "center", justifyContent: "center",
            flexDirection: "column", padding: "30px",
            cursor: "pointer",
          }}
        >
          <div style={{ fontSize: "60px", marginBottom: "20px", animation: "pulse 2s ease-in-out infinite",
            filter: "drop-shadow(0 0 15px rgba(232,160,32,0.4))" }}>
            {cutscene.emoji}
          </div>
          <div key={cutscene.current} style={{
            fontSize: "16px", fontWeight: 600, color: "#f0ece0",
            textAlign: "center", lineHeight: 1.6,
            animation: "fadeIn 0.5s ease-out",
            textShadow: "0 2px 8px rgba(0,0,0,0.5)",
            maxWidth: "280px",
          }}>
            {cutscene.lines[cutscene.current]}
          </div>
          <div style={{
            position: "absolute", bottom: "60px",
            fontSize: "10px", opacity: 0.4,
            animation: "pulse 2s ease-in-out infinite",
          }}>
            {cutscene.current < cutscene.lines.length - 1 ? "Toucher pour continuer ▶" : "Toucher pour commencer ▶"}
          </div>
          {/* Progress dots */}
          <div style={{ position: "absolute", bottom: "40px", display: "flex", gap: "6px" }}>
            {cutscene.lines.map((_, i) => (
              <div key={i} style={{
                width: "6px", height: "6px", borderRadius: "50%",
                background: i <= cutscene.current ? "#e8a020" : "rgba(255,248,230,0.2)",
                transition: "background 0.3s",
              }} />
            ))}
          </div>
        </div>
      )}

      {/* Capture cinematic */}
      {captureAnim && (
        <div style={{
          position: "fixed", inset: 0, zIndex: 230,
          background: "rgba(0,0,0,0.92)",
          display: "flex", alignItems: "center", justifyContent: "center",
          flexDirection: "column",
        }}>
          {captureAnim.phase === "freeze" && (
            <div style={{ textAlign: "center", animation: "fadeIn 0.3s" }}>
              <div style={{ fontSize: "60px", animation: "pulse 0.5s ease-in-out infinite" }}>🧬</div>
              <div style={{ fontSize: "14px", color: "#c888e8", fontWeight: 700, marginTop: "12px", letterSpacing: "2px" }}>
                EXTRACTION ADN...
              </div>
            </div>
          )}
          {captureAnim.phase === "dna" && (
            <div style={{ textAlign: "center", position: "relative", width: "200px", height: "200px" }}>
              {/* DNA particles flying */}
              {Array.from({ length: 12 }).map((_, i) => (
                <div key={i} style={{
                  position: "absolute",
                  top: `${50 + Math.sin(i * 0.52) * 40}%`,
                  left: `${50 + Math.cos(i * 0.52) * 40}%`,
                  width: "6px", height: "6px", borderRadius: "50%",
                  background: i % 3 === 0 ? "#e8a020" : i % 3 === 1 ? "#c888e8" : "#f8c840",
                  animation: `sparkle ${0.8 + i * 0.1}s ease-in-out ${i * 0.08}s infinite`,
                  boxShadow: `0 0 6px ${i % 2 ? "#e8a020" : "#c888e8"}`,
                }} />
              ))}
              <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)", fontSize: "40px",
                animation: "pulse 0.4s ease-in-out infinite" }}>🧬</div>
              <div style={{ position: "absolute", bottom: "-20px", left: "50%", transform: "translateX(-50%)", fontSize: "11px",
                color: "#c888e8", fontWeight: 700, letterSpacing: "2px", whiteSpace: "nowrap" }}>
                TRANSFERT GÉNÉTIQUE
              </div>
            </div>
          )}
          {captureAnim.phase === "merge" && (
            <div style={{ textAlign: "center", animation: "splashIn 0.5s ease-out" }}>
              <div style={{ fontSize: "80px", filter: "drop-shadow(0 0 20px rgba(232,160,32,0.6))" }}>💥</div>
              {Array.from({ length: 10 }).map((_, i) => (
                <div key={i} style={{
                  position: "absolute",
                  top: `${30 + (i * 7) % 40}%`,
                  left: `${15 + (i * 11) % 70}%`,
                  fontSize: "18px",
                  animation: `confettiFall ${0.5 + i * 0.1}s ease-out ${i * 0.05}s forwards`,
                }}>✨</div>
              ))}
              <div style={{ fontSize: "14px", color: "#f8c840", fontWeight: 900, marginTop: "8px", letterSpacing: "3px" }}>
                MUTATION !
              </div>
            </div>
          )}
          {captureAnim.phase === "reveal" && (
            <div style={{ textAlign: "center", animation: "splashIn 0.5s ease-out" }}>
              <div style={{ fontSize: "50px", marginBottom: "8px" }}>
                {captureAnim.exclusive ? "👑" : "🧬"}
              </div>
              <div style={{
                fontSize: "16px", fontWeight: 900, letterSpacing: "3px",
                color: captureAnim.exclusive ? "#e8a020" : "#c888e8",
                textShadow: captureAnim.exclusive ? "0 0 20px rgba(232,160,32,0.5)" : "none",
              }}>
                {captureAnim.exclusive ? "★ EXCLUSIF ★" : "NOUVEAU !"}
              </div>
              <div style={{ fontSize: "12px", color: "#f0ece0", marginTop: "6px" }}>
                {captureAnim.dinoName}
              </div>
              <div style={{ fontSize: "9px", opacity: 0.65, marginTop: "12px", animation: "pulse 2s infinite" }}>
                Intégration en cours...
              </div>
            </div>
          )}
        </div>
      )}

      {/* Egg hatching animation */}
      {eggHatching && (
        <div
          onClick={() => { if (eggHatching.phase === "reveal") setEggHatching(null); }}
          style={{
          position: "fixed", inset: 0, zIndex: 225,
          background: "rgba(0,0,0,0.9)",
          display: "flex", alignItems: "center", justifyContent: "center",
          flexDirection: "column",
          cursor: eggHatching.phase === "reveal" ? "pointer" : "default",
        }}>
          {eggHatching.phase === "shake" && (
            <div style={{
              fontSize: "80px",
              animation: "eggShake 0.3s ease-in-out infinite",
              filter: "drop-shadow(0 0 20px rgba(196,168,56,0.6))",
            }}>🥚</div>
          )}
          {eggHatching.phase === "crack" && (
            <>
              <div style={{
                fontSize: "80px",
                animation: "pulse 0.2s ease-in-out infinite",
                filter: "drop-shadow(0 0 30px rgba(255,255,255,0.8))",
              }}>💥</div>
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} style={{
                  position: "absolute",
                  top: `${40 + (i - 4) * 5}%`,
                  left: `${35 + (i * 11) % 30}%`,
                  fontSize: "16px",
                  animation: `sparkle ${0.6 + i * 0.1}s ease-out ${i * 0.05}s forwards`,
                }}>✨</div>
              ))}
            </>
          )}
          {eggHatching.phase === "reveal" && (
            <div style={{ textAlign: "center", animation: "splashIn 0.5s ease-out" }}>
              <div style={{ fontSize: "40px", marginBottom: "8px" }}>
                {eggHatching.rarity === "epic" ? "💎" : eggHatching.rarity === "rare" ? "⭐" : "🎁"}
              </div>
              <div style={{
                fontSize: "14px", fontWeight: 900, color: "#e8a020",
                letterSpacing: "2px", marginBottom: "4px",
              }}>
                {eggHatching.rarity === "epic" ? "ÉPIQUE !" : eggHatching.rarity === "rare" ? "RARE !" : "COMMUN"}
              </div>
              <div style={{ fontSize: "12px", color: "#f0ece0" }}>
                {eggHatching.reward}
              </div>
              <div style={{
                fontSize: "10px", opacity: 0.85, marginTop: "12px",
                animation: "pulse 2s ease-in-out infinite",
              }}>
                Toucher pour continuer
              </div>
            </div>
          )}
        </div>
      )}

      {/* Shop modal */}
      {showShop && (
        <div
          onClick={() => setShowShop(false)}
          style={{
            position: "fixed", inset: 0, zIndex: 215,
            background: "rgba(0,0,0,0.8)",
            display: "flex", alignItems: "center", justifyContent: "center",
            padding: "16px",
          }}
        >
          <div onClick={e => e.stopPropagation()} style={{
            width: "100%", maxWidth: "340px",
            background: "linear-gradient(135deg, #141810 0%, #0e120a 100%)",
            border: "2px solid #e8a020",
            borderRadius: "12px",
            padding: "16px",
            maxHeight: "80vh",
            overflowY: "auto",
          }}>
            <div style={{ textAlign: "center", marginBottom: "12px" }}>
              <div style={{ fontSize: "28px" }}>🏪</div>
              <div style={{ fontSize: "14px", fontWeight: 900, color: "#e8a020", letterSpacing: "2px" }}>BOUTIQUE</div>
              <div style={{ fontSize: "12px", color: "#f0b830", marginTop: "4px" }}>💰 {shopCoins} pièces</div>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
              {SHOP_ITEMS.map(item => {
                const canAfford = shopCoins >= item.cost;
                return (
                  <button
                    key={item.key}
                    disabled={!canAfford}
                    onClick={() => {
                      if (!canAfford) return;
                      setShopCoins(shopCoins - item.cost);
                      if (item.type === "color") {
                        setUnlockedColors(prev => [...prev, item.value]);
                      } else if (item.type === "item") {
                        setInventory(prev => ({ ...prev, [item.value]: Math.min(5, (prev[item.value] || 0) + item.qty) }));
                      } else if (item.type === "egg") {
                        setEggs(eggs + 1);
                      }
                    }}
                    style={{
                      display: "flex", alignItems: "center", gap: "10px",
                      padding: "10px",
                      background: canAfford ? "rgba(245,236,210,0.08)" : "rgba(80,80,80,0.1)",
                      border: `1px solid ${canAfford ? "#3a3828" : "#444"}`,
                      borderRadius: "8px",
                      color: canAfford ? "#f0ece0" : "#888",
                      fontFamily: "system-ui, -apple-system, sans-serif",
                      fontSize: "11px",
                      cursor: canAfford ? "pointer" : "not-allowed",
                      textAlign: "left",
                    }}
                  >
                    <span style={{ fontSize: "20px" }}>{item.emoji}</span>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 700 }}>{item.name}</div>
                    </div>
                    <div style={{
                      fontWeight: 900, fontSize: "12px",
                      color: canAfford ? "#f0b830" : "#888",
                    }}>
                      {item.cost} 💰
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Dino ID Card */}
      {showIdCard && (
        <div
          onClick={() => setShowIdCard(false)}
          style={{
            position: "fixed", inset: 0, zIndex: 220,
            background: "rgba(0,0,0,0.85)",
            display: "flex", alignItems: "center", justifyContent: "center",
            padding: "16px",
            animation: "fadeIn 0.3s ease-out",
            perspective: "800px",
          }}
        >
          <div
            ref={cardRef}
            onClick={e => e.stopPropagation()}
            onMouseMove={onCardMove}
            onTouchMove={onCardMove}
            onMouseLeave={() => setGyroTilt({ x: 0, y: 0 })}
            onTouchEnd={() => setGyroTilt({ x: 0, y: 0 })}
            style={{
              width: "100%", maxWidth: "340px",
              transform: `rotateY(${gyroTilt.x * 15}deg) rotateX(${-gyroTilt.y * 12}deg)`,
              transformStyle: "preserve-3d",
              transition: "transform 0.1s ease-out",
              background: totalWins >= 50
                ? "linear-gradient(145deg, #e8a020 0%, #9050d0 25%, #58b8e8 50%, #f8c840 75%, #e8a020 100%)"
                : totalWins >= 30
                  ? "linear-gradient(145deg, #6a5020 0%, #e8a020 30%, #8a6a20 100%)"
                  : totalWins >= 15
                    ? "linear-gradient(145deg, #4a2868 0%, #6a3890 30%, #3a1848 100%)"
                    : totalWins >= 5
                      ? "linear-gradient(145deg, #2a4878 0%, #3a68a8 30%, #1a2848 100%)"
                      : "linear-gradient(145deg, #1a6b5a 0%, #141810 30%, #0e120a 100%)",
              backgroundSize: totalWins >= 50 ? "300% 300%" : "100% 100%",
              animation: totalWins >= 50 ? "shimmer 3s ease-in-out infinite" : "none",
              border: `3px solid ${ARENA_RANKS[arenaRank]?.color || "#3a3828"}`,
              borderRadius: "16px",
              padding: "0",
              overflow: "hidden",
              boxShadow: `${-gyroTilt.x * 15}px ${gyroTilt.y * 10}px 40px rgba(0,0,0,0.5), 0 0 15px ${ARENA_RANKS[arenaRank]?.color || "#3a3828"}40, inset 0 1px 0 rgba(245,236,210,0.15)`,
              position: "relative",
            }}
          >
            {/* Holographic shine overlay — follows touch/mouse */}
            <div style={{
              position: "absolute", inset: 0, zIndex: 5, pointerEvents: "none",
              background: `linear-gradient(${120 + gyroTilt.x * 60}deg, 
                transparent ${20 + gyroTilt.y * 20}%, 
                rgba(255,180,50,0.2) ${35 + gyroTilt.x * 15}%, 
                rgba(50,200,255,0.15) ${50 + gyroTilt.y * 12}%, 
                rgba(220,80,255,0.18) ${65 - gyroTilt.x * 15}%, 
                rgba(50,255,150,0.12) ${78 - gyroTilt.y * 10}%,
                transparent ${90 - gyroTilt.y * 20}%)`,
              borderRadius: "16px",
              transition: "background 0.08s ease-out",
              mixBlendMode: "screen",
            }} />
            {/* Hint */}
            <div style={{
              position: "absolute", bottom: "6px", left: "50%", transform: "translateX(-50%)",
              fontSize: "7px", opacity: 0.35, pointerEvents: "none", zIndex: 6, whiteSpace: "nowrap",
            }}>
              ↔ Incline la carte avec ton doigt
            </div>
            {/* Arena rank badge */}
            <div style={{
              position: "absolute", top: "10px", right: "12px",
              fontSize: "10px", fontWeight: 900,
              color: ARENA_RANKS[arenaRank]?.color || "#3a3828",
              display: "flex", alignItems: "center", gap: "3px",
            }}>
              {ARENA_RANKS[arenaRank]?.icon} {ARENA_RANKS[arenaRank]?.name}
            </div>
            {/* Card header */}
            <div style={{
              padding: "12px 16px 8px",
              background: "linear-gradient(180deg, rgba(245,236,210,0.12), transparent)",
              display: "flex", justifyContent: "space-between", alignItems: "center",
            }}>
              <div>
                <div style={{ fontSize: "18px", fontWeight: 900, color: "#f0ece0", letterSpacing: "1px" }}>{name}</div>
                <div style={{ fontSize: "10px", opacity: 0.75, fontStyle: "italic" }}>{generateName(build)}</div>
              </div>
              <div style={{
                padding: "3px 10px",
                background: "rgba(0,0,0,0.35)",
                borderRadius: "10px",
                fontSize: "11px", fontWeight: 700,
              }}>
                {TYPE_EMOJI[getBuildType(build)]} {getBuildType(build).toUpperCase()}
              </div>
            </div>

            {/* Dino art centered */}
            <div style={{
              padding: "8px 30px",
              background: "radial-gradient(ellipse at center, rgba(245,236,210,0.08) 0%, transparent 70%)",
            }}>
              <DinoArt build={build} pattern={pattern} />
            </div>

            {/* Level + stars + hearts */}
            <div style={{ textAlign: "center", padding: "0 16px 8px" }}>
              <span style={{ fontSize: "12px", fontWeight: 700, color: "#e8a020" }}>
                Niv. {level}
              </span>
              <span style={{ marginLeft: "8px", fontSize: "12px", color: "#e8a020" }}>
                {Array.from({ length: Math.min(5, Math.ceil(level / 3)) }).map((_, i) => "★").join("")}
                {Array.from({ length: 5 - Math.min(5, Math.ceil(level / 3)) }).map((_, i) => "☆").join("")}
              </span>
              <div style={{ marginTop: "4px", fontSize: "13px" }}>
                {Array.from({ length: 5 }).map((_, i) => (
                  <span key={i} style={{ color: i < friendshipHearts ? "#cc2030" : "#555", marginRight: "2px" }}>
                    {i < friendshipHearts ? "❤" : "🤍"}
                  </span>
                ))}
              </div>
              <div style={{ fontSize: "9px", opacity: 0.85, marginTop: "2px" }}>
                {xp}/{level * 50} XP · {totalWins} victoires · {shopCoins} 💰
              </div>
            </div>

            {/* Stats grid */}
            <div style={{
              margin: "0 12px",
              padding: "10px",
              background: "rgba(0,0,0,0.25)",
              borderRadius: "8px",
            }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "6px" }}>
                {[
                  { k: "attaque", l: "ATQ", e: "⚔️" },
                  { k: "defense", l: "DEF", e: "🛡️" },
                  { k: "vitesse", l: "VIT", e: "💨" },
                  { k: "force", l: "FRC", e: "💪" },
                  { k: "intel", l: "INT", e: "🧠" },
                  { k: "taille", l: "TAI", e: "📏" },
                ].map(s => (
                  <div key={s.k} style={{
                    textAlign: "center", padding: "4px",
                    background: "rgba(245,236,210,0.05)",
                    borderRadius: "6px",
                  }}>
                    <div style={{ fontSize: "12px" }}>{s.e}</div>
                    <div style={{ fontSize: "14px", fontWeight: 900, color: playerStatsLeveled[s.k] >= 10 ? "#f0b830" : playerStatsLeveled[s.k] >= 7 ? "#8aca68" : "#f0ece0" }}>
                      {(playerStatsLeveled[s.k] || 0).toFixed(1)}
                    </div>
                    <div style={{ fontSize: "8px", opacity: 0.85 }}>{s.l}</div>
                  </div>
                ))}
              </div>
              <div style={{ textAlign: "center", marginTop: "6px", fontSize: "10px", color: "#f8c840" }}>
                ❤ {computeHP(playerStatsLeveled, trait, permaBonus.hp || 0)} PV
              </div>
            </div>

            {/* Parts + trait + equipment */}
            <div style={{ padding: "10px 12px", fontSize: "9px" }}>
              {/* Trait */}
              {trait && (() => {
                const t = TRAITS.find(x => x.key === trait);
                return t ? (
                  <div style={{ marginBottom: "6px", display: "flex", alignItems: "center", gap: "6px" }}>
                    <span>{t.emoji}</span>
                    <span style={{ fontWeight: 700 }}>{t.name}</span>
                    <span style={{ opacity: 0.85 }}>— {t.desc}</span>
                  </div>
                ) : null;
              })()}
              {/* Equipment */}
              {equipment && (() => {
                const eq = EQUIPMENT_LIST.find(e => e.key === equipment);
                return eq ? (
                  <div style={{ marginBottom: "6px", display: "flex", alignItems: "center", gap: "6px" }}>
                    <span>{eq.emoji}</span>
                    <span style={{ fontWeight: 700 }}>{eq.name}</span>
                    <span style={{ opacity: 0.85 }}>— {eq.desc}</span>
                  </div>
                ) : null;
              })()}
              {/* Parts with rarity */}
              <div style={{ display: "flex", flexWrap: "wrap", gap: "3px", marginTop: "4px" }}>
                {PARTS.filter(p => p.key !== "color").map(p => {
                  const d = DINOS[build[p.key]];
                  const isExcl = d?.exclusive;
                  const rarC = d?.rarity === "legendary" ? "#e8a020" : d?.rarity === "epic" ? "#9050d0" : d?.rarity === "rare" ? "#7090a0" : "#3a3828";
                  return (
                    <span key={p.key} style={{
                      padding: "2px 6px",
                      background: `${rarC}20`,
                      border: `1px solid ${rarC}`,
                      borderRadius: "4px",
                      fontSize: "8px",
                    }}>
                      {p.icon} {d?.name?.split(" ")[0] || "?"}{isExcl ? " ★" : ""}
                    </span>
                  );
                })}
              </div>
            </div>

            {/* DNA Helix */}
            <div style={{ padding: "4px 12px 8px" }}>
              <div style={{ fontSize: "8px", opacity: 0.55, textAlign: "center", letterSpacing: "1px", marginBottom: "2px" }}>SÉQUENCE ADN</div>
              <svg viewBox="0 0 300 60" style={{ width: "100%", display: "block" }}>
                {Array.from({ length: 20 }).map((_, i) => {
                  const x = i * 15 + 10;
                  const y1 = 30 + Math.sin(i * 0.8) * 18;
                  const y2 = 30 - Math.sin(i * 0.8) * 18;
                  const partKeys = ["head","teeth","frontLegs","backLegs","back","tail","color"];
                  const pk = partKeys[i % 7];
                  const d = DINOS[build[pk]];
                  const col = d?.rarity === "legendary" ? "#e8a020" : d?.rarity === "epic" ? "#c888e8" : d?.rarity === "rare" ? "#60a0f0" : "#48a848";
                  return (
                    <g key={i}>
                      <circle cx={x} cy={y1} r={3} fill={col} opacity={0.8}>
                        <animate attributeName="cy" values={`${y1};${y2};${y1}`} dur="3s" begin={`${i*0.15}s`} repeatCount="indefinite" />
                      </circle>
                      <circle cx={x} cy={y2} r={3} fill={col} opacity={0.4}>
                        <animate attributeName="cy" values={`${y2};${y1};${y2}`} dur="3s" begin={`${i*0.15}s`} repeatCount="indefinite" />
                      </circle>
                      {i % 2 === 0 && <line x1={x} y1={y1} x2={x} y2={y2} stroke={col} strokeWidth={0.8} opacity={0.2}>
                        <animate attributeName="y1" values={`${y1};${y2};${y1}`} dur="3s" begin={`${i*0.15}s`} repeatCount="indefinite" />
                        <animate attributeName="y2" values={`${y2};${y1};${y2}`} dur="3s" begin={`${i*0.15}s`} repeatCount="indefinite" />
                      </line>}
                    </g>
                  );
                })}
              </svg>
            </div>

            {/* Mood bar */}
            <div style={{
              padding: "8px 16px 12px",
              background: "linear-gradient(transparent, rgba(0,0,0,0.2))",
              display: "flex", justifyContent: "center", gap: "12px",
              fontSize: "10px",
            }}>
              <span>🍖 {Math.round(careHunger)}%</span>
              <span>😊 {Math.round(careHappiness)}%</span>
              <span>💤 {Math.round(careEnergy)}%</span>
              <span style={{ color: careMood.color }}>{careMood.emoji} {careMood.label}</span>
            </div>
          </div>
        </div>
      )}

      {/* Splash screen */}
      {view === "splash" && (
        <div
          onClick={() => {
            setView("build"); setShowSplash(false);
            try { playRoar("tyrant"); } catch(e) {}
            // Start music from user gesture (needed for browsers)
            if (musicOn) { musicMoodRef.current = "ambient"; startMusic("ambient"); }
          }}
          style={{
            position: "fixed", inset: 0, zIndex: 300,
            background: "radial-gradient(ellipse at 50% 80%, #1a3a28 0%, #0a1810 60%, #050c06 100%)",
            display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
            cursor: "pointer", overflow: "hidden",
          }}
        >
          {/* Floating particles */}
          {Array.from({ length: 20 }).map((_, i) => (
            <div key={`p${i}`} style={{
              position: "absolute",
              left: `${5 + (i * 17) % 90}%`,
              bottom: `-5%`,
              width: `${2 + i % 3}px`, height: `${2 + i % 3}px`,
              borderRadius: "50%",
              background: i % 3 === 0 ? "#e8a020" : i % 3 === 1 ? "#c888e8" : "#48a848",
              opacity: 0.4 + (i % 5) * 0.1,
              animation: `floatUp ${6 + i * 0.7}s ease-in ${i * 0.4}s infinite`,
            }} />
          ))}

          {/* Main content */}
          <div style={{ textAlign: "center", position: "relative", zIndex: 2 }}>
            {/* Subtitle */}
            <div style={{
              fontSize: "9px", letterSpacing: "5px", color: "#e8a020", marginBottom: "8px",
              textTransform: "uppercase", fontWeight: 700,
              animation: "fadeIn 1s ease-out 0.5s both",
            }}>
              ◆ CABINET DE CHLOÉ ◆
            </div>

            {/* Main title — letter by letter */}
            <div style={{ display: "flex", justifyContent: "center", gap: "3px", marginBottom: "16px" }}>
              {"DINO·HYBRIDE".split("").map((ch, i) => (
                <span key={i} style={{
                  fontSize: "30px", fontWeight: 900,
                  background: "linear-gradient(180deg, #f8f0d0, #e8a020, #6a4a10)",
                  WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
                  backgroundClip: "text",
                  animation: `splashIn 0.4s ease-out ${0.8 + i * 0.06}s both`,
                  filter: `drop-shadow(0 2px 4px rgba(0,0,0,0.5))`,
                }}>{ch}</span>
              ))}
            </div>

            {/* Dino preview — single centered */}
            <div style={{
              width: "160px", margin: "0 auto 20px",
              animation: "splashIn 0.8s ease-out 1.6s both",
              filter: "drop-shadow(0 8px 16px rgba(0,0,0,0.5))",
            }}>
              <DinoArt build={build} pattern={pattern} />
            </div>

            {/* Stats */}
            <div style={{
              fontSize: "10px", fontStyle: "italic", opacity: 0.85, letterSpacing: "2px",
              animation: "fadeIn 1s ease-out 2s both",
            }}>
              Niv.{level} · {totalWins} victoire{totalWins > 1 ? "s" : ""} · {Object.keys(bestiary).length} espèces
            </div>

            {/* CTA */}
            <div style={{
              fontSize: "12px", opacity: 0.6, marginTop: "30px",
              animation: "pulse 2s ease-in-out 2.5s infinite",
            }}>
              ▶ TOUCHER POUR COMMENCER
            </div>
          </div>
        </div>
      )}

      {/* Evolution modal */}
      {evolutionPending && (
        <div style={{
          position: "fixed", inset: 0, zIndex: 210,
          background: "rgba(0,0,0,0.8)",
          display: "flex", alignItems: "center", justifyContent: "center",
          padding: "20px",
        }}>
          <div style={{
            background: "linear-gradient(135deg, #141810 0%, #0e120a 100%)",
            border: "2px solid #e8a020",
            borderRadius: "12px",
            padding: "20px",
            maxWidth: "340px", width: "100%",
            boxShadow: "0 0 30px rgba(196,168,56,0.4)",
          }}>
            <div style={{ textAlign: "center", marginBottom: "12px" }}>
              <div style={{ fontSize: "32px", marginBottom: "4px" }}>🧬</div>
              <div style={{ fontSize: "14px", letterSpacing: "2px", color: "#e8a020", fontWeight: 900 }}>
                ÉVOLUTION NIV. {evolutionPending}
              </div>
              <div style={{ fontSize: "10px", opacity: 0.85, marginTop: "4px" }}>
                Choisis UNE partie à muter gratuitement
              </div>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
              {PARTS.filter(p => p.key !== "color").map(p => (
                <button
                  key={p.key}
                  onClick={() => {
                    setActivePart(p.key);
                    setEvolutionPending(null);
                    setView("build");
                  }}
                  style={{
                    padding: "8px 12px",
                    background: "rgba(245,236,210,0.1)",
                    color: "#f0ece0",
                    border: "1px solid #3a3828",
                    borderRadius: "8px",
                    fontFamily: "system-ui, -apple-system, sans-serif",
                    fontSize: "11px",
                    cursor: "pointer",
                    textAlign: "left",
                    display: "flex", justifyContent: "space-between",
                  }}
                >
                  <span>{p.icon} {p.label}</span>
                  <span style={{ opacity: 0.85, fontSize: "9px" }}>{DINOS[build[p.key]].name}</span>
                </button>
              ))}
            </div>
            <button
              onClick={() => setEvolutionPending(null)}
              style={{
                marginTop: "8px", width: "100%", padding: "8px",
                background: "transparent", color: "#f0ece0", border: "1px solid #2a2820",
                borderRadius: "8px", fontFamily: "system-ui, -apple-system, sans-serif", fontSize: "10px", cursor: "pointer",
              }}
            >
              Plus tard
            </button>
          </div>
        </div>
      )}

      {/* Pre-combat screen */}
      {preCombatScreen && (
        <div style={{
          position: "fixed", inset: 0, zIndex: 205,
          background: "rgba(0,0,0,0.85)",
          display: "flex", alignItems: "center", justifyContent: "center",
          animation: "fadeIn 0.3s ease-out",
        }}>
          <div style={{ textAlign: "center", width: "100%", padding: "20px" }}>
            <div style={{ display: "flex", justifyContent: "space-around", alignItems: "center", marginBottom: "16px" }}>
              <div style={{ width: "35%" }}>
                <DinoArt build={build} pattern={pattern} />
                <div style={{ fontSize: "11px", fontWeight: 700, marginTop: "4px" }}>{name}</div>
                <div style={{ fontSize: "9px", opacity: 0.85 }}>Niv.{level} {TYPE_EMOJI[getBuildType(build)]}</div>
              </div>
              <div style={{ fontSize: "20px", fontWeight: 900, color: "#e8a020", letterSpacing: "3px" }}>VS</div>
              <div style={{ width: "35%" }}>
                <div style={{ transform: "scaleX(-1)" }}>
                  <DinoArt build={preCombatScreen.build} />
                </div>
                <div style={{ fontSize: "11px", fontWeight: 700, marginTop: "4px" }}>{preCombatScreen.name}</div>
                <div style={{ fontSize: "9px", opacity: 0.85 }}>Niv.{preCombatScreen.level || level} {TYPE_EMOJI[getBuildType(preCombatScreen.build)]}</div>
              </div>
            </div>
            <div style={{
              fontSize: "28px", fontWeight: 900, color: "#f0b830",
              letterSpacing: "6px", animation: "pulse 0.8s ease-in-out infinite",
            }}>
              COMBAT !
            </div>
          </div>
        </div>
      )}

      {/* Quiz modal */}
      {quizActive && (
        <div style={{
          position: "fixed", inset: 0, zIndex: 200,
          background: "rgba(0,0,0,0.7)",
          display: "flex", alignItems: "center", justifyContent: "center",
          padding: "20px",
        }}>
          <div style={{
            background: "linear-gradient(135deg, #141810 0%, #0e120a 100%)",
            border: "2px solid #e8a020",
            borderRadius: "12px",
            padding: "20px",
            maxWidth: "340px",
            width: "100%",
            boxShadow: "0 8px 30px rgba(0,0,0,0.6)",
          }}>
            <div style={{ textAlign: "center", marginBottom: "12px" }}>
              <div style={{ fontSize: "28px", marginBottom: "6px" }}>🧠</div>
              <div style={{ fontSize: "12px", letterSpacing: "2px", color: "#e8a020", fontWeight: 700, textTransform: "uppercase" }}>
                Quiz Paléontologie
              </div>
              <div style={{ fontSize: "9px", opacity: 0.75, marginTop: "2px" }}>
                Bonne réponse = +25% dégâts contre le boss
              </div>
            </div>
            <div style={{
              fontSize: "13px", lineHeight: 1.4, marginBottom: "14px", textAlign: "center",
              color: "#f0ece0", fontStyle: "italic",
            }}>
              {quizActive.q}
            </div>
            {!quizActive.answered ? (
              <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                {quizActive.opts.map((opt, i) => (
                  <button
                    key={i}
                    onClick={() => answerQuiz(opt)}
                    style={{
                      padding: "10px",
                      background: "rgba(245,236,210,0.1)",
                      color: "#f0ece0",
                      border: "1px solid #3a3828",
                      borderRadius: "8px",
                      fontFamily: "system-ui, -apple-system, sans-serif",
                      fontSize: "11px",
                      cursor: "pointer",
                      textAlign: "left",
                    }}
                  >
                    {opt}
                  </button>
                ))}
              </div>
            ) : (
              <div style={{
                textAlign: "center",
                padding: "16px",
                background: quizActive.correct ? "rgba(56,200,120,0.2)" : "rgba(200,56,56,0.2)",
                border: `1px solid ${quizActive.correct ? "#e8a020" : "#cc2020"}`,
                borderRadius: "8px",
                fontSize: "14px",
                fontWeight: 700,
              }}>
                {quizActive.correct ? "✅ Correct ! +25% dégâts !" : `❌ Raté ! La réponse était : ${quizActive.a}`}
              </div>
            )}
          </div>
        </div>
      )}

      <header style={{
        padding: "20px 20px 14px",
        borderBottom: "1px solid rgba(255,248,230,0.05)",
        textAlign: "center",
        background: "linear-gradient(180deg, rgba(232,160,32,0.08) 0%, transparent 100%)",
        position: "relative",
      }}>
        <div style={{ fontSize: "10px", letterSpacing: "4px", opacity: 0.65, marginBottom: "2px", textTransform: "uppercase" }}>
          Le labo de Chloé
        </div>
        <h1 style={{
          fontSize: "28px",
          margin: 0,
          fontWeight: 900,
          letterSpacing: "2px",
          fontFamily: "system-ui, -apple-system, sans-serif",
          background: "linear-gradient(135deg, #f8c840 0%, #cc2020 50%, #e8a020 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          backgroundClip: "text",
        }}>
          DINO·HYBRIDE
        </h1>
        <div className="card-raised" style={{
          marginTop: "10px",
          display: "inline-flex",
          alignItems: "center",
          gap: "10px",
          padding: "5px 14px",
          background: "linear-gradient(135deg, rgba(60,90,70,0.5), rgba(30,50,35,0.5))",
          border: "1px solid #3a3828",
          borderRadius: "14px",
          fontSize: "10px",
          letterSpacing: "1px",
        }}>
          <span>⭐ {level}</span>
          <span style={{ opacity: 0.85 }}>|</span>
          <span>{ARENA_RANKS[arenaRank]?.icon}</span>
          <span style={{ opacity: 0.85 }}>|</span>
          <span style={{ color: "#cc2030" }}>
            {Array.from({ length: friendshipHearts }).map(() => "❤").join("")}
            {friendshipHearts === 0 && "🤍"}
          </span>
          <span style={{ opacity: 0.85 }}>|</span>
          <span>🥚 {eggs}</span>
          <span style={{ opacity: 0.85 }}>|</span>
          <span onClick={() => setShowShop(true)} style={{ cursor: "pointer", color: "#f0b830" }}>💰 {shopCoins}</span>
          <span style={{ opacity: 0.5 }}>|</span>
          <span onClick={() => { setMusicOn(!musicOn); if (!musicOn) startMusic("ambient"); else stopMusic(); }}
            style={{ cursor: "pointer", fontSize: "12px" }}>{musicOn ? "🔊" : "🔇"}</span>
        </div>
      </header>

      {/* Bottom navigation bar */}
      {view !== "splash" && (
      <nav style={{
        position: "fixed",
        bottom: 0, left: 0, right: 0,
        zIndex: 150,
        background: "rgba(14,16,32,0.92)",
        backdropFilter: "blur(16px)", WebkitBackdropFilter: "blur(16px)",
        borderTop: "1px solid rgba(255,248,230,0.05)",
        display: "flex",
        justifyContent: "space-around",
        padding: "8px 4px env(safe-area-inset-bottom, 6px)",
      }}>
        {[
          { k: "build", icon: "🔧", label: "Atelier" },
          { k: "adventure", icon: "🗺️", label: "Aventure" },
          { k: "battle", icon: "⚔️", label: "Arène" },
          { k: "gallery", icon: "🏛️", label: "Vitrine" },
          { k: "bestiary", icon: "📖", label: "Dex" },
          { k: "book", icon: "📚", label: "Carnet" },
        ].map(tab => {
          const active = view === tab.k;
          let badge = false;
          if (tab.k === "adventure") badge = ZONES.some((z, i) => level >= z.minLevel && !achievements[`zone_${z.key}_done`] && (zoneWinsMap[z.key] || 0) >= z.wins);
          if (tab.k === "book" && evolutionPending) badge = true;
          return (
            <button key={tab.k} onClick={() => setView(tab.k)} style={{
              background: active ? "rgba(232,160,32,0.15)" : "transparent",
              border: "none",
              borderRadius: "10px",
              color: active ? "#f8c840" : "rgba(255,255,255,0.4)",
              display: "flex", flexDirection: "column", alignItems: "center",
              cursor: "pointer",
              padding: "4px 10px",
              position: "relative",
              transition: "color 0.2s, background 0.2s",
            }}>
              <span style={{ fontSize: "18px" }}>{tab.icon}</span>
              <span style={{ fontSize: "8px", marginTop: "2px", fontWeight: active ? 700 : 400 }}>{tab.label}</span>
              {badge && (
                <div style={{
                  position: "absolute", top: "2px", right: "6px",
                  width: "7px", height: "7px", borderRadius: "50%",
                  background: "#cc2020",
                }} />
              )}
            </button>
          );
        })}
      </nav>
      )}

      {view === "build" && (
        <div className="view-enter" key="build">
          {/* Dino display */}
          <div className="card-parchment" style={{
            margin: "20px 16px",
            padding: "18px",
            border: "2px solid #2a2820",
            borderRadius: "6px",
            position: "relative",
          }}>
            {/* Corner ornaments */}
            {["tl","tr","bl","br"].map(c => (
              <div key={c} style={{
                position: "absolute",
                [c.includes("t") ? "top" : "bottom"]: "6px",
                [c.includes("l") ? "left" : "right"]: "6px",
                width: "12px", height: "12px",
                borderTop: c.includes("t") ? "2px solid #2a2820" : "none",
                borderBottom: c.includes("b") ? "2px solid #2a2820" : "none",
                borderLeft: c.includes("l") ? "2px solid #2a2820" : "none",
                borderRight: c.includes("r") ? "2px solid #2a2820" : "none",
              }} />
            ))}

            <div
              onClick={(e) => {
                if (playMiniGame?.active) { tapPlay(); return; }
                if (dino3D) return;
                // Touch reactions — detect which body part was tapped
                const rect = e.currentTarget.getBoundingClientRect();
                const rx = (e.clientX - rect.left) / rect.width;
                const ry = (e.clientY - rect.top) / rect.height;
                let reaction;
                if (rx > 0.55 && ry < 0.45) {
                  reaction = { type: "head", emoji: "😊" }; // head pat
                  try { playRoar(DINOS[build.head]?.family || "tyrant"); } catch(e) {}
                } else if (rx > 0.3 && rx < 0.65 && ry > 0.35 && ry < 0.75) {
                  reaction = { type: "belly", emoji: "🤣" }; // belly rub
                } else if (rx < 0.3) {
                  reaction = { type: "tail", emoji: "💫" }; // tail wag
                } else {
                  reaction = { type: "pet", emoji: "❤️" }; // generic pet
                }
                setTouchReaction(reaction);
                vibrate(20);
                setTimeout(() => setTouchReaction(null), 1200);
              }}
              style={{
                aspectRatio: "500/320", width: "100%", position: "relative",
                cursor: "pointer",
                border: playMiniGame?.active ? "2px solid #f0b830" : "2px solid transparent",
                borderRadius: "8px",
                transition: "border-color 0.3s",
                overflow: "hidden",
              }}
            >
              {/* Habitat background — changes with dino type */}
              {!dino3D && !playMiniGame?.active && (() => {
                const dinoType = getBuildType(build);
                const habitats = {
                  feu: { sky1: "#2a1010", sky2: "#3a1808", ground: "#1a0e08", groundL: "#241208", mountain: "#1a0800",
                    accent: "#cc4010", trees: false, water: false, lava: true },
                  eau: { sky1: "#0a1828", sky2: "#0a2838", ground: "#0a1820", groundL: "#0e1e28", mountain: "#081420",
                    accent: "#2080c0", trees: false, water: true, lava: false },
                  terre: { sky1: "#1a2838", sky2: "#1a3028", ground: "#1a2818", groundL: "#1e2a14", mountain: "#0e1a10",
                    accent: "#48a848", trees: true, water: false, lava: false },
                  air: { sky1: "#182838", sky2: "#283848", ground: "#1a2828", groundL: "#1e3030", mountain: "#142028",
                    accent: "#88b8e0", trees: false, water: false, lava: false },
                  roche: { sky1: "#1a1818", sky2: "#2a2420", ground: "#1a1610", groundL: "#221c14", mountain: "#141010",
                    accent: "#8a7050", trees: false, water: false, lava: false },
                  nature: { sky1: "#0a1a10", sky2: "#142818", ground: "#0e1a08", groundL: "#142010", mountain: "#081408",
                    accent: "#30802a", trees: true, water: false, lava: false },
                };
                const h = habitats[dinoType] || habitats.terre;
                return (
                <svg viewBox="0 0 500 320" style={{ position: "absolute", inset: 0, width: "100%", height: "100%", zIndex: 0, pointerEvents: "none" }}>
                  <defs>
                    <linearGradient id="skyG" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor={h.sky1} />
                      <stop offset="60%" stopColor={h.sky2} />
                      <stop offset="100%" stopColor={h.ground} />
                    </linearGradient>
                  </defs>
                  <rect width="500" height="320" fill="url(#skyG)" />
                  {/* Mountains */}
                  <path d="M0,220 L60,150 L120,190 L180,130 L240,180 L300,120 L360,170 L420,140 L500,200 L500,320 L0,320Z" fill={h.mountain} opacity="0.5" />
                  {/* Ground */}
                  <rect x="0" y="260" width="500" height="60" fill={h.ground} />
                  <rect x="0" y="265" width="500" height="55" fill={h.groundL} />
                  {/* Lava streams (feu) */}
                  {h.lava && [100, 300].map((x, i) => (
                    <g key={`lava${i}`}>
                      <rect x={x} y="262" width={20 + i * 15} height="3" rx="1" fill="#cc3010" opacity="0.4">
                        <animate attributeName="opacity" values="0.3;0.6;0.3" dur={`${2 + i}s`} repeatCount="indefinite" />
                      </rect>
                      <rect x={x + 5} y="263" width={10 + i * 8} height="1.5" rx="1" fill="#ff6020" opacity="0.3" />
                    </g>
                  ))}
                  {/* Water (eau) */}
                  {h.water && (
                    <g>
                      <rect x="0" y="268" width="500" height="52" fill="#0a2030" opacity="0.6" />
                      {[0,1,2,3].map(i => (
                        <path key={`wave${i}`} d={`M0 ${278 + i * 10} Q125 ${274 + i * 10} 250 ${278 + i * 10} T500 ${278 + i * 10}`}
                          fill="none" stroke="#1a4060" strokeWidth="1" opacity="0.3">
                          <animate attributeName="d"
                            values={`M0 ${278+i*10} Q125 ${274+i*10} 250 ${278+i*10} T500 ${278+i*10};M0 ${278+i*10} Q125 ${282+i*10} 250 ${278+i*10} T500 ${278+i*10};M0 ${278+i*10} Q125 ${274+i*10} 250 ${278+i*10} T500 ${278+i*10}`}
                            dur={`${3+i}s`} repeatCount="indefinite" />
                        </path>
                      ))}
                    </g>
                  )}
                  {/* Grass */}
                  {[30,80,150,220,310,380,450].map((x,i) => (
                    <g key={`grass${i}`}>
                      <line x1={x} y1={265} x2={x-3} y2={258} stroke={h.accent} strokeWidth="1.5" opacity="0.3" />
                      <line x1={x+3} y1={265} x2={x+6} y2={256} stroke={h.accent} strokeWidth="1.5" opacity="0.25" />
                    </g>
                  ))}
                  {/* Trees (terre/nature) */}
                  {h.trees && [50,190,350,430].map((x,i) => (
                    <g key={`tree${i}`} opacity="0.2">
                      <rect x={x} y={230} width="4" height="30" fill={shadeColor(h.accent, -30)} />
                      <circle cx={x+2} cy={228} r="10" fill={h.accent} />
                    </g>
                  ))}
                  {/* Clouds (air) */}
                  {dinoType === "air" && [80, 250, 400].map((x, i) => (
                    <g key={`cloud${i}`} opacity="0.12">
                      <ellipse cx={x} cy={60 + i * 30} rx={30 + i * 5} ry={8} fill="#88b8e0">
                        <animateTransform attributeName="transform" type="translate" values="0,0;20,0;0,0" dur={`${10+i*3}s`} repeatCount="indefinite" />
                      </ellipse>
                    </g>
                  ))}
                  {/* Rocks (roche) */}
                  {dinoType === "roche" && [60,180,320,420].map((x, i) => (
                    <g key={`rock${i}`} opacity="0.25">
                      <polygon points={`${x},265 ${x+8},250 ${x+15},258 ${x+20},265`} fill="#4a3828" />
                    </g>
                  ))}
                  {/* Butterflies */}
                  <text x="120" y="160" fontSize="10" opacity="0.2">
                    🦋
                    <animateTransform attributeName="transform" type="translate" values="0,0;15,-8;30,0;15,8;0,0" dur="6s" repeatCount="indefinite" />
                  </text>
                </svg>
                );
              })()}

              {/* 2D view */}
              {!dino3D && (
                <div style={{
                  animation: !playMiniGame?.active && !careAnim && !touchReaction
                    ? "dinoWalk 3s ease-in-out infinite"
                    : touchReaction?.type === "belly" ? "pulse 0.3s ease-in-out 3"
                    : touchReaction?.type === "tail" ? "dinoWalk 0.2s ease-in-out 5"
                    : "none",
                  position: "relative", zIndex: 1,
                }}>
                  <DinoArt build={build} crying={crying} pattern={pattern} />
                </div>
              )}

              {/* Touch reaction emoji */}
              {touchReaction && (
                <div style={{
                  position: "absolute", top: "15%",
                  left: touchReaction.type === "head" ? "65%" : touchReaction.type === "tail" ? "20%" : "50%",
                  transform: "translateX(-50%)",
                  fontSize: "28px",
                  animation: "splashIn 0.3s ease-out",
                  pointerEvents: "none", zIndex: 10,
                  filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.5))",
                }}>
                  {touchReaction.emoji}
                </div>
              )}

              {/* 3D voxel view */}
              {dino3D && <DinoArt3D build={build} />}

              {/* Ground shadow (2D only) */}
              {!dino3D && (
                <div style={{
                  position: "absolute",
                  bottom: "10%", left: "50%",
                  width: "50%", height: "6%",
                  transform: "translateX(-50%)",
                  background: "radial-gradient(ellipse, rgba(0,0,0,0.2) 0%, transparent 70%)",
                  borderRadius: "50%",
                  pointerEvents: "none",
                }} />
              )}

              {/* 2D/3D toggle */}
              <button
                onClick={(e) => { e.stopPropagation(); setDino3D(!dino3D); }}
                style={{
                  position: "absolute", bottom: "8px", right: "8px",
                  width: "28px", height: "28px",
                  background: dino3D ? "rgba(232,160,32,0.4)" : "rgba(0,0,0,0.4)",
                  border: dino3D ? "1px solid #e8a020" : "1px solid rgba(255,248,230,0.12)",
                  borderRadius: "50%",
                  color: "#f0ece0",
                  fontSize: "10px", fontWeight: 900,
                  cursor: "pointer",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  zIndex: 10,
                }}
              >{dino3D ? "2D" : "3D"}</button>
              {dino3D && (
                <div style={{
                  position: "absolute", bottom: "10px", left: "8px",
                  fontSize: "7px", opacity: 0.5, pointerEvents: "none",
                }}>
                  ↔ Glisse pour tourner
                </div>
              )}

              {/* Dust puffs while walking */}
              {!playMiniGame?.active && !careAnim && !dino3D && (
                <>
                  {[0, 1, 2].map(i => (
                    <div key={`dust-${i}`} style={{
                      position: "absolute",
                      bottom: `${9 + i * 2}%`,
                      left: `${32 + i * 14}%`,
                      width: "8px", height: "8px",
                      borderRadius: "50%",
                      background: "rgba(180,160,120,0.25)",
                      pointerEvents: "none",
                      animation: `dustPuff 1.5s ease-out ${i * 0.5}s infinite`,
                    }} />
                  ))}
                </>
              )}

              {/* Tap burst particles during mini-game */}
              {playMiniGame?.active && (
                <>
                  {/* Big counter overlay */}
                  <div style={{
                    position: "absolute", top: "8px", left: "50%", transform: "translateX(-50%)",
                    fontSize: "24px", fontWeight: 900, color: "#f0b830",
                    textShadow: "0 2px 4px rgba(0,0,0,0.7)",
                    pointerEvents: "none", zIndex: 22,
                  }}>
                    {playMiniGame.taps}/{playMiniGame.target}
                  </div>
                  <div style={{
                    position: "absolute", bottom: "25%", left: "50%", transform: "translateX(-50%)",
                    fontSize: "14px", fontWeight: 900, color: "#f0ece0",
                    textShadow: "0 2px 4px rgba(0,0,0,0.7)",
                    animation: "pulse 0.4s ease-in-out infinite",
                    pointerEvents: "none", zIndex: 22,
                    letterSpacing: "3px",
                  }}>
                    TAP TAP TAP !
                  </div>
                  {/* Burst particle on each tap */}
                  <div key={tapBurst} style={{
                    position: "absolute",
                    top: `${25 + (tapBurst * 17) % 40}%`,
                    left: `${15 + (tapBurst * 23) % 60}%`,
                    fontSize: "22px",
                    animation: "sparkle 0.4s ease-out forwards",
                    pointerEvents: "none", zIndex: 21,
                  }}>
                    {["⭐", "💛", "✨", "💫", "🌟"][tapBurst % 5]}
                  </div>
                </>
              )}

              {/* Bug hunt overlay */}
              {bugHunt?.active && bugHunt.bugs.map(bug => !bug.caught && (
                <div
                  key={bug.id}
                  onClick={(e) => { e.stopPropagation(); catchBug(bug.id); }}
                  style={{
                    position: "absolute",
                    top: `${bug.y}%`,
                    left: `${bug.x}%`,
                    fontSize: "20px",
                    cursor: "pointer",
                    zIndex: 25,
                    animation: "dinoWalk 0.8s ease-in-out infinite",
                    filter: "drop-shadow(0 1px 2px rgba(0,0,0,0.5))",
                    transition: "transform 0.1s",
                  }}
                >🦟</div>
              ))}
              {bugHunt?.active && (
                <div style={{
                  position: "absolute", top: "8px", left: "50%", transform: "translateX(-50%)",
                  fontSize: "12px", fontWeight: 900, color: "#48a848",
                  textShadow: "0 1px 3px rgba(0,0,0,0.7)",
                  pointerEvents: "none", zIndex: 26,
                  animation: "pulse 0.5s ease-in-out infinite",
                }}>
                  🦟 Attrape-les ! {bugHunt.caught}/5
                </div>
              )}

              {/* Mood badge - top right */}
              <div style={{
                position: "absolute", top: "4px", right: "4px",
                fontSize: "20px",
                filter: "drop-shadow(0 1px 2px rgba(0,0,0,0.5))",
              }}>
                {careMood.emoji}
              </div>

              {/* Care action animation overlay */}
              {careAnim === "feed" && (
                <>
                  {[0, 1, 2].map(i => (
                    <div key={`feed-${i}`} style={{
                      position: "absolute",
                      top: `${25 + i * 8}%`,
                      left: `${35 + i * 12}%`,
                      fontSize: `${20 + i * 4}px`,
                      animation: `confettiFall ${0.8 + i * 0.2}s ease-in ${i * 0.15}s forwards`,
                      pointerEvents: "none",
                      zIndex: 20,
                      filter: "drop-shadow(0 2px 3px rgba(0,0,0,0.4))",
                    }}>🍖</div>
                  ))}
                  <div style={{
                    position: "absolute", top: "35%", left: "50%", transform: "translateX(-50%)",
                    fontSize: "12px", fontWeight: 900, color: "#e87830",
                    textShadow: "0 1px 3px rgba(0,0,0,0.6)",
                    animation: "floatUp 1s ease-out forwards",
                    pointerEvents: "none", zIndex: 20,
                  }}>+35% 🍖</div>
                </>
              )}
              {careAnim === "play" && (
                <>
                  {[0, 1, 2, 3].map(i => (
                    <div key={`play-${i}`} style={{
                      position: "absolute",
                      top: `${20 + (i % 2) * 15}%`,
                      left: `${20 + i * 15}%`,
                      fontSize: "16px",
                      animation: `sparkle ${0.5 + i * 0.1}s ease-out ${i * 0.08}s forwards`,
                      pointerEvents: "none",
                      zIndex: 20,
                    }}>⭐</div>
                  ))}
                </>
              )}
              {careAnim === "sleep" && (
                <div style={{
                  position: "absolute", inset: 0,
                  background: "rgba(30,40,60,0.35)",
                  borderRadius: "4px",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  pointerEvents: "none",
                  zIndex: 20,
                  animation: "fadeIn 0.3s ease-out",
                }}>
                  <div style={{
                    fontSize: "28px",
                    animation: "pulse 1s ease-in-out infinite",
                    filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.5))",
                  }}>💤</div>
                </div>
              )}

              {/* Care bonus indicator - top left */}
              {careBonus.perfect && (
                <div style={{
                  position: "absolute", top: "4px", left: "4px",
                  fontSize: "8px", fontWeight: 900,
                  color: "#f8c840",
                  background: "rgba(0,0,0,0.5)",
                  padding: "2px 6px",
                  borderRadius: "6px",
                  letterSpacing: "1px",
                }}>
                  ✨ PARFAIT
                </div>
              )}
              {!careBonus.canSpecial && (
                <div style={{
                  position: "absolute", top: "4px", left: "4px",
                  fontSize: "8px", fontWeight: 900,
                  color: "#ff8888",
                  background: "rgba(0,0,0,0.5)",
                  padding: "2px 6px",
                  borderRadius: "6px",
                }}>
                  ⚠ Épuisé
                </div>
              )}

              {/* Mini care gauges - bottom overlay */}
              <div style={{
                position: "absolute", bottom: "0", left: "0", right: "0",
                padding: "6px 10px 4px",
                background: "linear-gradient(transparent, rgba(0,0,0,0.55))",
                borderRadius: "0 0 4px 4px",
                display: "flex",
                gap: "4px",
                alignItems: "flex-end",
              }}>
                {[
                  { emoji: "🍖", value: careHunger, color: "#e87830" },
                  { emoji: "😊", value: careHappiness, color: "#f0b830" },
                  { emoji: "💤", value: careEnergy, color: "#58b8e8" },
                ].map((g, i) => (
                  <div key={i} style={{ flex: 1 }}>
                    <div style={{ fontSize: "8px", textAlign: "center", marginBottom: "1px" }}>{g.emoji}</div>
                    <div style={{
                      height: "5px",
                      background: "rgba(0,0,0,0.4)",
                      borderRadius: "3px",
                      overflow: "hidden",
                    }}>
                      <div style={{
                        width: `${g.value}%`,
                        height: "100%",
                        background: g.value >= 70 ? g.color : g.value >= 20 ? `${g.color}88` : "#cc2020",
                        borderRadius: "3px",
                        transition: "width 0.5s",
                        animation: g.value < 20 ? "pulse 1s infinite" : "none",
                      }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <input
              value={name}
              onChange={e => setName(e.target.value)}
              style={{
                width: "100%",
                background: "transparent",
                border: "none",
                borderBottom: "1px solid rgba(255,255,255,0.2)",
                fontFamily: "system-ui, -apple-system, sans-serif",
                fontSize: "20px",
                fontStyle: "italic",
                textAlign: "center",
                color: "#c0b8a8",
                marginTop: "8px",
                padding: "4px 0",
                outline: "none",
              }}
            />
            <div style={{ fontSize: "10px", textAlign: "center", color: "#c0b8a8", marginTop: "2px", fontStyle: "italic" }}>
              {generateName(build)}
            </div>
            <div style={{ textAlign: "center", marginTop: "4px" }}>
              <span style={{
                display: "inline-block",
                padding: "2px 10px",
                background: "rgba(60,90,70,0.25)",
                border: "1px solid #2a2820",
                borderRadius: "10px",
                fontSize: "11px",
                color: "#f0ece0",
              }}>
                {TYPE_EMOJI[getBuildType(build)]} {getBuildType(build).toUpperCase()}
              </span>
            </div>
            <div style={{ fontSize: "9px", letterSpacing: "2px", textAlign: "center", color: "#c0b8a8", marginTop: "3px" }}>
              SPECIMEN N°{String(Object.values(build).reduce((a,b)=>a+b,0)).padStart(4,"0")}
            </div>
          </div>

          {/* Care actions (compact) */}
          <div style={{ display: "flex", gap: "6px", padding: "0 16px", marginBottom: "12px" }}>
              <button
                onClick={feedDino}
                disabled={fedToday >= 3 && (inventory.food || 0) <= 0}
                style={{
                  flex: 1, padding: "8px 4px",
                  background: careHunger >= 90 ? "rgba(80,80,80,0.15)" : "linear-gradient(135deg, rgba(232,120,56,0.2), rgba(180,80,30,0.25))",
                  color: "#f0ece0",
                  border: `1px solid ${careHunger < 30 ? "#cc2020" : "#e87830"}`,
                  borderRadius: "8px",
                  fontFamily: "system-ui, -apple-system, sans-serif",
                  fontSize: "9px",
                  cursor: careHunger >= 90 ? "not-allowed" : "pointer",
                  opacity: careHunger >= 90 ? 0.4 : 1,
                }}
              >
                <div style={{ fontSize: "16px" }}>🍖</div>
                <div style={{ fontSize: "7px", marginTop: "1px" }}>{fedToday >= 3 ? `🍖${inventory.food || 0}` : `${3 - fedToday}x gratuit`}</div>
                <div style={{ fontSize: "6px", opacity: 0.75 }}>+faim +😊 +❤</div>
              </button>

              {playMiniGame ? (
                <button
                  onClick={playMiniGame.active ? tapPlay : undefined}
                  style={{
                    flex: 1, padding: "8px 4px",
                    background: playMiniGame.active
                      ? "linear-gradient(135deg, rgba(232,216,72,0.4), rgba(196,168,56,0.5))"
                      : "rgba(104,245,168,0.2)",
                    color: "#f0ece0",
                    border: playMiniGame.active ? "2px solid #f0b830" : "1px solid #f8c840",
                    borderRadius: "8px",
                    fontFamily: "system-ui, -apple-system, sans-serif",
                    fontSize: "9px",
                    cursor: "pointer",
                  }}
                >
                  {playMiniGame.active ? (
                    <>
                      <div style={{ fontSize: "16px", fontWeight: 900, animation: "pulse 0.3s ease-in-out infinite" }}>👆</div>
                      <div style={{ fontSize: "7px" }}>Tapez le dino !</div>
                    </>
                  ) : (
                    <>
                      <div style={{ fontSize: "14px" }}>✅</div>
                      <div style={{ fontSize: "8px", fontWeight: 700, color: "#f8c840" }}>+{playMiniGame.result}% 😊</div>
                    </>
                  )}
                </button>
              ) : (
                <button
                  onClick={startPlayMiniGame}
                  disabled={careHappiness >= 90}
                  style={{
                    flex: 1, padding: "8px 4px",
                    background: careHappiness >= 90 ? "rgba(80,80,80,0.15)" : "linear-gradient(135deg, rgba(232,216,72,0.15), rgba(196,168,56,0.2))",
                    color: "#f0ece0",
                    border: `1px solid ${careHappiness < 30 ? "#cc2020" : "#f0b830"}`,
                    borderRadius: "8px",
                    fontFamily: "system-ui, -apple-system, sans-serif",
                    fontSize: "9px",
                    cursor: careHappiness >= 90 ? "not-allowed" : "pointer",
                    opacity: careHappiness >= 90 ? 0.4 : 1,
                  }}
                >
                  <div style={{ fontSize: "16px" }}>🎮</div>
                  <div style={{ fontSize: "7px", marginTop: "1px" }}>Jouer</div>
                </button>
              )}

              <button
                onClick={sleepDino}
                disabled={sleepCooldown > 0 || careEnergy >= 90}
                style={{
                  flex: 1, padding: "8px 4px",
                  background: sleepCooldown > 0 || careEnergy >= 90 ? "rgba(80,80,80,0.15)" : "linear-gradient(135deg, rgba(88,184,232,0.15), rgba(56,120,200,0.2))",
                  color: "#f0ece0",
                  border: `1px solid ${careEnergy < 30 ? "#cc2020" : "#58b8e8"}`,
                  borderRadius: "8px",
                  fontFamily: "system-ui, -apple-system, sans-serif",
                  fontSize: "9px",
                  cursor: sleepCooldown > 0 || careEnergy >= 90 ? "not-allowed" : "pointer",
                  opacity: sleepCooldown > 0 || careEnergy >= 90 ? 0.4 : 1,
                }}
              >
                <div style={{ fontSize: "16px" }}>💤</div>
                <div style={{ fontSize: "7px", marginTop: "1px" }}>{sleepCooldown > 0 ? `⏱${sleepCooldown * 5}m` : "Dormir"}</div>
              </button>

              {/* Bug hunt button */}
              {!bugHunt && (
                <button
                  onClick={startBugHunt}
                  disabled={careHunger >= 90}
                  style={{
                    flex: 1, padding: "8px 4px",
                    background: careHunger >= 90 ? "rgba(80,80,80,0.15)" : "linear-gradient(135deg, rgba(140,200,60,0.2), rgba(80,120,30,0.25))",
                    color: "#f0ece0",
                    border: `1px solid ${careHunger < 30 ? "#cc2020" : "#48a848"}`,
                    borderRadius: "8px",
                    fontFamily: "system-ui, -apple-system, sans-serif",
                    fontSize: "9px",
                    cursor: careHunger >= 90 ? "not-allowed" : "pointer",
                    opacity: careHunger >= 90 ? 0.4 : 1,
                  }}
                >
                  <div style={{ fontSize: "16px" }}>🦟</div>
                  <div style={{ fontSize: "7px", marginTop: "1px" }}>Chasse</div>
                  <div style={{ fontSize: "6px", opacity: 0.75 }}>gratuit +faim</div>
                </button>
              )}
              {bugHunt && (
                <div style={{
                  flex: 1, padding: "8px 4px",
                  background: bugHunt.active ? "rgba(140,200,60,0.3)" : "rgba(104,245,168,0.2)",
                  border: bugHunt.active ? "2px solid #48a848" : "1px solid #f8c840",
                  borderRadius: "8px",
                  textAlign: "center",
                  fontSize: "9px",
                }}>
                  {bugHunt.active ? (
                    <div style={{ fontWeight: 900, fontSize: "12px" }}>{bugHunt.caught}/5 🦟</div>
                  ) : (
                    <div style={{ color: "#f8c840", fontWeight: 700 }}>+{bugHunt.result}% 🍖</div>
                  )}
                </div>
              )}
          </div>


          {/* Cry & action buttons */}
          <div style={{ display: "flex", gap: "8px", padding: "0 16px", marginBottom: "16px" }}>
            <button onClick={() => { playCry(build); setCrying(false); setTimeout(() => setCrying(true), 10); setTimeout(() => setCrying(false), 700); }} style={btnPrimary}>
              ◉ CRI
            </button>
            <button onClick={randomize} style={btnSecondary}>
              ⟳ ALÉA
            </button>
            <button onClick={save} style={btnSecondary}>
              ✚ SAUVER
            </button>
            <button onClick={() => setShowIdCard(true)} style={btnSecondary}>
              📋
            </button>
            <button onClick={generateAiName} disabled={aiNaming === "loading"} style={{...btnSecondary, color: "#c888e8", border: "1px solid rgba(200,136,232,0.3)"}}>
              {aiNaming === "loading" ? "⏳" : "✨IA"}
            </button>
          </div>
          <div style={{ display: "flex", gap: "8px", padding: "0 16px", marginBottom: "16px" }}>
            <button onClick={() => startBattle()} className="card-raised" style={{
              ...btnPrimary,
              background: "linear-gradient(135deg, #dd2828 0%, #aa1818 50%, #6a0e0e 100%)",
              color: "#f0ece0",
              border: "2px solid #e84040",
              borderRadius: "8px",
              flex: 1,
              padding: "16px",
              fontSize: "14px",
              fontWeight: 900,
              letterSpacing: "4px",
              textShadow: "0 2px 4px rgba(0,0,0,0.6)",
            }}>
              ⚔ ENVOYER AU COMBAT
            </button>
            <button onClick={startRunner} style={{
              padding: "16px 12px",
              background: "linear-gradient(135deg, rgba(72,168,72,0.3), rgba(40,100,40,0.4))",
              color: "#f0ece0",
              border: "1px solid #48a848",
              borderRadius: "8px",
              fontSize: "12px",
              fontWeight: 700,
              cursor: "pointer",
            }}>
              🏃 Course
            </button>
          </div>


          {/* Stats */}
          <div style={{ padding: "0 16px", marginBottom: "20px" }}>
            <div style={{ fontSize: "10px", letterSpacing: "2px", opacity: 0.85, marginBottom: "8px", color: "#f8c840", fontWeight: 700, textAlign: "center" }}>
              ── CARACTÉRISTIQUES ──
              <span style={{ fontSize: "9px", opacity: 0.75, fontWeight: 400 }}> (cap: {statCap})</span>
            </div>
            {/* HP display */}
            <div style={{
              marginBottom: "10px",
              padding: "8px 10px",
              background: "rgba(56,200,120,0.12)",
              border: "1px solid #e8a020",
            }}>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: "11px", textTransform: "uppercase", letterSpacing: "1px" }}>
                <span>❤ Points de vie</span>
                <span style={{ color: "#f8c840", fontWeight: 700 }}>{computeHP(playerStatsLeveled, trait, permaBonus.hp || 0)} PV</span>
              </div>
              {level > 1 && (
                <div style={{ fontSize: "8px", opacity: 0.75, marginTop: "2px" }}>
                  (base {computeHP(stats, trait, permaBonus.hp || 0)} · bonus niveau +{computeHP(playerStatsLeveled, trait, permaBonus.hp || 0) - computeHP(stats, trait, permaBonus.hp || 0)})
                </div>
              )}
            </div>
            {Object.entries(stats).map(([k, v]) => {
              const eggB = k !== "taille" ? (permaBonus[k] || 0) : 0;
              const traitB = k !== "taille" ? (traitBonus[k] || 0) : 0;
              const eqB = k !== "taille" ? (equipBonus[k] || 0) : 0;
              const levelB = k !== "taille" ? v * ((level - 1) * 0.1) : 0;
              const raw = v + levelB + eggB + traitB + eqB;
              const capped = k !== "taille" ? Math.min(statCap, raw) : raw;
              const total = Math.round(capped * 10) / 10;
              const isCapped = raw > statCap && statCap < 15 && k !== "taille";
              const maxVal = 15;
              const barW = Math.min(100, (total / maxVal) * 100);
              const capPos = (statCap / maxVal) * 100;
              // Color based on value
              const barColor = total >= 10 ? "linear-gradient(90deg, #e8a020, #f0b830)"
                : total >= 7 ? "linear-gradient(90deg, #5a9a48, #8aca68)"
                : total >= 4 ? "linear-gradient(90deg, #c89040, #e8b858)"
                : "linear-gradient(90deg, #a85030, #c87050)";
              const labels = { attaque: "ATQ", defense: "DEF", vitesse: "VIT", force: "FRC", taille: "TAI", intel: "INT" };
              return (
              <div key={k} style={{ marginBottom: "6px" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: "11px", letterSpacing: "1px" }}>
                  <span style={{ textTransform: "uppercase", fontWeight: 700, minWidth: "28px" }}>{labels[k]}</span>
                  <div style={{
                    flex: 1, height: "10px", background: "#1a2818", border: "1px solid #2a2820",
                    borderRadius: "5px", margin: "0 8px", overflow: "hidden", position: "relative",
                  }}>
                    <div style={{ width: `${barW}%`, height: "100%", background: barColor, transition: "width 0.3s" }} />
                    {k !== "taille" && statCap < 15 && (
                      <div style={{ position: "absolute", left: `${capPos}%`, top: 0, bottom: 0, width: "2px", background: "#e87830", zIndex: 2, opacity: 0.9 }} />
                    )}
                  </div>
                  <span style={{
                    minWidth: "32px", textAlign: "right", fontWeight: 700, fontSize: "12px",
                    color: isCapped ? "#e87830" : total >= 10 ? "#f0b830" : total >= 7 ? "#8aca68" : "#f0ece0",
                  }}>
                    {total.toFixed(1)}
                  </span>
                </div>
                {(eggB > 0 || traitB > 0 || eqB > 0) && (
                  <div style={{ fontSize: "7px", opacity: 0.75, marginLeft: "36px", marginTop: "1px" }}>
                    {levelB > 0 && `niv +${levelB.toFixed(1)} `}
                    {eggB > 0 && `🥚+${eggB.toFixed(1)} `}
                    {traitB > 0 && `trait +${traitB.toFixed(1)} `}
                    {eqB > 0 && `🗡+${eqB.toFixed(1)} `}
                    {isCapped && `⛔ cap ${statCap}`}
                  </div>
                )}
              </div>
              );
            })}
          </div>



          {/* Part selector tabs */}
          <div style={{
            display: "flex",
            gap: "4px",
            padding: "0 16px",
            overflowX: "auto",
            marginBottom: "12px",
            scrollbarWidth: "none",
          }}>
            {PARTS.map(p => (
              <button
                key={p.key}
                onClick={() => setActivePart(p.key)}
                style={{
                  padding: "10px 12px",
                  background: activePart === p.key ? "#f0ece0" : "transparent",
                  color: activePart === p.key ? "#0a0e08" : "#f0ece0",
                  border: "1px solid #2a2820",
                  fontFamily: "system-ui, -apple-system, sans-serif",
                  fontSize: "10px",
                  letterSpacing: "1px",
                  whiteSpace: "nowrap",
                  cursor: "pointer",
                  textTransform: "uppercase",
                  flexShrink: 0,
                }}
              >
                {p.icon} {p.label}
              </button>
            ))}
          </div>

          {/* Dino picker */}
          <div style={{ padding: "0 16px" }}>
            <div style={{ fontSize: "10px", letterSpacing: "2px", opacity: 0.75, marginBottom: "8px" }}>
              CHOISIR L'ESPÈCE DONNEUSE — {PARTS.find(p => p.key === activePart).label.toUpperCase()}
            </div>

            {/* Special unlocked colors (only shown on color tab) */}
            {activePart === "color" && unlockedColors.length > 0 && (
              <div style={{
                marginBottom: "8px",
                padding: "8px",
                background: "linear-gradient(135deg, rgba(212,175,55,0.15) 0%, rgba(160,128,42,0.05) 100%)",
                border: "1px solid #e8a020",
              }}>
                <div style={{ fontSize: "9px", letterSpacing: "1px", marginBottom: "6px", color: "#e8a020" }}>
                  ✨ COULEURS RARES (ŒUFS)
                </div>
                <div style={{ display: "flex", flexWrap: "wrap", gap: "4px" }}>
                  {unlockedColors.map((c, i) => {
                    const selected = build.customColor === c;
                    return (
                      <button
                        key={i}
                        onClick={() => setBuild({ ...build, customColor: selected ? null : c })}
                        style={{
                          width: "30px", height: "30px",
                          background: c,
                          border: selected ? "2px solid #f0ece0" : "1px solid #0a0e08",
                          cursor: "pointer",
                          padding: 0,
                        }}
                        title="Couleur rare"
                      />
                    );
                  })}
                </div>
                {build.customColor && (
                  <div style={{ fontSize: "8px", marginTop: "4px", opacity: 0.85 }}>
                    Couleur rare active — clique à nouveau pour revenir aux dinos
                  </div>
                )}
              </div>
            )}

            <div style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: "6px",
              maxHeight: "320px",
              overflowY: "auto",
              padding: "4px",
              border: "1px solid #2a2820",
              background: "rgba(0,0,0,0.35)",
            }}>
              {DINOS.map((d, i) => ({ d, i }))
                .filter(x => !x.d.exclusive || unlockedExclusives.includes(x.i))
                .sort((a, b) => {
                  // Exclusives at the end with a ★
                  if (a.d.exclusive !== b.d.exclusive) return a.d.exclusive ? 1 : -1;
                  return a.d.name.localeCompare(b.d.name, "fr");
                })
                .map(({ d, i }) => {
                const selected = build[activePart] === i;
                const isExcl = d.exclusive;
                const rarCol = d.rarity === "legendary" ? "#e8a020" : d.rarity === "epic" ? "#c888e8" : d.rarity === "rare" ? "#60a0f0" : null;
                return (
                  <button
                    key={i}
                    onClick={() => {
                      const update = { ...build, [activePart]: i };
                      if (activePart === "color") update.customColor = null;
                      setBuild(update);
                    }}
                    style={{
                      padding: "8px",
                      background: selected ? "#f0ece0" : isExcl ? "rgba(232,160,32,0.1)" : "rgba(60,90,70,0.2)",
                      color: selected ? "#0a0e08" : "#f0ece0",
                      border: `1px solid ${selected ? "#f0ece0" : isExcl ? "#e8a020" : "#2a2820"}`,
                      textAlign: "left",
                      cursor: "pointer",
                      fontFamily: "system-ui, -apple-system, sans-serif",
                      position: "relative",
                    }}
                  >
                    {isExcl && (
                      <div style={{
                        position: "absolute", top: "2px", right: "4px",
                        fontSize: "8px", fontWeight: 900,
                        color: rarCol || "#e8a020",
                      }}>★</div>
                    )}
                    <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                      <div style={{
                        width: "14px", height: "14px",
                        background: d.color,
                        border: `1px solid ${isExcl ? rarCol || "#e8a020" : "#0a0e08"}`,
                        borderRadius: isExcl ? "3px" : "0",
                        flexShrink: 0,
                      }} />
                      <div style={{ fontSize: "11px", fontWeight: 700, lineHeight: 1.1, color: selected ? "#0a0e08" : isExcl ? rarCol || "#e8a020" : "#f0ece0" }}>{d.name}</div>
                    </div>
                    <div style={{ fontSize: "8px", opacity: 0.75, marginTop: "2px", letterSpacing: "1px" }}>
                      {d.era.toUpperCase()}
                    </div>
                    <div style={{ fontSize: "9px", opacity: 0.85, marginTop: "3px", lineHeight: 1.2 }}>
                      {describePartContribution(i, activePart)}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>


          {/* Trait selector */}
          <div style={{ padding: "0 16px", marginBottom: "16px" }}>
            <div style={{ fontSize: "10px", letterSpacing: "2px", opacity: 0.85, marginBottom: "6px" }}>
              ── TRAIT DU DINO ──
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "4px" }}>
              {TRAITS.map(t => {
                const selected = trait === t.key;
                const tc = { sanguinaire: "#cc2020", resistant: "#5878a0", ruse: "#9050d0", fureur: "#e87830", endurant: "#38a038" };
                const color = tc[t.key] || "#888";
                const sb = TRAIT_STAT_BONUS[t.key] || {};
                const bonusChips = Object.entries(sb).filter(([, v]) => v > 0);
                return (
                  <button
                    key={t.key}
                    onClick={() => setTrait(selected ? null : t.key)}
                    style={{
                      padding: "8px",
                      background: selected
                        ? `linear-gradient(135deg, ${color}40 0%, ${color}20 100%)`
                        : "rgba(245,236,210,0.05)",
                      color: "#f0ece0",
                      border: selected ? `2px solid ${color}` : "1px solid #2a2820",
                      borderRadius: "8px",
                      fontFamily: "system-ui, -apple-system, sans-serif",
                      fontSize: "10px",
                      textAlign: "left",
                      cursor: "pointer",
                      boxShadow: selected ? `0 0 10px ${color}40, inset 0 1px 0 ${color}30` : "none",
                    }}
                  >
                    <div style={{ fontWeight: 700, marginBottom: "3px" }}>{t.emoji} {t.name}</div>
                    <div style={{ fontSize: "8px", opacity: 0.85, lineHeight: 1.2, marginBottom: "4px" }}>{t.desc}</div>
                    <div style={{ display: "flex", gap: "3px", flexWrap: "wrap" }}>
                      {bonusChips.map(([stat, val]) => (
                        <span key={stat} style={{
                          display: "inline-block",
                          padding: "1px 5px",
                          background: color,
                          color: "#fff",
                          borderRadius: "6px",
                          fontSize: "8px",
                          fontWeight: 700,
                        }}>
                          +{val} {stat === "intel" ? "INT" : stat.slice(0, 3).toUpperCase()}
                        </span>
                      ))}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Equipment selector */}
          {ownedEquipment.length > 0 && (
          <div style={{ padding: "0 16px", marginBottom: "16px" }}>
            <div style={{ fontSize: "10px", letterSpacing: "2px", opacity: 0.85, marginBottom: "6px", color: "#f8c840", fontWeight: 700, textAlign: "center" }}>
              ── ÉQUIPEMENT ──
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "4px" }}>
              {ownedEquipment.map(eKey => {
                const eq = EQUIPMENT_LIST.find(e => e.key === eKey);
                if (!eq) return null;
                const selected = equipment === eKey;
                const rc = eq.rarity === "epic" ? "#e8a020" : eq.rarity === "rare" ? "#7090a0" : "#3a3828";
                return (
                  <button
                    key={eKey}
                    onClick={() => setEquipment(selected ? null : eKey)}
                    style={{
                      padding: "6px 8px",
                      background: selected ? `${rc}30` : "rgba(245,236,210,0.05)",
                      color: "#f0ece0",
                      border: selected ? `2px solid ${rc}` : "1px solid #2a2820",
                      borderRadius: "8px",
                      fontFamily: "system-ui, -apple-system, sans-serif",
                      fontSize: "10px",
                      textAlign: "left",
                      cursor: "pointer",
                    }}
                  >
                    <div style={{ fontWeight: 700 }}>{eq.emoji} {eq.name}</div>
                    <div style={{ fontSize: "8px", opacity: 0.85 }}>{eq.desc}</div>
                  </button>
                );
              })}
            </div>
            {!ownedEquipment.length && (
              <div style={{ fontSize: "9px", opacity: 0.85, textAlign: "center", fontStyle: "italic" }}>
                Gagne des combats pour trouver des équipements.
              </div>
            )}
          </div>
          )}

          {/* Pattern selector */}
          <div style={{ padding: "0 16px", marginBottom: "16px" }}>
            <div style={{ fontSize: "10px", letterSpacing: "2px", opacity: 0.85, marginBottom: "6px", color: "#f8c840", fontWeight: 700, textAlign: "center" }}>
              ── MOTIF DE PEAU ──
            </div>
            <div style={{ display: "flex", gap: "6px", justifyContent: "center" }}>
              {PATTERNS.map(p => (
                <button
                  key={p.key}
                  onClick={() => setPattern(p.key)}
                  style={{
                    padding: "6px 10px",
                    background: pattern === p.key ? "rgba(245,236,210,0.15)" : "rgba(245,236,210,0.04)",
                    color: "#f0ece0",
                    border: pattern === p.key ? "2px solid #e8a020" : "1px solid #2a2820",
                    borderRadius: "8px",
                    fontFamily: "system-ui, -apple-system, sans-serif",
                    fontSize: "10px",
                    cursor: "pointer",
                  }}
                >
                  {p.emoji} {p.name}
                </button>
              ))}
            </div>
          </div>

          {/* Composition summary */}
          <div style={{ padding: "0 16px", marginBottom: "20px" }}>
            <div style={{ fontSize: "10px", letterSpacing: "2px", opacity: 0.85, marginBottom: "8px", color: "#f8c840", fontWeight: 700, textAlign: "center" }}>
              ── COMPOSITION ──
            </div>
            <div style={{
              border: "1px solid #2a2820",
              background: "rgba(0,0,0,0.35)",
              padding: "10px",
            }}>
              {PARTS.map(p => {
                const dino = DINOS[build[p.key]];
                const contributes = partContributesTo(p.key);
                const isExcl = dino.exclusive;
                const rar = dino.rarity || "common";
                const rarColors = { common: null, rare: "#7090a0", epic: "#9050d0", legendary: "#e8a020" };
                const rarLabels = { common: null, rare: "RARE", epic: "ÉPIQUE", legendary: "LÉGEND." };
                return (
                  <div key={p.key} style={{
                    display: "flex",
                    alignItems: "flex-start",
                    gap: "8px",
                    padding: "6px 0",
                    borderBottom: "1px dashed rgba(245,236,210,0.15)",
                    background: isExcl ? "rgba(196,168,56,0.08)" : "transparent",
                  }}>
                    <div style={{
                      width: "12px", height: "12px",
                      background: dino.color,
                      border: isExcl ? "2px solid #e8a020" : "1px solid #0a0e08",
                      borderRadius: isExcl ? "50%" : 0,
                      flexShrink: 0,
                      marginTop: "2px",
                      boxShadow: isExcl ? "0 0 6px rgba(196,168,56,0.5)" : "none",
                    }} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: "flex", justifyContent: "space-between", gap: "8px", fontSize: "10px", letterSpacing: "1px", textTransform: "uppercase", opacity: 0.85 }}>
                        <span>{p.icon} {p.label}</span>
                        {contributes.length > 0 && (
                          <span style={{ fontSize: "8px", opacity: 0.85 }}>→ {contributes.join(" · ")}</span>
                        )}
                      </div>
                      <div style={{ fontSize: "12px", fontStyle: "italic", marginTop: "1px", display: "flex", gap: "6px", alignItems: "center" }}>
                        <span>{dino.name}</span>
                        {rarLabels[rar] && (
                          <span style={{
                            fontSize: "7px", fontWeight: 900, fontStyle: "normal",
                            padding: "1px 4px", borderRadius: "4px",
                            background: rarColors[rar], color: "#fff",
                            letterSpacing: "0.5px",
                          }}>{rarLabels[rar]}</span>
                        )}
                        {isExcl && (
                          <span style={{ fontSize: "7px", fontWeight: 900, fontStyle: "normal", color: "#e8a020" }}>★</span>
                        )}
                      </div>
                      <div style={{ fontSize: "9px", opacity: 0.75, marginTop: "1px" }}>
                        {describePartContribution(build[p.key], p.key)}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

        </div>



      )}

      {view === "gallery" && (
        <div className="view-enter" key="gallery" style={{ padding: "20px 16px" }}>
          {saved.length === 0 ? (
            <div style={{ textAlign: "center", opacity: 0.85, padding: "40px 0", fontStyle: "italic" }}>
              Aucun spécimen archivé.<br/>
              Chloé, crée ton premier hybride dans l'atelier.
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
              <div style={{ fontSize: "9px", opacity: 0.85, textAlign: "center", marginBottom: "4px" }}>
                {saved.length} spécimen{saved.length > 1 ? "s" : ""} archivé{saved.length > 1 ? "s" : ""}
              </div>
              {saved.slice(0, galleryCount).map(s => {
                // Determine card rarity based on parts
                const partRarities = Object.values(s.build).filter((v, i) => i < 7).map(idx => DINOS[idx]?.rarity || "common");
                const hasLegendary = partRarities.includes("legendary");
                const hasEpic = partRarities.includes("epic");
                const hasRare = partRarities.includes("rare");
                const hasExcl = Object.values(s.build).filter((v, i) => i < 7).some(idx => DINOS[idx]?.exclusive);
                const cardBorder = hasLegendary ? "#e8a020" : hasEpic ? "#9050d0" : hasRare ? "#7090a0" : "#2a2820";
                const cardGlow = hasLegendary ? "0 0 12px rgba(196,168,56,0.4)" : hasEpic ? "0 0 10px rgba(152,88,200,0.3)" : hasRare ? "0 0 8px rgba(88,136,200,0.2)" : "none";
                const rarLabel = hasLegendary ? "LÉGENDAIRE" : hasEpic ? "ÉPIQUE" : hasRare ? "RARE" : null;
                const typeEmoji = TYPE_EMOJI[getBuildType(s.build)] || "🌍";
                return (
                <div key={s.id} style={{
                  background: "rgba(255,248,230,0.05)",
                  boxShadow: `inset 0 0 20px rgba(60,90,70,0.2), 0 3px 10px rgba(0,0,0,0.35), ${cardGlow}`,
                  border: `2px solid ${cardBorder}`,
                  borderRadius: "10px",
                  padding: "12px",
                  color: "#c0b8a8",
                  position: "relative",
                  overflow: "hidden",
                }}>
                  {/* Rarity ribbon */}
                  {rarLabel && (
                    <div style={{
                      position: "absolute", top: "8px", right: "-25px",
                      transform: "rotate(35deg)",
                      background: cardBorder,
                      color: "#fff",
                      fontSize: "7px",
                      fontWeight: 900,
                      padding: "2px 30px",
                      letterSpacing: "1px",
                      boxShadow: "0 1px 3px rgba(0,0,0,0.35)",
                    }}>
                      {rarLabel}
                    </div>
                  )}
                  <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
                    <div style={{ width: "100px", flexShrink: 0 }}>
                      <DinoArt build={s.build} />
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                    <input
                      value={s.name}
                      onChange={e => setSaved(saved.map(x => x.id === s.id ? { ...x, name: e.target.value } : x))}
                      style={{
                        width: "100%",
                        background: "transparent",
                        border: "none",
                        borderBottom: "1px solid rgba(255,255,255,0.2)",
                        fontFamily: "system-ui, -apple-system, sans-serif",
                        fontSize: "16px",
                        fontStyle: "italic",
                        fontWeight: 700,
                        color: "#c0b8a8",
                        padding: "2px 0",
                        outline: "none",
                      }}
                    />
                    <div style={{ fontSize: "9px", letterSpacing: "1px", opacity: 0.75, marginBottom: "2px" }}>
                      ATQ {s.stats.attaque} · DEF {s.stats.defense} · VIT {s.stats.vitesse}
                    </div>
                    <div style={{ fontSize: "9px", display: "flex", gap: "4px", flexWrap: "wrap", marginBottom: "4px", alignItems: "center" }}>
                      <span style={{ color: "#c0b8a8", fontWeight: 700 }}>Niv.{s.level || 1}</span>
                      <span style={{ opacity: 0.85 }}>·</span>
                      <span>🏆{s.totalWins || 0}</span>
                      <span style={{ opacity: 0.85 }}>·</span>
                      <span style={{ color: "#c83860" }}>
                        {Array.from({ length: Math.min(5, Math.floor((s.friendship || 0) / 100)) }).map(() => "❤").join("") || "🤍"}
                      </span>
                      {s.careHunger !== undefined && (
                        <>
                          <span style={{ opacity: 0.85 }}>·</span>
                          <span>🍖{Math.round(s.careHunger)}%</span>
                        </>
                      )}
                    </div>
                    <div style={{ display: "flex", gap: "4px" }}>
                      <button
                        onClick={() => {
                          setBuild(s.build);
                          setName(s.name);
                          if (s.level) setLevel(s.level);
                          if (s.xp !== undefined) setXp(s.xp);
                          if (s.totalWins !== undefined) setTotalWins(s.totalWins);
                          if (s.friendship !== undefined) setFriendship(s.friendship);
                          if (s.careHunger !== undefined) setCareHunger(s.careHunger);
                          if (s.careHappiness !== undefined) setCareHappiness(s.careHappiness);
                          if (s.careEnergy !== undefined) setCareEnergy(s.careEnergy);
                          if (s.trait) setTrait(s.trait);
                          if (s.equipment) setEquipment(s.equipment);
                          if (s.pattern) setPattern(s.pattern);
                          if (s.permaBonus) setPermaBonus(s.permaBonus);
                          setView("build");
                        }}
                        style={{ ...btnSmall, background: "#2a2820", color: "#f0ece0" }}
                      >
                        Charger
                      </button>
                      <button
                        onClick={() => playCry(s.build)}
                        style={{ ...btnSmall, background: "rgba(255,248,230,0.05)", color: "#f0ece0", border: "1px solid rgba(255,248,230,0.12)" }}
                      >
                        ◉ Cri
                      </button>
                      {confirmDeleteId === s.id ? (
                        <div style={{ display: "flex", gap: "3px" }}>
                          <button
                            onClick={() => { setSaved(saved.filter(x => x.id !== s.id)); setConfirmDeleteId(null); }}
                            style={{ ...btnSmall, background: "#7a2a2a", color: "#f0ece0", border: "1px solid #cc2020", fontSize: "8px" }}
                          >
                            Confirmer
                          </button>
                          <button
                            onClick={() => setConfirmDeleteId(null)}
                            style={{ ...btnSmall, background: "transparent", color: "#2a2820", border: "1px solid #2a2820", fontSize: "8px" }}
                          >
                            Non
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => setConfirmDeleteId(s.id)}
                          style={{ ...btnSmall, background: "transparent", color: "#e84040", border: "1px solid #7a2a2a" }}
                        >
                          ✕
                        </button>
                      )}
                    </div>
                  </div>
                </div>
                </div>
              );
              })}
              {/* Sentinel for lazy loading */}
              {galleryCount < saved.length && (
                <div ref={gallerySentinelRef} style={{
                  textAlign: "center", padding: "16px", opacity: 0.85, fontSize: "10px",
                }}>
                  ⏳ Chargement... ({galleryCount}/{saved.length})
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {view === "battle" && (
        <div className="view-enter" key="battle" style={{
          padding: "16px 12px",
          transform: screenShake ? "translateX(3px)" : "none",
          transition: screenShake ? "none" : "transform 0.1s",
          animation: screenShake ? "shake 0.3s ease-out" : "none",
          position: "relative",
        }}>
          {/* Impact flash overlay */}
          {screenFlash && (
            <div style={{
              position: "fixed", inset: 0, zIndex: 100, pointerEvents: "none",
              background: screenFlash === "white" ? "rgba(255,255,255,0.35)" : "rgba(200,56,56,0.25)",
              animation: "fadeIn 0.05s ease-out",
            }} />
          )}

          {/* Lightning bolt on critical */}
          {lightningBolt && (
            <svg style={{ position: "fixed", inset: 0, zIndex: 101, pointerEvents: "none", animation: "lightning 0.35s ease-out forwards" }}
              viewBox="0 0 400 600">
              <path d={`M${180+Math.random()*40},0 L${160+Math.random()*30},120 L${200+Math.random()*20},140 L${150+Math.random()*40},300 L${190+Math.random()*20},310 L${140+Math.random()*50},500 L${170+Math.random()*30},490 L${130+Math.random()*60},600`}
                fill="none" stroke="#f8f0a0" strokeWidth="4" strokeLinecap="round" />
              <path d={`M${180+Math.random()*40},0 L${160+Math.random()*30},120 L${200+Math.random()*20},140 L${150+Math.random()*40},300 L${190+Math.random()*20},310 L${140+Math.random()*50},500 L${170+Math.random()*30},490 L${130+Math.random()*60},600`}
                fill="none" stroke="#fff" strokeWidth="8" strokeLinecap="round" opacity="0.3" />
            </svg>
          )}
          {!enemy ? (
            <div style={{ textAlign: "center", padding: "30px 16px" }}>
              <div style={{ fontSize: "60px", marginBottom: "12px" }}>⚔️</div>
              <div style={{ fontSize: "14px", letterSpacing: "2px", marginBottom: "6px", textTransform: "uppercase" }}>
                Arène Préhistorique
              </div>
              <div style={{ fontSize: "11px", opacity: 0.85, marginBottom: "20px", lineHeight: 1.5 }}>
                Mets ton hybride à l'épreuve.
              </div>

              <div style={{
                background: "rgba(245,236,210,0.08)",
                border: "1px solid #2a2820",
                padding: "12px",
                marginBottom: "12px",
                fontSize: "11px",
              }}>
                <div style={{ fontStyle: "italic", marginBottom: "4px", opacity: 0.85 }}>Ton champion :</div>
                <div style={{ fontSize: "14px", fontWeight: 700 }}>{name}</div>
                <div style={{ fontSize: "10px", opacity: 0.85, marginTop: "4px", fontStyle: "italic" }}>
                  {generateName(build)}
                </div>
                <div style={{ display: "flex", justifyContent: "center", gap: "12px", marginTop: "8px", fontSize: "10px" }}>
                  <span>⭐ Niveau {level}</span>
                  <span style={{ opacity: 0.75 }}>XP {xp}/{xpForNextLevel}</span>
                </div>
                {availableAttacks.filter(a => a.special).length > 0 && (
                  <div style={{ marginTop: "8px", fontSize: "9px", opacity: 0.8 }}>
                    Attaques spéciales : {availableAttacks.filter(a => a.special).map(a => a.emoji).join(" ")}
                  </div>
                )}
              </div>

              <button onClick={() => startBattle()} style={{ ...btnPrimary, width: "100%", marginBottom: "8px" }}>
                ⚔ COMBAT LIBRE
              </button>
              <button onClick={startTournament} style={{
                ...btnPrimary,
                width: "100%",
                background: "linear-gradient(135deg, #7a3a8a 0%, #4a1a5a 100%)",
                borderColor: "#a838c8",
                color: "#f0ece0",
              }}>
                👑 TOURNOI (5 COMBATS)
              </button>
              <div style={{ fontSize: "9px", opacity: 0.85, marginTop: "6px", letterSpacing: "1px" }}>
                Apprenti → Vétéran → Champion → Légendaire → Apex
              </div>
            </div>
          ) : (
            <div>
              {/* Tournament progress */}
              {tournament && (
                <div style={{
                  display: "flex",
                  gap: "4px",
                  marginBottom: "8px",
                  justifyContent: "center",
                }}>
                  {TOURNAMENT_TIERS.map((t, i) => (
                    <div key={i} style={{
                      flex: 1,
                      padding: "4px 2px",
                      background: i < tournament.tier ? "#e8a020" : i === tournament.tier ? t.color : "rgba(245,236,210,0.1)",
                      border: "1px solid #2a2820",
                      fontSize: "8px",
                      textAlign: "center",
                      letterSpacing: "1px",
                      textTransform: "uppercase",
                      opacity: i <= tournament.tier ? 1 : 0.4,
                      fontWeight: i === tournament.tier ? 700 : 400,
                    }}>
                      {i < tournament.tier ? "✓" : t.name.slice(0, 4)}
                    </div>
                  ))}
                </div>
              )}

              {/* Sticky combat header: scene + HP bars */}
              <div style={{
                position: "sticky",
                top: 0,
                zIndex: 50,
                background: "linear-gradient(180deg, #1d7a6f 0%, #1a6b5a 100%)",
                paddingTop: "6px",
                marginTop: "-6px",
                marginLeft: "-12px",
                marginRight: "-12px",
                paddingLeft: "12px",
                paddingRight: "12px",
                paddingBottom: "8px",
                boxShadow: "0 6px 12px rgba(30,50,35,0.35)",
                borderBottom: "1px solid #2a2820",
              }}>
              {/* Battle scene with environment */}
              <div style={{
                background: environment.bg,
                border: "2px solid #2a2820",
                borderRadius: "8px",
                padding: "10px",
                marginBottom: "10px",
                position: "relative",
                overflow: "hidden",
                minHeight: "180px",
              }}>
                {/* Sky gradient layer */}
                <div style={{
                  position: "absolute", inset: 0,
                  background: "linear-gradient(180deg, rgba(255,248,230,0.07) 0%, transparent 40%, rgba(0,0,0,0.1) 100%)",
                  pointerEvents: "none", zIndex: 1,
                }} />

                {/* Background silhouette layer */}
                <div style={{
                  position: "absolute", bottom: "25%", left: 0, right: 0,
                  height: "30%",
                  background: "rgba(0,0,0,0.06)",
                  clipPath: "polygon(0% 80%, 5% 40%, 12% 60%, 20% 30%, 28% 50%, 35% 20%, 42% 45%, 50% 15%, 58% 40%, 65% 25%, 72% 55%, 80% 30%, 88% 50%, 95% 35%, 100% 70%, 100% 100%, 0% 100%)",
                  pointerEvents: "none", zIndex: 1,
                }} />
                {/* Environment label */}
                <div style={{
                  position: "absolute",
                  top: "4px",
                  left: "8px",
                  fontSize: "9px",
                  letterSpacing: "1px",
                  opacity: 0.85,
                  background: "rgba(0,0,0,0.35)",
                  padding: "2px 6px",
                  zIndex: 5,
                }}>
                  {environment.emoji} {environment.name} · {weather.emoji} {weather.name}
                </div>
                {/* Type & weather advantage banner */}
                <div style={{
                  position: "absolute",
                  top: "4px",
                  right: "8px",
                  fontSize: "9px",
                  background: "rgba(0,0,0,0.4)",
                  padding: "2px 6px",
                  zIndex: 5,
                  display: "flex",
                  gap: "6px",
                  alignItems: "center",
                }}>
                  {(() => {
                    const pType = getBuildType(build);
                    const eType = getBuildType(enemy.build);
                    const mult = getTypeMult(pType, eType);
                    const weatherBoost = weather.boosts?.[pType];
                    const weatherPenalty = weatherBoost && weatherBoost < 1;
                    const weatherBuff = weatherBoost && weatherBoost > 1;
                    return (
                      <>
                        <span style={{ color: mult > 1 ? "#f8c840" : mult < 1 ? "#ff8888" : "#f0ece0" }}>
                          {TYPE_EMOJI[pType]} vs {TYPE_EMOJI[eType]}
                          {mult > 1 && " ×1.5"}
                          {mult < 1 && " ×0.7"}
                        </span>
                        {weatherBuff && <span style={{ color: "#f8c840" }}>☀ +{Math.round((weatherBoost - 1) * 100)}%</span>}
                        {weatherPenalty && <span style={{ color: "#ff8888" }}>☁ {Math.round((weatherBoost - 1) * 100)}%</span>}
                      </>
                    );
                  })()}
                </div>

                {/* Attack visual effect */}
                {getAttackEffect()}

                {/* Ground with texture */}
                <div style={{
                  position: "absolute",
                  bottom: 0, left: 0, right: 0,
                  height: "30%",
                  background: environment.ground,
                  opacity: 0.85,
                  borderTop: "1px solid rgba(0,0,0,0.15)",
                }} />
                {/* Ground details */}
                <div style={{
                  position: "absolute",
                  bottom: 0, left: 0, right: 0,
                  height: "30%",
                  background: "repeating-linear-gradient(90deg, transparent 0px, transparent 8px, rgba(0,0,0,0.04) 8px, rgba(0,0,0,0.04) 9px)",
                  pointerEvents: "none", zIndex: 2,
                }} />
                {/* Ground highlight */}
                <div style={{
                  position: "absolute",
                  bottom: "20%", left: 0, right: 0,
                  height: "3%",
                  background: "linear-gradient(90deg, transparent 0%, rgba(255,248,230,0.07) 30%, rgba(255,255,255,0.1) 50%, rgba(255,248,230,0.07) 70%, transparent 100%)",
                  pointerEvents: "none", zIndex: 2,
                }} />

                {/* Weather particles */}
                {Array.from({ length: 8 }).map((_, i) => {
                  const wk = weather.key;
                  if (wk === "clear") {
                    // Soleil : rayons dorés qui scintillent
                    return (
                      <div key={`wp-${i}`} style={{
                        position: "absolute",
                        top: `${5 + (i * 11) % 60}%`,
                        left: `${(i * 19 + 8) % 85}%`,
                        fontSize: `${10 + (i % 3) * 4}px`,
                        opacity: 0.55 + (i % 3) * 0.15,
                        animation: `sparkle ${2.5 + i * 0.4}s ease-in-out ${i * 0.5}s infinite`,
                        pointerEvents: "none", zIndex: 3,
                      }}>✨</div>
                    );
                  }
                  if (wk === "rain") {
                    // Pluie : gouttes qui tombent
                    return (
                      <div key={`wp-${i}`} style={{
                        position: "absolute",
                        top: "-8%",
                        left: `${(i * 13 + 5) % 90}%`,
                        fontSize: "10px",
                        opacity: 0.5 + (i % 3) * 0.1,
                        animation: `confettiFall ${0.8 + i * 0.12}s linear ${i * 0.15}s infinite`,
                        pointerEvents: "none", zIndex: 3,
                      }}>💧</div>
                    );
                  }
                  if (wk === "storm") {
                    // Orage : gouttes + éclairs
                    return (
                      <div key={`wp-${i}`} style={{
                        position: "absolute",
                        top: i < 6 ? "-8%" : `${20 + i * 10}%`,
                        left: `${(i * 15 + 3) % 88}%`,
                        fontSize: i < 6 ? "10px" : "16px",
                        opacity: i < 6 ? 0.5 : 0.7,
                        animation: i < 6
                          ? `confettiFall ${0.7 + i * 0.1}s linear ${i * 0.12}s infinite`
                          : `sparkle ${1 + i * 0.3}s ease-in-out ${i * 0.5}s infinite`,
                        pointerEvents: "none", zIndex: 3,
                      }}>{i < 6 ? "💧" : "⚡"}</div>
                    );
                  }
                  if (wk === "fog") {
                    // Brume : nuages qui flottent lentement
                    return (
                      <div key={`wp-${i}`} style={{
                        position: "absolute",
                        top: `${15 + (i * 12) % 55}%`,
                        left: `${(i * 18) % 80}%`,
                        fontSize: "14px",
                        opacity: 0.15 + (i % 3) * 0.08,
                        animation: `dinoWalk ${4 + i * 0.5}s ease-in-out ${i * 0.6}s infinite`,
                        pointerEvents: "none", zIndex: 3,
                      }}>☁️</div>
                    );
                  }
                  if (wk === "snow") {
                    // Neige : flocons qui tombent doucement
                    return (
                      <div key={`wp-${i}`} style={{
                        position: "absolute",
                        top: "-8%",
                        left: `${(i * 14 + 7) % 88}%`,
                        fontSize: `${8 + (i % 3) * 3}px`,
                        opacity: 0.5 + (i % 3) * 0.15,
                        animation: `confettiFall ${2 + i * 0.3}s linear ${i * 0.25}s infinite`,
                        pointerEvents: "none", zIndex: 3,
                      }}>❄️</div>
                    );
                  }
                  return null;
                })}

                {/* Combat arena: player left, enemy right, same row */}
                <div style={{
                  position: "relative",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  minHeight: "140px",
                  padding: "8px 4px",
                }}>
                  {/* Player (left) */}
                  <div style={{ position: "relative", width: "42%" }}>
                    <div style={{
                      width: "100%",
                      transform: getAttackTransform(true),
                      transition: "transform 0.38s cubic-bezier(0.34, 1.56, 0.64, 1)",
                      filter: getAttackFilter(true),
                      animation: victoryAnim ? "victoryDance 1s ease-in-out 2" : "none",
                    }}>
                      <DinoArt build={build} crying={attackAnim?.who === "player" && attackAnim?.type === "attack"} pattern={pattern} />
                    </div>
                    {floatingDmg?.who === "player" && (
                      <div style={{
                        position: "absolute",
                        top: "10%", left: "30%",
                        fontSize: floatingDmg.crit ? "28px" : "20px",
                        fontWeight: 900,
                        color: floatingDmg.crit ? "#f0b830" : "#ff5050",
                        textShadow: "2px 2px 0 #0a0e08",
                        animation: "floatUp 1s ease-out forwards",
                        pointerEvents: "none",
                        zIndex: 10,
                      }}>
                        -{floatingDmg.value}{floatingDmg.crit && "!"}
                      </div>
                    )}
                  </div>

                  {/* VS marker (optional, subtle) */}
                  <div style={{
                    fontSize: "14px",
                    opacity: 0.85,
                    letterSpacing: "2px",
                    alignSelf: "center",
                  }}>⚔</div>

                  {/* Enemy (right, flipped) */}
                  <div style={{ position: "relative", width: "42%" }}>
                    <div style={{
                      width: "100%",
                      transform: `scaleX(-1) ${getAttackTransform(false)}`,
                      transition: "transform 0.38s cubic-bezier(0.34, 1.56, 0.64, 1)",
                      filter: getAttackFilter(false),
                    }}>
                      <DinoArt build={enemy.build} crying={attackAnim?.who === "enemy" && attackAnim?.type === "attack"} />
                    </div>
                    {floatingDmg?.who === "enemy" && (
                      <div style={{
                        position: "absolute",
                        top: "10%", right: "30%",
                        fontSize: floatingDmg.crit ? "28px" : "20px",
                        fontWeight: 900,
                        color: floatingDmg.crit ? "#f0b830" : "#ff5050",
                        textShadow: "2px 2px 0 #0a0e08",
                        animation: "floatUp 1s ease-out forwards",
                        pointerEvents: "none",
                        zIndex: 10,
                      }}>
                        -{floatingDmg.value}{floatingDmg.crit && "!"}
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* HP bars side-by-side */}
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "8px", marginBottom: "8px" }}>
                {/* Player HP */}
                <div style={{ background: "linear-gradient(135deg, rgba(56,200,120,0.15) 0%, rgba(26,74,42,0.25) 100%)", border: "1px solid #e8a020", borderRadius: "6px", padding: "8px", boxShadow: "inset 0 1px 0 rgba(104,245,168,0.15), 0 2px 6px rgba(56,200,120,0.15)" }}>
                  <div style={{ fontSize: "10px", fontWeight: 700, lineHeight: 1, marginBottom: "2px" }}>
                    {name} <span style={{ opacity: 0.75 }}>Niv{level}</span> <span title={getBuildType(build)}>{TYPE_EMOJI[getBuildType(build)]}</span>
                  </div>
                  <div style={{ fontSize: "9px", opacity: 0.85 }}>{battleState.playerHP}/{battleState.playerMaxHP} PV</div>
                  <div style={{ height: "8px", background: "#0a1a0a", border: "1px solid #e8a020", marginTop: "3px", borderRadius: "4px", overflow: "hidden", boxShadow: "inset 0 1px 2px rgba(0,0,0,0.6)" }}>
                    <div style={{
                      width: `${(battleState.playerHP / battleState.playerMaxHP) * 100}%`,
                      height: "100%",
                      background: hpBarColor((battleState.playerHP / battleState.playerMaxHP) * 100),
                      boxShadow: `${hpBarShadow((battleState.playerHP / battleState.playerMaxHP) * 100)}, inset 0 1px 0 rgba(255,255,255,0.3)`,
                      animation: (battleState.playerHP / battleState.playerMaxHP) < 0.25 ? "pulse 0.8s ease-in-out infinite" : "none",
                      transition: "width 0.5s ease-out",
                    }} />
                  </div>
                  {playerStatus && (
                    <div style={{ fontSize: "8px", marginTop: "3px", color: STATUS_EFFECTS[playerStatus.type].color }}>
                      {STATUS_EFFECTS[playerStatus.type].emoji} {STATUS_EFFECTS[playerStatus.type].label} ({playerStatus.turnsLeft})
                    </div>
                  )}
                  {playerBoostTurns > 0 && (
                    <div style={{ fontSize: "8px", marginTop: "2px", color: "#f8c840" }}>
                      🍇 Boost ({playerBoostTurns})
                    </div>
                  )}
                  {defending && (
                    <div style={{ fontSize: "8px", marginTop: "2px", color: "#68a8f5" }}>
                      🛡️ Défense active
                    </div>
                  )}
                  {trait === "fureur" && battleState.playerHP / battleState.playerMaxHP < 0.3 && battleState.playerHP > 0 && (
                    <div style={{ fontSize: "8px", marginTop: "2px", color: "#f58868" }}>
                      😤 FUREUR
                    </div>
                  )}
                </div>

                {/* Enemy HP */}
                <div style={{ background: "linear-gradient(135deg, rgba(200,56,56,0.15) 0%, rgba(74,26,26,0.25) 100%)", border: "1px solid #cc2020", borderRadius: "6px", padding: "8px", boxShadow: "inset 0 1px 0 rgba(245,136,104,0.15), 0 2px 6px rgba(200,56,56,0.15)" }}>
                  <div style={{ fontSize: "10px", fontWeight: 700, lineHeight: 1, marginBottom: "2px" }}>
                    {enemy.name.length > 16 ? enemy.name.slice(0, 16) + "…" : enemy.name}
                    {enemy.tier && <span style={{ opacity: 0.75 }}> Niv{enemy.level}</span>}
                    <span title={getBuildType(enemy.build)}> {TYPE_EMOJI[getBuildType(enemy.build)]}</span>
                    {(() => {
                      const m = getTypeMult(getBuildType(build), getBuildType(enemy.build));
                      if (m > 1) return <span style={{ color: "#f8c840", fontSize: "9px" }}> ×{m}</span>;
                      if (m < 1) return <span style={{ color: "#f58868", fontSize: "9px" }}> ×{m}</span>;
                      return null;
                    })()}
                  </div>
                  <div style={{ fontSize: "9px", opacity: 0.85, display: "flex", justifyContent: "space-between" }}>
                    <span>{battleState.enemyHP}/{battleState.enemyMaxHP} PV</span>
                    <span style={{ color: "#f5c838" }}>⭐ +{Math.round(20 + (enemy.stats.attaque + enemy.stats.defense) * 1.5 + (enemy.tier ? enemy.tier.powerMult * 15 : 0))} XP</span>
                  </div>
                  <div style={{ height: "8px", background: "#1a0a0a", border: "1px solid #cc2020", marginTop: "3px", borderRadius: "4px", overflow: "hidden", boxShadow: "inset 0 1px 2px rgba(0,0,0,0.6)" }}>
                    <div style={{
                      width: `${(battleState.enemyHP / battleState.enemyMaxHP) * 100}%`,
                      height: "100%",
                      background: hpBarColor((battleState.enemyHP / battleState.enemyMaxHP) * 100),
                      boxShadow: `${hpBarShadow((battleState.enemyHP / battleState.enemyMaxHP) * 100)}, inset 0 1px 0 rgba(255,255,255,0.3)`,
                      transition: "width 0.5s ease-out",
                    }} />
                  </div>
                  {enemyStatus && (
                    <div style={{ fontSize: "8px", marginTop: "3px", color: STATUS_EFFECTS[enemyStatus.type].color }}>
                      {STATUS_EFFECTS[enemyStatus.type].emoji} {STATUS_EFFECTS[enemyStatus.type].label} ({enemyStatus.turnsLeft})
                    </div>
                  )}
                </div>
              </div>
              </div>

              {/* Stat comparison */}
              <div style={{
                display: "grid",
                gridTemplateColumns: "1fr auto 1fr",
                gap: "2px",
                marginBottom: "6px",
                padding: "6px",
                background: "rgba(0,0,0,0.25)",
                border: "1px solid #2a2820",
                borderRadius: "6px",
                fontSize: "9px",
              }}>
                <div style={{ textAlign: "center", fontWeight: 700, opacity: 0.75 }}>Toi</div>
                <div style={{ textAlign: "center", opacity: 0.85 }}>VS</div>
                <div style={{ textAlign: "center", fontWeight: 700, opacity: 0.75 }}>Ennemi</div>
                {["attaque", "defense", "vitesse", "force", "intel"].map(k => {
                  const pv = playerStatsLeveled[k] || 0;
                  const ev = enemy.stats[k] || 0;
                  const better = pv > ev + 0.5;
                  const worse = ev > pv + 0.5;
                  return [
                    <div key={`p-${k}`} style={{ textAlign: "center", color: better ? "#f8c840" : worse ? "#ff8888" : "#f0ece0", fontWeight: better ? 700 : 400 }}>
                      {pv.toFixed(1)}
                    </div>,
                    <div key={`l-${k}`} style={{ textAlign: "center", opacity: 0.85, textTransform: "uppercase", letterSpacing: "1px" }}>
                      {k === "intel" ? "INT" : k.slice(0, 3)}
                    </div>,
                    <div key={`e-${k}`} style={{ textAlign: "center", color: worse ? "#f8c840" : better ? "#ff8888" : "#f0ece0", fontWeight: worse ? 700 : 400 }}>
                      {ev.toFixed(1)}
                    </div>,
                  ];
                })}
              </div>

              {/* Combat log */}
              <div ref={logRef} style={{
                background: "rgba(0,0,0,0.4)",
                border: "1px solid #2a2820",
                borderRadius: "6px",
                padding: "6px 8px",
                marginBottom: "10px",
                maxHeight: "85px",
                overflowY: "auto",
                fontSize: "10px",
                lineHeight: 1.4,
                scrollBehavior: "smooth",
              }}>
                {battleState.log.map((entry, i, arr) => (
                  <div key={i} style={{ marginBottom: "2px", opacity: i === arr.length - 1 ? 1 : i >= arr.length - 3 ? 0.7 : 0.4 }}>
                    {entry}
                  </div>
                ))}
              </div>

              {/* Action buttons */}
              {!battleState.finished ? (
                <div>
                  {/* Defense + Items */}
                  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr 1fr", gap: "4px", marginBottom: "6px" }}>
                    <button
                      onClick={() => {
                        if (battleState.turn !== "player" || attackAnim || battleState.finished) return;
                        setDefending(true);
                        setLastAttackKey(null);
                        const healAmt = Math.round(battleState.playerMaxHP * 0.15);
                        const newHP = Math.min(battleState.playerMaxHP, battleState.playerHP + healAmt);
                        setBattleState({ ...battleState, playerHP: newHP, log: [...battleState.log, `🛡️ Posture défensive ! -70% dégâts + contre-attaque ! (+${healAmt} PV)`], turn: "enemy" });
                        setTimeout(() => doEnemyTurn(battleState.playerHP, battleState.enemyHP), 600);
                      }}
                      disabled={battleState.turn !== "player" || attackAnim !== null}
                      style={{
                        padding: "6px 2px",
                        background: "rgba(56,120,200,0.2)",
                        color: "#f0ece0",
                        border: "1px solid #5878a0",
                        fontFamily: "system-ui, -apple-system, sans-serif",
                        fontSize: "9px",
                        letterSpacing: "1px",
                        cursor: battleState.turn === "player" && !attackAnim ? "pointer" : "not-allowed",
                        textTransform: "uppercase",
                        opacity: battleState.turn !== "player" || attackAnim ? 0.5 : 1,
                      }}
                    >
                      <div style={{ fontSize: "14px" }}>🛡️</div>
                      <div style={{ lineHeight: 1.1 }}>Défense</div>
                    </button>
                    {["heal", "antidote", "boost"].map(itemKey => {
                      const item = ITEMS[itemKey];
                      const count = inventory[itemKey] || 0;
                      const disabled = count <= 0 || battleState.turn !== "player" || attackAnim !== null;
                      return (
                        <button
                          key={itemKey}
                          onClick={() => {
                            if (disabled) return;
                            setInventory({ ...inventory, [itemKey]: count - 1 });
                            let newLog = [...battleState.log];
                            let newPlayerHP = battleState.playerHP;
                            if (itemKey === "heal") {
                              const healAmt = Math.round(battleState.playerMaxHP * 0.4);
                              newPlayerHP = Math.min(battleState.playerMaxHP, battleState.playerHP + healAmt);
                              newLog.push(`🌿 Tu manges une Fougère Curative (+${healAmt} PV)`);
                            } else if (itemKey === "antidote") {
                              setPlayerStatus(null);
                              newLog.push(`💧 Tu bois une Sève Purifiante, les effets se dissipent !`);
                            } else if (itemKey === "boost") {
                              setPlayerBoostTurns(2);
                              newLog.push(`🍇 Tu croques une Baie Féroce, dégâts boostés pendant 2 tours !`);
                            }
                            setLastAttackKey(null);
                            setBattleState({ ...battleState, playerHP: newPlayerHP, log: newLog, turn: "enemy" });
                            setTimeout(() => doEnemyTurn(newPlayerHP, battleState.enemyHP), 600);
                          }}
                          disabled={disabled}
                          style={{
                            padding: "6px 2px",
                            background: "rgba(120,200,56,0.15)",
                            color: "#f0ece0",
                            border: "1px solid #78c838",
                            fontFamily: "system-ui, -apple-system, sans-serif",
                            fontSize: "9px",
                            letterSpacing: "1px",
                            cursor: disabled ? "not-allowed" : "pointer",
                            textTransform: "uppercase",
                            opacity: disabled ? 0.4 : 1,
                            position: "relative",
                          }}
                        >
                          <div style={{ fontSize: "16px" }}>{item.emoji}</div>
                          <div style={{ lineHeight: 1.1, fontSize: "7px", marginTop: "1px" }}>{item.name.split(" ")[0]}</div>
                          <div style={{ lineHeight: 1, fontSize: "8px", fontWeight: 700, color: count > 0 ? "#f8c840" : "#ff8888" }}>{count}/5</div>
                        </button>
                      );
                    })}
                  </div>

                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "4px" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                      <div style={{ fontSize: "9px", letterSpacing: "2px", opacity: 0.75 }}>
                        ── ATTAQUES ──
                      </div>
                      <button
                        onClick={() => setShowTypeChart(true)}
                        style={{
                          width: "18px", height: "18px",
                          background: "rgba(196,168,56,0.2)",
                          border: "1px solid #e8a020",
                          borderRadius: "50%",
                          color: "#e8a020",
                          fontSize: "10px",
                          fontWeight: 900,
                          cursor: "pointer",
                          display: "flex", alignItems: "center", justifyContent: "center",
                          padding: 0,
                        }}
                      >?</button>
                    </div>
                    <div style={{
                      fontSize: "9px", padding: "1px 6px",
                      background: `${careMood.color}20`,
                      border: `1px solid ${careMood.color}50`,
                      borderRadius: "8px",
                      color: careMood.color,
                    }}>
                      {careMood.emoji} {careMood.label}
                    </div>
                  </div>
                  <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "5px" }}>
                    {availableAttacks.map(at => {
                      const cd = playerCooldowns[at.key] || 0;
                      const usesLeft = playerUsesLeft[at.key] !== undefined ? playerUsesLeft[at.key] : getMaxUses(at, playerStatsLeveled, trait);
                      const maxUses = getMaxUses(at, playerStatsLeveled, trait);
                      const onCooldown = cd > 0;
                      const exhausted = usesLeft <= 0;
                      const careBlocked = at.special && !careBonus.canSpecial;
                      const isDisabled = battleState.turn !== "player" || attackAnim !== null || onCooldown || exhausted || careBlocked;
                      // Estimate damage for this attack
                      const useAvg = at.uses.reduce((s, k) => s + (playerStatsLeveled[k] || 0), 0) / at.uses.length;
                      const pType = getBuildType(build);
                      const eType = getBuildType(enemy.build);
                      const typeMult = getTypeMult(pType, eType);
                      const weatherMult = weather.boosts?.[pType] || 1;
                      const estDmg = Math.max(2, Math.round(useAvg * 2.1 * (at.basePower || 1) * typeMult * weatherMult - (enemy.stats.defense || 5) * 0.55));
                      const effLabel = typeMult > 1 ? "Super efficace" : typeMult < 1 ? "Peu efficace" : null;
                      const effColor = typeMult > 1 ? "#f8c840" : typeMult < 1 ? "#ff8888" : null;
                      return (
                      <button
                        key={at.key}
                        onClick={() => playerAttack(at)}
                        disabled={isDisabled}
                        style={{
                          padding: "8px 6px",
                          background: exhausted
                            ? "linear-gradient(135deg, rgba(60,30,30,0.25) 0%, rgba(30,15,15,0.3) 100%)"
                            : onCooldown
                              ? "linear-gradient(135deg, rgba(80,80,80,0.15) 0%, rgba(40,40,40,0.25) 100%)"
                              : at.special
                                ? "linear-gradient(135deg, rgba(168,56,200,0.35) 0%, rgba(74,26,90,0.4) 100%)"
                                : "linear-gradient(135deg, rgba(245,236,210,0.12) 0%, rgba(60,90,70,0.2) 100%)",
                          color: "#f0ece0",
                          border: exhausted ? "1px dashed #5a3030" : onCooldown ? "1px solid #5a5a5a" : at.special ? "1px solid #c858e0" : "1px solid #e8a020",
                          borderRadius: "8px",
                          fontFamily: "system-ui, -apple-system, sans-serif",
                          fontSize: "10px",
                          letterSpacing: "1px",
                          cursor: isDisabled ? "not-allowed" : "pointer",
                          textTransform: "uppercase",
                          opacity: exhausted ? 0.35 : onCooldown ? 0.4 : (attackAnim !== null || battleState.turn !== "player" ? 0.5 : 1),
                          position: "relative",
                          boxShadow: !isDisabled && at.special
                            ? "0 0 10px rgba(200,88,224,0.3), inset 0 1px 0 rgba(255,248,230,0.12)"
                            : !isDisabled
                              ? "0 2px 4px rgba(0,0,0,0.35), inset 0 1px 0 rgba(245,236,210,0.1)"
                              : "none",
                        }}
                      >
                        <div style={{ fontSize: "16px", marginBottom: "1px" }}>{at.emoji}</div>
                        <div style={{ lineHeight: 1.1, fontSize: "10px" }}>{at.label}</div>
                        {/* Estimated damage + effectiveness */}
                        <div style={{ fontSize: "8px", marginTop: "2px", display: "flex", justifyContent: "center", gap: "4px", alignItems: "center" }}>
                          <span style={{ opacity: 0.85 }}>~{estDmg} dmg</span>
                          {effLabel && <span style={{ color: effColor, fontWeight: 700, fontSize: "7px" }}>{effLabel}</span>}
                        </div>
                        <div style={{ fontSize: "8px", opacity: 0.85, marginTop: "1px", color: usesLeft <= 1 ? "#ff8888" : "#f0ece0" }}>
                          {usesLeft}/{maxUses} {at.special && `· ⏱${at.cooldown}`}
                        </div>
                        {onCooldown && (
                          <div style={{
                            position: "absolute",
                            top: "50%", left: "50%",
                            transform: "translate(-50%, -50%)",
                            fontSize: "22px",
                            fontWeight: 900,
                            color: "#f0ece0",
                            textShadow: "1px 1px 0 #0a0e08",
                            pointerEvents: "none",
                          }}>
                            ⏱ {cd}
                          </div>
                        )}
                        {exhausted && !onCooldown && (
                          <div style={{
                            position: "absolute",
                            top: "50%", left: "50%",
                            transform: "translate(-50%, -50%)",
                            fontSize: "20px",
                            color: "#ff5050",
                            textShadow: "1px 1px 0 #0a0e08",
                            pointerEvents: "none",
                            fontWeight: 900,
                          }}>
                            ✕
                          </div>
                        )}
                      </button>
                      );
                    })}
                  </div>

                  {/* Dernier Souffle - ultimate attack when HP < 10% */}
                  {!battleState.finished && battleState.playerHP > 0 &&
                    battleState.playerHP / battleState.playerMaxHP < 0.1 &&
                    !lastBreathAvailable && battleState.turn === "player" && (
                    (() => { setLastBreathAvailable(true); return null; })()
                  )}
                  {lastBreathAvailable && !battleState.finished && battleState.turn === "player" && (
                    <button
                      onClick={() => {
                        setLastBreathAvailable(false);
                        playSfx("lastbreath");
                        try { playRoar(DINOS[build.head]?.family || "tyrant"); } catch(e) {}
                        vibrate([100, 50, 200]);
                        const dmg = Math.round(playerStatsLeveled.attaque * 4 + playerStatsLeveled.force * 3);
                        const newEHP = Math.max(0, battleState.enemyHP - dmg);
                        setAttackAnim({ who: "player", type: "attack", attackKey: "charge", special: true });
                        setScreenFlash("white");
                        setTimeout(() => setScreenFlash(null), 200);
                        setScreenShake(true);
                        setTimeout(() => setScreenShake(false), 400);
                        setTimeout(() => {
                          setFloatingDmg({ who: "enemy", value: dmg, crit: true });
                          setTimeout(() => setFloatingDmg(null), 1000);
                          setAttackAnim(null);
                          const log = [...battleState.log, `🔥💀 DERNIER SOUFFLE ! -${dmg} PV !!!`];
                          if (newEHP <= 0) {
                            finishBattle("player", log, 0, battleState.playerHP);
                          } else {
                            setBattleState({ ...battleState, enemyHP: newEHP, log, turn: "enemy" });
                            setTimeout(() => doEnemyTurn(battleState.playerHP, newEHP), 800);
                          }
                        }, 500);
                      }}
                      style={{
                        marginTop: "6px", width: "100%", padding: "12px",
                        background: "linear-gradient(135deg, #e82020 0%, #a00000 50%, #600000 100%)",
                        color: "#f8c840",
                        border: "2px solid #ff4040",
                        borderRadius: "10px",
                        fontFamily: "system-ui, -apple-system, sans-serif",
                        fontSize: "13px",
                        fontWeight: 900,
                        letterSpacing: "3px",
                        cursor: "pointer",
                        textTransform: "uppercase",
                        animation: "pulse 0.6s ease-in-out infinite",
                        boxShadow: "0 0 20px rgba(232,32,32,0.5), inset 0 1px 0 rgba(255,255,255,0.2)",
                        textShadow: "0 2px 4px rgba(0,0,0,0.6)",
                      }}
                    >
                      🔥💀 DERNIER SOUFFLE 💀🔥
                    </button>
                  )}

                  {!confirmFlee ? (
                    <button
                      onClick={() => setConfirmFlee(true)}
                      style={{
                        marginTop: "8px",
                        width: "100%",
                        padding: "8px",
                        background: "transparent",
                        color: "#c89858",
                        border: "1px dashed #2a2820",
                        fontFamily: "system-ui, -apple-system, sans-serif",
                        fontSize: "10px",
                        letterSpacing: "2px",
                        cursor: "pointer",
                        textTransform: "uppercase",
                      }}
                    >
                      🏃 {tournament ? "Abandonner le tournoi" : "Fuir le combat"}
                    </button>
                  ) : (
                    <div style={{
                      marginTop: "8px",
                      padding: "10px",
                      background: "rgba(200,56,56,0.15)",
                      border: "1px solid #cc2020",
                      textAlign: "center",
                    }}>
                      <div style={{ fontSize: "11px", marginBottom: "8px" }}>
                        {tournament ? "Abandonner le tournoi ?" : "Vraiment fuir ?"}
                      </div>
                      <div style={{ display: "flex", gap: "6px" }}>
                        <button
                          onClick={() => {
                            setEnemy(null);
                            setTournament(null);
                            setPlayerStatus(null);
                            setEnemyStatus(null);
                            setPlayerCooldowns({});
                            setEnemyCooldowns({});
                            setConfirmFlee(false);
                            setView("build");
                          }}
                          style={{
                            flex: 1,
                            padding: "8px",
                            background: "#cc2020",
                            color: "#f0ece0",
                            border: "1px solid #cc2020",
                            fontFamily: "system-ui, -apple-system, sans-serif",
                            fontSize: "10px",
                            letterSpacing: "2px",
                            cursor: "pointer",
                            textTransform: "uppercase",
                          }}
                        >
                          Oui, fuir
                        </button>
                        <button
                          onClick={() => setConfirmFlee(false)}
                          style={{
                            flex: 1,
                            padding: "8px",
                            background: "transparent",
                            color: "#f0ece0",
                            border: "1px solid #2a2820",
                            fontFamily: "system-ui, -apple-system, sans-serif",
                            fontSize: "10px",
                            letterSpacing: "2px",
                            cursor: "pointer",
                            textTransform: "uppercase",
                          }}
                        >
                          Annuler
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                  {battleState.winner === "player" ? (
                    <div style={{
                      textAlign: "center",
                      padding: "16px",
                      background: "linear-gradient(135deg, rgba(56,200,120,0.2) 0%, rgba(196,168,56,0.15) 100%)",
                      border: "2px solid #e8a020",
                      borderRadius: "10px",
                      boxShadow: "0 0 20px rgba(56,200,120,0.3)",
                      animation: "fadeIn 0.5s ease-out",
                      position: "relative",
                      overflow: "hidden",
                    }}>
                      {/* Confetti particles */}
                      {Array.from({ length: 12 }).map((_, i) => (
                        <div key={i} style={{
                          position: "absolute",
                          top: "-5px",
                          left: `${8 + i * 8}%`,
                          width: `${4 + (i % 3) * 2}px`,
                          height: `${4 + (i % 3) * 2}px`,
                          background: ["#f0b830", "#f8c840", "#c888e8", "#58b8e8", "#e87830", "#f0ece0"][i % 6],
                          borderRadius: i % 2 === 0 ? "50%" : "1px",
                          animation: `confettiFall ${1.5 + (i % 4) * 0.3}s ease-in ${i * 0.1}s forwards`,
                          opacity: 0.9,
                          zIndex: 1,
                        }} />
                      ))}
                      <div style={{ fontSize: "36px", marginBottom: "4px", animation: "pulse 1.5s ease-in-out infinite", position: "relative", zIndex: 2 }}>🏆</div>
                      <div style={{ fontSize: "16px", fontWeight: 900, letterSpacing: "3px", color: "#f8c840", position: "relative", zIndex: 2 }}>VICTOIRE</div>
                      <div style={{ fontSize: "12px", color: "#e8a020", marginTop: "4px", position: "relative", zIndex: 2 }}>+{battleState.xpGain || 0} XP</div>
                      {/* XP bar mini */}
                      <div style={{ marginTop: "8px", position: "relative", zIndex: 2 }}>
                        <div style={{ height: "6px", background: "#1a2818", borderRadius: "3px", overflow: "hidden", border: "1px solid #2a2820" }}>
                          <div style={{
                            width: `${Math.min(100, ((xp + (battleState.xpGain || 0)) / (level * 50)) * 100)}%`,
                            height: "100%",
                            background: "linear-gradient(90deg, #e8a020, #f0b830)",
                            transition: "width 1s ease-out",
                          }} />
                        </div>
                        <div style={{ fontSize: "8px", opacity: 0.75, marginTop: "2px" }}>
                          {xp + (battleState.xpGain || 0)}/{level * 50} XP
                        </div>
                      </div>
                    </div>
                  ) : (
                    <div style={{
                      textAlign: "center",
                      padding: "16px",
                      background: "linear-gradient(135deg, rgba(200,56,56,0.15) 0%, rgba(60,20,20,0.3) 100%)",
                      border: "2px solid #cc2020",
                      borderRadius: "10px",
                      animation: "fadeIn 0.5s ease-out",
                    }}>
                      <div style={{ fontSize: "36px", marginBottom: "4px", filter: "grayscale(0.5)" }}>💀</div>
                      <div style={{ fontSize: "16px", fontWeight: 900, letterSpacing: "3px", color: "#ff8888" }}>DÉFAITE</div>
                      <div style={{ fontSize: "11px", opacity: 0.8, marginTop: "8px", lineHeight: 1.4, fontStyle: "italic" }}>
                        {(() => {
                          // Tactical tip based on why you lost
                          const pType = getBuildType(build);
                          const eType = getBuildType(enemy.build);
                          const mult = getTypeMult(pType, eType);
                          if (mult < 1) return `💡 Ton type ${TYPE_EMOJI[pType]} ${pType} est faible contre ${TYPE_EMOJI[eType]} ${eType}. Essaie un dino de type ${Object.entries(TYPE_CHART[eType] || {}).find(([,v]) => v < 1)?.[0] || "différent"}.`;
                          if (playerStatsLeveled.defense < enemy.stats.attaque) return "💡 Ton adversaire était plus puissant. Monte de niveau ou équipe-toi mieux.";
                          if (playerStatsLeveled.vitesse < enemy.stats.vitesse) return "💡 L'adversaire était plus rapide. Un dino plus véloce esquiverait mieux.";
                          return "💡 Utilise des objets et la défense au bon moment. Chaque détail compte.";
                        })()}
                      </div>
                    </div>
                  )}

                  {/* Capture offer */}
                  {captureOffer && battleState.winner === "player" && (() => {
                    // Compute stat diff
                    const newBuild = { ...build, [captureOffer.partKey]: captureOffer.dinoIdx };
                    const newStats = computeStats(newBuild);
                    const oldStats = stats;
                    const diffs = {};
                    Object.keys(oldStats).forEach(k => {
                      diffs[k] = Math.round((newStats[k] - oldStats[k]) * 10) / 10;
                    });
                    const hasPositive = Object.values(diffs).some(d => d > 0);
                    const hasNegative = Object.values(diffs).some(d => d < 0);
                    return (
                    <div style={{
                      padding: "10px",
                      background: "linear-gradient(135deg, rgba(150,88,200,0.2) 0%, rgba(74,26,90,0.25) 100%)",
                      border: "1px solid #9050d0",
                      borderRadius: "8px",
                    }}>
                      <div style={{ fontSize: "11px", fontWeight: 700, marginBottom: "4px", color: "#c888e8" }}>
                        🧬 Capture disponible !
                      </div>
                      <div style={{ fontSize: "10px", marginBottom: "6px", lineHeight: 1.3 }}>
                        Greffer la <strong>{PARTS.find(p => p.key === captureOffer.partKey)?.label}</strong> de <strong>{captureOffer.dinoName}</strong> ?
                        {DINOS[captureOffer.dinoIdx]?.exclusive && (
                          <span style={{ display: "inline-block", marginLeft: "4px", padding: "1px 5px", background: "#e8a020", color: "#1a0f08", borderRadius: "4px", fontSize: "8px", fontWeight: 900 }}>
                            ★ EXCLUSIF
                          </span>
                        )}
                      </div>
                      {/* Stat diff */}
                      <div style={{
                        display: "flex", flexWrap: "wrap", gap: "4px", marginBottom: "8px",
                        padding: "6px", background: "rgba(0,0,0,0.2)", borderRadius: "4px",
                      }}>
                        {Object.entries(diffs).filter(([, d]) => d !== 0).map(([k, d]) => (
                          <span key={k} style={{
                            fontSize: "10px", fontWeight: 700,
                            color: d > 0 ? "#f8c840" : "#ff8888",
                            padding: "1px 4px",
                            background: d > 0 ? "rgba(56,200,120,0.15)" : "rgba(200,56,56,0.15)",
                            borderRadius: "4px",
                          }}>
                            {d > 0 ? "+" : ""}{d} {k === "intel" ? "INT" : k.slice(0, 3).toUpperCase()}
                          </span>
                        ))}
                        {Object.values(diffs).every(d => d === 0) && (
                          <span style={{ fontSize: "9px", opacity: 0.75 }}>Aucun changement</span>
                        )}
                      </div>
                      <div style={{ display: "flex", gap: "6px" }}>
                        <button
                          onClick={() => {
                            const partLabel = PARTS.find(p => p.key === captureOffer.partKey)?.label || "";
                            const dName = captureOffer.dinoName;
                            const isExcl = DINOS[captureOffer.dinoIdx]?.exclusive;
                            // Start cinematic
                            setCaptureAnim({ phase: "freeze", partKey: captureOffer.partKey, dinoName: dName, exclusive: isExcl });
                            playSfx("crit");
                            vibrate([50, 30, 50, 30, 100]);
                            setTimeout(() => setCaptureAnim(prev => prev ? { ...prev, phase: "dna" } : null), 800);
                            setTimeout(() => setCaptureAnim(prev => prev ? { ...prev, phase: "merge" } : null), 2200);
                            setTimeout(() => {
                              setCaptureAnim(prev => prev ? { ...prev, phase: "reveal" } : null);
                              playSfx("victory");
                            }, 3200);
                            setTimeout(() => {
                              setBuild(newBuild);
                              setCaptureOffer(null);
                              setCaptureAnim(null);
                            }, 4500);
                          }}
                          style={{
                            flex: 1, padding: "8px",
                            background: "linear-gradient(135deg, #9050d0 0%, #6a2a8a 100%)",
                            color: "#f0ece0", border: "1px solid #c888e8", borderRadius: "6px",
                            fontFamily: "system-ui, -apple-system, sans-serif", fontSize: "10px", cursor: "pointer",
                            fontWeight: 700, letterSpacing: "1px",
                          }}
                        >
                          ✓ Capturer
                        </button>
                        <button
                          onClick={() => setCaptureOffer(null)}
                          style={{
                            flex: 1, padding: "8px",
                            background: "transparent",
                            color: "#f0ece0", border: "1px solid #2a2820", borderRadius: "6px",
                            fontFamily: "system-ui, -apple-system, sans-serif", fontSize: "10px", cursor: "pointer",
                          }}
                        >
                          ✕ Refuser
                        </button>
                      </div>
                    </div>
                    );
                  })()}
                  {tournament && battleState.winner === "player" && tournament.tier < TOURNAMENT_TIERS.length && (
                    <button onClick={continueTournament} style={{
                      ...btnPrimary, width: "100%",
                      background: "linear-gradient(135deg, #7a3a8a 0%, #4a1a5a 100%)",
                      borderColor: "#a838c8",
                      color: "#f0ece0",
                    }}>
                      👑 COMBAT SUIVANT — {TOURNAMENT_TIERS[tournament.tier].name}
                    </button>
                  )}

                  {/* Adventure mode: progression buttons */}
                  {battleState.isAdventure && battleState.winner === "player" && !battleState.isBoss && battleState.zoneIdx !== undefined && (() => {
                    const z = ZONES[battleState.zoneIdx];
                    const currentWins = zoneWinsMap[z.key] || 0;
                    const bossReady = currentWins >= z.wins;
                    return (
                      <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                        <div style={{
                          textAlign: "center", fontSize: "11px", padding: "6px",
                          background: "rgba(60,90,70,0.3)", border: "1px solid #2a2820", borderRadius: "6px",
                        }}>
                          {z.emoji} {z.name} — {Math.min(currentWins, z.wins)}/{z.wins} combats
                        </div>
                        {!bossReady ? (
                          <button onClick={() => startZoneBattle(battleState.zoneIdx, false)} style={{
                            ...btnPrimary, width: "100%",
                            background: "linear-gradient(135deg, #5a7a48 0%, #3a5a30 100%)",
                            borderColor: "#8aaa68",
                            color: "#f0ece0",
                          }}>
                            🌿 Combat suivant ({currentWins}/{z.wins})
                          </button>
                        ) : (
                          <button onClick={() => startBossQuiz(battleState.zoneIdx)} style={{
                            ...btnPrimary, width: "100%",
                            background: "linear-gradient(135deg, #dd2828 0%, #8a2020 100%)",
                            borderColor: "#e84040",
                            color: "#f0ece0",
                          }}>
                            👑 Affronter {z.boss} !
                          </button>
                        )}
                      </div>
                    );
                  })()}

                  {/* Adventure boss won: back to adventure */}
                  {battleState.isAdventure && battleState.winner === "player" && battleState.isBoss && (
                    <button onClick={() => { setEnemy(null); setView("adventure"); }} style={{
                      ...btnPrimary, width: "100%",
                      background: "linear-gradient(135deg, #e8a020 0%, #207848 100%)",
                      borderColor: "#f8c840",
                      color: "#f0ece0",
                    }}>
                      🗺️ Zone suivante
                    </button>
                  )}

                  {/* Adventure lost: retry + back to adventure */}
                  {battleState.isAdventure && battleState.winner === "enemy" && (
                    <button onClick={() => { setEnemy(null); setView("adventure"); }} style={{ ...btnSecondary, width: "100%" }}>
                      🗺️ Retour aventure
                    </button>
                  )}

                  {battleState.winner === "enemy" && lastEnemyData && (
                    <button onClick={retryBattle} style={{
                      ...btnPrimary, width: "100%",
                      background: "linear-gradient(135deg, #dd2828 0%, #aa1818 100%)",
                      borderColor: "#e84040",
                      color: "#f0ece0",
                    }}>
                      🔄 Réessayer contre {lastEnemyData.name.length > 16 ? lastEnemyData.name.slice(0, 16) + "…" : lastEnemyData.name}
                    </button>
                  )}

                  {/* Non-adventure buttons */}
                  {!battleState.isAdventure && (
                    <button onClick={() => startBattle()} style={{ ...btnPrimary, width: "100%" }}>
                      ⚔ NOUVEL ADVERSAIRE
                    </button>
                  )}
                  <button onClick={() => { setEnemy(null); setTournament(null); setView("build"); }} style={{ ...btnSecondary, width: "100%" }}>
                    ← Retour atelier
                  </button>
                </div>
              )}
            </div>
          )}
          <style>{`
            @keyframes shake {
              0%, 100% { transform: translateX(0); }
              20% { transform: translateX(-4px); }
              40% { transform: translateX(4px); }
              60% { transform: translateX(-2px); }
              80% { transform: translateX(2px); }
            }
            @keyframes floatUp {
              0% { transform: translateY(0) scale(0.5); opacity: 0; }
              20% { transform: translateY(-10px) scale(1.2); opacity: 1; }
              80% { transform: translateY(-30px) scale(1); opacity: 1; }
              100% { transform: translateY(-50px) scale(0.9); opacity: 0; }
            }
            @keyframes effectPop {
              0% { transform: scale(0.2) rotate(-20deg); opacity: 0; }
              30% { transform: scale(1.4) rotate(10deg); opacity: 1; }
              70% { transform: scale(1.1) rotate(-5deg); opacity: 1; }
              100% { transform: scale(0.9) rotate(0); opacity: 0; }
            }
          `}</style>
        </div>
      )}

      {view === "adventure" && (
        <div className="view-enter" key="adventure" style={{ padding: "12px" }}>
          {/* ISLAND MAP */}
          <div style={{ marginBottom: "12px", borderRadius: "16px", overflow: "hidden", border: "1px solid #2a2820", position: "relative" }}>
            <svg viewBox="0 0 340 400" style={{ width: "100%", display: "block", background: "linear-gradient(180deg, #1a3048 0%, #0a2038 40%, #0a1828 100%)" }}>
              {/* Ocean waves */}
              {[60,120,180,240,300,360].map((y,i) => (
                <path key={`w${i}`} d={`M0 ${y} Q85 ${y-8} 170 ${y} T340 ${y}`} fill="none" stroke="rgba(100,180,220,0.08)" strokeWidth="1">
                  <animate attributeName="d" values={`M0 ${y} Q85 ${y-8} 170 ${y} T340 ${y};M0 ${y} Q85 ${y+8} 170 ${y} T340 ${y};M0 ${y} Q85 ${y-8} 170 ${y} T340 ${y}`} dur={`${4+i*0.5}s`} repeatCount="indefinite" />
                </path>
              ))}
              {/* Island shape */}
              <path d="M80,40 Q150,15 250,45 Q310,65 300,130 Q320,200 280,260 Q300,310 260,350 Q200,390 140,360 Q80,340 50,280 Q20,220 40,160 Q25,100 80,40Z"
                fill="#2a3818" stroke="#3a4828" strokeWidth="2" />
              <path d="M90,50 Q155,28 245,52 Q300,72 292,132 Q312,198 275,255 Q292,305 255,342 Q198,380 145,352 Q88,335 58,278 Q30,220 48,162 Q35,108 90,50Z"
                fill="#354820" stroke="none" />
              {/* Beach edge */}
              <path d="M80,40 Q150,15 250,45 Q310,65 300,130 Q320,200 280,260 Q300,310 260,350 Q200,390 140,360 Q80,340 50,280 Q20,220 40,160 Q25,100 80,40Z"
                fill="none" stroke="#c8b878" strokeWidth="1.5" strokeDasharray="3,4" opacity="0.4" />
              {/* Volcano */}
              <polygon points="220,95 245,60 270,95" fill="#5a3020" stroke="#8a4a30" strokeWidth="1" />
              <ellipse cx="245" cy="62" rx="8" ry="4" fill="#cc2020" opacity="0.6">
                <animate attributeName="opacity" values="0.4;0.8;0.4" dur="2s" repeatCount="indefinite" />
              </ellipse>
              {/* Rivers */}
              <path d="M245,95 Q230,140 200,180 Q180,220 170,270" fill="none" stroke="#2060a0" strokeWidth="2" opacity="0.5" />
              <path d="M200,180 Q160,200 130,190" fill="none" stroke="#2060a0" strokeWidth="1.5" opacity="0.4" />
              {/* Trees scattered */}
              {[[100,80],[130,100],[160,70],[115,150],[85,200],[100,280],[150,310],[200,320],[250,280],[140,240]].map(([x,y],i) => (
                <text key={`tree${i}`} x={x} y={y} fontSize="8" opacity="0.3">🌿</text>
              ))}

              {/* Zone nodes */}
              {(() => {
                const positions = [
                  {x:140,y:70},{x:110,y:120},{x:170,y:150},{x:230,y:110},
                  {x:200,y:190},{x:130,y:200},{x:90,y:260},{x:170,y:280},
                  {x:240,y:250},{x:195,y:340}
                ];
                // Paths between zones
                const paths = [[0,1],[1,2],[2,3],[3,4],[4,5],[5,6],[6,7],[7,8],[8,9]];
                return (
                  <>
                    {/* Paths */}
                    {paths.map(([a,b],i) => {
                      const za = positions[a]; const zb = positions[b];
                      const unlocked = level >= ZONES[b]?.minLevel;
                      return <line key={`path${i}`} x1={za.x} y1={za.y} x2={zb.x} y2={zb.y}
                        stroke={unlocked ? "#e8a020" : "#444"} strokeWidth={unlocked ? 2 : 1}
                        strokeDasharray={unlocked ? "none" : "4,4"} opacity={unlocked ? 0.6 : 0.3} />;
                    })}
                    {/* Zone circles */}
                    {ZONES.map((z, i) => {
                      const p = positions[i];
                      const unlocked = level >= z.minLevel;
                      const completed = achievements[`zone_${z.key}_done`] === true;
                      const current = i === adventureZone;
                      const selected = selectedMapZone === i;
                      const wins = zoneWinsMap[z.key] || 0;
                      return (
                        <g key={z.key} onClick={() => {
                          if (unlocked) setSelectedMapZone(selected ? null : i);
                        }} style={{ cursor: unlocked ? "pointer" : "default" }}>
                          {/* Glow for current zone */}
                          {current && unlocked && !selected && (
                            <circle cx={p.x} cy={p.y} r={18} fill="none" stroke="#e8a020" strokeWidth={1} opacity={0.4}>
                              <animate attributeName="r" values="16;20;16" dur="2s" repeatCount="indefinite" />
                              <animate attributeName="opacity" values="0.2;0.6;0.2" dur="2s" repeatCount="indefinite" />
                            </circle>
                          )}
                          {/* Selection ring */}
                          {selected && (
                            <circle cx={p.x} cy={p.y} r={20} fill="none" stroke="#f8c840" strokeWidth={2} opacity={0.8}>
                              <animate attributeName="r" values="18;22;18" dur="1.5s" repeatCount="indefinite" />
                            </circle>
                          )}
                          {/* Main circle */}
                          <circle cx={p.x} cy={p.y} r={14}
                            fill={completed ? "#2a5a20" : unlocked ? "#3a3020" : "#1a1a1a"}
                            stroke={selected ? "#f8c840" : completed ? "#48a848" : unlocked ? "#8a7040" : "#333"}
                            strokeWidth={selected ? 2.5 : current ? 2 : 1.5} />
                          {/* Zone emoji */}
                          <text x={p.x} y={p.y + 1} textAnchor="middle" dominantBaseline="middle"
                            fontSize="14" opacity={unlocked ? 1 : 0.4}>
                            {unlocked ? z.emoji : "🔒"}
                          </text>
                          {/* Completion checkmark */}
                          {completed && (
                            <>
                              <circle cx={p.x + 10} cy={p.y - 10} r={5} fill="#48a848" stroke="#2a5a20" strokeWidth={1} />
                              <text x={p.x + 10} y={p.y - 8} textAnchor="middle" fontSize="6" fill="#fff" fontWeight={900}>✓</text>
                            </>
                          )}
                          {/* Progress dots for incomplete */}
                          {unlocked && !completed && (
                            <g>
                              {Array.from({ length: z.wins }).map((_, wi) => (
                                <circle key={wi} cx={p.x - (z.wins * 2) + wi * 4 + 2} cy={p.y + 18}
                                  r={1.5} fill={wi < wins ? "#e8a020" : "#4a4030"} />
                              ))}
                            </g>
                          )}
                          {/* Zone name */}
                          <text x={p.x} y={p.y + (unlocked && !completed ? 26 : 24)} textAnchor="middle" fontSize="5.5" fill="#f0ece0"
                            opacity={unlocked ? 0.85 : 0.35} fontWeight={selected || current ? 700 : 400}>
                            {z.name.split(" ")[0]}
                          </text>
                        </g>
                      );
                    })}

                    {/* Player dino on current zone */}
                    {positions[Math.min(adventureZone, 9)] && (
                      <text x={positions[Math.min(adventureZone, 9)].x + 16}
                        y={positions[Math.min(adventureZone, 9)].y - 10}
                        fontSize="16">
                        🦖
                        <animate attributeName="y" values={`${positions[Math.min(adventureZone, 9)].y - 12};${positions[Math.min(adventureZone, 9)].y - 8};${positions[Math.min(adventureZone, 9)].y - 12}`} dur="2s" repeatCount="indefinite" />
                      </text>
                    )}
                  </>
                );
              })()}
              {/* Compass */}
              <text x="300" y="30" fontSize="16" opacity="0.4">🧭</text>
              <text x="295" y="45" fontSize="5" fill="#f0ece0" opacity="0.4">N</text>
            </svg>
          </div>

          {/* Selected zone detail panel */}
          {selectedMapZone !== null && (() => {
            const z = ZONES[selectedMapZone];
            if (!z) return null;
            const completed = achievements[`zone_${z.key}_done`] === true;
            const wins = zoneWinsMap[z.key] || 0;
            const bossReady = wins >= z.wins;
            return (
              <div style={{
                margin: "0 0 12px",
                padding: "14px",
                background: "linear-gradient(135deg, rgba(232,160,32,0.08), rgba(20,24,16,0.95))",
                border: "1px solid #e8a020",
                borderRadius: "14px",
                animation: "fadeIn 0.2s ease-out",
                position: "relative",
              }}>
                {/* Close button */}
                <button onClick={() => setSelectedMapZone(null)} style={{
                  position: "absolute", top: "8px", right: "8px",
                  background: "rgba(0,0,0,0.3)", border: "none", borderRadius: "50%",
                  width: "24px", height: "24px", color: "#f0ece0", fontSize: "12px",
                  cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
                }}>✕</button>

                <div style={{ fontSize: "15px", fontWeight: 900, color: "#e8a020", marginBottom: "2px" }}>
                  {z.emoji} {z.name}
                </div>
                <div style={{ fontSize: "9px", opacity: 0.65, marginBottom: "8px" }}>
                  Niv.{z.minLevel} · Boss : {z.boss}
                </div>

                {/* Progress */}
                <div style={{ display: "flex", alignItems: "center", gap: "6px", marginBottom: "10px" }}>
                  <div style={{ flex: 1, height: "8px", background: "#2a2820", borderRadius: "4px", overflow: "hidden" }}>
                    <div style={{
                      width: `${Math.min(100, (wins / z.wins) * 100)}%`,
                      height: "100%",
                      background: completed ? "#48a848" : bossReady ? "#e8a020" : "linear-gradient(90deg, #8a7040, #e8a020)",
                      borderRadius: "4px",
                    }} />
                  </div>
                  <div style={{ fontSize: "10px", fontWeight: 700, minWidth: "30px" }}>
                    {completed ? "✓" : `${wins}/${z.wins}`}
                  </div>
                </div>

                {/* Big action button */}
                <button
                  onClick={() => {
                    startZoneBattle(selectedMapZone, bossReady && !completed);
                    setSelectedMapZone(null);
                  }}
                  style={{
                    width: "100%", padding: "14px",
                    background: completed
                      ? "linear-gradient(135deg, #48a848, #2a6a28)"
                      : bossReady
                        ? "linear-gradient(135deg, #cc2020, #8a1010)"
                        : "linear-gradient(135deg, #e8a020, #c88818)",
                    color: "#f0ece0",
                    border: "none", borderRadius: "12px",
                    fontSize: "13px", fontWeight: 900, cursor: "pointer",
                    letterSpacing: "2px",
                    boxShadow: "0 4px 12px rgba(0,0,0,0.3)",
                  }}
                >
                  {completed ? "🔄 REJOUER" : bossReady ? `👑 BOSS : ${z.boss.split(" ")[0]}` : `⚔ EXPLORER (${wins}/${z.wins})`}
                </button>
                {bossReady && !completed && (
                  <button
                    onClick={() => generateAiAdvice(z.boss, FAMILY_TYPES[DINOS[z.bossIdx]?.family] || "terre")}
                    style={{
                      padding: "8px", marginTop: "6px", width: "100%",
                      background: "rgba(200,136,232,0.1)", border: "1px solid rgba(200,136,232,0.3)",
                      borderRadius: "8px", color: "#c888e8", fontSize: "10px", cursor: "pointer",
                    }}
                  >
                    🧠 Conseil IA avant le boss
                  </button>
                )}
              </div>
            );
          })()}

          {/* Zone detail list */}
          <div style={{ fontSize: "12px", fontWeight: 700, color: "#e8a020", textAlign: "center", marginBottom: "8px", letterSpacing: "2px" }}>
            ZONES D'EXPÉDITION
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
            {ZONES.map((z, i) => {
              const unlocked = level >= z.minLevel;
              const completed = (achievements[`zone_${z.key}_done`] === true);
              const wins = zoneWinsMap[z.key] || 0;
              const bossReady = wins >= z.wins;
              return (
                <div key={z.key} style={{
                  background: completed
                    ? "linear-gradient(135deg, rgba(56,200,120,0.25) 0%, rgba(30,90,50,0.35) 100%)"
                    : unlocked
                      ? "linear-gradient(135deg, rgba(245,236,210,0.12) 0%, rgba(70,100,80,0.25) 100%)"
                      : "linear-gradient(135deg, rgba(40,30,20,0.6) 0%, rgba(20,15,10,0.7) 100%)",
                  border: `1px solid ${completed ? "#e8a020" : unlocked ? "#3a3828" : "#333"}`,
                  borderRadius: "10px",
                  padding: "12px",
                  opacity: unlocked ? 1 : 0.5,
                  boxShadow: completed
                    ? "0 0 10px rgba(56,200,120,0.2), inset 0 1px 0 rgba(104,245,168,0.15)"
                    : unlocked
                      ? "0 2px 6px rgba(0,0,0,0.35), inset 0 1px 0 rgba(245,236,210,0.1)"
                      : "none",
                }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: "13px", fontWeight: 700 }}>
                        {z.emoji} {z.name} {completed && "✓"}
                      </div>
                      <div style={{ fontSize: "9px", opacity: 0.85, marginTop: "2px" }}>
                        Niv. {z.minLevel} · Boss : {z.boss}
                      </div>
                      {unlocked && !completed && (
                        <div style={{ marginTop: "4px" }}>
                          <div style={{ fontSize: "9px", marginBottom: "2px" }}>
                            Exploration : {Math.min(wins, z.wins)}/{z.wins} {bossReady && "— Boss prêt !"}
                          </div>
                          <div style={{ height: "5px", background: "#1a2818", border: "1px solid #2a2820", borderRadius: "3px", overflow: "hidden" }}>
                            <div style={{
                              width: `${Math.min(100, (wins / z.wins) * 100)}%`,
                              height: "100%",
                              background: bossReady ? "linear-gradient(90deg, #e8a020, #f8c840)" : "linear-gradient(90deg, #5a7a48, #8aaa68)",
                            }} />
                          </div>
                        </div>
                      )}
                    </div>
                    {unlocked && (
                      <div style={{ display: "flex", flexDirection: "column", gap: "4px", marginLeft: "8px" }}>
                        <button
                          onClick={() => startZoneBattle(i, false)}
                          style={{
                            padding: "6px 10px",
                            background: "rgba(245,236,210,0.1)",
                            color: "#f0ece0",
                            border: "1px solid #f0ece0",
                            borderRadius: "6px",
                            fontFamily: "system-ui, -apple-system, sans-serif",
                            fontSize: "9px",
                            letterSpacing: "1px",
                            cursor: "pointer",
                            textTransform: "uppercase",
                          }}
                        >
                          Explorer
                        </button>
                        <button
                          onClick={() => bossReady && startBossQuiz(i)}
                          disabled={!bossReady}
                          style={{
                            padding: "6px 10px",
                            background: bossReady ? "rgba(200,56,56,0.25)" : "rgba(80,80,80,0.15)",
                            color: bossReady ? "#f0ece0" : "#888",
                            border: `1px solid ${bossReady ? "#cc2020" : "#555"}`,
                            borderRadius: "6px",
                            fontFamily: "system-ui, -apple-system, sans-serif",
                            fontSize: "9px",
                            letterSpacing: "1px",
                            cursor: bossReady ? "pointer" : "not-allowed",
                            textTransform: "uppercase",
                            opacity: bossReady ? 1 : 0.5,
                          }}
                        >
                          {bossReady ? "👑 Boss" : `🔒 ${wins}/${z.wins}`}
                        </button>
                      </div>
                    )}
                    {!unlocked && (
                      <div style={{ fontSize: "20px" }}>🔒</div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Foraging zone */}
          <div style={{
            marginTop: "16px",
            padding: "12px",
            background: "linear-gradient(135deg, rgba(120,200,56,0.12) 0%, rgba(60,100,30,0.2) 100%)",
            border: "1px solid #78c838",
            borderRadius: "10px",
            fontSize: "10px",
            textAlign: "center",
            boxShadow: "0 0 12px rgba(120,200,56,0.15), inset 0 1px 0 rgba(180,245,130,0.15)",
          }}>
            <div style={{ marginBottom: "6px", fontWeight: 700, color: "#c8f878", fontSize: "12px", letterSpacing: "1px" }}>🌾 Zone de Cueillette</div>
            <div style={{ fontSize: "9px", opacity: 0.85, marginBottom: "8px", lineHeight: 1.3 }}>
              Cherche des plantes et baies dans la nature.<br/>
              Disponible {3 - (gatheredAtLevel === level ? gatheredThisLevel : 0)}/3 fois au niveau {level}.
            </div>
            <div style={{ fontSize: "11px", marginBottom: "6px" }}>
              Inventaire : 🍖{inventory.food || 0} 🌿{inventory.heal || 0} 💧{inventory.antidote || 0} 🍇{inventory.boost || 0}
            </div>
            <button
              onClick={() => {
                const currentGathered = gatheredAtLevel === level ? gatheredThisLevel : 0;
                if (currentGathered >= 3) return;
                if (gatheredAtLevel !== level) {
                  setGatheredAtLevel(level);
                  setGatheredThisLevel(1);
                } else {
                  setGatheredThisLevel(currentGathered + 1);
                }
                const roll = Math.random();
                const itemKey = roll < 0.35 ? "food" : roll < 0.6 ? "heal" : roll < 0.8 ? "boost" : "antidote";
                setInventory(prev => ({
                  ...prev,
                  [itemKey]: Math.min(5, (prev[itemKey] || 0) + 1),
                }));
                const item = ITEMS[itemKey];
                setLastHatch(`🌾 Tu trouves : +1 ${item.emoji} ${item.name}`);
              }}
              disabled={gatheredAtLevel === level && gatheredThisLevel >= 3}
              style={{
                padding: "8px 14px",
                background: gatheredAtLevel === level && gatheredThisLevel >= 3
                  ? "rgba(120,120,120,0.2)"
                  : "linear-gradient(135deg, #78c838 0%, #4a8a20 100%)",
                color: "#f0ece0",
                border: "1px solid #78c838",
                fontFamily: "system-ui, -apple-system, sans-serif",
                fontSize: "10px",
                letterSpacing: "1px",
                cursor: gatheredAtLevel === level && gatheredThisLevel >= 3 ? "not-allowed" : "pointer",
                textTransform: "uppercase",
                opacity: gatheredAtLevel === level && gatheredThisLevel >= 3 ? 0.5 : 1,
                fontWeight: 700,
              }}
            >
              🌾 Cueillir
            </button>
          </div>

          <div style={{
            marginTop: "16px",
            padding: "10px",
            background: "rgba(245,236,210,0.05)",
            border: "1px solid #2a2820",
            fontSize: "10px",
            textAlign: "center",
          }}>
            <div style={{ marginBottom: "4px" }}>🥚 Œufs collectés : <strong>{eggs}</strong></div>
            <div style={{ opacity: 0.85, fontSize: "9px", marginBottom: "8px" }}>Bats les boss pour collecter des œufs rares</div>
            {lastHatch && (
              <div style={{
                marginBottom: "10px",
                padding: "6px 8px",
                background: "rgba(212,175,55,0.2)",
                border: "1px solid #e8a020",
                fontSize: "9px",
                color: "#f0ece0",
              }}>
                {lastHatch}
              </div>
            )}
            {eggs > 0 && (
              <button
                onClick={() => {
                  if (eggs < 1) return;
                  const rarRoll = Math.random();
                  const rarity = rarRoll < 0.6 ? "common" : rarRoll < 0.9 ? "rare" : "epic";
                  const typeRoll = Math.random();
                  const rewardType = typeRoll < 0.4 ? "color" : typeRoll < 0.75 ? "stat" : "items";
                  setEggs(eggs - 1);
                  // Start hatching animation
                  setEggHatching({ phase: "shake", rarity });
                  setTimeout(() => setEggHatching({ phase: "crack", rarity }), 1200);
                  setTimeout(() => {
                    let rewardText = "";
                    if (rewardType === "color") {
                      const common = ["#e8a020","#c0c0c0","#b0e0e6","#8b4513","#a0522d","#708090","#6b8e23","#cd853f","#b8860b","#2e8b57"];
                      const rareC = ["#ff6347","#9370db","#00ced1","#ff1493","#20b2aa","#da70d6","#ffa500","#7b68ee"];
                      const epicC = ["#ffd700","#e91e63","#00ffff","#00ff88","#ff00ff","#4169e1","#dc143c","#32cd32"];
                      const pool = rarity === "epic" ? epicC : rarity === "rare" ? rareC : common;
                      const avail = pool.filter(c => !unlockedColors.includes(c));
                      if (avail.length > 0) {
                        setUnlockedColors(prev => [...prev, avail[Math.floor(Math.random() * avail.length)]]);
                        rewardText = "🎨 Nouvelle couleur débloquée !";
                      } else {
                        const s = ["attaque","defense","vitesse","force","intel"][Math.floor(Math.random()*5)];
                        const a = rarity === "epic" ? 1.0 : rarity === "rare" ? 0.5 : 0.3;
                        setPermaBonus(prev => ({...prev, [s]: (prev[s]||0)+a}));
                        rewardText = `+${a} ${s} permanent !`;
                      }
                    } else if (rewardType === "stat") {
                      const s = ["attaque","defense","vitesse","force","intel"][Math.floor(Math.random()*5)];
                      const a = rarity === "epic" ? 1.5 : rarity === "rare" ? 0.8 : 0.4;
                      setPermaBonus(prev => ({...prev, [s]: (prev[s]||0)+a}));
                      rewardText = `💪 +${a} ${s} permanent !`;
                    } else {
                      if (rarity === "epic") {
                        setPermaBonus(prev => ({...prev, hp: (prev.hp||0)+15}));
                        setInventory(prev => ({...prev, heal: Math.min(5,(prev.heal||0)+3), boost: Math.min(5,(prev.boost||0)+3)}));
                        rewardText = "❤️ +15 PV + inventaire complet !";
                      } else if (rarity === "rare") {
                        setPermaBonus(prev => ({...prev, hp: (prev.hp||0)+8}));
                        setInventory(prev => ({...prev, heal: Math.min(5,(prev.heal||0)+2), food: Math.min(10,(prev.food||0)+3)}));
                        rewardText = "❤️ +8 PV + objets !";
                      } else {
                        setInventory(prev => ({...prev, heal: Math.min(5,(prev.heal||0)+2), food: Math.min(10,(prev.food||0)+2)}));
                        rewardText = "🎁 +2🌿 +2🍖";
                      }
                    }
                    setLastHatch(rewardText);
                    setEggHatching({ phase: "reveal", rarity, reward: rewardText });
                  }, 2200);
                }}
                style={{
                  padding: "12px 16px",
                  background: "linear-gradient(135deg, #f0b830 0%, #e8a020 50%, #3a3828 100%)",
                  color: "#f0ece0",
                  border: "2px solid #f0b830",
                  borderRadius: "10px",
                  fontFamily: "system-ui, -apple-system, sans-serif",
                  fontSize: "12px",
                  letterSpacing: "2px",
                  cursor: "pointer",
                  textTransform: "uppercase",
                  fontWeight: 900,
                  boxShadow: "0 0 16px rgba(255,216,56,0.5), inset 0 1px 0 rgba(255,255,255,0.4), 0 4px 10px rgba(0,0,0,0.4)",
                  animation: "eggShake 2.2s ease-in-out infinite",
                }}
              >
                🥚 Faire éclore un œuf
              </button>
            )}

            {/* Permanent bonuses display */}
            {(permaBonus.attaque || permaBonus.defense || permaBonus.vitesse || permaBonus.force || permaBonus.intel || permaBonus.hp) ? (
              <div style={{ marginTop: "10px", padding: "6px 8px", background: "rgba(212,175,55,0.1)", border: "1px solid #7a8a3a", fontSize: "9px" }}>
                <div style={{ color: "#e8a020", fontWeight: 700, marginBottom: "3px" }}>💎 Bonus permanents (œufs)</div>
                <div style={{ display: "flex", flexWrap: "wrap", gap: "6px", justifyContent: "center" }}>
                  {permaBonus.hp > 0 && <span>❤️ +{permaBonus.hp} PV</span>}
                  {permaBonus.attaque > 0 && <span>⚔️ +{permaBonus.attaque.toFixed(1)} ATQ</span>}
                  {permaBonus.defense > 0 && <span>🛡️ +{permaBonus.defense.toFixed(1)} DEF</span>}
                  {permaBonus.vitesse > 0 && <span>💨 +{permaBonus.vitesse.toFixed(1)} VIT</span>}
                  {permaBonus.force > 0 && <span>💪 +{permaBonus.force.toFixed(1)} FRC</span>}
                  {permaBonus.intel > 0 && <span>🧠 +{permaBonus.intel.toFixed(1)} INT</span>}
                </div>
              </div>
            ) : null}
            {unlockedColors.length > 0 && (
              <div style={{ marginTop: "10px", fontSize: "9px", opacity: 0.8 }}>
                Couleurs rares débloquées : {unlockedColors.length}
                <div style={{ display: "flex", gap: "3px", justifyContent: "center", marginTop: "4px" }}>
                  {unlockedColors.map((c, i) => (
                    <div key={i} style={{ width: "14px", height: "14px", background: c, border: "1px solid #0a0e08" }} />
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {view === "book" && (
        <div className="view-enter" key="book" style={{ padding: "16px" }}>
          <div style={{ textAlign: "center", marginBottom: "12px" }}>
            <div style={{ fontSize: "14px", letterSpacing: "2px", textTransform: "uppercase" }}>
              📚 Carnet de Paléontologue
            </div>
            <div style={{ fontSize: "10px", opacity: 0.75, marginTop: "4px" }}>
              Succès et fiches des dinosaures réels
            </div>
          </div>

          {/* Achievements */}
          <div style={{ marginBottom: "16px" }}>
            <div style={{ fontSize: "10px", letterSpacing: "2px", opacity: 0.75, marginBottom: "6px" }}>
              ── TROPHÉES ──
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "4px" }}>
              {ACHIEVEMENTS.map(a => {
                const state = { totalWins, level, bestiary, saved, adventureZone, eggs, bossDefeated: achievements.bossDefeated };
                const unlocked = a.check(state);
                return (
                  <div key={a.key} style={{
                    padding: "8px 10px",
                    background: unlocked
                      ? "linear-gradient(135deg, rgba(245,200,56,0.2) 0%, rgba(140,100,20,0.15) 100%)"
                      : "rgba(0,0,0,0.35)",
                    border: `1px solid ${unlocked ? "#f5c838" : "#2a2820"}`,
                    borderRadius: "8px",
                    opacity: unlocked ? 1 : 0.5,
                    boxShadow: unlocked ? "0 0 8px rgba(245,200,56,0.25), inset 0 1px 0 rgba(255,216,56,0.2)" : "none",
                  }}>
                    <div style={{ fontSize: "11px", fontWeight: 700 }}>
                      {unlocked ? a.emoji : "🔒"} {a.name}
                    </div>
                    <div style={{ fontSize: "8px", opacity: 0.85, marginTop: "2px", lineHeight: 1.2 }}>
                      {a.desc}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Dino fact sheets */}
          <div style={{ fontSize: "10px", letterSpacing: "2px", opacity: 0.75, marginBottom: "6px" }}>
            ── FICHES DINOSAURES ──
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
            {DINOS.map((d, i) => ({ d, i }))
              .filter(x => !x.d.exclusive)
              .sort((a, b) => a.d.name.localeCompare(b.d.name, "fr"))
              .map(({ d, i }) => {
                const facts = getDinoFacts(d.name);
                return (
                  <div key={i} style={{
                    background: "rgba(255,248,230,0.04)",
                    color: "#c0b8a8",
                    border: "1px solid #2a2820",
                    borderRadius: "10px",
                    padding: "10px 12px",
                  }}>
                    <div style={{ fontSize: "13px", fontWeight: 700, marginBottom: "3px" }}>
                      {d.name} {TYPE_EMOJI[FAMILY_TYPES[d.family]]}
                    </div>
                    <div style={{ fontSize: "9px", opacity: 0.75, marginBottom: "4px" }}>
                      {d.era} · {d.family}
                    </div>
                    {facts && (
                      <div style={{ fontSize: "9px", lineHeight: 1.5 }}>
                        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "2px 8px", marginBottom: "4px" }}>
                          <div>📏 {facts.size}</div>
                          <div>⚖️ {facts.weight}</div>
                          <div>🍖 {facts.diet}</div>
                          <div>🌍 {facts.loc}</div>
                        </div>
                        <div style={{ fontSize: "8px", opacity: 0.65, marginBottom: "4px" }}>
                          🕐 {facts.era}
                        </div>
                        {facts.facts.map((f, fi) => (
                          <div key={fi} style={{ marginBottom: "2px", paddingLeft: "14px", position: "relative" }}>
                            <span style={{ position: "absolute", left: 0 }}>🦴</span> {f}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })}
          </div>

          {/* Danger zone: reset */}
          <div style={{
            marginTop: "24px",
            padding: "12px",
            background: "rgba(200,56,56,0.08)",
            border: "1px dashed #cc2020",
            textAlign: "center",
          }}>
            <div style={{ fontSize: "10px", letterSpacing: "2px", color: "#cc2020", marginBottom: "6px" }}>
              ── ZONE DE DANGER ──
            </div>
            <div style={{ fontSize: "9px", opacity: 0.85, marginBottom: "10px", lineHeight: 1.4 }}>
              Efface toute la progression : niveau, bestiaire, succès, œufs, couleurs rares, inventaire, dinos sauvegardés. Cette action est irréversible.
            </div>
            {!confirmReset ? (
              <button
                onClick={() => setConfirmReset(true)}
                style={{
                  padding: "8px 14px",
                  background: "transparent",
                  color: "#cc2020",
                  border: "1px solid #cc2020",
                  fontFamily: "system-ui, -apple-system, sans-serif",
                  fontSize: "10px",
                  letterSpacing: "2px",
                  cursor: "pointer",
                  textTransform: "uppercase",
                }}
              >
                🔄 Recommencer le jeu
              </button>
            ) : (
              <div>
                <div style={{ fontSize: "11px", marginBottom: "8px", color: "#cc2020", fontWeight: 700 }}>
                  ⚠️ Es-tu sûre ? Toute la progression sera perdue.
                </div>
                <div style={{ display: "flex", gap: "6px", justifyContent: "center" }}>
                  <button
                    onClick={resetGame}
                    style={{
                      padding: "8px 14px",
                      background: "#cc2020",
                      color: "#f0ece0",
                      border: "1px solid #cc2020",
                      fontFamily: "system-ui, -apple-system, sans-serif",
                      fontSize: "10px",
                      letterSpacing: "2px",
                      cursor: "pointer",
                      textTransform: "uppercase",
                      fontWeight: 700,
                    }}
                  >
                    Oui, tout effacer
                  </button>
                  <button
                    onClick={() => setConfirmReset(false)}
                    style={{
                      padding: "8px 14px",
                      background: "transparent",
                      color: "#f0ece0",
                      border: "1px solid #2a2820",
                      fontFamily: "system-ui, -apple-system, sans-serif",
                      fontSize: "10px",
                      letterSpacing: "2px",
                      cursor: "pointer",
                      textTransform: "uppercase",
                    }}
                  >
                    Annuler
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {view === "bestiary" && (
        <div className="view-enter" key="bestiary" style={{ padding: "20px 16px" }}>
          <div style={{ fontSize: "10px", letterSpacing: "2px", opacity: 0.85, marginBottom: "6px", textAlign: "center" }}>
            ── CRÉATURES RENCONTRÉES ──
          </div>
          {/* Pokédex progress */}
          <div style={{
            textAlign: "center", marginBottom: "12px", padding: "8px",
            background: "rgba(0,0,0,0.25)", borderRadius: "8px", border: "1px solid #2a2820",
          }}>
            <div style={{ fontSize: "20px", fontWeight: 900, color: "#e8a020" }}>
              {Object.keys(bestiary).length} / {DINOS.length}
            </div>
            <div style={{ fontSize: "9px", opacity: 0.75 }}>espèces découvertes</div>
            <div style={{
              height: "6px", background: "#1a2818", border: "1px solid #2a2820",
              borderRadius: "3px", marginTop: "4px", overflow: "hidden",
            }}>
              <div style={{
                width: `${(Object.keys(bestiary).length / DINOS.length) * 100}%`,
                height: "100%",
                background: Object.keys(bestiary).length >= DINOS.length
                  ? "linear-gradient(90deg, #e8a020, #f0b830)"
                  : "linear-gradient(90deg, #5a9a48, #8aca68)",
              }} />
            </div>
          </div>
          {Object.keys(bestiary).length === 0 ? (
            <div style={{ textAlign: "center", opacity: 0.85, padding: "40px 0", fontStyle: "italic", fontSize: "12px" }}>
              Aucune créature rencontrée.<br/>
              Combats des adversaires pour remplir ton bestiaire.
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
              {Object.entries(bestiary).map(([name, info]) => {
                const headName = info.build?.head !== undefined ? DINOS[info.build.head]?.name : null;
                const facts = getDinoFacts(headName || name);
                const headIdx = info.build?.head;
                const dino = headIdx !== undefined ? DINOS[headIdx] : null;
                const dinoColor = dino?.color || "#888";
                const typeEmoji = dino ? (TYPE_EMOJI[FAMILY_TYPES[dino.family]] || "🌍") : "🌍";
                return (
                <div key={name} onClick={() => setSelectedDex({ name, ...info })} style={{
                  background: "rgba(255,248,230,0.04)",
                  border: "1px solid #2a2820",
                  borderRadius: "10px",
                  padding: "10px 12px",
                  color: "#c0b8a8",
                  display: "flex",
                  gap: "10px",
                  alignItems: "center",
                  cursor: "pointer",
                }}>
                  {/* Color swatch instead of full DinoArt for perf */}
                  <div style={{
                    width: "40px", height: "40px", flexShrink: 0, borderRadius: "10px",
                    background: `linear-gradient(135deg, ${dinoColor}, ${shadeColor(dinoColor, -30)})`,
                    border: `2px solid ${shadeColor(dinoColor, -50)}`,
                    display: "flex", alignItems: "center", justifyContent: "center",
                    fontSize: "18px",
                  }}>{typeEmoji}</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: "12px", fontWeight: 700, lineHeight: 1.1 }}>{name}</div>
                    <div style={{ fontSize: "9px", opacity: 0.75, marginTop: "2px" }}>
                      {info.encounters}× · {info.defeated}× vaincu
                      {facts && <span> · {facts.diet}</span>}
                    </div>
                    {facts && (
                      <div style={{ fontSize: "8px", opacity: 0.55, marginTop: "2px" }}>
                        📏 {facts.size} · 🕐 {facts.era.split("(")[0].trim()}
                      </div>
                    )}
                    <div style={{ fontSize: "8px", opacity: 0.55, marginTop: "2px" }}>
                      Toucher pour la fiche complète →
                    </div>
                    {info.lastTier && (
                      <div style={{ fontSize: "9px", opacity: 0.85, marginTop: "1px" }}>
                        Rang max : {info.lastTier}
                      </div>
                    )}
                  </div>
                </div>
                );
              })}
            </div>
          )}
        </div>
      )}


    </div>
  );
}

const btnPrimary = {
  flex: 2,
  padding: "12px",
  background: "linear-gradient(135deg, #e8a020 0%, #c88818 100%)",
  color: "#141810",
  border: "none",
  borderRadius: "12px",
  fontFamily: "system-ui, -apple-system, sans-serif",
  fontSize: "12px",
  fontWeight: 700,
  letterSpacing: "2px",
  cursor: "pointer",
  textTransform: "uppercase",
  boxShadow: "0 2px 8px rgba(232,160,32,0.3)",
};

const btnSecondary = {
  flex: 1,
  padding: "12px 8px",
  background: "rgba(255,248,230,0.05)",
  color: "#f0ece0",
  border: "1px solid rgba(255,248,230,0.1)",
  borderRadius: "12px",
  fontFamily: "system-ui, -apple-system, sans-serif",
  fontSize: "11px",
  letterSpacing: "1px",
  cursor: "pointer",
  backdropFilter: "blur(4px)",
};

const btnSmall = {
  padding: "6px 12px",
  fontSize: "10px",
  fontWeight: 600,
  fontFamily: "system-ui, -apple-system, sans-serif",
  border: "none",
  borderRadius: "8px",
  cursor: "pointer",
  textTransform: "uppercase",
};
