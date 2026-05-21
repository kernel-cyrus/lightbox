# Lightbox

Adds **Run** and **Debug** buttons to the editor title bar (the same area Claude Code lives in). Each button runs a configured shell command or `.sh` script in a fresh terminal that is automatically moved into a floating window.

## Install (local dev)

```bash
npm install
npm run compile
# package into a .vsix
npx vsce package
code --install-extension lightbox-0.0.1.vsix
```

Or press <kbd>F5</kbd> in VSCode to launch an Extension Development Host.

## Configure

Open `settings.json` and add:

```jsonc
// shorthand: just the command
"lightbox.run": "top",
"lightbox.debug": "htop",

// full form: object with extra options
"lightbox.run": { "script": "${workspaceFolder}/scripts/qemu/run.sh" },
"lightbox.debug": {
  "script": "${workspaceFolder}/scripts/qemu/run.sh",
  "args": ["--debug"],
  "cwd": "${workspaceFolder}/scripts/qemu"
}
```

A button is only shown when its value is a non-empty string or has `script` set.

### Fields

| Field            | Description                                                                                  |
| ---------------- | -------------------------------------------------------------------------------------------- |
| `script`         | Command or path to `.sh`. Relative paths resolve against `cwd`.                              |
| `cwd`            | Working dir. Supports `${workspaceFolder}`, `${fileDirname}`, `${env:VAR}`. Defaults to root.|
| `args`           | Extra args appended to the command (each shell-quoted automatically).                        |
| `floatingWindow` | If `true` (default), terminal is moved into a separate VSCode window after launch.           |
| `autoClose`      | If `true` (default), the terminal is disposed when the command finishes (closing the floating window). Requires shell integration. |

## How it works

The extension declares two fixed menu items (`Run`, `Debug`) in `package.json`. Each is shown only when its `script` is configured (controlled by a context key updated on activation and on every config change).

The terminal is created via `vscode.window.createTerminal`, then the built-in command `workbench.action.terminal.moveIntoNewWindow` floats it into a separate window. Floating-window support requires VSCode 1.85+.
