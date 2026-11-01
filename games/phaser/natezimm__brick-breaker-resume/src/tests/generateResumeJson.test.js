const {
  DEFAULT_INPUT,
  DEFAULT_OUTPUT,
  extractResumeElements,
  parseArgs,
  printHelp,
  validateResumeElements,
} = require('../scripts/generate_resume_json.js');

describe('generate_resume_json script helpers', () => {
  test('parseArgs uses defaults and resolves paths', () => {
    expect(parseArgs([])).toEqual({
      input: DEFAULT_INPUT,
      output: DEFAULT_OUTPUT,
      help: false,
    });
  });

  test('parseArgs accepts custom input and output aliases', () => {
    expect(parseArgs(['-i', 'resume.docx', '-o', 'resume.json'])).toMatchObject(
      {
        input: expect.stringContaining('resume.docx'),
        output: expect.stringContaining('resume.json'),
        help: false,
      }
    );
  });

  test('parseArgs rejects unknown arguments and missing values', () => {
    expect(() => parseArgs(['--bad'])).toThrow('Unknown argument');
    expect(() => parseArgs(['--input'])).toThrow('Missing value for --input');
  });

  test('printHelp includes supported flags', () => {
    expect(printHelp()).toContain('--input');
    expect(printHelp()).toContain('--output');
  });

  test('extractResumeElements preserves block tags and splits text blocks', () => {
    const elements = extractResumeElements(`
      <h1>Nathan Zimmerman</h1>
      <p>Senior Engineer\nPlatform Lead</p>
    `);

    expect(elements).toEqual([
      { tag: 'h1', text: 'Nathan Zimmerman' },
      { tag: 'p', text: 'Senior Engineer' },
      { tag: 'p', text: 'Platform Lead' },
    ]);
  });

  test('extractResumeElements emits one entry per list item', () => {
    const elements = extractResumeElements(`
      <p>WORK HISTORY</p>
      <ul><li>Built the first thing.</li><li>Shipped the second thing.</li></ul>
      <ol><li>Ranked first</li></ol>
    `);

    expect(elements).toEqual([
      { tag: 'p', text: 'WORK HISTORY' },
      { tag: 'li', text: 'Built the first thing.' },
      { tag: 'li', text: 'Shipped the second thing.' },
      { tag: 'li', text: 'Ranked first' },
    ]);
  });

  test('validateResumeElements enforces the generated schema', () => {
    expect(validateResumeElements([{ tag: 'p', text: 'Valid text' }])).toEqual([
      { tag: 'p', text: 'Valid text' },
    ]);

    expect(() => validateResumeElements([])).toThrow('at least one');
    expect(() =>
      validateResumeElements([{ tag: 'P', text: 'bad tag' }])
    ).toThrow('invalid tag');
    expect(() => validateResumeElements([{ tag: 'p', text: '' }])).toThrow(
      'empty text'
    );
  });
});
