Write-Output 'NDE init!'

$basePath = $PSScriptRoot
$beforePull = git -C $basePath rev-parse HEAD 2>$null
if ($beforePull) {
  $beforePull = $beforePull.Trim()
}
git -C $basePath pull --ff-only
if ($LASTEXITCODE -ne 0) {
  throw 'Windows repository was not updated.'
}
$afterPull = git -C $basePath rev-parse HEAD 2>$null
if ($afterPull) {
  $afterPull = $afterPull.Trim()
}
if ($beforePull -and $beforePull -ne $afterPull) {
  Write-Output 'init.ps1 was updated. Restarting...'
  & $PSCommandPath @args
  exit $LASTEXITCODE
}

$topath = Join-Path $basePath 'topath'
$exec = Join-Path $topath 'd.ps1'
if ([System.IO.Directory]::Exists($topath) -and [System.IO.File]::Exists($exec)) {
  $path = [Environment]::GetEnvironmentVariable('path', [System.EnvironmentVariableTarget]::User)
  if (($path -split ';') -notcontains $topath) {
    [Environment]::SetEnvironmentVariable('path', "$path;$topath", [System.EnvironmentVariableTarget]::User)
  }
} else {
  Write-Output 'Path error!'
}

$user = (wsl.exe whoami).Trim()
$internalPath = "/home/$user/nde"
$distro = (wsl.exe -l -q | Select-Object -First 1).Trim()
$externalPath = "\\wsl$\$distro$($internalPath -replace '/', '\')"
$repoUrl = git -C $basePath remote get-url origin 2>$null
if ($repoUrl) {
  $repoUrl = $repoUrl.Trim()
}
if (!$repoUrl) {
  throw "Cannot determine the Git origin for $basePath"
}

wsl.exe test -d "$internalPath/.git"
$repoExists = $LASTEXITCODE -eq 0
if (!$repoExists) {
  wsl.exe test -e $internalPath
  if ($LASTEXITCODE -eq 0) {
    throw "$internalPath exists but is not a Git repository"
  }

  wsl.exe git clone $repoUrl $internalPath
  if ($LASTEXITCODE -ne 0) {
    throw 'Could not clone the repository into WSL'
  }
}

wsl.exe chmod +x "$internalPath/topath/d.sh" "$internalPath/init.sh"

$initPath = "$internalPath/init.sh"
wsl.exe $initPath ps1

$importCrt = Read-Host 'Import nginx root certificate? [yN]'
if ($importCrt -match '(?i)^(yes|y)$') {
  $path = Join-Path $externalPath 'cfg\nginx\cert\NdeRootCA.crt'

  $delCrt = Read-Host 'Delete old root certificates? [Yn]'
  if ($delCrt -notmatch '(?i)^(no|n)$') {
    Get-ChildItem Cert:\CurrentUser\Root |
      Where-Object { $_.Subject -match 'NDE-Root-CA' } |
      Remove-Item
  }

  Write-Output "Importing $path"
  Import-Certificate -FilePath $path -CertStoreLocation Cert:\CurrentUser\Root
}

if ($args -ne 'script') {
  Write-Host -NoNewLine 'Ready!'
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
