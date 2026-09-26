// Shop window, like a Poké Mart: Buy / Sell tabs, pick an item, choose how many, confirm.

import { state } from "../state/game.js";
import { ITEMS } from "../data/items.js";
import { SHOPS, sellPrice } from "../data/shops.js";
import { play } from "../audio/sounds.js";
import { openScreen, esc } from "./screen.js";
import { artImg } from "./art.js";

const MAX_QTY = 99;

export function openShop(hud, shopId) {
  const shop = SHOPS[shopId];
  let tab = "buy";
  let selected = null;
  let qty = 1;
  return openScreen(hud, {
    title: shop.name, icon: artImg("boutique", "🛒"), className: "shop",
    render(body, api) {
      const rows = tab === "buy"
        ? shop.stock.map(([id, price]) => ({ id, price, owned: state.bag[id] || 0 }))
        : Object.entries(state.bag).filter(([id, q]) => q > 0 && sellPrice(id) !== null).map(([id, q]) => ({ id, price: sellPrice(id), owned: q }));
      if (!rows.some((r) => r.id === selected)) { selected = rows[0]?.id ?? null; qty = 1; }
      const cur = rows.find((r) => r.id === selected);
      const maxQty = !cur ? 0 : tab === "buy" ? Math.min(MAX_QTY, Math.floor(state.money / cur.price)) : cur.owned;
      qty = Math.max(1, Math.min(qty, maxQty || 1));
      body.innerHTML = `
        <div class="pockets"><button data-tab="buy" class="${tab === "buy" ? "on" : ""}">Acheter</button><button data-tab="sell" class="${tab === "sell" ? "on" : ""}">Vendre</button></div>
        ${rows.map((r) => `<button class="item ${r.id === selected ? "on" : ""}" data-it="${r.id}"><div class="ic">${artImg(r.id, ITEMS[r.id].icon)}</div><div>${esc(ITEMS[r.id].name)}<div class="shop-own">Dans le sac : ${r.owned}</div></div><div class="qty">${r.price} 🪙</div></button>`).join("")
          || `<div class="scr-empty">${tab === "buy" ? "Plus rien en rayon." : "Rien à vendre : la boutique rachète les objets qu'elle vend."}</div>`}
        ${cur ? `<div class="item-desc"><div class="big">${artImg(cur.id, ITEMS[cur.id].icon)}</div><b>${esc(ITEMS[cur.id].name)}</b><br>${esc(ITEMS[cur.id].desc)}
          <div class="qty-row"><button class="chip" data-q="-1" aria-label="Moins">−</button><b>${qty}</b><button class="chip" data-q="1" aria-label="Plus">+</button>
          <span class="shop-total">${tab === "buy" ? "Total" : "Tu reçois"} : ${qty * cur.price} 🪙</span></div>
          <button class="btn-main" data-deal ${maxQty ? "" : "disabled"}>${tab === "buy" ? (maxQty ? `Acheter ${qty}` : "Pas assez de pièces") : `Vendre ${qty}`}</button></div>` : ""}
        <div class="money">${artImg("piece", "🪙")} ${state.money} pièces</div>`;
      body.onclick = (e) => {
        const t = e.target.closest("[data-tab]");
        if (t) { tab = t.dataset.tab; selected = null; play("ui_move", { volume: 0.4 }); return api.rerender(); }
        const it = e.target.closest("[data-it]");
        if (it) { selected = it.dataset.it; qty = 1; play("ui_move", { volume: 0.4 }); return api.rerender(); }
        const q = e.target.closest("[data-q]");
        if (q) { qty = Math.max(1, Math.min(maxQty || 1, qty + +q.dataset.q)); play("ui_move", { volume: 0.3 }); return api.rerender(); }
        if (e.target.closest("[data-deal]") && cur && maxQty) {
          const total = qty * cur.price;
          if (tab === "buy") {
            state.money -= total;
            state.bag = { ...state.bag, [cur.id]: (state.bag[cur.id] || 0) + qty };
            api.toast(`Tu achètes ${qty} × ${ITEMS[cur.id].name} pour ${total} pièces.`);
          } else {
            state.money += total;
            state.bag = { ...state.bag, [cur.id]: cur.owned - qty };
            api.toast(`Tu vends ${qty} × ${ITEMS[cur.id].name} pour ${total} pièces.`);
          }
          play("coins", { volume: 0.6 });
          qty = 1;
          api.rerender();
        }
      };
    },
  });
}
