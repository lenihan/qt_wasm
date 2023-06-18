# CMakeList.txt : Top-level CMake project file, do global configuration
# and include sub-projects here.

cmake_minimum_required(VERSION 3.16)
project("qt_wasm")

# Use `dump_vars()` to see cmake variables. Helpful for debugging.
function(dump_vars)
  get_cmake_property(_variableNames VARIABLES)
  list (SORT _variableNames)
  foreach (_variableName ${_variableNames})
      message(STATUS "${_variableName}=${${_variableName}}")
  endforeach()
endfunction()

# From https://doc.qt.io/qt-6/cmake-get-started.html#structuring-projects
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets)
qt_standard_project_setup()

# Visual Studio: Group ALL_BUILD.vcxproj and ZERO_CHECK.vcxproj under "CMakePredifinedTargets"
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Include sub-projects
add_subdirectory(src/hello_qt)
