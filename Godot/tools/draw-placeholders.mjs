// Prop pictures drawn as vectors: the campfire and its flame as the web version drew them
// (no ground shadow: the game casts it).
//   feu_camp.png  the web version's campfire: a ring of stones around crossed logs, embers
//   flamme.png    its flame, apart (it flickers in the game)
//   papillon.png  a butterfly (web version), white wings tinted in the game
// Usage (from the repository root): node Godot/tools/draw-placeholders.mjs
import sharp from "sharp";

const OUT = "Godot/assets/art/props";
const INK = "#2a180c";

const pictures = {
  feu_camp: [64, 56, `
    <ellipse cx="32" cy="42" rx="18" ry="7" fill="#2a1c10"/>
    <line x1="16" y1="46" x2="46" y2="36" stroke="#3b2414" stroke-width="9" stroke-linecap="round"/><line x1="16" y1="46" x2="46" y2="36" stroke="#7a5230" stroke-width="5" stroke-linecap="round"/>
    <line x1="18" y1="36" x2="48" y2="46" stroke="#3b2414" stroke-width="9" stroke-linecap="round"/><line x1="18" y1="36" x2="48" y2="46" stroke="#7a5230" stroke-width="5" stroke-linecap="round"/>
    <line x1="24" y1="48" x2="40" y2="34" stroke="#3b2414" stroke-width="9" stroke-linecap="round"/><line x1="24" y1="48" x2="40" y2="34" stroke="#7a5230" stroke-width="5" stroke-linecap="round"/>
    <circle cx="32" cy="41" r="6" fill="#e0672a"/><circle cx="32" cy="41" r="3" fill="#ffd36a"/>
    <ellipse cx="54.0" cy="42.0" rx="6" ry="4.5" transform="rotate(0 54.0 42.0)" fill="#a9a392" stroke="#4b473e" stroke-width="2"/>
    <ellipse cx="48.9" cy="47.8" rx="6" ry="4.5" transform="rotate(40 48.9 47.8)" fill="#8d877a" stroke="#4b473e" stroke-width="2"/>
    <ellipse cx="35.8" cy="50.9" rx="6" ry="4.5" transform="rotate(80 35.8 50.9)" fill="#a9a392" stroke="#4b473e" stroke-width="2"/>
    <ellipse cx="21.0" cy="49.8" rx="6" ry="4.5" transform="rotate(120 21.0 49.8)" fill="#8d877a" stroke="#4b473e" stroke-width="2"/>
    <ellipse cx="11.3" cy="45.1" rx="6" ry="4.5" transform="rotate(160 11.3 45.1)" fill="#a9a392" stroke="#4b473e" stroke-width="2"/>
    <ellipse cx="11.3" cy="38.9" rx="6" ry="4.5" transform="rotate(200 11.3 38.9)" fill="#8d877a" stroke="#4b473e" stroke-width="2"/>
    <ellipse cx="21.0" cy="34.2" rx="6" ry="4.5" transform="rotate(240 21.0 34.2)" fill="#a9a392" stroke="#4b473e" stroke-width="2"/>
    <ellipse cx="35.8" cy="33.1" rx="6" ry="4.5" transform="rotate(280 35.8 33.1)" fill="#8d877a" stroke="#4b473e" stroke-width="2"/>
    <ellipse cx="48.9" cy="36.2" rx="6" ry="4.5" transform="rotate(320 48.9 36.2)" fill="#a9a392" stroke="#4b473e" stroke-width="2"/>`, 4],
  // Its flame (web: flame(), 36 x 44), a separate picture: it flickers in the game.
  flamme: [36, 44, `
    <path d="M3 42 C 0 22, 15 14, 18 2 C 24 18, 36 23, 33 42 Z" fill="#d9481e"/>
    <path d="M7 42 C 5 27, 16 21, 18 12 C 22 24, 31 28, 29 42 Z" fill="#f28a2a"/>
    <path d="M12 42 C 11 33, 17 30, 18 24 C 20 31, 25 34, 24 42 Z" fill="#ffe07a"/>`, 4],
  // A butterfly (web: butterfly(), 12 x 10): white wings, tinted in the game.
  papillon: [12, 10, `
    <ellipse cx="3.5" cy="4" rx="3.5" ry="3" transform="rotate(-23 3.5 4)" fill="#ffffff"/>
    <ellipse cx="8.5" cy="4" rx="3.5" ry="3" transform="rotate(23 8.5 4)" fill="#ffffff"/>
    <rect x="5.5" y="2" width="1" height="7" fill="#2a1a0a"/>`, 6],
};

for (const [name, [w, h, body, k = 2]] of Object.entries(pictures)) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;
  await sharp(Buffer.from(svg)).resize(w * k, h * k).png().toFile(`${OUT}/${name}.png`);
  console.log(`${OUT}/${name}.png`);
}
