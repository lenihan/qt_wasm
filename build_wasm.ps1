# From https://doc.qt.io/qt-6/wasm.htm
Set-Location ~/repos/qt_wasm/build-wasm
../../emsdk/emsdk_env.ps1
../../emsdk/emsdk install 3.1.25
../../emsdk/emsdk activate 3.1.25
cmake `
    -DCMAKE_TOOLCHAIN_FILE="C:/Users/david/repos/qt6/build-wasm/install/qtbase/lib/cmake/Qt6/qt.toolchain.cmake" `
    -DCMAKE_TOOLCHAIN_FILE="C:\Users\david\repos\emsdk\upstream\emscripten\cmake\Modules\Platform\Emscripten.cmake"
    -DCMAKE_MODULE_PATH="C:/Users/david/repos/qt6/build-wasm/install/lib/cmake/Qt6" `
    -DCMAKE_LIBRARY_PATH="C:/Users/david/repos/qt6/build-wasm/install/lib/cmake/Qt6" `
    ..

#    C:\Users\david\repos\qt6\build-wasm\install\lib\cmake\Qt6\FindWrapRt.cmake
#    C:\Users\david\repos\qt6\build-wasm\qtbase\lib\cmake\Qt6\FindWrapRt.cmake


#    -- Using Qt bundled ZLIB.
#    -- Using Qt bundled PCRE2.
#    -- Could NOT find WrapRt (missing: WrapRt_FOUND)
#    CMake Warning at C:/Program Files/CMake/share/cmake-3.26/Modules/CMakeFindDependencyMacro.cmake:76 (find_package):
#      Found package configuration file:
   
#        C:/Users/david/repos/qt6/build-wasm/qtbase/lib/cmake/Qt6Core/Qt6CoreConfig.cmake
   
#      but it set Qt6Core_FOUND to FALSE so package "Qt6Core" is considered to be
#      NOT FOUND.  Reason given by package:
   
#      Qt6Core could not be found because dependency WrapRt could not be found.
   
#      Configuring with --debug-find-pkg=WrapRt might reveal details why the
#      package was not found.
   
#      Configuring with -DQT_DEBUG_FIND_PACKAGE=ON will print the values of some
#      of the path variables that find_package uses to try and find the package.
   
#    Call Stack (most recent call first):
#      C:/Users/david/repos/qt6/build-wasm/qtbase/lib/cmake/Qt6/QtPublicDependencyHelpers.cmake:111 (find_dependency)
#      C:/Users/david/repos/qt6/build-wasm/qtbase/lib/cmake/Qt6Widgets/Qt6WidgetsDependencies.cmake:39 (_qt_internal_find_qt_dependencies)
#      C:/Users/david/repos/qt6/build-wasm/qtbase/lib/cmake/Qt6Widgets/Qt6WidgetsConfig.cmake:40 (include)
#      C:/Users/david/repos/qt6/build-wasm/qtbase/lib/cmake/Qt6/Qt6Config.cmake:157 (find_package)
#      CMakeLists.txt:20 (find_package)