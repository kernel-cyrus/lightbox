import * as vscode from 'vscode';
import * as path from 'path';

type ButtonId = 'run' | 'debug';

interface ButtonConfig {
  script?: string;
  cwd?: string;
  args?: string[];
  floatingWindow?: boolean;
  autoClose?: boolean;
}

const LABEL: Record<ButtonId, string> = {
  run: 'Run',
  debug: 'Debug',
};

function getConfig(id: ButtonId): ButtonConfig {
  const raw = vscode.workspace.getConfiguration('lightbox').get<string | ButtonConfig>(id);
  if (typeof raw === 'string') {
    return raw ? { script: raw } : {};
  }
  return raw ?? {};
}

function expandVars(input: string): string {
  const folder =
    vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? process.env.HOME ?? process.cwd();
  const activeFile = vscode.window.activeTextEditor?.document.uri.fsPath;
  const fileDirname = activeFile ? path.dirname(activeFile) : folder;
  return input
    .replace(/\$\{workspaceFolder\}/g, folder)
    .replace(/\$\{fileDirname\}/g, fileDirname)
    .replace(/\$\{env:([^}]+)\}/g, (_, k) => process.env[k] ?? '');
}

function quoteArg(arg: string): string {
  if (arg === '' || /[\s"'$`\\!*?(){}[\]<>|&;#~]/.test(arg)) {
    return `'${arg.replace(/'/g, `'\\''`)}'`;
  }
  return arg;
}

async function syncContext(): Promise<void> {
  for (const id of ['run', 'debug'] as ButtonId[]) {
    const enabled = Boolean(getConfig(id).script);
    await vscode.commands.executeCommand('setContext', `lightbox.${id}Enabled`, enabled);
  }
}

async function runButton(id: ButtonId): Promise<void> {
  const cfg = getConfig(id);
  if (!cfg.script) {
    const pick = await vscode.window.showWarningMessage(
      `Lightbox ${LABEL[id]} is not configured. Set "lightbox.${id}.script" in settings.`,
      'Open Settings',
    );
    if (pick === 'Open Settings') {
      await vscode.commands.executeCommand('workbench.action.openSettings', `lightbox.${id}`);
    }
    return;
  }

  const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  const cwd = cfg.cwd ? expandVars(cfg.cwd) : workspaceRoot;
  const scriptExpanded = expandVars(cfg.script);
  const args = (cfg.args ?? []).map((a) => quoteArg(expandVars(a)));

  const isPath = /[\\/]/.test(scriptExpanded) || scriptExpanded.endsWith('.sh');
  const scriptToken = isPath ? quoteArg(scriptExpanded) : scriptExpanded;
  const commandLine = [scriptToken, ...args].join(' ');

  const terminal = vscode.window.createTerminal({
    name: `Lightbox ${LABEL[id]}`,
    cwd,
  });
  terminal.show();

  const floating = cfg.floatingWindow !== false;
  const moveToNewWindow = () => {
    vscode.commands.executeCommand('workbench.action.terminal.moveIntoNewWindow').then(
      undefined,
      () => vscode.commands.executeCommand('workbench.action.terminal.moveToNewWindow'),
    );
  };

  const sendCommand = () => {
    if (terminal.shellIntegration) {
      terminal.shellIntegration.executeCommand(commandLine);
    } else {
      terminal.sendText(commandLine, true);
    }
    if (floating) {
      setTimeout(moveToNewWindow, 50);
    }
  };

  if (terminal.shellIntegration) {
    sendCommand();
  } else {
    let fired = false;
    const sub = vscode.window.onDidChangeTerminalShellIntegration((e) => {
      if (e.terminal !== terminal || fired) return;
      fired = true;
      sub.dispose();
      clearTimeout(fallback);
      sendCommand();
    });
    const fallback = setTimeout(() => {
      if (fired) return;
      fired = true;
      sub.dispose();
      sendCommand();
    }, 3000);
  }

  const autoClose = cfg.autoClose !== false;
  if (autoClose) {
    let started = false;
    const subs: vscode.Disposable[] = [];
    const cleanup = () => {
      while (subs.length) subs.pop()!.dispose();
    };
    subs.push(
      vscode.window.onDidStartTerminalShellExecution((e) => {
        if (e.terminal === terminal) started = true;
      }),
      vscode.window.onDidEndTerminalShellExecution((e) => {
        if (e.terminal !== terminal || !started) return;
        cleanup();
        terminal.dispose();
      }),
      vscode.window.onDidCloseTerminal((t) => {
        if (t === terminal) cleanup();
      }),
    );
  }
}

export function activate(context: vscode.ExtensionContext): void {
  void syncContext();

  context.subscriptions.push(
    vscode.commands.registerCommand('lightbox.run', () => runButton('run')),
    vscode.commands.registerCommand('lightbox.debug', () => runButton('debug')),
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('lightbox')) {
        void syncContext();
      }
    }),
  );
}

export function deactivate(): void {
  /* no-op */
}
