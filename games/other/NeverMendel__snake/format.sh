#!/bin/bash
find -type f \( -iname "*.h" -o -iname "*.cpp" \) -not -path "./build/*" | xargs clang-format-18 -i -style=file
