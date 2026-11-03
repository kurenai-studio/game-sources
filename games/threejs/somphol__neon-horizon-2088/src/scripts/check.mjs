#!/usr/bin/env node
// Release checker for NEON HORIZON 2088. Dependency-free; run with `node scripts/check.mjs`.

import { execFileSync } from 'node:child_process'
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs'
import { dirname, join, relative, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
let checks = 0
const failures = []

function pass(condition, label) {
  checks++
  if (!condition) failures.push(label)
}

function read(path) {
  return readFileSync(join(root, path), 'utf8')
}

function walk(dir, extensions) {
  const out = []
  for (const entry of readdirSync(join(root, dir), { withFileTypes: true })) {
    if (entry.name === '.git' || entry.name === 'node_modules') continue
    const rel = join(dir, entry.name)
    if (entry.isDirectory()) out.push(...walk(rel, extensions))
    else if (extensions.some((ext) => entry.name.endsWith(ext))) out.push(rel)
  }
  return out
}

// 1. Required release files.
const required = [
  'index.html',
  'style.css',
  'script.js',
  'README.md',
  'AGENTS.md',
  'LICENSE',
  '.nojekyll',
  'docs/ARCHITECTURE.md',
  'docs/REPRODUCTION.md',
  'docs/DEPLOYMENT.md',
  'docs/TESTING.md',
  'docs/social-card.png',
  'scripts/check.mjs',
  'skills/neon-horizon-2088/SKILL.md',
  'skills/neon-horizon-2088/ATTRIBUTION.md',
  'skills/neon-horizon-2088/references/method.md',
  'skills/neon-horizon-2088/references/lessons.md',
  'skills/neon-horizon-2088/references/verification.md',
]
for (const file of required) pass(existsSync(join(root, file)), `missing required file: ${file}`)

// 2. Local src/href references in index.html resolve.
const html = read('index.html')
const refPattern = /\b(?:src|href)\s*=\s*["']([^"']+)["']/g
let match
while ((match = refPattern.exec(html)) !== null) {
  const ref = match[1].trim()
  if (!ref || ref.startsWith('#') || /^(?:https?:|data:|mailto:|tel:|\/\/)/i.test(ref)) continue
  const target = ref.split(/[?#]/)[0]
  if (!target) continue
  const resolved = target.startsWith('/') ? join(root, target) : resolve(root, target)
  pass(existsSync(resolved), `index.html references missing local file: ${ref}`)
}

// 3. Relative Markdown links resolve.
const markdownFiles = [
  'README.md',
  'AGENTS.md',
  'CHANGELOG.md',
  'CONTRIBUTING.md',
  'SECURITY.md',
  'CODE_OF_CONDUCT.md',
  'THIRD_PARTY_NOTICES.md',
  ...walk('docs', ['.md']),
  ...walk('skills', ['.md']),
]
const linkPattern = /!?\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g
for (const file of markdownFiles) {
  const text = read(file)
  let link
  while ((link = linkPattern.exec(text)) !== null) {
    const target = link[1].trim()
    if (!target || target.startsWith('#') || /^(?:https?:|mailto:|data:|tel:)/i.test(target)) continue
    const pathPart = target.split(/[?#]/)[0]
    if (!pathPart) continue
    const resolved = pathPart.startsWith('/')
      ? join(root, pathPart)
      : resolve(dirname(join(root, file)), pathPart)
    pass(
      existsSync(resolved),
      `${file} has a broken relative link: ${target}`,
    )
  }
}

// 4. JavaScript syntax.
for (const file of walk('.', ['.js', '.mjs'])) {
  try {
    execFileSync(process.execPath, ['--check', join(root, file)], { stdio: 'pipe' })
    pass(true, '')
  } catch (error) {
    pass(false, `node --check failed for ${file}\n${error.stderr?.toString() ?? error.message}`)
  }
}

// 5. JSON parses.
for (const file of walk('.', ['.json'])) {
  try {
    JSON.parse(readFileSync(join(root, file), 'utf8'))
    pass(true, '')
  } catch (error) {
    pass(false, `invalid JSON: ${file} (${error.message})`)
  }
}

// 6. The skill template must be exactly the three release sources, byte-for-byte.
const templateDir = 'skills/neon-horizon-2088/assets/template'
const templateFiles = existsSync(join(root, templateDir))
  ? readdirSync(join(root, templateDir)).filter((name) => {
      try {
        return statSync(join(root, templateDir, name)).isFile()
      } catch {
        return false
      }
    }).sort()
  : []
pass(
  JSON.stringify(templateFiles) === JSON.stringify(['index.html', 'script.js', 'style.css']),
  `template must contain exactly index.html, script.js and style.css (found: ${templateFiles.join(', ') || 'nothing'})`,
)
for (const name of ['index.html', 'style.css', 'script.js']) {
  const source = join(root, name)
  const copy = join(root, templateDir, name)
  if (!existsSync(copy)) {
    pass(false, `template is missing ${name}`)
    continue
  }
  pass(
    readFileSync(source).equals(readFileSync(copy)),
    `template ${name} is not byte-identical to the release source`,
  )
}

// 7. Skill frontmatter and the no-absolute-path rule.
const skillPath = 'skills/neon-horizon-2088/SKILL.md'
let skill = ''
try {
  skill = read(skillPath)
} catch {
  // The required-file check above already reports the missing SKILL.md.
}
const frontmatter = skill.match(/^---\n([\s\S]*?)\n---/)
pass(Boolean(frontmatter), 'SKILL.md has no YAML frontmatter')
const field = (key) => frontmatter?.[1].match(new RegExp(`^${key}:\\s*(.+)$`, 'm'))?.[1]?.trim()
pass(field('name') === 'neon-horizon-2088', 'SKILL.md name must be neon-horizon-2088')
pass((field('description')?.length ?? 0) >= 20, 'SKILL.md description must be at least 20 characters')
pass(Boolean(field('version')), 'SKILL.md version is missing')
for (const file of [...walk('skills', ['.md']), ...markdownFiles.filter((f) => f.startsWith('docs/'))]) {
  pass(!read(file).includes('/Users/'), `${file} contains an absolute /Users/ path`)
}

// 8. README documentation index points at the release docs.
const readme = read('README.md')
for (const link of [
  'AGENTS.md',
  'docs/REPRODUCTION.md',
  'docs/ARCHITECTURE.md',
  'docs/TESTING.md',
  'docs/DEPLOYMENT.md',
  'skills/neon-horizon-2088/SKILL.md',
]) {
  pass(readme.includes(`](${link})`), `README Documentation section is missing ${link}`)
}

// Report.
if (failures.length) {
  for (const failure of failures) console.error(`FAIL ${failure}`)
  console.error(`FAILED ${checks} checks, ${failures.length} failure(s)`)
  process.exit(1)
}
console.log(`OK ${checks} checks`)
