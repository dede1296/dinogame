class_name Layers3D
## Physics layers of the 3D world (docs/migration-3d.md). Same meaning and order as the 2D ones
## named in project.godot (monde, joueur, dinos, interactions, eau), so a mask reads the same way.

const WORLD := 1          # ground, cliffs, rocks, buildings: what stops a body and the camera
const PLAYER := 2         # Chloé
const DINOS := 4          # wild dinos, companions, mounts
const INTERACT := 8       # areas that can be examined, picked up, talked to
const WATER := 16         # deep water: blocks whoever cannot swim
