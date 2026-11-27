#!/usr/bin/env bun
import { execSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { Database } from 'bun:sqlite';
import { dump, load } from 'js-yaml';

const ROOT = new URL('../../', import.meta.url).pathname;
const DB_PATH = `${ROOT}docs/business-rules/rules.db`;
const RULES_DIR = `${ROOT}docs/business-rules`;
const HISTORY_DIR = `${RULES_DIR}/history`;

const VALID_STATUSES = ['active', 'superseded', 'inactive'];

/** Template with a placeholder feature id; indexing it would create a real feature and clash on the next build. */
const TEMPLATE_FILE = 'fea-template.yaml';

const help = () => {};

const getDb = () => {
  const db = new Database(DB_PATH, { create: true });
  db.run('PRAGMA journal_mode = WAL');
  return db;
};

const initDb = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS features (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      purpose TEXT,
      scope TEXT NOT NULL DEFAULT ''
    );
    CREATE TABLE IF NOT EXISTS rules (
      id TEXT PRIMARY KEY,
      feature_id TEXT NOT NULL REFERENCES features(id),
      status TEXT NOT NULL DEFAULT 'active',
      title TEXT NOT NULL,
      rule TEXT NOT NULL,
      why TEXT,
      context TEXT,
      supersedes TEXT,
      superseded_by TEXT,
      superseded_reason TEXT
    );
    CREATE TABLE IF NOT EXISTS scenarios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      rule_id TEXT NOT NULL REFERENCES rules(id),
      title TEXT NOT NULL,
      given_text TEXT,
      when_text TEXT,
      then_text TEXT
    );
  `);
};

const parseArgs = (args) => {
  const opts = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      const key = args[i].slice(2);
      const next = args[i + 1];
      if (next && !next.startsWith('--')) {
        opts[key] = next;
        i++;
      } else {
        opts[key] = true;
      }
    }
  }
  return opts;
};

const generateRuleId = (featureId, ruleContent) => {
  const hash = createHash('sha256').update(`${featureId}:${ruleContent}`).digest('hex').slice(0, 7);
  return `BR-${hash}`;
};

const buildLineage = (db, ruleId) => {
  const lineage = [];
  let current = ruleId;
  while (current) {
    const row = db
      .prepare('SELECT id, rule, status, superseded_reason, supersedes FROM rules WHERE id = ?')
      .get(current);
    if (!row) break;
    lineage.unshift({
      id: row.id,
      rule: row.rule,
      status: row.status,
      superseded_reason: row.superseded_reason || undefined,
    });
    current = row.supersedes || null;
  }
  return lineage;
};

const cmdBuild = () => {
  const db = getDb();
  initDb(db);

  db.run('DELETE FROM scenarios; DELETE FROM rules; DELETE FROM features;');

  const files = readdirSync(RULES_DIR)
    .filter((f) => f.endsWith('.yaml') && f !== TEMPLATE_FILE)
    .sort();

  const insertFeature = db.prepare('INSERT INTO features (id, name, purpose, scope) VALUES (?, ?, ?, ?)');
  const insertRule = db.prepare(
    'INSERT INTO rules (id, feature_id, status, title, rule, why, context, supersedes, superseded_by, superseded_reason) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
  );
  const insertScenario = db.prepare(
    'INSERT INTO scenarios (rule_id, title, given_text, when_text, then_text) VALUES (?, ?, ?, ?, ?)',
  );

  const tx = db.transaction(() => {
    for (const file of files) {
      const content = readFileSync(`${RULES_DIR}/${file}`, 'utf-8');
      const data = load(content);
      insertFeature.run(data.id, data.name, data.purpose, data.scope || '');
      for (const rule of data.rules || []) {
        insertRule.run(
          rule.id,
          data.id,
          rule.status || 'active',
          rule.title || '',
          rule.rule || '',
          rule.why || null,
          rule.context || null,
          rule.supersedes || null,
          rule.superseded_by || null,
          rule.superseded_reason || null,
        );
        for (const sc of rule.scenarios || []) {
          insertScenario.run(rule.id, sc.title || '', sc.given || null, sc.when || null, sc.then || null);
        }
      }
    }

    const updSuperseded = db.prepare(
      "UPDATE rules SET status = 'superseded', superseded_by = ? WHERE id = ? AND status = 'active'",
    );
    for (const file of files) {
      const content = readFileSync(`${RULES_DIR}/${file}`, 'utf-8');
      const data = load(content);
      for (const rule of data.rules || []) {
        if (rule.supersedes) {
          updSuperseded.run(rule.id, rule.supersedes);
        }
      }
    }
  });

  tx();
  db.close();
};

const cmdQuery = (args) => {
  const opts = parseArgs(args);
  const db = getDb();
  initDb(db);

  const statusFilter = opts.status && opts.status !== 'true' ? opts.status : null;

  if (statusFilter && !VALID_STATUSES.includes(statusFilter) && statusFilter !== 'all') {
    db.close();
    return;
  }

  let result;

  if (opts.feature) {
    const feature = db.prepare('SELECT id, name, purpose, scope FROM features WHERE id = ?').get(opts.feature);
    if (!feature) {
      db.close();
      return;
    }

    let rows;
    if (statusFilter === 'all') {
      rows = db
        .prepare(
        "SELECT * FROM rules WHERE feature_id = ? ORDER BY CASE status WHEN 'active' THEN 0 WHEN 'superseded' THEN 1 WHEN 'inactive' THEN 2 END, id",
        )
        .all(opts.feature);
    } else {
      const status = statusFilter || 'active';
      rows = db
        .prepare('SELECT * FROM rules WHERE feature_id = ? AND status = ? ORDER BY id')
        .all(opts.feature, status);
    }

    result = {
      feature: { id: feature.id, name: feature.name, purpose: feature.purpose, scope: feature.scope },
      rules: rows.map((r) => ({
        id: r.id,
        status: r.status,
        title: r.title,
        rule: r.rule,
        why: r.why,
        context: r.context,
        supersedes: r.supersedes,
        superseded_by: r.superseded_by,
        superseded_reason: r.superseded_reason,
      })),
    };
  } else if (opts.id) {
    const rule = db
      .prepare('SELECT r.*, f.name as feature_name FROM rules r JOIN features f ON r.feature_id = f.id WHERE r.id = ?')
      .get(opts.id);
    if (!rule) {
      db.close();
      return;
    }
    const scenarios = db
      .prepare('SELECT title, given_text, when_text, then_text FROM scenarios WHERE rule_id = ?')
      .all(opts.id);
    const lineage = buildLineage(db, rule.supersedes);
    lineage.push({
      id: rule.id,
      rule: rule.rule,
      status: rule.status,
      superseded_reason: rule.superseded_reason || undefined,
    });
    const successor = db
      .prepare('SELECT id, rule, status, superseded_reason FROM rules WHERE supersedes = ?')
      .get(rule.id);
    if (successor) {
      lineage.push({
        id: successor.id,
        rule: successor.rule,
        status: successor.status,
        superseded_reason: successor.superseded_reason || undefined,
      });
    }
    result = {
      id: rule.id,
      feature: { id: rule.feature_id, name: rule.feature_name },
      status: rule.status,
      title: rule.title,
      rule: rule.rule,
      why: rule.why,
      context: rule.context,
      supersedes: rule.supersedes,
      superseded_by: rule.superseded_by,
      superseded_reason: rule.superseded_reason,
      scenarios: scenarios.map((s) => ({ title: s.title, given: s.given_text, when: s.when_text, then: s.then_text })),
      lineage,
    };
  } else if (opts.features) {
    const features = db.prepare('SELECT id, name, purpose, scope FROM features ORDER BY id').all();
    if (opts.names) {
      result = features.map((f) => ({ id: f.id, name: f.name }));
    } else {
      result = features.map((f) => {
        const counts = db
          .prepare('SELECT status, COUNT(*) as count FROM rules WHERE feature_id = ? GROUP BY status')
          .all(f.id);
        const summary = { active: 0, superseded: 0, inactive: 0 };
        for (const c of counts) summary[c.status] = c.count;
        return { ...f, rules: summary };
      });
    }
  } else if (opts.search) {
    const term = `%${opts.search}%`;
    result = db
      .prepare(
        'SELECT id, name, purpose, scope FROM features WHERE name LIKE ? OR purpose LIKE ? OR id LIKE ? ORDER BY id',
      )
      .all(term, term, term);
  } else {
    const status = statusFilter || 'active';
    if (status === 'all') {
      result = db
        .prepare(
          'SELECT r.id, r.feature_id, f.name as feature_name, r.status, r.title, r.rule, r.why, r.context FROM rules r JOIN features f ON r.feature_id = f.id ORDER BY f.id, r.id',
        )
        .all();
    } else {
      result = db
        .prepare(
          'SELECT r.id, r.feature_id, f.name as feature_name, r.status, r.title, r.rule, r.why, r.context FROM rules r JOIN features f ON r.feature_id = f.id WHERE r.status = ? ORDER BY f.id, r.id',
        )
        .all(status);
    }
  }

  db.close();
  console.log(JSON.stringify(result ?? null, null, 2));
};

const cmdAdd = () => {
  const input = readFileSync('/dev/stdin', 'utf-8');
  const data = load(input);

  if (!data.feature || !data.rule) {
    process.exit(1);
  }

  const db = getDb();
  initDb(db);

  const ruleId = data.id || generateRuleId(data.feature, data.rule);

  const existing = db.prepare('SELECT id, rule FROM rules WHERE id = ?').get(ruleId);
  if (existing) {
    if (existing.rule === data.rule) {
      db.close();
      return;
    }
    process.exit(1);
  }

  if (data.supersedes) {
    const old = db.prepare('SELECT id, status FROM rules WHERE id = ?').get(data.supersedes);
    if (!old) {
      process.exit(1);
    }
    if (old.status !== 'active') {
      process.exit(1);
    }
  }

  const status = data.status || 'active';
  if (!VALID_STATUSES.includes(status)) {
    process.exit(1);
  }

  const existingFeature = db.prepare('SELECT id FROM features WHERE id = ?').get(data.feature);
  if (!existingFeature) {
    db.prepare('INSERT INTO features (id, name, purpose, scope) VALUES (?, ?, ?, ?)').run(
      data.feature,
      data.feature_name || data.feature,
      data.feature_purpose || null,
      data.feature_scope || null,
    );
  }

  const tx = db.transaction(() => {
    db.prepare(
      'INSERT INTO rules (id, feature_id, status, title, rule, why, context, supersedes, superseded_by, superseded_reason) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    ).run(
      ruleId,
      data.feature,
      status,
      data.title || '',
      data.rule,
      data.why || null,
      data.context || null,
      data.supersedes || null,
      data.superseded_by || null,
      data.superseded_reason || null,
    );

    db.prepare('DELETE FROM scenarios WHERE rule_id = ?').run(ruleId);
    for (const sc of data.scenarios || []) {
      db.prepare('INSERT INTO scenarios (rule_id, title, given_text, when_text, then_text) VALUES (?, ?, ?, ?, ?)').run(
        ruleId,
        sc.title || '',
        sc.given || null,
        sc.when || null,
        sc.then || null,
      );
    }

    if (data.supersedes) {
      db.prepare('UPDATE rules SET status = ?, superseded_by = ?, superseded_reason = ? WHERE id = ?').run(
        'superseded',
        ruleId,
        data.superseded_reason || null,
        data.supersedes,
      );
    }
  });

  tx();
  db.close();
  cmdDump();
};

/**
 * Updates the name, purpose or scope of an existing area, read as YAML from stdin:
 * `feature` plus any of `feature_name`, `feature_purpose`, `feature_scope`. `add` only writes
 * those fields when it creates the area, so this is the one way to change them. Rules are not touched.
 */
const cmdArea = () => {
  const data = load(readFileSync('/dev/stdin', 'utf-8')) || {};
  if (!data.feature) {
    process.stderr.write('Missing the area to update: feature: FEA-XXX\n');
    process.exit(1);
  }

  const db = getDb();
  initDb(db);
  const feature = db.prepare('SELECT id, name, purpose, scope FROM features WHERE id = ?').get(data.feature);
  if (!feature) {
    db.close();
    process.stderr.write(`${data.feature} does not exist\n`);
    process.exit(1);
  }

  db.prepare('UPDATE features SET name = ?, purpose = ?, scope = ? WHERE id = ?').run(
    data.feature_name ?? feature.name,
    data.feature_purpose ?? feature.purpose,
    data.feature_scope ?? feature.scope,
    data.feature,
  );
  db.close();
  cmdDump();
};

/**
 * Deletes a rule that should never have existed (wrong feature id, accidental
 * duplicate, half-written submission). A rule that was merely wrong is replaced
 * with `supersedes` instead, which keeps the history.
 * Refuses to touch a rule that is part of a supersedes chain: deleting it would
 * leave another rule pointing at nothing.
 */
const cmdDelete = (args) => {
  const opts = parseArgs(args);
  const ruleId = typeof opts.id === 'string' ? opts.id : null;
  if (ruleId === null) {
    process.stderr.write('Missing the rule to delete: --id BR-xxx\n');
    process.exit(1);
  }

  const db = getDb();
  initDb(db);

  const rule = db.prepare('SELECT id, status, supersedes, superseded_by FROM rules WHERE id = ?').get(ruleId);
  if (!rule) {
    db.close();
    process.stderr.write(`${ruleId} does not exist\n`);
    process.exit(1);
  }
  if (rule.superseded_by) {
    db.close();
    process.stderr.write(`${ruleId} was already superseded by ${rule.superseded_by}: it is history and is kept\n`);
    process.exit(1);
  }
  if (rule.supersedes) {
    db.close();
    process.stderr.write(`${ruleId} superseded ${rule.supersedes}: deleting it would leave that rule pointing at nothing\n`);
    process.exit(1);
  }

  const tx = db.transaction(() => {
    db.prepare('DELETE FROM scenarios WHERE rule_id = ?').run(ruleId);
    db.prepare('DELETE FROM rules WHERE id = ?').run(ruleId);
  });
  tx();
  db.close();

  process.stderr.write(`${ruleId} deleted\n`);
  cmdDump();
};

const cmdDump = () => {
  const db = getDb();
  initDb(db);

  const files = readdirSync(RULES_DIR).filter((f) => f.endsWith('.yaml') && f !== TEMPLATE_FILE);
  if (files.length > 0 && !existsSync(HISTORY_DIR)) {
    mkdirSync(HISTORY_DIR, { recursive: true });
  }
  if (files.length > 0) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 23);
    execSync(`tar czf "${HISTORY_DIR}/${timestamp}.tar.gz" -C "${RULES_DIR}" ${files.join(' ')} 2>/dev/null`, {
      stdio: 'ignore',
    });
  }

  const features = db.prepare('SELECT * FROM features ORDER BY id').all();

  for (const feature of features) {
    const rules = db
      .prepare(
        "SELECT * FROM rules WHERE feature_id = ? ORDER BY CASE status WHEN 'active' THEN 0 WHEN 'superseded' THEN 1 WHEN 'inactive' THEN 2 END, id",
      )
      .all(feature.id);

    const doc = {
      id: feature.id,
      name: feature.name,
      purpose: feature.purpose,
      scope: feature.scope || undefined,
      rules: rules.map((r) => {
        const scenarios = db
          .prepare('SELECT title, given_text, when_text, then_text FROM scenarios WHERE rule_id = ?')
          .all(r.id);
        return {
          id: r.id,
          status: r.status,
          title: r.title || undefined,
          rule: r.rule,
          why: r.why || undefined,
          context: r.context || undefined,
          supersedes: r.supersedes || undefined,
          superseded_by: r.superseded_by || undefined,
          superseded_reason: r.superseded_reason || undefined,
          scenarios:
            scenarios.length > 0
              ? scenarios.map((s) => ({
                  title: s.title,
                  given: s.given_text || undefined,
                  when: s.when_text || undefined,
                  then: s.then_text || undefined,
                }))
              : undefined,
        };
      }),
    };

    const cleanDoc = JSON.parse(JSON.stringify(doc));
    const yamlContent = dump(cleanDoc, { indent: 2, lineWidth: 120, noRefs: true });
    writeFileSync(`${RULES_DIR}/${feature.id.toLowerCase()}.yaml`, yamlContent);
  }

  db.close();
};

const main = () => {
  const cmd = process.argv[2];
  const args = process.argv.slice(3);

  switch (cmd) {
    case 'build':
      cmdBuild();
      break;
    case 'query':
      cmdQuery(args);
      break;
    case 'add':
      cmdAdd();
      break;
    case 'dump':
      cmdDump();
      break;
    case 'delete':
      cmdDelete(args);
      break;
    case 'area':
      cmdArea();
      break;
    default:
      help();
      break;
  }
};

main();
