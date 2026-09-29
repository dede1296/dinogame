"""Vrais volumes 3D des grands décors : étapes hors Blender (Python de ComfyUI).
Voir volumes_blender.py et docs/direction-artistique.md, « Grands décors en vraie 3D ».

  python volumes.py hunyuan <sorte…>   workflows Hunyuan3D (image -> maillage), dino_workflows/hy3d_<sorte>.json
  python volumes.py face <sorte>       texture de face : l'image du jeu, couleurs étendues hors silhouette
  python volumes.py flancs <sorte>     workflow ComfyUI qui peint les deux flancs rendus par Blender
  python volumes.py textures <sorte>   flancs peints -> textures (fond et contour extérieur retirés)

Ordre pour une sorte : hunyuan (ComfyUI) -> face -> blender prep -> flancs (ComfyUI) -> textures -> blender bake.
"""
import glob, json, os, shutil, sys
from collections import deque
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.normpath(os.path.join(HERE, "..", ".."))
ART = os.path.join(GODOT, "assets", "art", "props")
COMFY = "C:/ComfyUI_windows_portable/ComfyUI"
FLOWS = "C:/ComfyUI_windows_portable/dino_workflows"
WORK = "C:/ComfyUI_windows_portable/blender_tests/volumes"
# Ce que ComfyUI doit peindre sur les flancs (anglais : le modèle de texte de SD 1.5).
DESC = {
    "maison_blanche": "the gable end of a white stone cottage with a grey-blue slate roof and a stone chimney",
    "maison_jaune": "the side wall of a yellow plastered house with a red tiled roof",
    "maison_port": "the side wall of a grey stone harbour house with a slate roof",
    "cabinet": "the side wall of an old grey stone house covered with ivy, slate roof",
    "cabane_pilotis": "the side of a wooden hut on stilts with a thatched straw roof",
    "tente": "the side of a brown canvas camping tent",
    "tente_nomade": "the side of a striped red and cream nomad tent",
    "rocher_canyon": "the side of a layered orange sandstone rock",
    "rocher": "the side of a big grey boulder",
    "rocher_mousse": "the side of a big grey boulder covered with green moss",
    "arche_rocheuse": "the side of an orange sandstone rock arch",
    "squelette_geant": "a giant dinosaur skeleton lying half buried in sand, bleached bones",
    "crane_geant_desert": "the side of a giant dinosaur skull half buried in sand, bleached bone",
    "statue_dino": "the side of a mossy stone tyrannosaurus statue on a stone pedestal",
    "os_geant": "a giant dinosaur ribcage of bleached bones in sand",
}


def key_white(arr, thr=200):
    """Fond clair relié au bord (le contour brun du dessin l'arrête)."""
    h, w, _ = arr.shape
    light = arr.min(axis=2) > thr
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
    return bg


def grow(mask, n):
    for _ in range(n):
        g = mask.copy()
        g[1:] |= mask[:-1]; g[:-1] |= mask[1:]; g[:, 1:] |= mask[:, :-1]; g[:, :-1] |= mask[:, 1:]
        mask = g
    return mask


def bleed(arr, filled, n):
    """Étend les couleurs de `filled` sur n px (projections légèrement décalées), puis sur tout le
    reste (la couleur la plus proche) : une face projetée hors de la silhouette n'est jamais noire."""
    h, w, _ = arr.shape
    col = np.where(filled[..., None], arr, 0.0)
    for _ in range(n):
        acc = np.zeros_like(col)
        cnt = np.zeros((h, w), np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            m = np.roll(np.roll(filled, dy, 0), dx, 1)
            acc += np.roll(np.roll(col, dy, 0), dx, 1) * m[..., None]
            cnt += m
        new = (~filled) & (cnt > 0)
        col[new] = acc[new] / cnt[new][:, None]
        filled = filled | new
    if filled.any():
        iy, ix = ndimage.distance_transform_edt(~filled, return_distances=False, return_indices=True)
        col = col[iy, ix]
    return col


def face(k):
    im = np.asarray(Image.open(os.path.join(ART, k + ".png")).convert("RGBA"), dtype=np.float32)
    inside = im[..., 3] > 127
    inside = ~grow(~inside, 6)   # le contour brun extérieur : étiré sur les bords du modèle, il les brunit
    out = bleed(im[..., :3], inside, 40)
    os.makedirs(os.path.join(WORK, k), exist_ok=True)
    Image.fromarray(out.astype(np.uint8)).save(os.path.join(WORK, k, "tex_face.png"))
    # Guide de couleurs des flancs (rendus Blender pour ComfyUI) : sans le contour brun, qui
    # s'étirerait sur les murs vus de côté.
    hint = bleed(im[..., :3], ~grow(~inside, 9), 60)
    Image.fromarray(hint.astype(np.uint8)).save(os.path.join(WORK, k, "tex_face_guide.png"))
    print("face :", k)


def hunyuan(kinds, octree=192):
    for k in kinds:
        im = Image.open(os.path.join(ART, k + ".png")).convert("RGBA")
        s = int(max(im.size) * 1.25)
        bg = Image.new("RGB", (s, s), (255, 255, 255))
        bg.paste(im, ((s - im.width) // 2, (s - im.height) // 2), im)
        bg.save(COMFY + "/input/hy3d_%s.png" % k)
        w = {"54": {"class_type": "ImageOnlyCheckpointLoader", "inputs": {"ckpt_name": "hunyuan3d-dit-v2_fp16.safetensors"}},
             "70": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["54", 0], "shift": 1.0}},
             "66": {"class_type": "EmptyLatentHunyuan3Dv2", "inputs": {"resolution": 3072, "batch_size": 1}},
             "100": {"class_type": "LoadImage", "inputs": {"image": "hy3d_%s.png" % k}},
             "101": {"class_type": "CLIPVisionEncode", "inputs": {"clip_vision": ["54", 1], "image": ["100", 0], "crop": "none"}},
             "102": {"class_type": "Hunyuan3Dv2Conditioning", "inputs": {"clip_vision_output": ["101", 0]}},
             "103": {"class_type": "KSampler", "inputs": {"seed": 7, "steps": 20, "cfg": 8.0, "sampler_name": "euler",
                     "scheduler": "normal", "denoise": 1.0, "model": ["70", 0], "positive": ["102", 0],
                     "negative": ["102", 1], "latent_image": ["66", 0]}},
             "104": {"class_type": "VAEDecodeHunyuan3D", "inputs": {"samples": ["103", 0], "vae": ["54", 2],
                     "num_chunks": 8000, "octree_resolution": octree}},
             "105": {"class_type": "VoxelToMesh", "inputs": {"voxel": ["104", 0], "algorithm": "surface net", "threshold": 0.6}},
             "106": {"class_type": "SaveGLB", "inputs": {"mesh": ["105", 0], "filename_prefix": "volumes/" + k}}}
        json.dump(w, open(FLOWS + "/hy3d_%s.json" % k, "w"), indent=1)
        print("hunyuan :", FLOWS + "/hy3d_%s.json" % k)


def flancs(k):
    """Workflow ComfyUI : les rendus Blender des flancs (couleurs de la face, relief du modèle)
    repeints dans le style du jeu (SD 1.5 + LoRA Ambrelune + IPAdapter sur l'image du jeu)."""
    ref = Image.open(os.path.join(ART, k + ".png")).convert("RGBA")
    bg = Image.new("RGB", ref.size, (255, 255, 255)); bg.paste(ref, mask=ref.split()[3])
    bg.save(COMFY + "/input/vol_ref_%s.png" % k)
    w = {
        "1": {"class_type": "IPAdapterModelLoader", "inputs": {"ipadapter_file": "ip-adapter-plus_sd15.safetensors"}},
        "2": {"class_type": "CLIPVisionLoader", "inputs": {"clip_name": "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"}},
        "3": {"class_type": "LoadImage", "inputs": {"image": "vol_ref_%s.png" % k}},
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "v1-5-pruned-emaonly-fp16.safetensors"}},
        "40": {"class_type": "LoraLoader", "inputs": {"model": ["4", 0], "clip": ["4", 1], "lora_name": "ambrelune_style.safetensors",
               "strength_model": 0.8, "strength_clip": 0.8}},
        "5": {"class_type": "CLIPSetLastLayer", "inputs": {"clip": ["40", 1], "stop_at_clip_layer": -1}},
        "6": {"class_type": "IPAdapterAdvanced", "inputs": {"model": ["40", 0], "ipadapter": ["1", 0], "image": ["3", 0],
              "clip_vision": ["2", 0], "weight": 0.6, "weight_type": "linear", "combine_embeds": "average",
              "start_at": 0.0, "end_at": 1.0, "embeds_scaling": "V only"}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["5", 0], "text":
              "photo, realistic, 3d render, cgi, flat grey shading, smooth plastic, sketch, thin lines, pastel, washed out, "
              "blurry, low quality, deformed, extra objects, sheet, text, watermark, background scenery"}},
        "10": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["5", 0], "text":
               "ambrelune style, %s, side view from above, high angle, cute cartoon game asset, bold thick dark brown outline, "
               "clean lineart, cel shading, vibrant saturated colors, mobile game sprite, sticker style, plain white background" % DESC[k]}},
    }
    n = 20
    for side in ("est", "ouest"):
        src = os.path.join(WORK, k, "rendu_%s.png" % side)
        im = Image.open(src).convert("RGBA")
        bgs = Image.new("RGB", im.size, (255, 255, 255)); bgs.paste(im, mask=im.split()[3])
        bgs.save(COMFY + "/input/vol_%s_%s.png" % (k, side))
        w[str(n)] = {"class_type": "LoadImage", "inputs": {"image": "vol_%s_%s.png" % (k, side)}}
        w[str(n + 1)] = {"class_type": "VAEEncode", "inputs": {"pixels": [str(n), 0], "vae": ["4", 2]}}
        w[str(n + 2)] = {"class_type": "KSampler", "inputs": {"seed": 7, "steps": 25, "cfg": 7.0, "sampler_name": "dpmpp_2m",
                         "scheduler": "karras", "denoise": 0.5, "model": ["6", 0], "positive": ["10", 0], "negative": ["7", 0],
                         "latent_image": [str(n + 1), 0]}}
        w[str(n + 3)] = {"class_type": "VAEDecode", "inputs": {"samples": [str(n + 2), 0], "vae": ["4", 2]}}
        w[str(n + 4)] = {"class_type": "SaveImage", "inputs": {"images": [str(n + 3), 0], "filename_prefix": "volumes_flancs/%s_%s" % (k, side)}}
        n += 10
    path = FLOWS + "/vol_flancs_%s.json" % k
    json.dump({"prompt": w, "front": True}, open(path.replace(".json", ".api.json"), "w"))   # pour /prompt, en tête de file
    json.dump(w, open(path, "w"), indent=1)
    print("flancs :", path)


def textures(k):
    for side in ("est", "ouest"):
        src = sorted(glob.glob(COMFY + "/output/volumes_flancs/%s_%s_*.png" % (k, side)))[-1]
        arr = np.asarray(Image.open(src).convert("RGB"), dtype=np.float32)
        bg = grow(key_white(arr), 6)          # le fond, et le contour brun extérieur (teinte aux arêtes)
        out = bleed(arr, ~bg, 48)
        Image.fromarray(out.astype(np.uint8)).save(os.path.join(WORK, k, "tex_%s.png" % side))
    print("textures :", k)


def kinds(k):
    """Prop.KINDS (world/prop.gd) : le modèle de la sorte, et sa collision = son emprise au sol."""
    import re
    info = json.load(open(os.path.join(WORK, k, "info.json")))
    glb = os.path.join(GODOT, "assets", "models", "volumes", k + ".glb")
    if not os.path.exists(glb):
        print("pas de modèle :", k)
        return
    path = os.path.join(GODOT, "world", "prop.gd")
    src = open(path, encoding="utf-8").read()
    m = re.search(r'^\t"%s": \{(.*?)\},\n' % k, src, re.M | re.S)
    body = re.sub(r'"model": "[^"]*", ?\s*', "", m.group(1))
    body = re.sub(r'"solid": (Vector2\([^)]*\)|[\d.]+)', '"solid": Vector2(%d, %d)' % tuple(info["solid_px"]), body)
    body = " ".join(body.split())
    entry = '\t"%s": {"model": "res://assets/models/volumes/%s.glb",\n\t\t%s},\n' % (k, k, body)
    open(path, "w", encoding="utf-8").write(src[:m.start()] + entry + src[m.end():])
    print("KINDS :", entry.strip())


if __name__ == "__main__":
    cmd, kinds_ = sys.argv[1], sys.argv[2:]
    for k in kinds_ if cmd != "hunyuan" else [None]:
        {"face": face, "flancs": flancs, "textures": textures, "kinds": kinds}.get(cmd, lambda _: hunyuan(kinds_))(k)
