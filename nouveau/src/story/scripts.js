// Story scripts. Each script is an async function receiving the world API:
//   say(name, text), choose([...]) -> index, toast(text), wait(ms), flag(k), setFlag(k),
//   giveStarter(i), heal(), save(), pushBack(), hideNpc(id), npcFace(id, dir), faceNpc(id)

import { DINOS } from "../../../src/data/dinos.js";
import { state } from "../state/game.js";
import { CHAPTER1, rocHint } from "./chapter1.js";
import { ITEMS } from "../data/items.js";
import { HELENE_LETTER } from "../data/voiceLines.js";
import { dexCounts, rocComment, pendingRocRewards, nextRocReward } from "../data/dex.js";

export const STARTERS = [
  { species: "Velociraptor", nickname: "Vif", pitch: "Rapide et malin. Il frappe le premier, mais encaisse mal les coups.", type: "Vent 💨" },
  { species: "Triceratops", nickname: "Trident", pitch: "Solide comme un roc. Lent, mais presque impossible à renverser.", type: "Terre 🌍" },
  { species: "Spinosaurus", nickname: "Voile", pitch: "Un chasseur des rivières. Puissant, surtout près de l'eau.", type: "Eau 💧" },
];

export function speciesIndex(name) {
  return DINOS.findIndex((d) => d.name.startsWith(name));
}

const ROC = "Prof. Roc";

// Like Professor Oak: Roc looks at the Dinodex and rewards every 10 species caught.
async function rocDexEvaluation(say, give) {
  const { seen, caught } = dexCounts();
  const rewards = pendingRocRewards();
  if (!rewards.length) {
    const next = nextRocReward();
    if (next && caught) await say(ROC, `Ton Dinodex : ${caught} espèce${caught > 1 ? "s" : ""} possédée${caught > 1 ? "s" : ""}. Reviens me voir à ${next.at}, j'aurai quelque chose pour toi.`);
    return;
  }
  await say(ROC, `Montre-moi ton Dinodex… ${seen} espèces vues, ${caught} possédées !`);
  await say(ROC, rocComment(caught));
  for (const r of rewards) {
    for (const [id, qty] of Object.entries(r.items)) give(id, qty);
    if (r.money) state.money += r.money;
    const list = Object.entries(r.items).map(([id, qty]) => `${qty} × ${ITEMS[id].name}`);
    if (r.money) list.push(`${r.money} pièces`);
    await say(null, `Pour tes ${r.at} espèces, tu reçois : ${list.join(", ")} !`);
    state.flags.rocDexReward = r.at;
  }
}
const MAIA = "Maïa";

export const SCRIPTS = {
  ...CHAPTER1,

  async intro({ say, wait }) {
    await wait(400);
    await say(null, "Après trois jours de mer, la brume se déchire enfin.");
    await say(null, "Devant toi : Ambrelune. L'île de ta grand-mère.");
    await say("Chloé", "« Si tu lis ceci, c'est que je ne suis plus là pour t'accueillir. Le Cabinet est à toi. »");
    await say("Chloé", "… Le Cabinet. Il doit être quelque part dans le village.");
  },

  async pecheur({ say, flag }) {
    if (!flag("starter")) {
      await say("Pêcheur", "Alors c'est toi, la petite-fille d'Hélène ? T'as ses yeux.");
      await say("Pêcheur", "Le Cabinet, c'est le grand bâtiment en pierre avec la tour, au nord de la place. Le vieux Roc t'attend depuis des semaines.");
    } else {
      await say("Pêcheur", "La nuit, on voit des lueurs violettes du côté du volcan. Les anciens disent que c'est l'Ombre Noire…");
    }
  },

  async enfant({ say }) {
    await say("Petit Léo", "Tu savais que les dinos adorent les hautes herbes ? Si tu marches dedans, ils te sautent dessus !");
    await say("Petit Léo", "Moi j'ai pas le droit d'y aller. Ma mère dit que c'est dangereux.");
  },

  async mamie({ say, flag }) {
    if (!flag("journal_1")) {
      await say("Mamie Rose", "Hélène aimait se promener dans les Plaines. Elle disparaissait parfois derrière les arbres, au nord-est, là où le bois est si dense qu'on ne voit plus le ciel.");
      await say("Mamie Rose", "Je me suis toujours demandé où elle allait…");
    } else {
      await say("Mamie Rose", "Tu as trouvé son bosquet secret ? Elle serait fière de toi, ma chérie.");
    }
  },

  async randonneur({ say }) {
    await say("Randonneur", "Tu vois l'étang, là-bas ? Les gens y perdent toujours des choses. Fouille bien le long des berges.");
    await say("Randonneur", "Astuce : appuie sur A face à un endroit suspect. On ne trouve que ce qu'on cherche !");
  },

  async roc({ say, flag, setFlag, heal, give, setRespawn }) {
    if (!flag("met_roc")) {
      await say(ROC, "Chloé ! Enfin… Tu as bien grandi depuis la photo qu'Hélène gardait sur son bureau.");
      await say(ROC, "Je suis Anselme Roc. J'ai travaillé trente ans aux côtés de ta grand-mère.");
      await say(ROC, "Il y a un an, elle est partie vers le volcan avec son sac et son vieux carnet. Elle n'est jamais revenue.");
      await say(ROC, "Depuis, des gens masqués rôdent sur l'île. Ils se font appeler l'Ombre Noire. Ils cherchent quelque chose… les Cœurs d'Ambre, je crois.");
      await say(ROC, "Tu ne peux pas explorer Ambrelune sans compagnon. Hélène avait préparé trois œufs avant de partir. Ils viennent d'éclore.");
      await say(ROC, "Ils sont sur les socles, à droite. Approche-toi et choisis celui qui te ressemble.");
      setFlag("met_roc");
      return;
    }
    if (!flag("starter")) {
      await say(ROC, "Prends ton temps. Les trois socles, à droite. Chacun a son caractère.");
      return;
    }
    if (!flag("roc_after")) {
      const d = state.party[0];
      await say(ROC, `${d.nickname} a l'air de t'avoir adoptée. Bien.`);
      await say(ROC, "Écoute-moi. Au nord du village s'étendent les Plaines des Fougères. Marche dans les hautes herbes et tu croiseras des dinos sauvages.");
      await say(ROC, "Rapporte-moi des fragments d'ambre : chacun contient l'ADN d'une espèce. Avec eux, le Cabinet pourra créer des hybrides.");
      await say(ROC, "Et Chloé… si tu trouves des pages du journal d'Hélène, apporte-les-moi. Elle écrivait tout.");
      await say(ROC, "Tiens, prends ça. Des Colliers d'ambre : lance-en un sur un dino sauvage affaibli et il te suivra peut-être.");
      give("collier", 5);
      give("fougere", 3);
      await say(null, "Tu reçois 5 Colliers d'ambre et 3 Fougères curatives !");
      await say(ROC, "Et si ton équipe est épuisée, reviens me voir. Le Cabinet soigne tous les dinos.");
      setFlag("roc_after");
      return;
    }
    heal();
    setRespawn({ x: 6, y: 5, dir: "up", name: "au Cabinet" });
    await say(ROC, "Laisse-moi examiner ton équipe… Voilà, tes dinos sont en pleine forme !");
    await rocDexEvaluation(say, give);
    for (const line of rocHint()) await say(ROC, line);
  },

  async boutique({ say, shop }) {
    await say("Rosalie", "Bienvenue à la boutique ! Colliers, fougères, baies… Tout ce qu'il faut pour partir à l'aventure.");
    await shop("portAmbre");
    await say("Rosalie", "Reviens quand tu veux. Et fais attention à toi sur les chemins !");
  },

  async starter({ say, choose, flag, giveStarter }, index) {
    const s = STARTERS[index];
    if (flag("starter")) {
      await say(null, "Le socle est vide maintenant. Il reste une douce chaleur sur la pierre.");
      return;
    }
    if (!flag("met_roc")) {
      await say(null, "Un petit dino dort sous une cloche de verre. Tu devrais d'abord parler au Professeur Roc.");
      return;
    }
    await say(null, `Un bébé ${s.species} te fixe à travers la vitre. Type : ${s.type}.\n${s.pitch}`);
    const c = await choose([`Choisir ${s.species}`, "Réfléchir encore"]);
    if (c !== 0) return;
    giveStarter(index);
    await say(null, `${s.species} bondit hors de son socle et se frotte contre ta jambe !`);
    await say(null, `Tu l'appelles… ${s.nickname}.`);
    await say(ROC, "Excellent choix. Hélène aurait choisi le même, j'en suis sûr.");
  },

  async lettre({ say, letter, flag, setFlag }) {
    await say(null, "Une lettre posée sur la table, adressée à « Chloé ». L'écriture de ta grand-mère.");
    await letter(HELENE_LETTER, "— H.", "helene-lettre");
    if (!flag("letter_read")) {
      setFlag("letter_read");
      await say("Chloé", "« Là où tout a commencé »… Le grand crâne dans les Plaines ?");
    }
  },

  async lit({ say, choose, heal, save, setRespawn }) {
    await say(null, "Le lit d'Hélène. Les draps sentent encore la lavande.");
    const c = await choose(["Se reposer et sauvegarder", "Non"]);
    if (c !== 0) return;
    heal();
    setRespawn({ x: 1, y: 3, dir: "left", name: "dans le lit d'Hélène" });
    save();
    await say(null, "Tu te reposes un moment. Tes dinos sont en pleine forme. Partie sauvegardée.");
  },

  // Campfires: rest points in each region. After a defeat, Chloé wakes up at the last one used.
  async feuDeCamp({ say, choose, heal, save, setRespawn }, spot) {
    await say(null, "Un feu de camp crépite doucement. Quelqu'un l'entretient pour les voyageurs.");
    const c = await choose(["Se reposer et sauvegarder", "Repartir"]);
    if (c !== 0) return;
    heal();
    setRespawn(spot);
    save();
    await say(null, "Tu te réchauffes près des flammes. Tes dinos sont en pleine forme. Partie sauvegardée.");
    await say(null, "Si tu perds un combat, tu reviendras ici.");
  },

  // Trigger at the northern edge of the village.
  async sortieVillage({ say, flag, setFlag, pushBack, hideNpc, npcFace }) {
    if (!flag("starter")) {
      npcFace("maia", "down");
      await say(MAIA, "Hé, hé, hé ! Tu vas où comme ça ?");
      await say(MAIA, "Sans dino, les hautes herbes c'est du suicide. Va d'abord voir le vieux Roc au Cabinet.");
      pushBack();
      return;
    }
    if (flag("maia_met")) return;
    npcFace("maia", "down");
    await say(MAIA, "Alors c'est toi, la nouvelle ? Maïa. Mon père est capitaine du port.");
    await say(MAIA, `Et ça, c'est ton dino ? … Pas mal. Mais le mien est plus rapide.`);
    await say(MAIA, "Tout le monde dit que ta grand-mère cherchait un trésor. Moi je vais le trouver avant toi. On parie ?");
    await say(MAIA, "Rendez-vous devant le grand tronc au nord ! Le premier qui trouve comment passer a gagné !");
    setFlag("maia_met");
    hideNpc("maia");
  },

  async crane({ say, flag, setFlag }) {
    await say(null, "Un crâne de Tricératops géant, à moitié enfoui. Quelqu'un a gravé dessus : « H.V. — ici tout a commencé ».");
    if (flag("letter_read") && !flag("crane_hint")) {
      setFlag("crane_hint");
      await say("Chloé", "« Ici tout a commencé »… Mais il n'y a rien ici. Peut-être que « le commencement » est ailleurs ? Mamie Rose parlait d'un bois au nord-est…");
    }
  },
};
