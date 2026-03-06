$ErrorActionPreference = "Continue"
Set-Location "build\Desktop_Qt_6_10_1_MinGW_64_bit-Debug"

# Intentar compilar capturando stderr
$process = Start-Process -FilePath "C:\Qt\Tools\mingw1310_64\bin\g++.exe" `
    -ArgumentList @(
        "-DMINGW_HAS_SECURE_API=1",
        "-DQT_CORE_LIB",
        "-DQT_GUI_LIB",
        "-DQT_NEEDS_QMAIN",
        "-DQT_NETWORK_LIB",
        "-DQT_OPENGL_LIB",
        "-DQT_PRINTSUPPORT_LIB",
        "-DQT_QMLINTEGRATION_LIB",
        "-DQT_QML_LIB",
        "-DQT_QUICKCONTROLS2_LIB",
        "-DQT_QUICK_LIB",
        "-DQT_SQL_LIB",
        "-DQT_WIDGETS_LIB",
        "-DUNICODE",
        "-DWIN32",
        "-DWIN64",
        "-D_ENABLE_EXTENDED_ALIGNED_STORAGE",
        "-D_UNICODE",
        "-D_WIN64",
        "@CMakeFiles/appSistemaInventario.dir/includes_CXX.rsp",
        "-std=gnu++17",
        "-c",
        "D:\Repositorios\SistemaInventario\src\services\PrintService.cpp",
        "-o",
        "test_compile.obj"
    ) `
    -NoNewWindow `
    -Wait `
    -PassThru `
    -RedirectStandardError "..\..\compile_error.txt" `
    -RedirectStandardOutput "..\..\compile_output.txt"

Write-Output "Exit Code: $($process.ExitCode)"
Write-Output "`n=== ERRORS ==="
Get-Content "..\..\compile_error.txt" -ErrorAction SilentlyContinue
Write-Output "`n=== OUTPUT ==="
Get-Content "..\..\compile_output.txt" -ErrorAction SilentlyContinue
