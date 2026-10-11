class_name ShotCaption
## A caption written on the test's own view: what this test is about, in a few words (Greg, 04/10:
## the test must say on screen what it tests — and it must STAY there, not flash by shot after
## shot). So: one caption for the whole run (`show_on`, left up until the end), small, top left.
## `save` is for a one-off picture that needs its own words.

const MARGIN := 14
const TOP := 34
const BAR := Color(0.05, 0.06, 0.08, 0.72)
const INK := Color(1, 0.93, 0.76)
const SIZE := 15


## Writes `text` at the top left and leaves it there for the whole test; gives back the layer,
## to free at the end (or to keep until the game closes).
static func show_on(tree: SceneTree, text: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 128
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BAR
	style.set_corner_radius_all(6)
	style.content_margin_left = MARGIN
	style.content_margin_right = MARGIN
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	bar.add_theme_stylebox_override(&"panel", style)
	bar.position = Vector2(MARGIN, TOP)   # under the demo's own line of controls
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE   # (it sits over the HUD: it must not catch the mouse)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.add_theme_font_size_override(&"font_size", SIZE)
	label.add_theme_color_override(&"font_color", INK)
	bar.add_child(label)
	layer.add_child(bar)
	tree.root.add_child(layer)
	return layer


## The whole thing: caption up, picture saved to `path`, caption down.
static func save(tree: SceneTree, path: String, text: String) -> void:
	var layer := show_on(tree, text)
	await tree.process_frame
	await tree.process_frame
	tree.root.get_viewport().get_texture().get_image().save_png(path)
	layer.queue_free()
