const fs = require('fs');
const path = require('path');
const mammoth = require('mammoth');
const { JSDOM } = require('jsdom');

const DEFAULT_INPUT = path.join(
  __dirname,
  '../public/assets/Nathan Zimmerman Resume.docx'
);
const DEFAULT_OUTPUT = path.join(__dirname, '../public/assets/resume.json');

function printHelp() {
  return [
    'Usage: node scripts/generate_resume_json.js [--input path/to/resume.docx] [--output path/to/resume.json]',
    '',
    'Options:',
    '  --input, -i   Resume .docx file to convert',
    '  --output, -o  JSON file to write',
    '  --help, -h    Show this help message',
  ].join('\n');
}

function parseArgs(argv = []) {
  const options = {
    input: DEFAULT_INPUT,
    output: DEFAULT_OUTPUT,
    help: false,
  };

  for (let index = 0; index < argv.length; index++) {
    const arg = argv[index];

    if (arg === '--help' || arg === '-h') {
      options.help = true;
      continue;
    }

    if (arg === '--input' || arg === '-i') {
      options.input = argv[++index];
      continue;
    }

    if (arg === '--output' || arg === '-o') {
      options.output = argv[++index];
      continue;
    }

    throw new Error(`Unknown argument: ${arg}`);
  }

  if (!options.input) {
    throw new Error('Missing value for --input');
  }

  if (!options.output) {
    throw new Error('Missing value for --output');
  }

  return {
    ...options,
    input: path.resolve(options.input),
    output: path.resolve(options.output),
  };
}

function validatePaths({ input, output }) {
  if (path.extname(input).toLowerCase() !== '.docx') {
    throw new Error(`Input must be a .docx file: ${input}`);
  }

  if (path.extname(output).toLowerCase() !== '.json') {
    throw new Error(`Output must be a .json file: ${output}`);
  }

  const inputStat = fs.statSync(input);
  if (!inputStat.isFile()) {
    throw new Error(`Input must be a file: ${input}`);
  }
}

function pushTextBlocks(elements, tag, text) {
  text
    .split(/[\n•]/)
    .map((block) => block.trim())
    .filter((block) => block.length > 0)
    .forEach((block) => {
      elements.push({ tag, text: block });
    });
}

function extractResumeElements(html) {
  const dom = new JSDOM(html);
  const doc = dom.window.document;
  const elements = [];

  doc.body.childNodes.forEach((node) => {
    if (node.nodeType !== 1) return;

    const tag = node.tagName.toLowerCase();

    // Each list item becomes its own entry; reading the whole list's
    // textContent would run the items together without a separator.
    if (tag === 'ul' || tag === 'ol') {
      node.querySelectorAll('li').forEach((item) => {
        pushTextBlocks(elements, 'li', item.textContent);
      });
      return;
    }

    pushTextBlocks(elements, tag, node.textContent);
  });

  return elements;
}

function validateResumeElements(elements) {
  if (!Array.isArray(elements)) {
    throw new Error('Resume JSON must be an array');
  }

  if (elements.length === 0) {
    throw new Error('Resume JSON must include at least one text element');
  }

  elements.forEach((element, index) => {
    if (!element || typeof element !== 'object' || Array.isArray(element)) {
      throw new Error(`Resume element ${index} must be an object`);
    }

    if (
      typeof element.tag !== 'string' ||
      !/^[a-z][a-z0-9-]*$/.test(element.tag)
    ) {
      throw new Error(`Resume element ${index} has an invalid tag`);
    }

    if (typeof element.text !== 'string' || element.text.trim().length === 0) {
      throw new Error(`Resume element ${index} has empty text`);
    }
  });

  return elements;
}

async function convertResume({
  input = DEFAULT_INPUT,
  output = DEFAULT_OUTPUT,
} = {}) {
  const resolvedOptions = {
    input: path.resolve(input),
    output: path.resolve(output),
  };

  validatePaths(resolvedOptions);

  console.log(`Reading ${resolvedOptions.input}...`);
  const buffer = fs.readFileSync(resolvedOptions.input);

  console.log('Converting to HTML...');
  const result = await mammoth.convertToHtml({ buffer });

  console.log('Parsing HTML...');
  const elements = validateResumeElements(extractResumeElements(result.value));

  fs.mkdirSync(path.dirname(resolvedOptions.output), { recursive: true });
  console.log(
    `Writing ${elements.length} elements to ${resolvedOptions.output}...`
  );
  fs.writeFileSync(
    resolvedOptions.output,
    `${JSON.stringify(elements, null, 2)}\n`
  );

  return elements;
}

async function main(argv = process.argv.slice(2)) {
  const options = parseArgs(argv);

  if (options.help) {
    console.log(printHelp());
    return;
  }

  await convertResume(options);
  console.log('Done.');
}

if (require.main === module) {
  main().catch((error) => {
    console.error('Error processing resume:', error.message);
    process.exit(1);
  });
}

module.exports = {
  DEFAULT_INPUT,
  DEFAULT_OUTPUT,
  convertResume,
  extractResumeElements,
  parseArgs,
  printHelp,
  validateResumeElements,
};
