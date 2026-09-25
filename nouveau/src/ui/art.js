// Illustrated UI assets (made with nano-banana, processed by scripts/process-art.mjs).

const ART = new Set(["fougere", "baie", "collier", "ambre", "fossile", "journal", "piece", "sceau_plaines", "sac", "equipe", "papier"]);

/** URL of an illustration in assets/ui, or null if there is none for this name. */
export function artUrl(name) {
  return ART.has(name) ? new URL(`../../assets/ui/${name}.webp`, import.meta.url).href : null;
}

/** An <img> for an item or UI illustration, falling back to the emoji. */
export function artImg(name, fallback = "", cls = "art") {
  const url = artUrl(name);
  return url ? `<img class="${cls}" src="${url}" alt="" draggable="false">` : fallback;
}
