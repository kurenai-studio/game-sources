add_executable(Tests-Core-Grid "GridTesting.cpp")

set_target_properties(Tests-Core-Grid PROPERTIES OUTPUT_NAME "Tests-Core-Grid")
target_link_libraries(Tests-Core-Grid PRIVATE GTest::gtest GTest::gtest_main GTest::gmock GTest::gmock_main GridWorks)

add_test(CoreGrid_GTest Tests-Core-Grid)

install(TARGETS Tests-Core-Grid
    RUNTIME DESTINATION tests/framework
    LIBRARY DESTINATION tests/framework
    ARCHIVE DESTINATION tests/framework)
install(FILES $<TARGET_RUNTIME_DLLS:Tests-Core-Grid> DESTINATION tests/framework)

if(${VERBOSE})
    message(STATUS "CORE-GRID TEST ADDED.")
endif()