#!/usr/bin/env node
import { createReadStream } from 'node:fs';
import { writeFile } from 'node:fs/promises';

const MAX_INPUT_BYTES = 1_048_576;
const help = `Moon Graph — MoonBit graph layout and SVG renderer

Usage: node cli/moon-graph.mjs [input-file|-] [options]

  --input-format json|text   Input syntax (default: json)
  --format json|svg          Output syntax (default: json)
  --algorithm NAME          Override root elk.algorithm
  --direction DIRECTION     RIGHT, DOWN, LEFT, or UP
  --pretty                  Pretty-print JSON output
  --output PATH             Write output file (default: stdout)
  --algorithms              List implemented algorithms
  --help                    Show this help
  --                        End option parsing

With no input-file or with -, read stdin. Build first: npm run build.
Layout/parse/render errors exit 1. Argument errors exit 2.
` ;

function parseArgs(args) {
  const options = { inputFormat: 'json', format: 'json', algorithm: '', direction: '', pretty: false };
  const names = new Map([['--input-format', 'inputFormat'], ['--format', 'format'], ['--algorithm', 'algorithm'], ['--direction', 'direction'], ['--output', 'output']]);
  const seen = new Set();
  let positionalOnly = false;
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (!positionalOnly && arg === '--') { positionalOnly = true; continue; }
    if (!positionalOnly && ['--help', '--algorithms', '--pretty'].includes(arg)) {
      if (seen.has(arg)) throw new Error(`duplicate option: ${arg}`);
      seen.add(arg);
      options[arg.slice(2)] = true;
    } else if (!positionalOnly && names.has(arg)) {
      if (seen.has(arg)) throw new Error(`duplicate option: ${arg}`);
      seen.add(arg);
      const value = args[++i];
      if (!value || value.startsWith('--')) throw new Error(`missing value for ${arg}`);
      options[names.get(arg)] = value;
    } else if (!positionalOnly && arg.startsWith('-') && arg !== '-') {
      throw new Error(`unknown option: ${arg}`);
    } else {
      if (options.input !== undefined) throw new Error('only one input file is allowed');
      options.input = arg;
    }
  }
  if (!['json', 'text'].includes(options.inputFormat)) throw new Error('--input-format must be json or text');
  if (!['json', 'svg'].includes(options.format)) throw new Error('--format must be json or svg');
  if (options.direction && !['RIGHT', 'DOWN', 'LEFT', 'UP'].includes(options.direction)) throw new Error('--direction must be RIGHT, DOWN, LEFT, or UP');
  return options;
}

async function readInput(path) {
  const stream = path !== undefined && path !== '-' ? createReadStream(path) : process.stdin;
  const chunks = [];
  let length = 0;
  for await (const chunk of stream) {
    length += chunk.length;
    if (length > MAX_INPUT_BYTES) throw new Error(`input exceeds ${MAX_INPUT_BYTES} bytes`);
    chunks.push(chunk);
  }
  return new TextDecoder('utf-8', { fatal: true }).decode(Buffer.concat(chunks));
}

async function run() {
  let options;
  try { options = parseArgs(process.argv.slice(2)); }
  catch (error) { process.stderr.write(`moon-graph: ${error.message}\n`); return 2; }
  if (options.help) { process.stdout.write(help); return 0; }
  let bridge;
  try { bridge = await import('../_build/js/release/build/bridge/bridge.js'); }
  catch (error) { throw new Error(`cannot load MoonBit bridge; run npm run build first (${error.message})`); }
  if (options.algorithms) { process.stdout.write(`${bridge.list_algorithms()}\n`); return 0; }
  const input = await readInput(options.input);
  const result = JSON.parse(bridge.transform(input, options.inputFormat, options.format, options.algorithm, options.direction, String(options.pretty)));
  if (!result.ok) throw new Error(result.error);
  const output = `${result.data}\n`;
  if (options.output) await writeFile(options.output, output, 'utf8');
  else await new Promise((resolve, reject) => process.stdout.write(output, error => error ? reject(error) : resolve()));
  return 0;
}

process.stdout.on('error', error => {
  if (error.code === 'EPIPE') process.exit(0);
  process.stderr.write(`moon-graph: ${error.message}\n`);
  process.exit(1);
});
try { process.exitCode = await run(); }
catch (error) { process.stderr.write(`moon-graph: ${error.message}\n`); process.exitCode = 1; }
