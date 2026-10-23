# Introduction
Hi there, welcome to c-snake-raylib!

This repository is for a snake game written in C using raylib!

More information will be added here in the future

# Setup (Building from source)

## From the terminal on MacOS
 - Prerequisities: You will need CMake installed on your machine
 - Step 1: clone this repo
 - Step 2: in the terminal, go to the root directory of where the project is cloned
 - Step 3: Pick an option from below and proceed with the steps in it

### Option 1 (manually entering build steps)
 - Step 4: type 'cmake -B build', hit enter
 - Step 5: type 'cmake --build build', hit enter
 - Step 6: type './build/c_snake', hit enter

### OR

### Option 2 (single command bash script)
 - Step 4: type 'sh build.sh', hit enter


# Acknowledgements
This project uses raylib, a library created to help with game programming! \
Here are some links with more information about raylib: \
website: https://www.raylib.com \
github: https://github.com/raysan5/raylib

The CMake template I have used is (mostly) from a github gist, \
which is linked in this video by the creator: https://www.youtube.com/watch?v=_i4wRjcp8eU

The sublime text project file setup (along with the compile errors highlighting) is based \
on a similar setup done by [Karl Zylinski](https://www.youtube.com/@karl_zylinski) for an Odin project in this video: https://www.youtube.com/watch?v=RF2MgVqfBV8
