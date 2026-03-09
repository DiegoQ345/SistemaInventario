Set-Location 'G:\Repositorios\SistemaInventario\build\Desktop_Qt_6_10_2_MinGW_64_bit-Debug'
$out = & 'G:\qt\Tools\Ninja\ninja.exe' 2>&1 | Out-String
$out | Set-Content 'G:\Repositorios\SistemaInventario\build_full.txt' -Encoding UTF8
Write-Host "Build output length: $($out.Length)"
Write-Host "--- Last 2000 chars ---"
Write-Host $out.Substring([Math]::Max(0, $out.Length - 2000))
