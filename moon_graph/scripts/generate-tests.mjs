import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const target = fileURLToPath(new URL('../graph/scenarios_test.mbt', import.meta.url));
const marker = '// BEGIN GENERATED SCENARIOS';
const original = readFileSync(target, 'utf8');
if (!original.includes(marker)) throw new Error('Missing scenario generation marker');
let output = original.slice(0, original.indexOf(marker)) + marker + '\n';
const algorithms = ['layered', 'force', 'radial', 'box', 'fixed'];
const directions = ['RIGHT', 'DOWN', 'LEFT', 'UP'];
const families = ['chain', 'star', 'cycle', 'disconnected', 'binary', 'diamond', 'ports', 'compound'];
let count = 0;
for (const algorithm of algorithms) {
  for (const direction of directions) {
    for (const family of families) {
      for (let variant = 0; variant < 2; variant++) {
        const description = variant === 0 ? 'uniform-small-seed7-orthogonal' : 'varied-large-seed104729-polyline';
        output += '\n///|\ntest "scenario ' + [algorithm, direction, family, description].join(' ') + '" {\n';
        output += '  check_scenario("' + algorithm + '", "' + direction + '", "' + family + '", ' + variant + ')\n}\n';
        count++;
      }
    }
  }
}
writeFileSync(target, output);
console.log('Generated ' + count + ' independently named layout scenarios.');
