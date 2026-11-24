extends CanvasLayer

## Loading screen. Shown while a world loads in the background.
## To change the picture, select the "Background" TextureRect in loading.tscn and set its Texture.
## Worlds that need extra time to build their collisions can keep the screen up until
## GameState.world_ready is true (the flat road world does not use this).

const MIN_SHOW_TIME := 0.5  # Seconds the screen stays up, even if loading is fast.
const DOT_TIME := 0.4       # Seconds between the animated dots.

@onready var spinner: TextureRect = $Spinner
@onready var label: Label = $Label
@onready var bar: ProgressBar = $ProgressBar

var _path := ""
var _on_ready: Callable
var _elapsed := 0.0
var _dot_timer := 0.0
var _dots := 0
var _called := false
var _waits_for_world := false


## Starts loading scene_path in the background. When it is loaded, on_ready is called with the PackedScene.
func start(scene_path: String, on_ready: Callable) -> void:
	_path = scene_path
	_on_ready = on_ready
	_waits_for_world = true
	ResourceLoader.load_threaded_request(scene_path)


func _ready() -> void:
	spinner.texture = Icons.make("settings", 128, Color(1, 1, 1, 0.9))
	spinner.pivot_offset = spinner.size * 0.5
	bar.value = 0


func _process(delta: float) -> void:
	_elapsed += delta
	spinner.rotation += delta * 3.0

	_dot_timer += delta
	if _dot_timer >= DOT_TIME:
		_dot_timer = 0.0
		_dots = (_dots + 1) % 4
		label.text = "Yuklanmoqda" + ".".repeat(_dots)

	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(_path, progress)
	if not _called:
		var loaded := 0.0
		if progress.size() > 0:
			loaded = float(progress[0])
		# The bar never reaches 100% before the loading has really finished.
		bar.value = minf(loaded, _elapsed / MIN_SHOW_TIME) * 100.0

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_called = true
			var packed := ResourceLoader.load_threaded_get(_path) as PackedScene
			_on_ready.call(packed)
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Could not load: " + _path)
			queue_free()
			return

	if _called and _elapsed >= MIN_SHOW_TIME and (not _waits_for_world or GameState.world_ready):
		bar.value = 100.0
		queue_free()
