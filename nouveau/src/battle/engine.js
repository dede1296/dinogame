// Turn-based battle rules, independent from rendering.
// Each call to `turn(action)` resolves one turn and returns a list of events that the
// battle scene plays back with animations and messages.

import { TYPE_CHART } from "../../../src/game/types.js";
import { MOVES, TYPE_NAMES } from "./moves.js";
import { statsOf, typeOf, xpReward, gainXp, catchDifficulty } from "./dino.js";

export const STATUS = {
  saigne: { name: "Saignement", icon: "🩸", turns: 99 },
  etourdi: { name: "Étourdi", icon: "💫", turns: 1 },
  peur: { name: "Apeuré", icon: "😱", turns: 3 },
};
const STAT_NAMES = { atk: "L'attaque", def: "La défense", spd: "La vitesse" };

const stageMult = (s) => (s >= 0 ? (2 + s) / 2 : 2 / (2 - s));
const effectiveness = (moveType, defType) => (moveType === "neutre" ? 1 : TYPE_CHART[moveType]?.[defType] || 1);

export class Battle {
  /**
   * @param player { team: dino[] }        the player's party (mutated: hp, xp, level…)
   * @param foe    { team: dino[], trainer?: { name, boss?, reward? } }
   *               boss: a lone named creature (Alpha…): no trainer name, no catch, no escape.
   * @param bag    { itemId: qty }         mutated when items are used
   */
  constructor({ player, foe, bag, rng = Math.random }) {
    this.rng = rng;
    this.bag = bag;
    this.wild = !foe.trainer;
    this.trainer = foe.trainer || null;
    this.sides = {
      player: { team: player.team, active: player.team.findIndex((d) => d.hp > 0), stages: fresh() },
      foe: { team: foe.team, active: 0, stages: fresh() },
    };
    this.over = false;
    this.result = null;
    this.escapeTries = 0;
  }

  active(side) {
    const s = this.sides[side];
    return s.team[s.active];
  }

  name(side) {
    const d = this.active(side);
    if (side === "player") return d.nickname;
    if (this.wild) return `${d.speciesName} sauvage`;
    return this.trainer.boss ? d.nickname : `le ${d.speciesName} de ${this.trainer.name}`;
  }

  // ---------------------------------------------------------------- turn
  turn(action) {
    const ev = [];
    if (this.over) return ev;
    const foeAction = this.chooseFoeAction();

    // Non-move actions happen before any attack.
    if (action.type === "run") {
      if (this.tryRun(ev)) return ev;
    } else if (action.type === "switch") {
      this.doSwitch("player", action.index, ev);
    } else if (action.type === "item") {
      if (action.item === "collier") {
        if (this.tryCatch(ev)) return ev;
      } else {
        this.useItem(action.item, ev);
      }
    }

    const order = [];
    if (action.type === "move") order.push({ side: "player", move: action.index });
    order.push({ side: "foe", move: foeAction });
    if (order.length === 2) {
      const [a, b] = order;
      const pa = MOVES[this.active(a.side).moves[a.move]?.id]?.priority ? 1 : 0;
      const pb = MOVES[this.active(b.side).moves[b.move]?.id]?.priority ? 1 : 0;
      const sa = this.speed(a.side), sb = this.speed(b.side);
      if (pb > pa || (pb === pa && (sb > sa || (sb === sa && this.rng() < 0.5)))) order.reverse();
    }

    for (const o of order) {
      if (this.over) break;
      if (this.active(o.side).hp <= 0) continue;
      this.useMove(o.side, o.move, ev);
      if (this.checkFaints(ev)) break;
    }
    if (!this.over) this.endOfTurn(ev);
    return ev;
  }

  speed(side) {
    return statsOf(this.active(side)).spd * stageMult(this.sides[side].stages.spd);
  }

  // ---------------------------------------------------------------- moves
  useMove(side, index, ev) {
    const other = side === "player" ? "foe" : "player";
    const user = this.active(side), target = this.active(other);
    if (user.status?.id === "etourdi") {
      ev.push({ type: "text", text: `${cap(this.name(side))} est étourdi et ne peut pas bouger !` });
      user.status = null;
      ev.push({ type: "status", side, status: null });
      return;
    }
    const slot = user.moves[index];
    const move = MOVES[slot?.id] || MOVES.charge;
    if (slot) slot.pp = Math.max(0, slot.pp - 1);
    ev.push({ type: "move", side, move: slot?.id || "charge", text: `${cap(this.name(side))} utilise ${move.name} !` });

    if (this.rng() > move.accuracy) {
      ev.push({ type: "miss", side, text: `${cap(this.name(other))} esquive l'attaque !` });
      return;
    }

    if (move.power > 0) {
      const { damage, crit, eff } = this.damage(side, other, move);
      target.hp = Math.max(0, target.hp - damage);
      ev.push({ type: "damage", side: other, amount: damage, hp: target.hp, maxHp: statsOf(target).hp, crit, eff, moveType: move.type });
      if (crit) ev.push({ type: "text", text: "Coup critique !" });
      if (eff > 1) ev.push({ type: "text", text: "C'est super efficace !" });
      else if (eff < 1) ev.push({ type: "text", text: "Ce n'est pas très efficace…" });
    }

    const fx = move.effect;
    if (!fx) return;
    if (fx.heal) {
      const max = statsOf(user).hp, amount = Math.min(max - user.hp, Math.ceil(max * fx.heal));
      user.hp += amount;
      ev.push({ type: "heal", side, amount, hp: user.hp, maxHp: max, text: `${cap(this.name(side))} récupère des forces !` });
    }
    if (fx.status && target.hp > 0 && !target.status && this.rng() < fx.chance) {
      target.status = { id: fx.status, turns: STATUS[fx.status].turns };
      const msg = { saigne: "saigne !", etourdi: "est étourdi !", peur: "a peur !" }[fx.status];
      ev.push({ type: "status", side: other, status: fx.status, text: `${cap(this.name(other))} ${msg}` });
    }
    for (const [who, changes] of [["self", fx.self], ["foe", fx.foe]]) {
      if (!changes) continue;
      const s = who === "self" ? side : other;
      for (const [stat, delta] of Object.entries(changes)) this.changeStage(s, stat, delta, ev);
    }
  }

  damage(side, other, move) {
    const user = this.active(side), target = this.active(other);
    const A = statsOf(user).atk * stageMult(this.sides[side].stages.atk) * (user.status?.id === "peur" ? 0.6 : 1);
    const D = statsOf(target).def * stageMult(this.sides[other].stages.def);
    const L = user.level;
    let dmg = Math.floor(Math.floor(((2 * L) / 5 + 2) * move.power * (A / D)) / 50) + 2;
    const stab = move.type === typeOf(user.build) ? 1.25 : 1;
    const eff = effectiveness(move.type, typeOf(target.build));
    const crit = this.rng() < (move.crit ? 1 / 6 : 1 / 16);
    dmg = Math.max(1, Math.floor(dmg * stab * eff * (crit ? 1.5 : 1) * (0.85 + this.rng() * 0.15)));
    return { damage: dmg, crit, eff };
  }

  changeStage(side, stat, delta, ev) {
    const st = this.sides[side].stages;
    const before = st[stat];
    st[stat] = Math.max(-4, Math.min(4, st[stat] + delta));
    const who = cap(this.name(side));
    if (st[stat] === before) {
      ev.push({ type: "text", text: `${STAT_NAMES[stat]} de ${who} ne peut plus changer !` });
      return;
    }
    const txt = delta > 1 ? "augmente beaucoup" : delta > 0 ? "augmente" : delta < -1 ? "baisse beaucoup" : "baisse";
    ev.push({ type: "stat", side, stat, delta, text: `${STAT_NAMES[stat]} de ${who} ${txt} !` });
  }

  // ---------------------------------------------------------------- end of turn
  endOfTurn(ev) {
    for (const side of ["player", "foe"]) {
      const d = this.active(side);
      if (!d || d.hp <= 0 || !d.status) continue;
      if (d.status.id === "saigne") {
        const max = statsOf(d).hp, loss = Math.max(1, Math.floor(max / 12));
        d.hp = Math.max(0, d.hp - loss);
        ev.push({ type: "damage", side, amount: loss, hp: d.hp, maxHp: max, bleed: true, text: `${cap(this.name(side))} perd du sang…` });
      } else if (d.status.id === "peur") {
        d.status.turns -= 1;
        if (d.status.turns <= 0) {
          d.status = null;
          ev.push({ type: "status", side, status: null, text: `${cap(this.name(side))} n'a plus peur.` });
        }
      }
    }
    this.checkFaints(ev);
  }

  checkFaints(ev) {
    for (const side of ["foe", "player"]) {
      const d = this.active(side);
      if (d.hp > 0 || d.fainted) continue;
      d.fainted = true;
      ev.push({ type: "faint", side, text: `${cap(this.name(side))} est K.O. !` });
      if (side === "foe") this.onFoeFainted(d, ev);
      else this.onPlayerFainted(ev);
      if (this.over) return true;
    }
    return false;
  }

  onFoeFainted(foe, ev) {
    const me = this.active("player");
    if (me.hp > 0) {
      const xp = xpReward(foe, !this.wild);
      ev.push({ type: "xp", amount: xp, text: `${me.nickname} gagne ${xp} points d'expérience !` });
      for (const e of gainXp(me, xp)) {
        if (e.type === "level") ev.push({ type: "level", level: e.level, text: `${me.nickname} passe au niveau ${e.level} !` });
        else ev.push({ type: "learn", move: e.move, text: e.replaced ? `${me.nickname} oublie ${MOVES[e.replaced].name} et apprend ${MOVES[e.move].name} !` : `${me.nickname} apprend ${MOVES[e.move].name} !` });
      }
    }
    const next = this.sides.foe.team.findIndex((d) => d.hp > 0);
    if (next >= 0) {
      this.sides.foe.active = next;
      this.sides.foe.stages = fresh();
      ev.push({ type: "switch", side: "foe", index: next, text: `${this.trainer.name} envoie ${this.active("foe").speciesName} !` });
    } else {
      this.finish("win", ev);
    }
  }

  onPlayerFainted(ev) {
    if (this.sides.player.team.some((d) => d.hp > 0)) ev.push({ type: "needSwitch" });
    else this.finish("lose", ev);
  }

  finish(result, ev) {
    this.over = true;
    this.result = result;
    for (const s of Object.values(this.sides)) for (const d of s.team) delete d.fainted;
    // Temporary conditions don't outlast the battle; bleeding does until healed.
    for (const d of this.sides.player.team) if (d.status && d.status.id !== "saigne") d.status = null;
    ev.push({ type: "end", result });
  }

  // ---------------------------------------------------------------- actions
  doSwitch(side, index, ev) {
    const s = this.sides[side];
    if (index === s.active || s.team[index]?.hp <= 0) return;
    const old = this.active(side);
    s.active = index;
    s.stages = fresh();
    ev.push({ type: "switch", side, index, text: side === "player" ? `Reviens, ${old.nickname} ! Vas-y, ${this.active(side).nickname} !` : "" });
  }

  // Forced switch after a K.O. (does not cost a turn).
  replaceFainted(index) {
    const ev = [];
    this.doSwitch("player", index, ev);
    return ev;
  }

  tryRun(ev) {
    if (!this.wild) {
      ev.push({ type: "text", text: this.trainer.boss ? "Impossible de fuir : il te barre la route !" : "On ne fuit pas un combat de dresseur !" });
      return false;
    }
    this.escapeTries += 1;
    const chance = (this.speed("player") / this.speed("foe")) * 0.5 + 0.35 + this.escapeTries * 0.15;
    if (this.rng() < chance) {
      ev.push({ type: "run", success: true, text: "Tu prends la fuite !" });
      this.finish("run", ev);
      return true;
    }
    ev.push({ type: "run", success: false, text: "Impossible de fuir !" });
    return false;
  }

  tryCatch(ev) {
    if (!this.wild) {
      ev.push({ type: "text", text: this.trainer.boss ? "Il est bien trop puissant pour être capturé !" : "On ne peut pas capturer le dino d'un dresseur !" });
      return false;
    }
    if (!this.bag.collier) return false;
    this.bag.collier -= 1;
    const foe = this.active("foe"), max = statsOf(foe).hp;
    const chance = Math.min(0.95, Math.max(0.05, catchDifficulty(foe.build) * (1 - (foe.hp / max) * 0.75) * (foe.status ? 1.4 : 1)));
    const perShake = Math.cbrt(chance);
    let shakes = 0;
    while (shakes < 3 && this.rng() < perShake) shakes++;
    const success = shakes === 3;
    ev.push({ type: "catch", shakes, success, text: "Tu lances un Collier d'ambre !" });
    if (success) {
      ev.push({ type: "text", text: `${foe.speciesName} est capturé !` });
      this.finish("catch", ev);
      return true;
    }
    ev.push({ type: "text", text: ["Oh non ! Il s'est libéré tout de suite !", "Presque ! Il s'est libéré.", "Aaah ! C'était si proche !"][shakes] || "Il s'est libéré !" });
    return false;
  }

  useItem(item, ev) {
    if (!this.bag[item]) return;
    this.bag[item] -= 1;
    const d = this.active("player");
    if (item === "fougere") {
      const max = statsOf(d).hp, amount = Math.min(max - d.hp, Math.max(20, Math.ceil(max * 0.4)));
      d.hp += amount;
      ev.push({ type: "heal", side: "player", amount, hp: d.hp, maxHp: max, text: `${d.nickname} mange une Fougère curative et récupère ${amount} PV.` });
      if (d.status?.id === "saigne") { d.status = null; ev.push({ type: "status", side: "player", status: null, text: "Le saignement s'arrête." }); }
    } else if (item === "baie") {
      ev.push({ type: "text", text: `${d.nickname} croque une Baie féroce !` });
      this.changeStage("player", "atk", 1, ev);
    }
  }

  // ---------------------------------------------------------------- foe AI
  chooseFoeAction() {
    const foe = this.active("foe"), me = this.active("player");
    const usable = foe.moves.map((m, i) => ({ m, i })).filter(({ m }) => m.pp > 0);
    if (!usable.length) return 0;
    const maxHp = statsOf(foe).hp;
    const scored = usable.map(({ m, i }) => {
      const mv = MOVES[m.id];
      let score;
      if (mv.power > 0) {
        score = mv.power * mv.accuracy * effectiveness(mv.type, typeOf(me.build)) * (mv.type === typeOf(foe.build) ? 1.25 : 1);
      } else if (mv.effect?.heal) {
        score = foe.hp < maxHp * 0.4 ? 120 : 5;
      } else if (mv.effect?.self && Object.keys(mv.effect.self).some((k) => this.sides.foe.stages[k] >= 2)) {
        score = 4; // already boosted: stacking more makes the fight a slog
      } else {
        score = 35; // stat or status moves: occasionally useful
      }
      return { i, score: score * (0.7 + this.rng() * 0.6) };
    });
    scored.sort((a, b) => b.score - a.score);
    return scored[0].i;
  }
}

function fresh() {
  return { atk: 0, def: 0, spd: 0 };
}

function cap(s) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

export { TYPE_NAMES };
