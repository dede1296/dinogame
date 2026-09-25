// Renders public/icon.svg into the PNG sizes phones need for home-screen install.
import sharp from "sharp";

const sizes = { "icon-192.png": 192, "icon-512.png": 512, "apple-touch-icon.png": 180 };
for (const [file, size] of Object.entries(sizes)) {
  await sharp("public/icon.svg").resize(size, size).png().toFile(`public/${file}`);
  console.log(`public/${file}`);
}
