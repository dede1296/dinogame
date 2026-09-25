// Geometry helpers that turn skeleton lines into smooth organic SVG outlines.

const f = (n) => Math.round(n * 10) / 10;
export const pt = ([x, y]) => `${f(x)},${f(y)}`;

// Smooth curve through points (Catmull-Rom converted to cubic Béziers).
// Returns only the segments after the first point, so it can be appended to a path.
function smoothThrough(points) {
  let d = "";
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[i - 1] || points[i];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = points[i + 2] || p2;
    const c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6];
    const c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6];
    d += ` C ${pt(c1)} ${pt(c2)} ${pt(p2)}`;
  }
  return d;
}

// Closed outline of a tapered tube following `points`, with a width per point
// and rounded caps. Used for necks, tails, arms and leg segments.
export function tube(points, widths) {
  const n = points.length;
  const left = [], right = [];
  for (let i = 0; i < n; i++) {
    const a = points[Math.max(0, i - 1)], b = points[Math.min(n - 1, i + 1)];
    let tx = b[0] - a[0], ty = b[1] - a[1];
    const len = Math.hypot(tx, ty) || 1;
    tx /= len; ty /= len;
    const nx = -ty, ny = tx, h = widths[i] / 2;
    left.push([points[i][0] + nx * h, points[i][1] + ny * h]);
    right.push([points[i][0] - nx * h, points[i][1] - ny * h]);
  }
  const rEnd = Math.max(0.5, widths[n - 1] / 2);
  const rStart = Math.max(0.5, widths[0] / 2);
  const back = right.slice().reverse();
  return `M ${pt(left[0])}${smoothThrough(left)} A ${f(rEnd)} ${f(rEnd)} 0 0 0 ${pt(back[0])}${smoothThrough(back)} A ${f(rStart)} ${f(rStart)} 0 0 0 ${pt(left[0])} Z`;
}

// Point along a polyline at fraction t (0..1), with the local direction.
export function along(points, t) {
  const segs = [];
  let total = 0;
  for (let i = 0; i < points.length - 1; i++) {
    const l = Math.hypot(points[i + 1][0] - points[i][0], points[i + 1][1] - points[i][1]);
    segs.push(l);
    total += l;
  }
  let d = t * total;
  for (let i = 0; i < segs.length; i++) {
    if (d <= segs[i] || i === segs.length - 1) {
      const k = segs[i] ? Math.min(1, d / segs[i]) : 0;
      const [x0, y0] = points[i], [x1, y1] = points[i + 1];
      return { x: x0 + (x1 - x0) * k, y: y0 + (y1 - y0) * k, angle: Math.atan2(y1 - y0, x1 - x0) };
    }
    d -= segs[i];
  }
  const last = points[points.length - 1];
  return { x: last[0], y: last[1], angle: 0 };
}

// Deterministic pseudo-random generator so a given dino always looks the same.
export function seeded(seed) {
  let s = seed >>> 0 || 1;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 4294967296;
  };
}
