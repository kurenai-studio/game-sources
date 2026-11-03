// @ts-check
import js from '@eslint/js'
import prettier from 'eslint-config-prettier'
import globals from 'globals'
import tseslint from 'typescript-eslint'

export default tseslint.config(
	{ ignores: ['dist', 'node_modules'] },
	js.configs.recommended,
	...tseslint.configs.recommendedTypeChecked,
	...tseslint.configs.stylisticTypeChecked,
	{
		files: ['src/**/*.ts'],
		languageOptions: {
			globals: globals.browser,
			parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
		},
		rules: {
			eqeqeq: ['error', 'always'],
			curly: ['error', 'multi-line'],
			'no-console': ['warn', { allow: ['warn', 'error'] }],
			'prefer-const': 'error',
			'no-var': 'error',
			'object-shorthand': 'error',
			'one-var': ['error', 'never'],
			'@typescript-eslint/consistent-type-imports': ['error', { fixStyle: 'inline-type-imports' }],
			'@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
			'@typescript-eslint/no-non-null-assertion': 'warn',
			'@typescript-eslint/prefer-nullish-coalescing': 'error',
			// Size guards: keep modules and functions small enough to read in one sitting
			'max-lines': ['warn', { max: 400, skipBlankLines: true, skipComments: true }],
			'max-lines-per-function': ['warn', { max: 120, skipBlankLines: true, skipComments: true }],
			complexity: ['warn', 25],
		},
	},
	{
		// Data tables: long by nature
		files: ['src/config/vehicles/**/*.ts'],
		rules: { 'max-lines': 'off' },
	},
	{
		files: ['*.js', '*.ts'],
		...tseslint.configs.disableTypeChecked,
		languageOptions: { globals: globals.node },
	},
	prettier,
)
