import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const basic = JSON.stringify({ id: 'g', children: [{ id: 'a' }, { id: 'b' }], edges: [{ id: 'e', sources: ['a'], targets: ['b'] }] });
function cli(args = [], input = basic) {
  const r = spawnSync(process.execPath, ['cli/moon-graph.mjs', ...args], { cwd: root, input, encoding: 'utf8', timeout: 20_000, maxBuffer: 5_000_000 });
  assert.ifError(r.error);
  return r;
}

test('help works with no input', () => {
  const r = cli(['--help'], ''); assert.equal(r.status, 0); assert.match(r.stdout, /Usage:/);
});
test('algorithm metadata is compiled MoonBit output', () => {
  const r = cli(['--algorithms']); assert.equal(r.status, 0); assert.deepEqual(JSON.parse(r.stdout), ['layered', 'force', 'radial', 'box', 'fixed']);
});
test('stdin JSON produces positioned nodes and routed edge', () => {
  const r = cli(); assert.equal(r.status, 0, r.stderr); const g = JSON.parse(r.stdout);
  assert.equal(g.children.length, 2); assert.ok(g.children[1].x > g.children[0].x); assert.equal(g.edges[0].sections.length, 1);
});
test('file pipeline and pretty output preserve Unicode', () => {
  const r = cli(['examples/pipeline.json', '--pretty']); assert.equal(r.status, 0, r.stderr); assert.match(r.stdout, /数据采集/); assert.match(r.stdout, /\n\s+"/);
});
test('text grammar handles cycles and UTF-8 labels', () => {
  const r = cli(['examples/workflow.txt', '--input-format', 'text']); assert.equal(r.status, 0, r.stderr); assert.equal(JSON.parse(r.stdout).children.length, 3); assert.match(r.stdout, /内容评审/);
});
test('hierarchical port graph produces SVG', () => {
  const r = cli(['examples/hierarchy-ports.json', '--format', 'svg']); assert.equal(r.status, 0, r.stderr); assert.match(r.stdout, /<svg/); assert.match(r.stdout, /数据库/);
});
test('cycle and self-edge are accepted', () => {
  const r = cli(['examples/cycle.json']); assert.equal(r.status, 0, r.stderr); assert.equal(JSON.parse(r.stdout).edges.length, 5);
});
for (const algorithm of ['layered', 'force', 'radial', 'box', 'fixed']) {
  test('CLI dispatches ' + algorithm, () => { const r = cli(['--algorithm', algorithm]); assert.equal(r.status, 0, r.stderr); assert.ok(JSON.parse(r.stdout).width >= 0); });
}
for (const direction of ['RIGHT', 'DOWN', 'LEFT', 'UP']) {
  test('CLI direction ' + direction, () => { const r = cli(['--direction', direction]); assert.equal(r.status, 0, r.stderr); const [a,b] = JSON.parse(r.stdout).children; assert.ok(direction === 'RIGHT' ? b.x > a.x : direction === 'LEFT' ? b.x < a.x : direction === 'DOWN' ? b.y > a.y : b.y < a.y); });
}
for (const args of [['--bogus'], ['--format'], ['--format', 'xml'], ['--input-format', 'yaml'], ['--direction', 'diagonal'], ['a', 'b'], ['--pretty', '--pretty'], ['--output', '--pretty'], ['--algorithm', 'layered', '--algorithm', 'force']]) {
  test('argument error: ' + args.join(' '), () => { const r = cli(args); assert.equal(r.status, 2); assert.equal(r.stdout, ''); assert.match(r.stderr, /moon-graph:/); });
}
for (const input of ['{bad', '{"id":"g","children":[{"id":"same"},{"id":"same"}]}', '{"id":"g","layoutOptions":{"elk.algorithm":"stress"}}', '{"id":"g","layoutOptions":{"bogus":"yes"}}', '{"id":"g","edges":[{"id":"e","sources":["missing"],"targets":["other"]}]}']) {
  test('input error is reported without stack: ' + input.slice(0, 48), () => { const r = cli([], input); assert.equal(r.status, 1); assert.equal(r.stdout, ''); assert.match(r.stderr, /moon-graph:/); assert.doesNotMatch(r.stderr, /at run \(/); });
}
test('unsupported override is a layout error', () => { const r = cli(['--algorithm', 'stress']); assert.equal(r.status, 1); assert.match(r.stderr, /algorithm/i); });
test('missing input file fails cleanly', () => { const r = cli(['examples/does-not-exist.json']); assert.equal(r.status, 1); assert.match(r.stderr, /ENOENT/); });
test('SVG escapes user text and never inserts script markup', () => {
  const r = cli(['--format', 'svg'], JSON.stringify({id:'g',children:[{id:'x',labels:[{text:'<script>alert("x")</script> & 中文'}]}]}));
  assert.equal(r.status, 0, r.stderr); assert.match(r.stdout, /&lt;script&gt;/); assert.doesNotMatch(r.stdout, /<script>/);
});
test('output path is written without stdout data', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'moon-graph-'));
  try { const path = join(dir, '结果.svg'); const r = cli(['--format','svg','--output',path]); assert.equal(r.status,0,r.stderr); assert.equal(r.stdout,''); assert.match(await readFile(path,'utf8'),/<svg/); }
  finally { await rm(dir,{recursive:true,force:true}); }
});
test('invalid UTF-8 is rejected', () => { const r = cli([], Buffer.from([0xff,0xfe])); assert.equal(r.status,1); assert.match(r.stderr,/encoded data|encoding/i); });
test('oversized stdin is rejected before layout', () => {
  // Rejecting input may close the pipe while spawnSync is still writing on Windows.
  const r = spawnSync(process.execPath, ['cli/moon-graph.mjs'], { cwd: root, input: ' '.repeat(1_048_577), encoding: 'utf8', timeout: 20_000 });
  if (r.error) assert.ok(['EOF', 'EPIPE'].includes(r.error.code), r.error.message);
  assert.equal(r.status, 1); assert.match(r.stderr, /exceeds/);
});
test('oversized file is rejected by bounded file reader', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'moon-graph-'));
  try { const path = join(dir, 'large.json'); await writeFile(path, ' '.repeat(1_048_577)); const r = cli([path]); assert.equal(r.status, 1); assert.match(r.stderr, /exceeds/); }
  finally { await rm(dir, { recursive: true, force: true }); }
});
test('end-of-options permits a filename beginning with dash', async () => {
  const dir = await mkdtemp(join(tmpdir(),'moon-graph-'));
  try { const path = join(dir,'-graph.json'); await writeFile(path,basic); const r=cli(['--',path]); assert.equal(r.status,0,r.stderr); }
  finally { await rm(dir,{recursive:true,force:true}); }
});
