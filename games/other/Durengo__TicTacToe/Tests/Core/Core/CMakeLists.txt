add_executable(Tests-CoreTesting "CoreTesting.cpp")

set_target_properties(Tests-CoreTesting PROPERTIES OUTPUT_NAME "Tests-CoreTesting")
target_link_libraries(Tests-CoreTesting PRIVATE GTest::gtest GTest::gtest_main GTest::gmock GTest::gmock_main)

add_test(Core_GTest Tests-CoreTesting)

install(TARGETS Tests-CoreTesting
    RUNTIME DESTINATION tests/framework
    LIBRARY DESTINATION tests/framework
    ARCHIVE DESTINATION tests/framework)
install(FILES $<TARGET_RUNTIME_DLLS:Tests-CoreTesting> DESTINATION tests/framework)

if(${VERBOSE})
    message(STATUS "CORE TEST ADDED.")
endif()