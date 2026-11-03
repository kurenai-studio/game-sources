local utils = import 'utils.libjsonnet';

{
  uses_user_defaults: true,
  project_type: 'c',
  project_name: 'tetris-efi',
  version: '0.0.1',
  description: 'A Tetris clone that runs as a UEFI application.',
  custom_project_badges: [
    {
      anchor: '[![Tests](https://github.com/Tatsh/tetris-efi/actions/workflows/tests.yml/badge.svg)]',
      href: 'https://github.com/Tatsh/tetris-efi/actions/workflows/tests.yml',
    },
    {
      anchor: '[![Coverage Status](https://coveralls.io/repos/github/Tatsh/tetris-efi/badge.svg?branch=master)]',
      href: 'https://coveralls.io/github/Tatsh/tetris-efi?branch=master',
    },
  ],
  keywords: ['efi', 'game', 'tetris', 'uefi'],
  want_main: false,
  want_codeql: true,
  github+: {
    codeql+: {
      languages: ['actions'],
      runs_on: 'ubuntu-latest',
      workflow_file: 'codeql-actions.yml',
    },
  },
  want_tests: false,  // Handled here not by Wiswa.
  want_winget: false,
  clang_format_args: 'src/*.c src/*.h tests/*.c',
  vscode+: {
    c_cpp+: {
      configurations: [
        {
          cStandard: 'gnu23',
          compilerArgs: ['-Wall', '-fno-stack-protector', '-fpic', '-fshort-wchar', '-mno-red-zone'],
          compilerPath: '/usr/bin/gcc',
          cppStandard: 'gnu++23',
          defines: ['EFI_FUNCTION_WRAPPER', 'GOP=1'],
          includePath: [
            '${default}',
            '${workspaceFolder}',
            '${workspaceFolder}/src',
            '/usr/include/efi/protocol',
            '/usr/include/efi/x86_64',
          ],
          name: 'Linux',
        },
      ],
    },
    launch+: {
      configurations: [
        {
          cwd: '${workspaceFolder}/build',
          name: 'test_piece',
          program: '${workspaceFolder}/build/tests/test_piece',
          request: 'launch',
          type: 'cppdbg',
        },
        {
          cwd: '${workspaceFolder}/build',
          name: 'test_game',
          program: '${workspaceFolder}/build/tests/test_game',
          request: 'launch',
          type: 'cppdbg',
        },
      ],
    },
    settings+: {
      'C_Cpp.default.includePath': [
        '/usr/include/efi',
        '/usr/include/efi/protocol',
        '/usr/include/efi/x86_64',
      ],
      'cmake.configureArgs': ['-DBUILD_TESTS=ON'],
    },
  },
}
+ {
  want_scan_build: true,
  github+: { workflows+: {
    scan_build+: {
      configure_command: 'cmake -S . -B build-scan -DCMAKE_BUILD_TYPE=Debug',
      documentation_steps: [
        {
          name: 'Build project homepage',
          uses: 'actions/jekyll-build-pages@44a6e6beabd48582f863aeeb6cb2151cc1716697',
          with: {
            destination: 'build/html',
          },
        },
      ],
      env: {},
      setup_steps: [
        {
          name: 'Install build dependencies',
          run: |||
            sudo apt-get update
            sudo apt-get install -y gnu-efi mtools ninja-build xorriso
          |||,
        },
        {
          name: 'Install current CMake',
          run: 'pipx install cmake',
        },
      ],
    },
  } },
}
