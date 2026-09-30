extends RefCounted
## Helper (« static » command of tools/capture.gd): what the game holds in video memory right
## now. The web freezes with the music still playing, which is what a lost graphics context looks
## like — and a browser tab loses it when it runs out of video memory.


static func video() -> String:
	var tex := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	var total := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	return "mémoire vidéo : %.0f Mo (dont textures %.0f Mo) | objets %d, nœuds %d" % [
		total / 1048576.0, tex / 1048576.0, objects, nodes]
