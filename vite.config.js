import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";
import { ambreluneServiceWorker } from "./nouveau/pwa/vitePlugin.js";

// Served from https://dede1296.github.io/dinogame/
export default defineConfig({
  base: "/dinogame/",
  // Two games: the classic one at the root, the new adventure under /nouveau/.
  build: {
    rollupOptions: {
      input: { main: "index.html", nouveau: "nouveau/index.html" },
    },
  },
  plugins: [
    react(),
    // Ambrelune (/nouveau/) is its own installable app with its own service worker.
    ambreluneServiceWorker(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["icon.svg", "apple-touch-icon.png"],
      manifest: {
        name: "Dino·Hybride — Labo de Chloé",
        short_name: "Dino·Hybride",
        description: "Crée tes dinos hybrides et pars à l'aventure !",
        lang: "fr",
        display: "standalone",
        orientation: "portrait",
        theme_color: "#141810",
        background_color: "#0a0e08",
        icons: [
          { src: "icon-192.png", sizes: "192x192", type: "image/png" },
          { src: "icon-512.png", sizes: "512x512", type: "image/png" },
          { src: "icon-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
        ],
      },
      workbox: {
        globPatterns: ["**/*.{js,css,html,svg,png}"],
        // The classic game's worker must leave Ambrelune alone (it has its own worker).
        globIgnores: ["nouveau/**", "assets/nouveau-*.js"],
        navigateFallbackDenylist: [/\/nouveau\//],
        maximumFileSizeToCacheInBytes: 5 * 1024 * 1024,
      },
    }),
  ],
});
