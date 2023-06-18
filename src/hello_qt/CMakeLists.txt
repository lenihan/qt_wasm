# project(hello_qt)
# add_executable(${PROJECT_NAME} hello_qt.cpp)
# target_link_libraries(${PROJECT_NAME} ${Qt6Widgets_LIBRARIES} ${Qt6Core_LIBRARIES})

# From https://doc.qt.io/qt-6/cmake-get-started.html#structuring-projects
qt_add_executable(hello_qt
    hello_qt.cpp
)

target_link_libraries(hello_qt PRIVATE Qt6::Widgets)

# set_target_properties(hello_qt PROPERTIES
#     WIN32_EXECUTABLE ON  # Use GUI WinMain() instead of console main(): https://cmake.org/cmake/help/latest/prop_tgt/WIN32_EXECUTABLE.html
#     MACOSX_BUNDLE ON     # Can be launched from Finder: https://cmake.org/cmake/help/latest/prop_tgt/MACOSX_BUNDLE.html
# )