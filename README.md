# C++ Native Messaging Host Sample

A lightweight, cross-platform reference implementation of a browser **Native Messaging Host** written in C++. This repository provides a boilerplate for secure, bi-directional communication between a Chromium Web Extension and a local C++ executable via standard I/O (`stdin`/`stdout`).

This implementation has been compiled, deployed, and verified to work in **user-space** across the following environments:

| Operating System | Browser Coverage | Toolchain / Compiler |
| :--- | :--- | :--- |
| **Windows 10/11 (x86_64)** | Google Chrome, Chromium | MSYS2 MinGW64 (`mingw64` / `cmake` + `Ninja`) |
| **Ubuntu Linux (x86_64)** | Google Chrome, Chromium | Native GCC (`g++` / `cmake`) |
| **Asahi Linux (arm64)** | Vivaldi | Native GCC (`g++` / `cmake`) |
| **macOS (M1 Pro)** | Google Chrome, Chromium | Homebrew GCC (`g++` / `cmake`) |

---

## Architecture Overview

The web extension communicates with the C++ host asynchronously. The browser spawns the native application as a separate process and manages its lifecycle via standard streams.

```text
[ Web Extension ] 
       │  ▲
       │  │  chrome.runtime.connectNative()
       ▼  │
[ Browser Process ] 
       │  ▲
       │  │  Standard I/O Streams (stdin / stdout)
       ▼  │
[ C++ Native Host Executable ]
```

---

## Project Structure

```text
.
├── CMakeLists.txt
├── extension
│   ├── background.js
│   ├── icon.png
│   ├── manifest.json               # Extension Manifest (MV3)
│   ├── popup.css
│   ├── popup.html
│   └── popup.js
├── host
│   ├── io.github.cpsdenis.json     # Native Host Manifest template
│   └── src
│       ├── CMakeLists.txt
│       └── main.cpp                # C++ Native Host source code
├── LICENSE
├── Makefile
└── README.md
```

---

## Protocol

Native Messaging communication relies on a structured protocol header:
1. Every message must be prefixed with a **4-byte unsigned integer** specifying the length of the following JSON string in native byte order.
2. The total size of an individual incoming message from the browser cannot exceed **1 MB**.
3. Outgoing responses from the C++ host to the browser cannot exceed **4 MB**.

### Windows Stream Warning
On Windows, standard I/O defaults to Text Mode (`O_TEXT`), which alters `\n` to `\r\n` and truncates data at the `0x1A` byte (EOF). The streams **must explicitly be converted to binary mode**:
```cpp
#ifdef _WIN32
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
#endif
```

---

## Prerequisites

Ensure your system has a C++17 compiler and CMake 3.12+ installed:

* **Windows (MSYS2)**: Open the **MinGW64** terminal and install packages:
    ```bash
    pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-cmake make
    ```
* **Linux (Ubuntu/Debian)**:
    ```bash
    sudo apt update && sudo apt install build-essential cmake
    ```
* **macOS (Homebrew)**: Install GCC and CMake via Homebrew:
    ```bash
    brew install gcc cmake
    ```

---

## How to Run the Sample

Running this sample configuration requires two key phases:

### 1. Build and Register the Native Host
Compile the binary program and register its structural location manifest to the local system using user-space directories:
```bash
make install
```

### 2. Install the Browser Extension
1. Open your browser and navigate directly to the extension management page: `chrome://extensions`.
1. Toggle on **Developer mode** using the switch located in the upper-right corner.
1. Click the **Load unpacked** button in the upper-left corner.
1. Select the `extension/` directory located inside this project repository workspace.
1. Call popup-window and send message

![](https://github.com/user-attachments/assets/911f2289-0ecc-4cdb-8297-e9fd18aa926b)

![](https://github.com/user-attachments/assets/9d6e171f-8c51-49ef-a175-444f4bcc8c7c)

---
## Compilation, Installation & Registration

To make testing and deployment simple, a **Makefile wrapper** is provided. 

#### ⚠️ **No Root Privileges Required**

The build system and installation targets work entirely within the current user's profile (`HKCU` on Windows registry, `~/.local/share` and user configurations on Unix). **Never run these commands with `sudo`**.

```
\$ make help

Target       Description
──────       ───────────
build        Build native host application
clean        Clean project output
debug        Print local makefile variables
help         Display this help screen
install      Build native host and install binary and manifests (User-space, no sudo)
purge        Uninstall and clean
rebuild      Clean and build the binary from scratch
reinstall    Uninstall and install
uninstall    Remove installed binary and native messaging manifests
```