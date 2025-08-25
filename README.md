# Linux Tray Bridge for Compose Native Tray

This module provides the Linux tray backend used by Compose Native Tray. It is a thin Go library compiled as a shared object (libsystray.so) and consumed from Kotlin/JVM via JNA.

It is a fork of https://github.com/energye/systray that was refactored and packaged to be used as a native tray bridge in Compose Native Tray (Compose Multiplatform Desktop). GTK and legacy XEmbed tray code are removed in favor of a StatusNotifier/AppIndicator implementation over DBus.

- Upstream base: getlantern/systray → energye/systray → this fork
- Purpose here: produce a small, self-contained Linux .so with an exported C API that maps directly to Kotlin/JNA in Compose Native Tray

Screenshots of the final integration live in the repository root under `screenshots/`.

## What you get

- Linux-only, DBus-based system tray implementation (StatusNotifier/AppIndicator)
- Click, double-click, and right-click support
- Dynamic menu building, submenus, separators, checkable items, show/hide/enable/disable, and per-item icons
- A stable C ABI exported by libsystray.so for use with JNA from Kotlin

## Where this library is used

Compose Native Tray loads this library on Linux through JNA. A prebuilt binary is included:

- Prebuilt .so: `src/commonMain/resources/linux-x86-64/libsystray.so`

If you replace or rebuild the library, ensure the replacement matches the exported API described below.

## Building from source

Prerequisites:
- Linux
- Go with CGO enabled (CGO_ENABLED=1)
- A C toolchain (e.g., gcc)

Options:

1) With Makefile (recommended)

```bash
cd linuxlibnew
make build-so
```

This produces optimized artifacts under `linuxlibnew/dist/`:
- `dist/libsystray.so`
- `dist/libsystray.h`

2) Manual build

```bash
cd linuxlibnew
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 \
  go build -buildmode=c-shared -o dist/libsystray.so ./jna
# Header will be generated at: dist/libsystray.h
```

Notes:
- Set `LD_LIBRARY_PATH` or copy the `.so` into a location discoverable by your app when running outside of Compose Native Tray.

## Exported C API (ABI)

The shared library exports the following C functions. These are consumed by Kotlin/JNA in `LinuxLibTray`:

- void Systray_InitCallbacks(void_cb ready, void_cb exit, void_cb onClick, void_cb onRClick, menu_item_cb onMenuItem)
- void Systray_PrepareExternalLoop()
- void Systray_NativeStart()
- void Systray_NativeEnd()
- void Systray_Quit()
- void Systray_SetIcon(const char* bytes, int length)
- void Systray_SetTitle(const char* title)
- void Systray_SetTooltip(const char* tooltip)
- void Systray_ResetMenu()
- void Systray_AddSeparator()
- unsigned int Systray_AddMenuItem(const char* title, const char* tooltip)
- unsigned int Systray_AddMenuItemCheckbox(const char* title, const char* tooltip, int checked)
- unsigned int Systray_AddSubMenuItem(unsigned int parentId, const char* title, const char* tooltip)
- unsigned int Systray_AddSubMenuItemCheckbox(unsigned int parentId, const char* title, const char* tooltip, int checked)
- int Systray_MenuItem_SetTitle(unsigned int id, const char* title)
- void Systray_MenuItem_Enable(unsigned int id)
- void Systray_MenuItem_Disable(unsigned int id)
- void Systray_MenuItem_Show(unsigned int id)
- void Systray_MenuItem_Hide(unsigned int id)
- void Systray_MenuItem_Check(unsigned int id)
- void Systray_MenuItem_Uncheck(unsigned int id)
- void Systray_SetMenuItemIcon(const char* bytes, int length, unsigned int id)
- void Systray_GetLastClickXY(int* outX, int* outY)

Callbacks are optional (pass NULL if you don’t need one). The `menu_item_cb` receives the clicked menu item id.

Event-loop integration:
- If your app manages its own event loop, use `Systray_PrepareExternalLoop()`, `Systray_NativeStart()`, and `Systray_NativeEnd()`.
- Otherwise, the original Go `Run` loop is wrapped by the bridge, and Compose Native Tray uses the external-loop mode.

## Using it from Compose Native Tray (Kotlin/JNA)

Compose Native Tray already contains the JNA mappings under `src/commonMain/kotlin/.../linux/LinuxLibTray.kt` and ships a prebuilt lib. You usually don’t need to call this API directly.

If you build a custom `.so` or run standalone, ensure the library named "systray" is discoverable by JNA:

```kotlin
// Example: add a search path at runtime (only needed when not using the bundled resource)
com.sun.jna.NativeLibrary.addSearchPath("systray", "/absolute/path/to/linuxlibnew/dist")
```

Minimal JNA usage example (standalone):

```kotlin
import com.sun.jna.Callback
import com.sun.jna.Native
import com.sun.jna.ptr.IntByReference

internal object LinuxLibTray {
    interface VoidCallback : Callback { fun invoke() }
    interface MenuItemCallback : Callback { fun invoke(menuId: Int) }
    init { Native.register("systray") }
    @JvmStatic external fun Systray_InitCallbacks(ready: VoidCallback?, exit: VoidCallback?, onClick: VoidCallback?, onRClick: VoidCallback?, onMenuItem: MenuItemCallback?)
    @JvmStatic external fun Systray_PrepareExternalLoop()
    @JvmStatic external fun Systray_NativeStart()
    @JvmStatic external fun Systray_NativeEnd()
    @JvmStatic external fun Systray_Quit()
    @JvmStatic external fun Systray_SetIcon(iconBytes: ByteArray, length: Int)
    @JvmStatic external fun Systray_SetTitle(title: String?)
    @JvmStatic external fun Systray_SetTooltip(tooltip: String?)
    @JvmStatic external fun Systray_ResetMenu()
    @JvmStatic external fun Systray_AddSeparator()
    @JvmStatic external fun Systray_AddMenuItem(title: String?, tooltip: String?): Int
    @JvmStatic external fun Systray_AddMenuItemCheckbox(title: String?, tooltip: String?, checked: Int): Int
    @JvmStatic external fun Systray_AddSubMenuItem(parentID: Int, title: String?, tooltip: String?): Int
    @JvmStatic external fun Systray_AddSubMenuItemCheckbox(parentID: Int, title: String?, tooltip: String?, checked: Int): Int
    @JvmStatic external fun Systray_MenuItem_SetTitle(id: Int, title: String?): Int
    @JvmStatic external fun Systray_MenuItem_Enable(id: Int)
    @JvmStatic external fun Systray_MenuItem_Disable(id: Int)
    @JvmStatic external fun Systray_MenuItem_Show(id: Int)
    @JvmStatic external fun Systray_MenuItem_Hide(id: Int)
    @JvmStatic external fun Systray_MenuItem_Check(id: Int)
    @JvmStatic external fun Systray_MenuItem_Uncheck(id: Int)
    @JvmStatic external fun Systray_SetMenuItemIcon(iconBytes: ByteArray, length: Int, id: Int)
    @JvmStatic external fun Systray_GetLastClickXY(outX: IntByReference, outY: IntByReference)
}
```

## Platform notes (Linux/BSD)

- This implementation uses DBus to communicate with StatusNotifier/AppIndicator providers. Very old trays may not display the icon.
- On desktop environments missing a StatusNotifier host, you may need a bridge like snixembed (for GNOME) or alternatives available in your distribution. Search for "StatusNotifierItems XEmbedded" in your package manager.

## Development tips

- Keep references to JNA callbacks to avoid them being garbage-collected.
- Don’t block the JVM thread inside callbacks; dispatch to background work if needed.
- If you add new exported functions in Go, update both the generated header and the Kotlin bindings.

## License and credits

- License: see `linuxlibnew/LICENSE`
- Credits:
    - https://github.com/energye/systray (base of this fork)
    - https://github.com/getlantern/systray (original project)
    - https://github.com/xilp/systray
    - https://github.com/cratonica/trayhost
