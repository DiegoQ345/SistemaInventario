Set-Location 'G:\Repositorios\SistemaInventario\build\Desktop_Qt_6_10_2_MinGW_64_bit-Debug'
$ErrorActionPreference = 'Continue'
$out = & 'G:\qt\Tools\Ninja\ninja.exe' 2>&1
$errors = $out | Where-Object { $_ -match ': error:|: note:|: warning:|^In file included|^   ' -and $_ -notmatch '^G:\\qt\\Tools\\mingw' }
[System.IO.File]::WriteAllLines('G:\Repositorios\SistemaInventario\build_errors.txt', $errors, [System.Text.Encoding]::UTF8)
Write-Host "Done. Lines captured: $($errors.Count)"
