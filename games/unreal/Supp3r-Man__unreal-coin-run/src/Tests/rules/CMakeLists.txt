cmake_minimum_required(VERSION 3.16)
project(CoinRunRulesTests CXX)

# Compiles the engine-free game rules from the Unreal project together with a plain console test runner.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CORE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../Source/CoinRun)

add_executable(rules_tests
    test_main.cpp
    ${CORE_DIR}/Rules/Dash.cpp
    ${CORE_DIR}/Rules/HighScore.cpp
    ${CORE_DIR}/Rules/Motion.cpp
    ${CORE_DIR}/Rules/Rng.cpp
    ${CORE_DIR}/Rules/RunState.cpp
    ${CORE_DIR}/Rules/Spawner.cpp)

# The rules are included as "Rules/Foo.h", relative to the module directory (the same include root the Unreal build uses).
target_include_directories(rules_tests PRIVATE ${CORE_DIR})

if(MSVC)
  target_compile_options(rules_tests PRIVATE /W4 /WX)
else()
  target_compile_options(rules_tests PRIVATE -Wall -Wextra -Wshadow -Werror)
endif()

enable_testing()
add_test(NAME rules_tests COMMAND rules_tests)
