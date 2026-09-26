// Vite plugin: writes dist/nouveau/sw.js from nouveau/pwa/sw.js, with the list of files
// Ambrelune needs (its JS chunks, sounds, images, icons) and a build id that changes only
// when one of them changes. Runs on `vite build` only.

import fs from "node:fs";
import crypto from "node:crypto";

const TEMPLATE = new URL("./sw.js", import.meta.url);
const PUBLIC_FILES = ["manifest.webmanifest", "icons/icon-192.png", "icons/icon-512.png", "icons/apple-touch-icon.png", "icons/favicon-48.png"];

export function ambreluneServiceWorker({ entry = "nouveau", dir = "nouveau" } = {}) {
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
        if (item.type === "asset" && (item.originalFileNames || []).some((n) => n.replace(/\\/g, "/").startsWith(`${dir}/`))) files.add(item.fileName);
      }
      files.delete(`${dir}/index.html`);

      // The classic game's PWA plugin injects its manifest and worker registration into
      // every page: Ambrelune has its own, so remove them from its page.
      const page = bundle[`${dir}/index.html`];
      if (page) {
        page.source = String(page.source)
          .replace(/<link rel="manifest" href="[^"]*\/manifest\.webmanifest">/g, (tag) => (tag.includes(`/${dir}/`) ? tag : ""))
          .replace(/<script id="vite-plugin-pwa:register-sw"[^>]*><\/script>/g, "");
      }

      // URLs relative to the worker, which lives in /<base>/nouveau/.
      const urls = ["./", ...PUBLIC_FILES, ...[...files].sort().map((f) => `../${f}`)];
      const html = page?.source || "";
      const template = fs.readFileSync(TEMPLATE, "utf8");
      const build = crypto.createHash("sha256").update(urls.join("\n")).update(String(html)).update(template).digest("hex").slice(0, 12);
      const source = template
        .replace("__BUILD__", build)
        .replace("__PRECACHE__", JSON.stringify(urls, null, 2));
      this.emitFile({ type: "asset", fileName: `${dir}/sw.js`, source });
    },
  };
}
