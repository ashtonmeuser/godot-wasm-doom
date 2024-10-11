# Porting Doom to Godot in 34 Lines of GDScript

<p align="center">
<img width="820" alt="Godot Wasm Doom" src="https://github.com/user-attachments/assets/2e29fc23-d591-4931-bffa-cc266f5e6de8">
</p>

Using a [WebAssembly Doom port](https://diekmann.github.io/wasm-fizzbuzz/doom/) and the [Godot Wasm addon](https://github.com/ashtonmeuser/godot-wasm), the 1993 classic Doom can be run and rendered in the [Godot game engine](https://godotengine.org/).

This article documents the porting process. The resulting source code can be found [here](https://github.com/ashtonmeuser/godot-wasm-doom).

## Background

The title of this article is somewhat misleading. The entirety of Doom cannot be implemented in a few dozen lines of GDScript. Instead, we'll be running and rendering a precompiled WebAssembly port of Doom within Godot.

WebAssembly, or Wasm, is an incredibly powerful and interesting technology. Originally developed for the web, it is now finding use outside of the browser. The greatest advantages of Wasm, in my opinion, are the following:
1. Incredible speed (approaching native implementation).
1. Safe and sandboxed runtime environment.
1. Compilation target for many languages (Rust, Go, C, etc.).

The [Godot Wasm FAQ](https://github.com/ashtonmeuser/godot-wasm/wiki/FAQs#why-would-i-use-wasm-in-godot) provides some more insight as to why one would want to use WebAssembly within Godot.

To take advantage of Wasm's benefits, I created the [Godot Wasm addon](https://github.com/ashtonmeuser/godot-wasm) for the Godot game engine. This addon enables compiling and initializing Wasm modules, accessing exported functions and globals from Godot, providing imports implemented in GDScript, and accessing Wasm module memory. The latest release as of this writing, [Godot Wasm v0.3.4](https://github.com/ashtonmeuser/godot-wasm/releases/tag/v0.3.4-godot-4), includes type inference for Wasm import and export functions. This makes the addon far more compatible with existing Wasm modules.

Throughout the creation of the Godot Wasm addon, one question kept nagging at me: **Can it run Doom?**

## Acknowledgement

This project owes a huge thanks to the incredible work of [Cornelius Diekmann](https://github.com/diekmann). Their [WebAssembly from Scratch](https://github.com/diekmann/wasm-fizzbuzz) project provided great insight into the porting process, the underlying Doom Wasm module, and clear guidance on running the module. Diekmann's [Wasm Doom example](https://diekmann.github.io/wasm-fizzbuzz/doom/) will be referenced throughout this write-up.

This article is written in a similar fashion to Diekmann's with the hope that somebody finds it similarly educational.

## Getting Started

The first thing we'll need is the Doom WebAssembly module. By inspecting the sources of [Diekmann's Wasm Doom example](https://diekmann.github.io/wasm-fizzbuzz/doom/), we can find and download the *doom.wasm* module (available [here](https://diekmann.github.io/wasm-fizzbuzz/doom/doom.wasm)).

Next, we'll need to install the [Godot game engine](https://godotengine.org/download/). Version 4.2.1 was used for this project.

Now we'll need to install the [Godot Wasm addon](https://github.com/ashtonmeuser/godot-wasm). This is available via the [Godot Asset Library](https://godotengine.org/asset-library/asset/2535). Further instructions regarding getting started with the Godot Wasm addon can be found [here](https://github.com/ashtonmeuser/godot-wasm/wiki/Getting-Started#installation).

With the addon installed, let's create a simple Godot project. Open Godot, create a new project, add a single [`MarginContainer` node](https://docs.godotengine.org/en/stable/classes/class_margincontainer.html), and anchor it as a Full Rect to occupy the entire view. When first running the project, you'll need to confirm that this scene is to be used as the main scene.

<p align="center">
<img width="896" alt="Create main container" src="https://github.com/ashtonmeuser/godot-wasm-doom/assets/7253863/085c8d1d-0897-4568-aa75-c1bcda98ca40">
</p>

Copy the downloaded *doom.wasm* file to the root directory of your Godot project.

Let's dive into the code. Attach a script to your `MarginContainer` and save it as *Main.gd*. Create an [`@onready`](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#onready-annotation) variable that will hold our Godot Wasm `Wasm` instance (see [`Wasm` class documentation](https://github.com/ashtonmeuser/godot-wasm/wiki/Class-Documentation:-Wasm)).

```gdscript
@onready var wasm = Wasm.new()
```

In our `_ready()` function, we'll need to load and compile the Wasm module binary (see [Usage guide](https://github.com/ashtonmeuser/godot-wasm/wiki/Getting-Started#usage)).

```gdscript
var file = FileAccess.get_file_as_bytes("res://doom.wasm")
wasm.compile(file)
```

Run the project and ensure there are no errors thrown.

Inspecting the *doom.wasm* module allows us to gain a better understanding of the exposed API. In the terminal, a similar inspection can be performed with the [Wasmer CLI](https://docs.wasmer.io/install) via `wasmer inspect doom.wasm`.

```gdscript
var info = wasm.inspect()
print(info)
```

This should print the following (formatted for clarity).

```json
{
   "import_functions": {
      "js.js_console_log": [[2, 2], []],
      "js.js_draw_screen": [[2], []],
      "js.js_milliseconds_since_start": [[], [2]],
      "js.js_stderr": [[2, 2], []],
      "js.js_stdout": [[2, 2], []]
   },
   "export_globals": {
      "__data_end": [2, false],
      "__heap_base": [2, false]
   },
   "export_functions": {
      "I_FinishUpdate": [[], []],
      "I_GetTime": [[], [2]],
      "I_InitGraphics": [[], []],
      "I_ReadScreen": [[2], []],
      "I_SetPalette": [[2], []],
      "I_ShutdownGraphics": [[], []],
      "I_StartFrame": [[], []],
      "I_StartTic": [[], []],
      "I_UpdateNoBlit": [[], []],
      "___errno_location": [[], [2]],
      "__fpclassifyl": [[2, 2], [2]],
      "__lock": [[2], []],
      "__lockfile": [[2], [2]],
      "__signbitl": [[2, 2], [2]],
      "__stdio_close": [[], []],
      "__stdio_seek": [[], []],
      "__syscall3": [[2, 2, 2, 2], [2]],
      "__toread": [[2], [2]],
      "__uflow": [[2], [2]],
      "__unlock": [[2], []],
      "__unlockfile": [[2], []],
      "access": [[2, 2], [2]],
      "add_browser_event": [[2, 2], []],
      "close": [[2], [2]],
      "copysignl": [[2, 2, 2, 2, 2], []],
      "doom_loop_step": [[], []],
      "exit": [[2], []],
      "fabsl": [[2, 2, 2], []],
      "fmodl": [[2, 2, 2, 2, 2], []],
      "fopen": [[2, 2], [2]],
      "free": [[2], []],
      "frexpl": [[2, 2, 2, 2], []],
      "fstat": [[2, 2], [2]],
      "getenv": [[2], [2]],
      "lseek": [[2, 2, 2], [2]],
      "main": [[2, 2], [2]],
      "malloc": [[2], [2]],
      "mbrtowc": [[2, 2, 2, 2], [2]],
      "mbsinit": [[2], [2]],
      "open": [[2, 2, 2], [2]],
      "read": [[2, 2, 2], [2]],
      "realloc": [[2, 2], [2]],
      "scalbn": [[3, 2], [3]],
      "scalbnl": [[2, 2, 2, 2], []],
      "strerror": [[2], [2]],
      "usleep": [[2], [2]],
      "wctomb": [[2, 2], [2]],
      "write": [[2, 2, 2], [2]]
   },
   "memory": {
      "min": 6684672,
      "max": 4294901760
   }
}
```

That's a lot of information! Fret not; we'll be ignoring most of this. For now, take note of the `import_functions` and `memory` properties.

Let's forge ahead and try to instantiate the Wasm module.

```gdscript
wasm.instantiate({})
```

You should see the following error:

> Main.gd:10 @ _ready(): Godot Wasm: Missing import function js.js_console_log  
&lt;C++ Source>   src/godot-wasm.cpp:330 @ instantiate()  
&lt;Stack Trace>  Main.gd:10 @ _ready()

Instantiation of our Wasm module is failing because we're not providing the expected imports.

## Satisfying Imports

Referring back to the inspection of the module, we can see five import functions. If you inspect the module via the Wasmer CLI tool, you'll also note that the module requires a memory import.

By viewing the *main.js* source of Diekmann's example, we can confirm that the following import functions are provided:
1. `js.js_console_log`
1. `js.js_stdout`
1. `js.js_stderr`
1. `js.js_milliseconds_since_start`
1. `js.js_draw_screen`

The object returned by `wasm.inspect()` represents each import function signature as an array of two arrays. The first array represents the parameter types, and the second represents the return values. Empty arrays represent no function parameters and a `void` return type, respectively. The types use Godot's [`Variant.Type` enumeration](https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html#enum-globalscope-variant-type). As an example, the `js.js_console_log` import function takes two integers as arguments and returns no value.

First, we'll satisfy function imports with stubbed-out functions. In your *Main.gd* file, add the following functions:

```gdscript
func console_log(offset, length):
	print("console_log: %s" % [offset, length])

func stdout(offset, length):
	print("stdout: %s %s" % [offset, length])

func stderr(offset, length):
	print("stderr: %s %s" % [offset, length])

func milliseconds_since_start():
	print("milliseconds_since_start")
	return 0

func draw_screen(offset):
	print("draw_screen: %s" % offset)
```

These functions don't implement the logic they're expected to yet. However, we'll at least be able to tell when the Wasm module is calling an imported function.

Let's provide these functions to the module as imports during instantiation. Each import function is represented by an array containing a Godot `Object` and the name of the method to call. We're using `self` as the target `Object` because each of the targeted methods is defined in the same file. Once again, in `_ready()`, add the following:

```gdscript
var imports = {
	"functions": {
		"js.js_console_log": [self, "console_log"],
		"js.js_draw_screen": [self, "draw_screen"],
		"js.js_milliseconds_since_start": [self, "milliseconds_since_start"],
		"js.js_stdout": [self, "stdout"],
		"js.js_stderr": [self, "stderr"]
	}
}
wasm.instantiate(imports)
```

We should now see a new error.

> Main.gd:17 @ _ready(): Godot Wasm: Missing import memory  
&lt;C++ Source>   src/godot-wasm.cpp:348 @ instantiate()  
&lt;Stack Trace>  Main.gd:17 @ _ready()

We'll now need to satisfy the memory import requirement. WebAssembly modules can either define their own internal (often exported) memory, which is created automatically by the runtime on instantiation, or import an external memory resource. In the case of our *doom.wasm* module, the latter applies.

Create another `@onready` variable at the top level of your main script.

```gdscript
@onready var memory = WasmMemory.new()
```

The external memory resource must meet some minimum size requirements. Referring back to our inspection, we can see that our memory must be a minimum of 6684672 bytes in size. Wasm module memory is not typically dealt with in bytes but rather *pages*, equivalent to 65536 bytes each. With this in mind, our memory resource must be a minimum of 102 (6684672 / 65536) pages. See the [Memory Operations guide](https://github.com/ashtonmeuser/godot-wasm/wiki/Memory-Operations) and [`WasmMemory` class documentation](https://github.com/ashtonmeuser/godot-wasm/wiki/Class-Documentation:-WasmMemory) for more information.

Let's expand our memory resource. We'll follow Diekmann's example and allocate 108 pages of memory. In `_ready()` and before instantiating our module, add the following:

```gdscript
memory.grow(108)
```

You can confirm the size of the memory via `memory.inspect()`.

Finally, let's modify our import object to include the memory and instantiate the module.

```gdscript
var imports = {
	"functions": {
		"js.js_console_log": [self, "console_log"],
		"js.js_draw_screen": [self, "draw_screen"],
		"js.js_milliseconds_since_start": [self, "milliseconds_since_start"],
		"js.js_stdout": [self, "stdout"],
		"js.js_stderr": [self, "stderr"]
	},
	"memory": memory
}
wasm.instantiate(imports)
```

The script should run without throwing any errors.

As an aside, the compilation and instantiation steps can be completed in one call with the [`load()` method](https://github.com/ashtonmeuser/godot-wasm/wiki/Class-Documentation:-Wasm#error-load--packedbytearray-bytecode-dictionary-imports-), which takes both the binary and import object as arguments.

```gdscript
wasm.load(file, imports)
```

## Initialize Doom, Part 1

Let's attempt to get Doom running. Referring to the Wasm module inspection from earlier, take note of the exported function `main()`. Sure enough, Diekmann's implementation calls this function first to initialize Doom. It takes two integers as arguments and returns an integer. The argument values go unused, and we'll ignore the return value.

To call a Wasm export function, use the [`function()` method](https://github.com/ashtonmeuser/godot-wasm/wiki/Class-Documentation:-Wasm#variant-function--string-name-array-args-). An array containing our arguments must be provided.

```gdscript
wasm.function("main", [0, 0])
```

> [!Note]
> The following section documents overcoming a since-fixed error with the Wasmer runtime (see https://github.com/wasmerio/wasmer/issues/4565). With the release of Wasmer [v4.3.5](https://github.com/wasmerio/wasmer/releases/tag/v4.3.5) and Godot Wasm [v0.3.7](https://github.com/ashtonmeuser/godot-wasm/releases/tag/v0.3.7-godot-4), this issue can be ignored. Doom is compatible with Godot Wasm used as either a [Godot addon](https://godotengine.org/asset-library/asset/2535) or Godot module and using either the Wasmer or Wasmtime runtimes. Skip to [Initialize Doom, Take 2](#initialize-doom-take-2) to continue porting Doom.

<details>

<summary>Debugging Wasmer Runtime Error</summary>

### Wasmer Runtime Error

We should see some output as well as an error thrown.

> console_log: 7077952 59  
console_log: 7078072 55

> Main.gd:21 @ _ready(): Godot Wasm: Failed calling function main  
&lt;C++ Source>   src/godot-wasm.cpp:458 @ function()  
&lt;Stack Trace>  Main.gd:21 @ _ready()

Our `main()` function failed; let's dive a little deeper.

### Implement Logging Imports

When calling our `main()` export function, the Wasm module called the `console_log()` import function twice before the invocation failed. We'll implement some basic logging to aid in debugging.

Some background regarding Wasm memory is important at this stage of the journey. WebAssembly memory is simply a contiguous buffer or array of bytes. As we saw earlier, this array can be expanded or grown. Memory is very important and frequently used with Wasm because of the limited API that can be exposed via import/export functions, also known as the Foreign Function Interface, or FFI. Only the following four fundamental data types can be directly exposed via Wasm import/export functions:
- 32-bit integer
- 64-bit integer
- 32-bit floating point
- 64-bit floating point

This begs the question: how do we transfer a string between Godot (the host) and the Wasm module (the guest)?

The answer is to take advantage of the module's memory. The Wasm module can write a string to memory in an agreed-upon format, and the host, i.e., Godot, can later read it. The host can be instructed where in memory to begin reading and how many bytes to read with simple integer values passed via import/export functions.

Godot Wasm's `WasmMemory` class (see [`WasmMemory` class documentation](https://github.com/ashtonmeuser/godot-wasm/wiki/Class-Documentation:-WasmMemory)) inherits from Godot's own [`StreamPeer` class](https://docs.godotengine.org/en/stable/classes/class_streampeer.html) and closely mirrors Godot's [`StreamPeerBuffer` class](https://docs.godotengine.org/en/stable/classes/class_streampeerbuffer.html#class-streampeerbuffer). This allows us to easily read raw bytes in a variety of contexts.

We now have the context required to implement our logging functions. We've already seen that the `js.js_console_log` import function accepts two integers as arguments. These integers represent the data offset, i.e., starting point and the data length, respectively. We'll use these to read the data to be printed. Referring to Diekmann's example, we expect strings to be stored as UTF-8. Reimplement the `stdout` and `console_log` GDScript functions as follows:

```gdscript
func stdout(offset, length):
	memory.seek(offset)
	var message = memory.get_utf8_string(length)
	print(message)

func console_log(offset, length):
	stdout(offset, length) # Reuse stdout implementation
```

The `seek()` method moves the cursor to a memory offset, while `get_utf8_string()` (inherited from `StreamPeer`) reads a UTF-8 string from raw bytes.

Running the project again reveals the expected data printed to the console before `main()` fails.

> Hello, World, from JS Console! Answer=42 (101010 in binary)  
Hello, world from rust! 🦀🦀🦀 (println! working)

Referencing Diekmann's example, we see the first two lines match. We can surmise that the error is happening before the following expected next line.

> Starting D_DoomMain

### Fruitlessly Debugging

We're expecting to see logs from the initialization of Doom. Firstly, we expect to see "Starting D_DoomMain". Let's investigate the cause of the `main()` function invocation error.

At this point, we have to get into the gritty details of the [Godot Wasm addon](https://github.com/ashtonmeuser/godot-wasm). We'll abandon the prepackaged addon from the Asset Library and compile the addon ourselves in order to debug.

Clone the repo and follow Godot Wasm's [Development guide](https://github.com/ashtonmeuser/godot-wasm/wiki/Development).

Let's modify the addon source. In *src/godot-wasm.cpp*, modify the `function()` method (permalink [here](https://github.com/ashtonmeuser/godot-wasm/blob/7ad22dd84ff05c99deac2b9620c8bfa60aaa2fc1/src/godot-wasm.cpp#L426)) to the following:

```cpp
wasm_trap_t* trap = wasm_func_call(func, &f_args, &f_results);
if (trap) {
  wasm_message_t message;
  wasm_trap_message(trap, &message);
  PRINT_ERROR(message.data);
  wasm_trap_delete(trap);
}
```

The above conditional reads the message from a returned `wasm_trap_t` pointer. Hopefully, this message provides some clarity.

Rebuild the Godot Wasm addon following the wiki Development guide.

```sh
scons target=template_release platform=linux
```

Populate the addon in the Godot Wasm Doom project (found in *GODOT_DOOM_DIR/addons/godot-wasm*) with the binaries generated by the Godot Wasm build step (found in *GODOT_WASM_DIR/addons/godot-wasm*). It may be convenient to create a symbolic link from the Doom project to the addon project to automatically get updated binaries. This can be accomplished on UNIX platforms by deleting the existing addons directory in the Doom project and running `ln -s PATH/TO/GODOT_WASM_DIR/addons PATH/TO/GODOT_DOOM_DIR/addons`.

Running the project again results in a new error being logged.

> Main.gd:21 @ _ready(): Godot Wasm: out of bounds memory access  
&lt;C++ Source>   src/godot-wasm.cpp:463 @ function()  
&lt;Stack Trace>  Main.gd:21 @ _ready()

The Wasm module or underlying runtime seems to be accessing memory outside of the allocated bounds.

Let's try allocating more memory. Using `memory.grow()`, allocate an assortment of memory sizes up to the maximum of 65536 pages. All values fail, with the final, largest value producing the following error:

> Main.gd:21 @ _ready(): Godot Wasm: unreachable  
&lt;C++ Source>   src/godot-wasm.cpp:463 @ function()  
&lt;Stack Trace>  Main.gd:21 @ _ready()

No luck. Revert the memory size to 108 pages. Unfortunately, the error messages do not provide many clues to go on. However, we've got another trick up our sleeve.

### Changing the WebAssembly Runtime

Godot Wasm supports both the [Wasmer](https://wasmer.io/) and [Wasmtime](https://wasmtime.dev/) runtimes. By default, Wasmer is used. As of writing this (2024-03-06), the prepackaged Godot Wasm addon, e.g., via Godot Asset Library, uses the default Wasmer runtime.

Let's go ahead and compile Godot Wasm again, this time using the Wasmtime runtime. Refer to the [Changing Runtime documentation](https://github.com/ashtonmeuser/godot-wasm/wiki/Development#changing-runtime). The following is compiling for Linux; replace `platform` as required, e.g., `windows`, `macos`.

```sh
scons target=template_release platform=linux wasm_runtime=wasmtime
```

Unless using a symbolic link between projects, package the addon binaries once again.

Note that compiling with the Wasmtime runtime on Windows is failing static linking as of Godot Wasm v0.3.4. In addition to the built Godot Wasm binaries, you'll need to copy *wasmtime.dll* to *GODOT_DOOM_DIR/addons/godot-wasm/bin/windows* and to update *godot-wasm.gdextension* to include the Wasmtime DLL as a dependency. Refer to the [*addons* directory of the project source](https://github.com/ashtonmeuser/godot-wasm-doom/tree/b4e80759a08cf4078b7bfafcb9662ec99f3c5ad8/addons/godot-wasm). This issue is now captured in [godot-wasm#65](https://github.com/ashtonmeuser/godot-wasm/issues/65).

Running the Godot Wasm Doom project now produces a plethora of STDOUT output and no errors! Success!

It seems as though there may be a deficiency with the Wasmer runtime (to be explored further).

</details>

## Initialize Doom, Part 2

Running the project once again produces the following (truncated) logs:

> Hello, World, from JS Console! Answer=42 (101010 in binary)  
Hello, world from rust! 🦀🦀🦀 (println! working)  
Starting D_DoomMain  
Triggering a printf  
Doom's screen is 320x200  
mallocing 12 bytes at 7078176  
...  
mallocing 140 bytes at 7078320  
startskill 2  deathmatch: 0  startmap: 1  startepisode: 1  
player 1 of 1 (1 nodes)  
S_Init: Setting up sound.  
stderr: 1047440 29  
HU_Init: Setting up heads up display.  
ST_Init: Init status bar.  
I_InitGraphics (TODO)

Using Diekmann's example as our guide, this is exactly the output we're expecting. Doom is successfully initializing!

## Implementing Additional Imports

In the above logs, we can see one call to the unimplemented `stderr()` import function.

> stderr: 1047440 29

Let's go ahead and implement a simple error logging function similar to what we did for `console_log()` and `stdout()` to properly satisfy the `js.js_stderr` import function. We'll push error messages printed from Doom to Godot's warning-level logging. This will draw attention to Doom errors while reserving Godot's error-level logging for critical errors encountered while running the Wasm module.

```gdscript
func stderr(offset, length):
	memory.seek(offset)
	var message = memory.get_utf8_string(length)
	push_warning(message)
```

Running the project again should produce a single warning.

> Main.gd:42 @ stderr(): S_Init: default sfx volume 8  
&lt;C++ Source>   core/variant/variant_utility.cpp:1111 @ push_warning()  
&lt;Stack Trace>  Main.gd:42 @ stderr()  
Main.gd:21 @ _ready()

Doom threw an error relating to sound effects. Sound effects were not implemented in this port of Doom, so we'll go ahead and ignore this supposed error.

Next, let's implement the `js.js_milliseconds_since_start` import function. In the *Main.gd* GDScript file, modify the `milliseconds_since_start()` method to the following:

```gdscript
func milliseconds_since_start():
	return Time.get_ticks_msec()
```

This uses the [`Time` singleton](https://docs.godotengine.org/en/stable/classes/class_time.html) to return the number of milliseconds since the program was started.

As an aside, we can shorten our script by passing the `Time` singleton object and the `get_ticks_msec()` method name directly as the import. We can now delete our custom `milliseconds_since_start()` method.

```gdscript
var imports = {
	"functions": {
		...
		"js.js_milliseconds_since_start": [Time, "get_ticks_msec"],
		...
	}
}
```

## Calling the Game Loop

Referring once again to Diekmann's example, we can see that there are only three export functions used.
1. `main`
1. `doom_loop_step`
1. `add_browser_event`

Let's proceed to calling the main Doom game loop. At the end of the `_ready()` function in your *Main.gd* script, call the `doom_loop_step()` export function.

```gdscript
wasm.function("doom_loop_step", [])
```

Running the project, we should see exactly one new log line appear.

> BASETIME initialized to 472

If we still had a `print()` call in our `milliseconds_since_start()`, we'd see that the Doom main loop function invoked the `js.js_milliseconds_since_start` import function. This crossed the FFI barrier from the Wasm module (guest) to Godot (host) and ingested the returned value. The printed value (in this case, 472) is the number of milliseconds that Godot's `Time` singleton has recorded since the program was started.

The game loop should not just be called once. Rather, it should be called repeatedly, ticking the game along with each invocation. Let's use Godot's `_process()` method to call Doom's game loop. Remove the call to `doom_loop_step` in `_ready()` and add the following to your script:

```gdscript
func _process(_delta):
	wasm.function("doom_loop_step", [])
```

Running the project again, we should see repeated calls to the `js.js_draw_screen` import function.

> ST_Init: Init status bar.  
I_InitGraphics (TODO)  
BASETIME initialized to 1262  
draw_screen: 5278204  
draw_screen: 5278204  
draw_screen: 5278204  
draw_screen: 5278204  
...

We're ready to implement our final (and most complex) import function, `js.js_draw_screen`!

## Rendering Doom

Per Diekmann's write-up, there is a custom rendering shim applied on top of classic Doom implemented in Rust. This simplifies our drawing/rendering implementation substantially, as it is outputting standard [RGBA8888](https://en.wikipedia.org/wiki/RGBA_color_model#RGBA8888) (also called RGBA8). This format consists of four color channels, each with a bit depth of one byte or eight bits. Godot supports this format via the [`FORMAT_RGBA8` flag](https://docs.godotengine.org/en/stable/classes/class_image.html#enumerations).

We know from Doom's logs that the screen dimensions are defined as 320x200.

We're finally getting to some graphical work in Godot. Click the 2D view and ensure the previously added `MarginContainer` is set to anchor mode Full Rect. Add a [`TextureRect`](https://docs.godotengine.org/en/stable/classes/class_texturerect.html) to the `MarginContainer`. Select the `TextureRect`, and on the right side of the screen, set the *Texture* property with a new [`ImageTexture`](https://docs.godotengine.org/en/stable/classes/class_imagetexture.html).

<p align="center">
<img width="1092" alt="Add TextureRect" src="https://github.com/ashtonmeuser/godot-wasm-doom/assets/7253863/ed54c6d3-8fcb-4c9e-8837-4d253dd6dfb8">
</p>

Back to the code. We'll need to instantiate an [`Image`](https://docs.godotengine.org/en/stable/classes/class_image.html) that holds the graphical data created by Doom. The image's data will be flashed to the `ImageTexture` created above. At the top of *Main.gd*, with the `@onready` variables, add the following:

```gdscript
var image = Image.new()
```

We'll need to create our `Image` and set it as the image value of the `ImageTexture`. Add the following anywhere in the `_ready()` function:

```gdscript
image = Image.create(320, 200, false, Image.FORMAT_RGBA8)
$TextureRect.texture.set_image(image)
```

We're now ready to draw the screen. Taking a look at `js.js_draw_screen`, we see that a single integer parameter is provided. This value points to the offset in memory at which graphical data begins. No length parameter is provided, as we can calculate the required space manually based on screen size, color channels, and channel bit depth (in bytes). We should anticipate reading SCREEN_SIZE × N_CHANNELS × BIT_DEPTH bytes, or 320 × 200 × 4 × 1 = 256,000 bytes.

As with retrieving strings from Wasm memory, we'll need to `seek()` to the correct offset in memory and read the data using one of the methods provided by the `StreamPeer` interface. This time, instead of reading a UTF-8 string, we'll read the raw bytes from memory as an array. The [`get_data()` method](https://docs.godotengine.org/en/stable/classes/class_streampeer.html#class-streampeer-method-get-data) is perfect for this. Take note that the return value of `get_data` is an array with two values: an error code and the raw data array itself. Replace our placeholder `draw_screen()` method with the following:

```gdscript
func draw_screen(offset):
	memory.seek(offset)
	var data = memory.get_data(320 * 200 * 4)
	image.set_data(320, 200, false, Image.FORMAT_RGBA8, data[1])
	$TextureRect.texture.update(image)
```

Running the project, we'll get our first glimpse of Doom!

<p align="center">
<img width="688" alt="First glimpse of Doom" src="https://github.com/ashtonmeuser/godot-wasm-doom/assets/7253863/1698e3b2-9541-4162-8749-8644bfa7d90a">
</p>

Something doesn't look quite right. In debugging this graphical issue with reference to Diekmann's example, it's clear that we should be using screen dimensions of 640x400. I'm not entirely sure where the discrepancy between the reported and actual resolutions comes from. Modify the Image creation and `draw_screen()` methods to reflect the new 640x400 resolution. Run the project.

<p align="center">
<img width="688" alt="Fixed Doom rendering" src="https://github.com/ashtonmeuser/godot-wasm-doom/assets/7253863/90bc600d-16d4-4aaf-8b93-6a95921cd5bd">
</p>

Success! Doom should be correctly displayed in all its pixelated glory, slowly cycling through three title/demo screens.

## Keyboard Input

We've implemented all import functions. The final export function, `add_browser_event`, remains. This function is used to forward keyboard input to the Wasm module.

As indicated by `wasm.inspect()`, the `add_browser_event()` export function receives two integer arguments and returns void. The arguments are as follows:
1. A boolean (represented as an integer) that denotes whether a key was released or pressed. This boolean is misleading in that a value of `false` or 0 represents a key pressed, while `true` or 1 represents a key released.
1. An integer key code that denotes the key that was pressed or released.

Let's grab some input. First, let's create a simple placeholder function used to explore input events in Godot.

```gdscript
func _input(event):
	if event is InputEventKey and !event.is_echo():
		var pressed = event.is_pressed()
		var keycode = event.keycode
		print("Keycode %s pressed? %s" % [keycode, pressed])
```

The [`_input()` method](https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-private-method-input) is called on frames during which input was detected. We're first making sure that the event is a keyboard event that was not [echoed](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html#echo-events). Next, we're checking to see if the key was pressed or released. Running the program and pressing the Enter key will output the following:

> Keycode 4194309 pressed? true  
Keycode 4194309 pressed? false

The key code value above is a bespoke Godot value based on the [`Key` enumeration](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enumerations). Printing `Key.KEY_ENTER` will produce the same value. This value does not match that expected by Doom, which uses DOS key codes, e.g., 13 for Enter. We'll need to map expected keys from Godot's values to Doom's. Informed by Diekmann's example, let's include a simple, incomplete `Dictionary` to map key codes at the top of *Main.gd*. Each `Dictionary` key represents a Godot key code, while their values represent the corresponding Doom/DOS key codes.

```gdscript
var keys = { KEY_ENTER: 13, KEY_BACKSPACE: 127, KEY_SPACE: 32, KEY_LEFT: 0xac, KEY_RIGHT: 0xae, KEY_UP: 0xad, KEY_DOWN: 0xaf, KEY_CTRL: 0x80+0x1d, KEY_ALT: 0x80+0x38, KEY_ESCAPE: 27, KEY_TAB: 9, KEY_SHIFT: 16 }
```

This captures many of the required keys but notably misses numeric, alphabetic, and function keys.

Let's modify our `_input()` method to display the mapped keys. We will map all unknown keys to key code 0, which Doom ultimately ignores. We'll also invert the value of `is_pressed()` and cast it to an integer to match Doom's API.

```gdscript
func _input(event):
	if event is InputEventKey and !event.is_echo():
		var pressed = int(!event.is_pressed())
		var keycode = keys.get(event.keycode, 0)
		print("Keycode %s pressed? %s" % [keycode, pressed])
```

Running the program and pressing the Enter key will now produce the following:

> Keycode 13 pressed? 0  
Keycode 13 pressed? 1

Finally, let's forward that mapped value to Doom via the `add_browser_event` export function.

```gdscript
func _input(event):
	if event is InputEventKey and !event.is_echo():
		var pressed = int(!event.is_pressed())
		var keycode = keys.get(event.keycode, 0)
		wasm.function("add_browser_event", [pressed, keycode])
```

When running the program, you should now be able to interact with Doom! Note that we're using the original [Doom keybinds](https://www.starehry.eu/download/action3d/docs/Doom-Manual.pdf), e.g., CTRL: shoot, Space: use/open, Enter: select.

<p align="center">
<img width="688" alt="Interacting with Doom" src="https://github.com/ashtonmeuser/godot-wasm-doom/assets/7253863/fe5d2d1f-c23c-4c42-9c97-623fcb4ac860">
</p>

Lastly, let's implement the remaining keybinds. The following ranges of Godot key codes will be mapped to Doom's expected values.
- [65, 90]: Alphabetic ASCII key codes that must be mapped to their lowercase selves, i.e., add 32.
- [48, 57]: Numeric keys whose values can be passed straight through to Doom, i.e., Godot and DOS key codes values match.
- [4194332, 4194343]: Function keys F1 through F12. These should be mapped to values 187 through 198.

We'll use some array mapping magic to map each range member to a `Dictionary` with a single key equal to the Godot key code and a corresponding value equal to the Doom/DOS key code. This format matches that defined by the previously declared `keys` variable. For each `Dictionary`, we can then use the [`merge()` method](https://docs.godotengine.org/en/stable/classes/class_dictionary.html#class-dictionary-method-merge) to include them in our mapping. Add the following anywhere in `_ready()`.

```gdscript
var alphabetic = range(KEY_A, KEY_Z + 1).map(func(x): return { x: x + 32 })
var numeric = range(KEY_0, KEY_9 + 1).map(func(x): return { x: x })
var function = range(KEY_F1, KEY_F12 + 1).map(func(x): return { x: 187 + x - KEY_F1 })
for k in alphabetic + numeric + function:
	keys.merge(k)
```

With that, we should receive alphabetic, numeric, and function key events. We can test this out by running the program, starting a new game of Doom, and pressing the 1 key. Our character should switch to bare hands. Pressing 2 returns to the default weapon.

## Wrapping Up

Done and done. I hope this exploration was as entertaining and educational for you as it was for me. Additionally, I hope this convinces you of the incredible power of WebAssembly! Because of the low performance requirements of Wasm and the fact that we've rendered the game to a simple `ImageTexture`, this is highly adaptable. For example, imagine walking up to a virtual monitor running a fully-functional version of Doom inside a 3D game!

Some additional steps are required to export this project. See the [Exporting guide](https://github.com/ashtonmeuser/godot-wasm/wiki/Exporting-Godot-Project) for more information.

The final resultant source code for this project is available [here](https://github.com/ashtonmeuser/godot-wasm-doom). Several of the functions defined above have been altered for brevity, although their logic remains the same.

## Final Remarks

As a personal plug, please go star the [Godot Wasm](https://github.com/ashtonmeuser/godot-wasm) project on GitHub. Feel free to open an issue or PR!

Call for aid: I'm by no means an expert with Windows and am struggling with statically linking the Wasmtime library as described by [godot-wasm#65](https://github.com/ashtonmeuser/godot-wasm/issues/65). I'd love a hand with this one!
