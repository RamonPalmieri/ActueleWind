import { spawnSync } from 'node:child_process';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const checks = [
  {
    name: 'Python syntax',
    command: 'python3',
    args: ['-m', 'py_compile', 'Get-ActueleWind.py'],
    env: { PYTHONPYCACHEPREFIX: mkdtempSync(join(tmpdir(), 'actuelewind-pycache-')) },
  },
  {
    name: 'PowerShell syntax',
    command: 'pwsh',
    args: [
      '-NoProfile',
      '-Command',
      '$errors = $null; $tokens = $null; [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path "./Get-ActueleWind.ps1"), [ref]$tokens, [ref]$errors) > $null; if ($errors.Count) { $errors | ForEach-Object { $_.Message }; exit 1 }',
    ],
    optional: true,
  },
  {
    name: 'PHP syntax',
    command: 'php',
    args: ['-l', 'Get-ActueleWind.php'],
    optional: true,
  },
];

let failed = false;

for (const check of checks) {
  const result = spawnSync(check.command, check.args, {
    encoding: 'utf8',
    env: { ...process.env, ...check.env },
  });

  if (result.error?.code === 'ENOENT' && check.optional) {
    console.log(`- ${check.name}: skipped (${check.command} not found)`);
    continue;
  }

  if (result.error) {
    console.error(`- ${check.name}: failed to start ${check.command}`);
    console.error(result.error.message);
    failed = true;
    continue;
  }

  if (result.status !== 0) {
    console.error(`- ${check.name}: failed`);
    const output = `${result.stdout}${result.stderr}`.trim();
    if (output) {
      console.error(output);
    }
    failed = true;
    continue;
  }

  console.log(`- ${check.name}: ok`);
}

if (failed) {
  process.exit(1);
}
