// Shops, like Poké Marts: one per town, each with its own stock (later towns sell more).
// Prices in coins; selling gives back half.

export const SHOPS = {
  portAmbre: {
    name: "Boutique de Port-Ambre",
    keeper: "Rosalie",
    stock: [["collier", 30], ["fougere", 20], ["baie", 25]],
  },
};

export const SELL_RATIO = 0.5;

/** What an item sells for (null if no shop buys it). */
export function sellPrice(id) {
  for (const shop of Object.values(SHOPS)) {
    const row = shop.stock.find(([item]) => item === id);
    if (row) return Math.floor(row[1] * SELL_RATIO);
  }
  return null;
}
