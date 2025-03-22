# Lynux

Lynux is a Linux desktop emulator game built with [Love2D](https://love2d.org/). It simulates a Linux‑style desktop complete with a top bar (showing date and time), a bottom bar of app icons, and draggable windows for individual applications. The project is modular—each app is contained in its own Lua file—and many share a common file system.

## Features

- **Linux Desktop Emulation:**  
  Emulates a Linux desktop with a status bar at the top and a taskbar at the bottom.

- **Multiple Applications:**  
  - **Email App:** Displays dummy email content.  
  - **Browser App:** Minimal web browser with a URL bar and dummy webpage content.  
  - **Files App:** A file manager that navigates a shared file system (loaded from `filesystem.json` or default data). Supports directory navigation and file operations.  
  - **Terminal App:** A full-featured terminal supporting common commands (echo, pwd, cd, mkdir, etc.) and inline function calls (e.g. `$pwd()`, `$date()`).  
  - **Roulette App:** A roulette game with betting and spin mechanics.  
  - **Text Editor:** Integrated with the Files App; opens files for editing. Displays the full file path at the top and uses red text if unsaved (dirty) and black when saved.  
  - **Dino App:** A simple dino game (or placeholder) for extra fun.

- **Shared File System:**  
  The file manager and terminal both operate on a shared file system stored in JSON format. If no saved file exists, default data is loaded from `data/filesystem.json`.

- **Scripting and Inline Substitutions in Terminal:**  
  Supports both usual commands (e.g., `echo "hello"`, `pwd`, `mkdir dir`) and function‑like commands using inline substitutions (e.g., `$echo("hello")`, `$pwd()`, `$date()`). Inline substitution looks for variables or built‑in function names and replaces them with their output.

## Installation and Running

1. **Install Love2D:**  
   Download and install [Love2D](https://love2d.org/).

2. **Clone or Download Lynux:**  
   Place the project folder (`Lynux/`) on your computer.

3. **Project Structure:**

   ```
   Lynux/
   ├── main.lua                  -- Entry point; sets up the desktop environment and window system.
   ├── email.lua                 -- Email app module.
   ├── browser.lua               -- Browser app module.
   ├── files.lua                 -- File manager module.
   ├── terminal.lua              -- Terminal app module.
   ├── terminal_commands.lua     -- Terminal command processing & inline substitutions.
   ├── roulette.lua              -- Roulette game app module.
   ├── texteditor.lua            -- Text editor module.
   ├── dino.lua                  -- Dino game module.
   ├── filesystem.lua            -- Shared file system module.
   ├── data/
   │   └── filesystem.json       -- Default file system data.
   └── assets/                   -- Images and icons for the apps.
   ```

4. **Run the Game:**  
   Launch Love2D and select the `Lynux/` folder or run via command line:
   ```bash
   love Lynux/
   ```

## How to Play

- **Desktop Interface:**  
  Click on the application icons in the taskbar at the bottom to launch apps. Windows can be dragged by their title bar, minimized, closed, or resized.

- **Terminal App:**  
  - Type commands such as `echo "hello"`, `pwd`, `mkdir myDir`, etc.  
  - Use inline function calls like `$pwd()`, `$date()`, `$time()` to insert dynamic values.
  - Type `help` in the terminal to see all available commands.

- **Files App and Text Editor:**  
  - Navigate directories and double‑click files to open them in the Text Editor.
  - The Text Editor displays the full file path at its top header.  
  - The file path appears in red if there are unsaved changes (dirty) and black once saved.  
  - Use Ctrl+S within the editor to save changes back to the shared file system.

- **Other Applications:**  
  Explore the Email, Browser, Roulette, and Dino apps for additional functionality and fun.

## Customization

- **Adding Commands:**  
  The terminal commands and inline function calls are implemented in `terminal_commands.lua` via an `inlineSubstitutions` table. You can easily add new commands by adding a new entry to this table.

- **Modular Apps:**  
  Each app is a standalone module, making it simple to extend or replace individual applications.

## Credits

- **Project Name:** Lynux  
- **Built with:** Love2D  
- **Inspiration:** Linux desktop environments, retro game emulators, and interactive prototyping.

Enjoy exploring your very own Linux desktop emulator game—Lynux!
