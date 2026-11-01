add_executable(Tests-Core-GameLogic "GameLogicTesting.cpp")

set_target_properties(Tests-Core-GameLogic PROPERTIES OUTPUT_NAME "Tests-Core-GameLogic")
target_link_libraries(Tests-Core-GameLogic PRIVATE GTest::gtest GTest::gtest_main GTest::gmock GTest::gmock_main GridWorks)

add_test(CoreGameLogic_GTest Tests-Core-GameLogic)

install(TARGETS Tests-Core-GameLogic
    RUNTIME DESTINATION tests/framework
    LIBRARY DESTINATION tests/framework
    ARCHIVE DESTINATION tests/framework)
install(FILES $<TARGET_RUNTIME_DLLS:Tests-Core-GameLogic> DESTINATION tests/framework)

if(${VERBOSE})
    message(STATUS "CORE-GRID TEST ADDED.")
endif()