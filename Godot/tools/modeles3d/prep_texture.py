"""Prepare une peinture ComfyUI pour la projection sur le modele 3D.
  python prep_texture.py <peinture.png> <texture.png>
Le fond blanc (relie au bord) est retire, puis le contour brun exterieur (ERODE px) : sur le
modele, il ferait une teinte foncee aux aretes. Les couleurs de la maison debordent ensuite
de BLEED px dans le fond, pour que les petits decalages de projection prennent la bonne teinte.
"""
import sys
from collections import deque
import numpy as np
from PIL import Image

ERODE, BLEED = 7, 48
src, dst = sys.argv[1], sys.argv[2]
arr = np.array(Image.open(src).convert("RGB")).astype(np.float32)
h, w, _ = arr.shape
light = arr.min(axis=2) > 200
bg = np.zeros((h, w), bool)
q = deque([(y, x) for y in range(h) for x in (0, w - 1) if light[y, x]] +
          [(y, x) for x in range(w) for y in (0, h - 1) if light[y, x]])
for y, x in q:
    bg[y, x] = True
while q:
    y, x = q.popleft()
    for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
        if 0 <= ny < h and 0 <= nx < w and not bg[ny, nx] and light[ny, nx]:
            bg[ny, nx] = True
            q.append((ny, nx))


def grow(mask, n):
    for _ in range(n):
        g = mask.copy()
        g[1:] |= mask[:-1]; g[:-1] |= mask[1:]; g[:, 1:] |= mask[:, :-1]; g[:, :-1] |= mask[:, 1:]
        mask = g
    return mask


filled = ~grow(bg, ERODE)
col = np.where(filled[..., None], arr, 0.0)
for _ in range(BLEED):
    acc = np.zeros_like(col)
    cnt = np.zeros((h, w), np.float32)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        acc += np.roll(np.roll(col, dy, 0), dx, 1) * np.roll(np.roll(filled, dy, 0), dx, 1)[..., None]
        cnt += np.roll(np.roll(filled, dy, 0), dx, 1)
    new = (~filled) & (cnt > 0)
    col[new] = acc[new] / cnt[new][:, None]
    filled |= new
col[~filled] = arr[~filled]
Image.fromarray(col.astype(np.uint8)).save(dst)
print("texture:", dst)
