// Small DSL to author tile maps with organic shapes instead of typing every tile.
// A map is a grid of single-character tile codes (see TILES in tiles.js).

export function hash(x, y, seed = 0) {
  let h = (x * 374761393 + y * 668265263 + seed * 2147483647) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
}

export class MapBuilder {
  constructor(width, height, fill = ".", seed = 1) {
    this.w = width;
    this.h = height;
    this.seed = seed;
    this.grid = Array.from({ length: height }, () => Array(width).fill(fill));
  }

  inside(x, y) {
    return x >= 0 && y >= 0 && x < this.w && y < this.h;
  }

  set(x, y, ch, only) {
    if (!this.inside(x, y)) return;
    if (only && !only.includes(this.grid[y][x])) return;
    this.grid[y][x] = ch;
  }

  get(x, y) {
    return this.inside(x, y) ? this.grid[y][x] : null;
  }

  rect(x, y, w, h, ch, only) {
    for (let j = y; j < y + h; j++) for (let i = x; i < x + w; i++) this.set(i, j, ch, only);
    return this;
  }

  // Ellipse with a wobbly edge (noise 0..1) so shapes look natural.
  blob(cx, cy, rx, ry, ch, { noise = 0.25, only } = {}) {
    for (let j = Math.floor(cy - ry - 2); j <= cy + ry + 2; j++) {
      for (let i = Math.floor(cx - rx - 2); i <= cx + rx + 2; i++) {
        const d = ((i - cx) / rx) ** 2 + ((j - cy) / ry) ** 2;
        const wobble = 1 + (hash(i, j, this.seed) - 0.5) * 2 * noise;
        if (d <= wobble) this.set(i, j, ch, only);
      }
    }
    return this;
  }

  // Thick polyline (roads, rivers).
  path(points, width, ch, only) {
    for (let k = 0; k < points.length - 1; k++) {
      const [x0, y0] = points[k], [x1, y1] = points[k + 1];
      const steps = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0)) * 2 + 1;
      for (let s = 0; s <= steps; s++) {
        const x = x0 + ((x1 - x0) * s) / steps, y = y0 + ((y1 - y0) * s) / steps;
        const r = (width - 1) / 2;
        for (let j = Math.round(y - r); j <= Math.round(y + r); j++) {
          for (let i = Math.round(x - r); i <= Math.round(x + r); i++) this.set(i, j, ch, only);
        }
      }
    }
    return this;
  }

  // Randomly sprinkle a tile over an area, only replacing the listed tiles.
  scatter(x, y, w, h, ch, density, only = ["."]) {
    for (let j = y; j < y + h; j++) {
      for (let i = x; i < x + w; i++) {
        if (hash(i, j, this.seed + ch.charCodeAt(0)) < density) this.set(i, j, ch, only);
      }
    }
    return this;
  }

  // Irregular forest border: trees fill everything outside a wobbly margin.
  forestBorder(thickness, tree = "T", alt = "P") {
    for (let j = 0; j < this.h; j++) {
      for (let i = 0; i < this.w; i++) {
        const edge = Math.min(i, j, this.w - 1 - i, this.h - 1 - j);
        const t = thickness + Math.floor(hash(i, j, this.seed + 7) * 2);
        if (edge < t) this.set(i, j, hash(i, j, this.seed + 9) < 0.3 ? alt : tree);
      }
    }
    return this;
  }

  toRows() {
    return this.grid.map((row) => row.join(""));
  }
}
