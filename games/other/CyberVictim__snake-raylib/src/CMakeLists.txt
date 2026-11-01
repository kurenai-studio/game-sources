cmake_minimum_required(VERSION 3.11) # FetchContent is available in 3.11+
project(Snake)

add_subdirectory(dependencies/raylib dependencies/raylib)

file(GLOB PROJECT_SOURCE_FILES CONFIGURE_DEPENDS *.[ch])
# include_directories(include/)
add_executable(${PROJECT_NAME} ${PROJECT_SOURCE_FILES})
if (MSVC)
else()
    target_compile_options(${PROJECT_NAME} PUBLIC -Wall -Wpedantic -Wextra -Wformat=2 -Wno-unused-parameter -Wshadow -Wwrite-strings -Wstrict-prototypes -Wold-style-definition -Wredundant-decls -Wnested-externs -Wmissing-include-dirs -Wjump-misses-init -Wlogical-op)
endif()
#set(raylib_VERBOSE 1)
target_link_libraries(${PROJECT_NAME} raylib)
file(COPY resources/ DESTINATION resources/)

# Web Configurations
if (${PLATFORM} STREQUAL "Web")
    # Tell Emscripten to build an example.html file.
    set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".html")
endif()

# Checks if OSX and links appropriate frameworks (Only required on MacOS)
if (APPLE)
    target_link_libraries(${PROJECT_NAME} "-framework IOKit")
    target_link_libraries(${PROJECT_NAME} "-framework Cocoa")
    target_link_libraries(${PROJECT_NAME} "-framework OpenGL")
endif()