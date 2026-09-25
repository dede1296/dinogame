import React, { useState, useMemo, useRef, useEffect } from "react";
import { DINOS, PARTS } from "./data/dinos.js";
import { startMusic, stopMusic } from "./audio/music.js";
import { playSfx, playRoar, vibrate } from "./audio/sfx.js";
import { playCry } from "./audio/cry.js";
import { DinoArt3D } from "./art/DinoArt3D.jsx";
import { DinoArt } from "./art/DinoArt.jsx";
import { shadeColor } from "./utils/color.js";
import { describePartContribution, partContributesTo, computeStats } from "./game/stats.js";
import { FAMILY_TYPES, TYPE_CHART, TYPE_EMOJI, getBuildType, getTypeMult, WEATHERS } from "./game/types.js";
import { ZONES, TRAITS, ITEMS } from "./data/world.js";
import { getDinoFacts } from "./data/facts.js";
import { ACHIEVEMENTS, EQUIPMENT_LIST, QUIZ_QUESTIONS, RIVAL_NAME, RIVAL_APPEARANCES, RIVAL_DIALOGUES, PATTERNS } from "./data/content.js";
import { generateName } from "./game/names.js";
import { generateEnemy, computeHP, statsWithLevel, getMaxUses, getAvailableAttacks, STATUS_EFFECTS, computeAttack, TOURNAMENT_TIERS, ENVIRONMENTS } from "./game/combat.js";
import { STORAGE_KEY, hasStorage, loadSave, writeSave } from "./storage/local.js";
import { CloudSaveButton } from "./cloud/CloudSave.jsx";
import { cloudEnabled } from "./cloud/client.js";

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
          {cloudEnabled && <span style={{ opacity: 0.5 }}>|</span>}
          <CloudSaveButton />
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
