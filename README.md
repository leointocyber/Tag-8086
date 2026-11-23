<div align="center">

# Tag Game

*A two-player tag game written in x86 Assembly for DOS*

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/leointocyber/Tag-8086/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-DOS%20%7C%20DOSBox-lightgrey.svg)](https://www.dosbox.com/)
[![Language](https://img.shields.io/badge/language-x86%20Assembly-orange.svg)](https://en.wikipedia.org/wiki/X86_assembly_language)

[![DOSBox](https://img.shields.io/badge/DOSBox-0.74--3-blue.svg)](https://www.dosbox.com/)
[![MASM](https://img.shields.io/badge/MASM-6.11-red.svg)](https://en.wikipedia.org/wiki/Microsoft_Macro_Assembler)

</div>

---

## About

This is a little two-player arcade game I wrote in x86 assembly. It runs in real-mode DOS using VGA Mode 13h (320×200, 256 colors). The idea is simple: Player 1 (the Runner) collects grapes for points while Player 2 (the Chaser) tries to catch them. Each grape is worth 100 points. Game ends when the Chaser tags the Runner.

**Released:** 2026-11-23 (v1.0.0)

**Players:** 2 (local, same keyboard)  
**Graphics:** VGA Mode 13h — 320×200, 256 colors  
**Controls:** WASD for Runner, Arrow keys for Chaser

---

## Requirements

- **DOSBox** (0.74-3 or later) — runs on Windows, macOS, Linux
- **MASM** or **TASM** — both included in the `8086/` folder along with LINK, DEBUG, and a few other utilities

---

## Building & Running

### Quick start (DOSBox)

```bash
# Mount the project folder
mount c /path/to/Tag-8086
c:

# Assemble with MASM
masm Tag.asm

# Link
link Tag.obj

# Run
Tag.exe
```

### Using TASM instead

```bash
tasm Tag.asm
tlink Tag.obj
Tag.exe
```

The `8086/` folder has everything you need: MASM.EXE, TASM.EXE, LINK.EXE, DEBUG.EXE, EDIT.COM, plus a few extras.

To run: launch DOSBox with the included `dosbox.conf`, or press `Alt+Enter` in DOSBox to toggle fullscreen.

**Download:** Prebuilt `Tag.exe` is included in `Tag_v1.0.0_full.zip` on the [Releases page](https://github.com/leointocyber/Tag-8086/releases).

---

## Controls

| Player | Action | Keys |
|--------|--------|------|
| **Runner (P1)** | Up / Down / Left / Right | `W` / `S` / `A` / `D` |
| **Chaser (P2)** | Up / Down / Left / Right | `↑` / `↓` / `←` / `→` |
| **Menu** | Start / Quit / Controls | `Y` / `N` / `C` |
| **In-Game** | Return to menu | `ESC` |

> **DOSBox speed:** `Ctrl+F11` slows down, `Ctrl+F12` speeds up

---

## Project Structure

```
Tag-8086/
├── Tag.asm          # Main source (x86 Assembly)
├── README.md        # This file
├── LICENSE          # MIT License
└── 8086/            # DOS dev tools
    ├── MASM.EXE
    ├── TASM.EXE
    ├── LINK.EXE
    ├── DEBUG.EXE
    ├── EDIT.COM
    ├── EXE2BIN.EXE
    ├── BIN2HEX.EXE
    └── TD.EXE
```

---

## Technical Notes

**Target:** Intel 8086/8088 (16-bit real mode)  
**Memory model:** Small (code + data ≤ 64 KB each)  
**Video:** Mode 13h — linear framebuffer at `A000:0000`  
**RNG:** Linear Congruential Generator (multiplier 25173, increment 13849)

| Component | Approach |
|-----------|----------|
| Rendering | `INT 10h, AH=0Ch` — direct pixel writes |
| Input | `INT 16h` — BIOS keyboard services |
| Collision | AABB (5×5 pixel squares) |
| Grape spawn | LCG, validated against bounds & runner |
| Frame delay | Busy-wait loop (`DEC CX / JNZ`) |

**Palette (Mode 13h):**
- Cyan (`0Bh`) — background
- Blue (`01h`) — Runner
- Red (`04h`) — Chaser
- Magenta (`05h`) — Grapes

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Acknowledgments

- **DOSBox team** — for keeping DOS alive
- **Ralf Brown's Interrupt List** — the bible for DOS/BIOS interrupts
- Everyone still writing assembly in 2026