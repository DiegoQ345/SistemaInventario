Set-Location 'G:\Repositorios\SistemaInventario\build\Desktop_Qt_6_10_2_MinGW_64_bit-Debug'
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = 'G:\qt\Tools\Ninja\ninja.exe'
$psi.Arguments = 'appSistemaInventario'
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.WorkingDirectory = 'G:\Repositorios\SistemaInventario\build\Desktop_Qt_6_10_2_MinGW_64_bit-Debug'
$proc = [System.Diagnostics.Process]::Start($psi)
$stdout = $proc.StandardOutput.ReadToEnd()
$stderr = $proc.StandardError.ReadToEnd()
$proc.WaitForExit()
$all = $stdout + $stderr
[System.IO.File]::WriteAllText('G:\Repositorios\SistemaInventario\build_output.txt', $all, [System.Text.Encoding]::UTF8)
$errorLines = ($all -split "`n") | Where-Object { $_ -match 'error:|FAILED' }
[System.IO.File]::WriteAllText('G:\Repositorios\SistemaInventario\build_errors.txt', ($errorLines -join "`n"), [System.Text.Encoding]::UTF8)
Write-Host "ExitCode: $($proc.ExitCode)  ErrorLines: $($errorLines.Count)"
