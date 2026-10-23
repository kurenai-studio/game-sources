cmake_minimum_required(VERSION 3.30)
project(c_snake C)

set(CMAKE_C_STANDARD 11) ## raylib requires this version


######## for raylib ########
include(FetchContent)

function(include_dependency libName gitURL gitTag)
    FetchContent_Declare(${libName}
        GIT_REPOSITORY ${gitURL}
            GIT_TAG ${gitTag}
            GIT_SHALLOW TRUE
            GIT_PROGRESS TRUE
    )
    FetchContent_MakeAvailable(${libName})
endfunction()

set(LIB1 raylib)
set (GIT_URL https://github.com/raysan5/raylib.git)
set (RAYLIB_TAG 5.5)

find_package(${LIB1} QUIET)
if (NOT ${LIB1}_FOUND)
    include_dependency(${LIB1} ${GIT_URL} ${RAYLIB_TAG})
endif ()
###### end for raylib ######

add_executable(c_snake main.c)

######## for raylib ########
#target_include_directories(c_snake PRIVATE ${raylib_INCLUDE_DIRS})

target_link_libraries(c_snake PRIVATE ${LIB1})
###### end for raylib ######
