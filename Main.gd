extends Control

@onready var wasm = Wasm.new()
@onready var memory = WasmMemory.new()
var image = Image.new()
var keys = { KEY_ENTER: 13, KEY_BACKSPACE: 127, KEY_SPACE: 32, KEY_LEFT: 0xac, KEY_RIGHT: 0xae, KEY_UP: 0xad, KEY_DOWN: 0xaf, KEY_CTRL: 0x80+0x1d, KEY_ALT: 0x80+0x38, KEY_ESCAPE: 27, KEY_TAB: 9, KEY_SHIFT: 16 }

func _ready():
	for k in range(KEY_A, KEY_Z + 1).map(func(x): return { x: x + 32 }) + range(KEY_0, KEY_9 + 1).map(func(x): return { x: x }) + range(KEY_F1, KEY_F12 + 1).map(func(x): return { x: 187 + x - KEY_F1 }): keys.merge(k)
	image = Image.create(640, 400, false, Image.FORMAT_RGBA8)
	$TextureRect.texture.set_image(image)
	memory.grow(108)
	var imports = {
		"functions": { "js.js_console_log": [self, "stdout"], "js.js_draw_screen": [self, "draw_screen"], "js.js_milliseconds_since_start": [Time, "get_ticks_msec"], "js.js_stdout": [self, "stdout"], "js.js_stderr": [self, "stderr"] },
		"memory": memory,
	}
	wasm.load(FileAccess.get_file_as_bytes("res://doom.wasm"), imports)
	wasm.function("main", [0, 0])

func _process(_delta):
	wasm.function("doom_loop_step", [])

func _input(event):
	if event is InputEventKey and !event.is_echo(): wasm.function("add_browser_event", [int(!event.is_pressed()), keys.get(event.keycode, 0)])

func draw_screen(offset):
	image.set_data(640, 400, false, Image.FORMAT_RGBA8, memory.seek(offset).get_data(640 * 400 * 4)[1])
	$TextureRect.texture.update(image)

func stdout(offset, length):
	print(memory.seek(offset).get_utf8_string(length))

func stderr(offset, length):
	push_warning(memory.seek(offset).get_utf8_string(length))
