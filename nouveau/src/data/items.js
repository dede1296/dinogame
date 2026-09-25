// Items that can be found in the world.
export const ITEMS = {
  fougere: { name: "Fougère curative", icon: "🌿", desc: "Soigne un dino pendant ou après un combat." },
  baie: { name: "Baie féroce", icon: "🍇", desc: "Rend un dino plus agressif pendant un combat." },
  ambre: { name: "Fragment d'ambre", icon: "🟠", desc: "Contient l'ADN d'une espèce. À analyser au Cabinet." },
  fossile: { name: "Fragment de fossile", icon: "🦴", desc: "Réunis un squelette complet pour faire revivre une espèce rare." },
  journal: { name: "Page du journal d'Hélène", icon: "📜", desc: "Une page arrachée du journal de ta grand-mère." },
  collier: { name: "Collier d'ambre", icon: "📿", desc: "Lancé sur un dino sauvage affaibli, il peut le capturer." },
  piece: { name: "Pièces", icon: "🪙", desc: "La monnaie de Port-Ambre." },
  sceau_plaines: { name: "Sceau des Plaines", icon: "🏅", desc: "Remis par le Tricératops Alpha. La preuve que les Plaines te reconnaissent." },
};

// Pages of Hélène's journal: the lore collectible.
export const JOURNAL = {
  1: {
    title: "Le premier réveil",
    text: "12 mars. Il a ouvert les yeux ce matin. Trente-deux ans de recherche, et un petit Protoceratops me regarde comme si j'étais sa mère. L'Ambre-Mère ne ment pas : l'ADN est intact. Anselme a pleuré. Moi aussi, un peu.\n\nJe dois garder le secret. Si l'on apprend ce que l'île contient, ils viendront tous.",
  },
  2: {
    title: "Les cinq Cœurs",
    text: "L'Ambre-Mère n'est pas un seul gisement. Il y a cinq cœurs, cinq nodules d'une pureté parfaite, dispersés sous l'île. Réunis, ils contiendraient le génome complet d'une créature qui n'aurait jamais dû exister.\n\nJ'ai caché les relevés. Anselme croit que je les ai détruits.",
  },
  3: {
    title: "La Grotte qui chante",
    text: "Les pêcheurs l'appellent la Grotte des Échos : le vent y siffle comme une flûte. Moi, j'y entends autre chose. Des battements. Très lents, très profonds, comme un cœur qui dort sous la pierre.\n\nJ'ai fait sceller l'entrée par un éboulement. Seul un dino à la tête dure pourra la rouvrir.",
  },
  4: {
    title: "Ce que j'ai fait",
    text: "Le premier hybride n'a pas survécu. Le deuxième non plus. Le troisième a vécu, mais il souffrait : des veines violettes sous les écailles, une fureur qui ne s'éteignait jamais.\n\nL'ambre forcé brûle ce qu'il touche. Il ne faut JAMAIS greffer sans l'accord du dino. Jamais.",
  },
  5: {
    title: "Le gardien des Plaines",
    text: "Le vieux Tricératops veille sous le grand crâne, là où j'ai réveillé mon premier dino. Il est l'Alpha de ces plaines. Il n'attaque pas par méchanceté : il protège.\n\nS'il te juge digne, Chloé, il te laissera passer. Au nord, derrière le grand tronc, commence la Forêt Jurassique. Ce que je cherche est bien plus loin encore.",
  },
};

export const FOSSIL_PARTS = { crane: "Crâne", colonne: "Colonne", cotes: "Côtes", pattes: "Pattes", queue: "Queue" };
