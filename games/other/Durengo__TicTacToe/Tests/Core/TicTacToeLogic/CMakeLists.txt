add_executable(Tests-Core-TicTacToeLogic "TicTacToeLogicTesting.cpp")

set_target_properties(Tests-Core-TicTacToeLogic PROPERTIES OUTPUT_NAME "Tests-Core-TicTacToeLogic")
target_link_libraries(Tests-Core-TicTacToeLogic PRIVATE GTest::gtest GTest::gtest_main GTest::gmock GTest::gmock_main GridWorks)

add_test(CoreTTTLogic_GTest Tests-Core-TicTacToeLogic)

install(TARGETS Tests-Core-TicTacToeLogic
    RUNTIME DESTINATION tests/framework
    LIBRARY DESTINATION tests/framework
    ARCHIVE DESTINATION tests/framework)
install(FILES $<TARGET_RUNTIME_DLLS:Tests-Core-TicTacToeLogic> DESTINATION tests/framework)

if(${VERBOSE})
    message(STATUS "CORE-GRID TEST ADDED.")
endif()