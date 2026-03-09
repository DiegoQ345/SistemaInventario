Set-Location 'G:\Repositorios\SistemaInventario\build\Desktop_Qt_6_10_2_MinGW_64_bit-Debug'
$out = & 'G:\qt\Tools\Ninja\ninja.exe' appSistemaInventario 2>&1
[System.IO.File]::WriteAllLines('G:\Repositorios\SistemaInventario\build_result.txt', $out, [System.Text.Encoding]::UTF8)
Write-Host "Build done. Total lines: $($out.Count)"
