#!/usr/bin/env node
import { existsSync, readdirSync, rmSync } from 'node:fs';
import { join } from 'node:path';

const HISTORY = new URL('../../docs/business-rules/history/', import.meta.url).pathname;

if (!existsSync(HISTORY)) {
  process.exit(0);
}

const files = readdirSync(HISTORY);
if (files.length === 0) {
  process.exit(0);
}

for (const file of files) {
  rmSync(join(HISTORY, file), { force: true });
}
