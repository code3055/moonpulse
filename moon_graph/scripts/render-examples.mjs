import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
for (const name of ['pipeline', 'hierarchy-ports', 'cycle', 'workflow']) {
  const text = name === 'workflow';
  const args = ['cli/moon-graph.mjs', 'examples/' + name + (text ? '.txt' : '.json'), '--input-format', text ? 'text' : 'json', '--format', 'svg', '--output', 'examples/' + name + '.svg'];
  const result = spawnSync(process.execPath, args, { cwd: root, encoding: 'utf8' });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(result.stderr || 'render failed: ' + name);
  process.stdout.write('Rendered examples/' + name + '.svg\n');
}
