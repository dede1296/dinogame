// Items that can be found in the world.
export const ITEMS = {
  fougere: { name: "Fougère curative", icon: "🌿", desc: "Soigne un dino pendant ou après un combat." },
  baie: { name: "Baie féroce", icon: "🍇", desc: "Rend un dino plus agressif pendant un combat." },
  ambre: { name: "Fragment d'ambre", icon: "🟠", desc: "Contient l'ADN d'une espèce. À analyser au Cabinet." },
  fossile: { name: "Fragment de fossile", icon: "🦴", desc: "Réunis un squelette complet pour faire revivre une espèce rare." },
  journal: { name: "Page du journal d'Hélène", icon: "📜", desc: "Une page arrachée du journal de ta grand-mère." },
  collier: { name: "Collier d'ambre", icon: "📿", desc: "Lancé sur un dino sauvage affaibli, il peut le capturer." },
  piece: { name: "Pièces", icon: "🪙", desc: "La monnaie de Port-Ambre." },
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
};

export const FOSSIL_PARTS = { crane: "Crâne", colonne: "Colonne", cotes: "Côtes", pattes: "Pattes", queue: "Queue" };
