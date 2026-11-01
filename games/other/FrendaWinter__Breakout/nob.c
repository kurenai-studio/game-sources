#define NOB_IMPLEMENTATION
#include "nob.h"

#define BUILD_FOLDER "build/"
#define SRC_FOLDER   "src/"

int main(int argc, char **argv)
{
    NOB_GO_REBUILD_URSELF(argc, argv);

    Nob_Cmd cmd = {0};

    if (!nob_mkdir_if_not_exists(BUILD_FOLDER)) return 1;
    nob_cmd_append(&cmd, "g++", 
                    "-Wall", "-Wextra",                                         // Warning
                    "-I/usr/include", "-lraylib",                               // Raylib
                    "-o", BUILD_FOLDER"breakout",                                  // Output
                    SRC_FOLDER"main.cpp");        // Source
    if (!nob_cmd_run_sync(cmd)) return 1;

    return 0;
}
