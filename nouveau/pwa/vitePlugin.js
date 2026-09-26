// Vite plugin: writes dist/sw.js from nouveau/pwa/sw.js, with the list of files
// Ambrelune needs (its JS chunks, sounds, images, icons) and a build id that changes only
// when one of them changes. Runs on `vite build` only.

import fs from "node:fs";
import crypto from "node:crypto";

const TEMPLATE = new URL("./sw.js", import.meta.url);
const PUBLIC_FILES = ["manifest.webmanifest", "icons/icon-192.png", "icons/icon-512.png", "icons/apple-touch-icon.png", "icons/favicon-48.png"];

/**
 * @param entry   name of Ambrelune's entry in rollupOptions.input
 * @param html    its page in the build output
 * @param srcDir  folder holding Ambrelune's code and assets (its files get cached)
 */
export function ambreluneServiceWorker({ entry = "main", html = "index.html", srcDir = "nouveau" } = {}) {
  return {
    name: "ambrelune-service-worker",
    apply: "build",
    enforce: "post",
    generateBundle(_options, bundle) {
      const files = new Set();
      const visit = (fileName) => {
        const item = bundle[fileName];
        if (!item || files.has(fileName)) return;
        files.add(fileName);
        if (item.type !== "chunk") return;
        [...item.imports, ...item.dynamicImports].forEach(visit);
        item.viteMetadata?.importedAssets?.forEach((a) => files.add(a));
        item.viteMetadata?.importedCss?.forEach((a) => files.add(a));
      };
      Object.values(bundle).filter((c) => c.type === "chunk" && c.isEntry && c.name === entry).forEach((c) => visit(c.fileName));
      // Assets used by the page itself (title screen images in the HTML's CSS).
      for (const item of Object.values(bundle)) {
        if (item.type === "asset" && (item.originalFileNames || []).some((n) => n.replace(/\\/g, "/").startsWith(`${srcDir}/`))) files.add(item.fileName);
      }
      files.delete(html);

      // URLs relative to the worker, which lives at the site root (/<base>/sw.js).
      const urls = ["./", ...PUBLIC_FILES, ...[...files].sort()];
      const page = String(bundle[html]?.source || "");
      const template = fs.readFileSync(TEMPLATE, "utf8");
      const build = crypto.createHash("sha256").update(urls.join("\n")).update(page).update(template).digest("hex").slice(0, 12);
      const source = template
        .replace("__BUILD__", build)
        .replace("__PRECACHE__", JSON.stringify(urls, null, 2));
      this.emitFile({ type: "asset", fileName: "sw.js", source });
    },
  };
}
