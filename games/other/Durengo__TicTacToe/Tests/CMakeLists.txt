find_package(GTest CONFIG REQUIRED)

add_subdirectory("Core")

if(${VERBOSE})
    message(STATUS "TTT GTEST SUITE ADDED.")
endif()