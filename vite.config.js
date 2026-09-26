import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { ambreluneServiceWorker } from "./nouveau/pwa/vitePlugin.js";

// Served from https://dede1296.github.io/dinogame/
// - Ambrelune (the game, code in nouveau/) is the main page: /dinogame/
// - the classic "Dino·Hybride" lab stays playable at /dinogame/ancien/
export default defineConfig({
  base: "/dinogame/",
  build: {
    rollupOptions: {
      input: { main: "index.html", ancien: "ancien/index.html" },
    },
  },
  plugins: [
    react(),
    // Ambrelune is an installable app (PWA): writes dist/sw.js with its files to cache.
    ambreluneServiceWorker(),
  ],
});
