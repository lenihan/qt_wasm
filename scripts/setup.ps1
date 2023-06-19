# Setup prerequisites, build environment, third_party directory, .env file for running apps.
#Requires -Version 7

# Global variables (all caps)
$ROOT_DIR = Resolve-Path $PSScriptRoot/..
$REPOS_DIR = Resolve-Path $ROOT_DIR/..
$QT_DIR = Join-Path $REPOS_DIR qt6
if ($IsWindows) {$OS = "windows"}
if ($IsLinux)   {$OS = "linux"}
if ($IsMacOS)   {$OS = "osx"}
$QT_BUILD_NATIVE_DIR = Join-Path $QT_DIR "build-$OS"
$QT_BUILD_WASM_DIR = Join-Path $QT_DIR "build-wasm"
$QT_INSTALL_NATIVE_DIR = Join-Path $QT_BUILD_NATIVE_DIR install
$QT_INSTALL_WASM_DIR = Join-Path $QT_BUILD_WASM_DIR install

function echo_command($cmd) {
    Write-Host $cmd -ForegroundColor Cyan
    Invoke-Expression $cmd
}

function setup_prerequisites {
    Write-Host "Setup prerequisites..." -ForegroundColor Green
    if ($IsWindows) {
        # verify access to required apps
        $required_apps = 
            "git", 
            "pwsh", 
            "cmake", 
            "perl", 
            "code", 
            "python3",
            "ninja",
            "$env:ProgramFiles\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1" 
        $all_commands_found = $true
        foreach ($ra in $required_apps) {
            $found_command = Get-Command $ra -ErrorAction SilentlyContinue
            if (!$found_command) {
                $all_commands_found = $false
                Write-Host "Could not find command: $ra" -ForegroundColor Red
            }
        }
        if (!$all_commands_found) {
            Write-Host "Cannot continue without access to required commands." -ForegroundColor Red
            exit
        }
    }
    elseif ($IsLinux) {
        $installed_packages = apt list --installed 2> $null
        $upgradeable_packages = apt list --upgradeable 2> $null
        function is_package_installed($pkg) {if ($installed_packages | Select-String "^$pkg/") {$true} else {$false}}
        function is_package_upgradeable($pkg) {if ($upgradeable_packages | Select-String "^$pkg/") {$true} else {$false}}
        $packages = "curl",                 # for vcpkg
                    "cmake",                # for vcpkg
                    "build-essential",      # for vcpkg: gcc, g++, make, C standard lib, dev tools                    
                    "bison",                # for gettext  (used by osg)
                    "python3-distutils",    # for fontconfig (used by osg)
                    "libgl1-mesa-dev",      # for osg "Could not find OpenGL"
                    "libtool",              # for osg

                    # for qt5: Some learned from https://github.com/microsoft/vcpkg/blob/master/scripts/azure-pipelines/linux/provision-image.sh
                    "libglu1-mesa-dev",     # for freeglut (used by qt5)
                    "libxi-dev",            # for angle (used by qt5)
                    "libxext-dev",          # for angle (used by qt5)
                    "autoconf",             # for icu (used by qt5)
                    "autoconf-archive",     # for icu (used by qt5)
                    "libx11-dev",
                    "libxkbcommon-x11-dev",                    
                    "libxext-dev",
                    "libxfixes-dev",
                    "libxrender-dev",
                    "libxcb1-dev",
                    "libx11-xcb-dev",
                    "libxcb-glx0-dev",
                    "libxcb-util0-dev",
                    "libxkbcommon-dev",
                    "libxcb-keysyms1-dev",
                    "libxcb-image0-dev",
                    "libxcb-shm0-dev",
                    "libxcb-icccm4-dev",
                    "libxcb-sync-dev",
                    "libxcb-xfixes0-dev",
                    "libxcb-shape0-dev",
                    "libxcb-randr0-dev",
                    "libxcb-render-util0-dev",
                    "libxcb-xinerama0-dev",
                    "libxcb-xkb-dev",
                    "libxcb-xinput-dev"

        $ran_apt_update = $false
        foreach ($pkg in $packages) {
            $installed = is_package_installed($pkg)
            if (!$installed) {
                if (!$ran_apt_update) {
                    echo_command "sudo apt update"
                    $ran_apt_update = $true
                }
                echo_command "sudo apt install -y $pkg"
            }
        }
        foreach ($pkg in $packages) {
            $upgradeable = is_package_upgradeable($pkg)
            if ($upgradeable) {
                if (!$ran_apt_update) {
                    echo_command "sudo apt update"
                    $ran_apt_update = $true
                }
                echo_command "sudo apt upgrade -y $pkg"
            }
        }
    }
    elseif ($IsMacOS) {
        # Unable to build qt5 (moc can't find libbz2d.1.0.dylib) because SIP (System Integrity Protection) won't pass
        # DYLD_LIBRARY_PATH to subprocesses.
        # Fix: Disable SIP
        # If SIP is enabled, exit
        $SIP_enabled = (csrutil status) -match "enabled."
        if ($SIP_enabled) {
            Write-Host "SIP (System Integrity Protection) must be disabled to build third party libraries." -ForegroundColor Red
            Write-Host "To disable, follow instructions here:" -ForegroundColor Red
            Write-Host "https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection" -ForegroundColor Red
            exit           
        }

        echo_command "brew install --cask visual-studio-code"
        echo_command "brew install autoconf"
        echo_command "brew install automake"
        echo_command "brew install libtool"
        echo_command "brew install nasm"
        echo_command "brew install cmake"
        echo_command "brew install autoconf-archive"
        echo_command "brew install gettext"
    }
}

function setup_build_environment {
    Write-Host "Setup build environment..." -ForegroundColor Green
    if ($IsWindows) {
        & "$env:ProgramFiles\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1" -Arch amd64
    }
}

function setup_third_party {
    Write-Host "Setup third party..." -ForegroundColor Green

    # qt build with wasm support
    Write-Host "Git clone Qt..." -ForegroundColor Green
    #
    # clone qt, init repo
    Set-Location $REPOS_DIR
    $QT_DIR_NAME = "qt6"
    git clone git://code.qt.io/qt/qt5.git $QT_DIR_NAME
    $QT_DIR = Join-Path $REPOS_DIR $QT_DIR_NAME
    Set-Location $QT_DIR
    git switch v6.5.1 --detach # from `git tag`
    perl ./init-repository
    # NOTE: Assuming setup_build_environment() already called
    # 
    Write-Host "Build native Qt..." -ForegroundColor Green
    if (Test-Path $QT_INSTALL_NATIVE_DIR) {
        Write-Host "Skipping native Qt build, install directory exists:  $QT_INSTALL_NATIVE_DIR" -ForegroundColor Yellow
    }
    else {
        # build native qt
        mkdir $QT_BUILD_NATIVE_DIR -ErrorAction SilentlyContinue
        Set-Location $QT_BUILD_NATIVE_DIR
        # configure qt, create ninja build files via cmake, set install to ./install dir
        ../configure -prefix ./install
        # build/install qt
        cmake --build . --parallel
        cmake --install .
        #
        # Install emsdk
        Write-Host "Install/activate emsdk..." -ForegroundColor Green
        Set-Location $REPOS_DIR
        # git clone https://github.com/emscripten-core/emsdk.git
        $EMSDK_DIR = Join-Path $REPOS_DIR "emsdk"
        Set-Location $EMSDK_DIR
        # Required emscripten version for Qt 3.6.1 is Emscripten 3.1.25 (from above https://doc.qt.io/qt-6/wasm.html)
        ./emsdk install 3.1.25 
        ./emsdk activate 3.1.25
        . ./emsdk_env.ps1
    }
    if (Test-Path $QT_INSTALL_WASM_DIR) {
        Write-Host "Skipping wasm Qt build, install directory exists:  $QT_INSTALL_WASM_DIR" -ForegroundColor Yellow
    }
    else {
        # build wasm qt (from https://doc.qt.io/qt-6/wasm.html)
        Write-Host "Build wasm Qt..." -ForegroundColor Green
        mkdir $QT_BUILD_WASM_DIR -ErrorAction SilentlyContinue
        Set-Location $QT_BUILD_WASM_DIR
        ../configure -qt-host-path "$BUILD_NATIVE_DIR/install" -platform wasm-emscripten -prefix ./install 
        cmake --build . --parallel 
        cmake --install . 
    }
}

function setup_environment_file {
    Write-Host "Setup environment file..." -ForegroundColor Green
    $ENV_FILE = Join-Path $ROOT_DIR .env
    Write-Host "Generate environment file $ENV_FILE for running apps"  -ForegroundColor Green

    # PATH environment variable
    $QT_BIN_DIR = Join-Path $QT_INSTALL_NATIVE_DIR bin
    $path_array = $env:PATH -Split [IO.Path]::PathSeparator
    $new_path_array = @($QT_BIN_DIR) + $path_array | Select-Object -Unique
    $PATH = $new_path_array -join [IO.Path]::PathSeparator

    # Output .env
    if ($IsWindows) {
@"
CMAKE_PREFIX_PATH=$QT_INSTALL_NATIVE_DIR
PATH=$PATH
QT_INSTALL_NATIVE_DIR=$QT_INSTALL_NATIVE_DIR
QT_INSTALL_WASM_DIR=$QT_INSTALL_WASM_DIR
VSCMD_ARG_TGT_ARCH=$env:VSCMD_ARG_TGT_ARCH
"@ | Set-Content $ENV_FILE
    }
    if ($IsLinux) {
@"
CMAKE_PREFIX_PATH=$QT_INSTALL_NATIVE_DIR
PATH=$PATH
QT_INSTALL_NATIVE_DIR=$QT_INSTALL_NATIVE_DIR
QT_INSTALL_WASM_DIR=$QT_INSTALL_WASM_DIR
"@ | Set-Content $ENV_FILE
    }
    if ($IsMacOS) {
@"
CMAKE_PREFIX_PATH=$QT_INSTALL_NATIVE_DIR
PATH=$PATH
QT_INSTALL_NATIVE_DIR=$QT_INSTALL_NATIVE_DIR
QT_INSTALL_WASM_DIR=$QT_INSTALL_WASM_DIR
"@ | Set-Content $ENV_FILE
    }    

    # Add environment variables to vs code workspace
    $VS_CODE_WORKSPACE_SETTINGS_PATH = Join-Path $ROOT_DIR .vscode settings.json
    if (Test-Path $VS_CODE_WORKSPACE_SETTINGS_PATH) {
        $settings = Get-Content $VS_CODE_WORKSPACE_SETTINGS_PATH | ConvertFrom-Json
    } else {
        New-Item -ItemType File $VS_CODE_WORKSPACE_SETTINGS_PATH -Force | Out-Null
        $settings = New-Object -TypeName PSObject
    }
    $env = @{}
    Get-Content $ENV_FILE | ForEach-Object {
        $name, $value = $_ -split '='
        $env += @{$name = $value}
    }   

    # store settings
    $terminal_integrated_env_os = $env
    $cmake_environment          = $env
    $files_associations         = @{"**/include/**" = "cpp"}
    $search_useIgnoreFiles      = $false
    $search_exclude             = @{"**/build" = $true; "third_party/vcpkg" = $true}

    # save settings
    $settings | Add-Member -MemberType NoteProperty -Name "terminal.integrated.env.$OS" -Value $terminal_integrated_env_os -Force
    $settings | Add-Member -MemberType NoteProperty -Name "cmake.environment"           -Value $cmake_environment          -Force
    $settings | Add-Member -MemberType NoteProperty -Name "files.associations"          -Value $files_associations         -Force
    $settings | Add-Member -MemberType NoteProperty -Name "search.useIgnoreFiles"       -Value $search_useIgnoreFiles      -Force
    $settings | Add-Member -MemberType NoteProperty -Name "search.exclude"              -Value $search_exclude             -Force
    $settings | ConvertTo-Json | Set-Content $VS_CODE_WORKSPACE_SETTINGS_PATH
}

try {
    # save current directory
    $working_directory_at_start = Get-Location
    
    setup_prerequisites
    setup_build_environment
    setup_third_party
    setup_environment_file
}
finally {
    # restore current directory
    Set-Location $working_directory_at_start
}
