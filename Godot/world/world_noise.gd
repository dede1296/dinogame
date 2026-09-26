class_name WorldNoise
## Shared tileable noise texture for the world shaders (ground, clouds…), generated once.

static var _texture: NoiseTexture2D


static func texture() -> NoiseTexture2D:
	if _texture == null:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.012
		noise.fractal_octaves = 4
		_texture = NoiseTexture2D.new()
		_texture.width = 256
		_texture.height = 256
		_texture.seamless = true
		_texture.normalize = true
		_texture.noise = noise
	return _texture
