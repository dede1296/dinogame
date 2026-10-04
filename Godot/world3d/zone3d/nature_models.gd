extends RefCounted
## 3D models of the zone's scenery, by Prop `kind` (phase 4 of docs/migration-3d.md).
## Every model: origin at the foot (y = 0), real metres, front towards +Z, flat-shaded
## colour-only materials (no texture), palette taken from the painted props.
## Made procedurally in Blender 5.2 (scripts: assets3d_src/nature/scripts/build.py, lib.py);
## the 1st entry of each list is the main one, the next ones are variants.
## Source of the inspiration/style survey: Kenney Nature Kit
## (https://kenney.nl/assets/nature-kit, downloaded to assets3d_src/nature/kenney, not used
## as-is: recoloured assembly replaced by own low-poly models for one coherent style).

const DIR := "res://assets/models3d/nature/"

const MODELS := {
	# Built in Blender: trunk with roots + clustered icosphere lobes (lighter on top). ~6 m.
	"arbre_rond": [DIR + "arbre_rond.glb", DIR + "arbre_rond_2.glb"],
	# Built in Blender: bare trunk then 9 whorls of leafy branches, in tiers. 7.7 m / 6.8 m.
	"araucaria": [DIR + "araucaria.glb", DIR + "araucaria_2.glb"],
	# Built in Blender: ringed trunk + crown of 11 drooping pinnate fronds. 3.6 m / 3.3 m.
	"fougere_arbre": [DIR + "fougere_arbre.glb", DIR + "fougere_arbre_2.glb"],
	# Built in Blender: clustered lobes clipped at the ground. ~1 m.
	"buisson": [DIR + "buisson.glb", DIR + "buisson_2.glb"],
	# Built in Blender: 7 arching thorny canes with leaves and red berries. 0.85 m.
	"ronces": [DIR + "ronces.glb"],
	# Built in Blender: 9 arching pinnate fronds with curled tips. 0.6 m.
	"fougeres": [DIR + "fougeres.glb", DIR + "fougeres_2.glb"],
	# Built in Blender: 8 jointed stems with whorls of needles, brown cones. 1.15 m.
	"prele": [DIR + "prele.glb"],
	# Built in Blender: faceted boulder + two small stones, faces coloured by light. ~1 m.
	"rocher": [DIR + "rocher.glb", DIR + "rocher_2.glb"],
	# Built in Blender: five small stones. 0.35 m.
	"cailloux": [DIR + "cailloux.glb"],
	# Built in Blender: stump with root flares and a pale cut top. 0.6 m / 0.75 m (broken).
	"souche": [DIR + "souche.glb", DIR + "souche_2.glb"],
	# Built in Blender: brown-capped mushrooms with cream stems + grass blades. 0.3 m.
	"champignons": [DIR + "champignons.glb", DIR + "champignons_2.glb"],
	# Built in Blender: tuft of pink and yellow five-petal flowers on stems. 0.4 m.
	"fleurs_roses": [DIR + "fleurs_roses.glb"],
	# Built in Blender: tuft of violet flowers (one yellow) on stems. 0.33 m.
	"fleurs_violettes": [DIR + "fleurs_violettes.glb"],
}
