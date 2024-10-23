Write-Output 'NDE init!'

$basePath = $PSScriptRoot
$topath = '{0}\topath' -f $basePath;
$exec = '{0}\d.ps1' -f $topath;
if ([System.IO.Directory]::Exists($topath) -and [System.IO.File]::Exists($exec)) {
  $path = [Environment]::GetEnvironmentVariable("path", [System.EnvironmentVariableTarget]::User)
  if (!($path -match ($topath -replace "\\", "\\")) ) {
    [Environment]::SetEnvironmentVariable("path", "$path;$topath", [System.EnvironmentVariableTarget]::User)
  }
}
else { Write-Output 'Path error!' }

$user = (wsl whoami) -replace '[^\w\d_]', ''
$internalPath = '/home/{0}/nde' -f $user
$distro = (wsl -l) -replace '[^A-Za-z() ]', ''
$distro = $distro | Select-String '(Default)' -CaseSensitive -SimpleMatch
$distro = $distro -replace '\W+\(.*', ''
$distro = $distro -replace '\W', ''
$externalPath = '\\wsl$\{0}{1}' -f $distro, $internalPath
$externalPath = $externalPath -replace ' / ', '\'

$copy = 'y'
if ([System.IO.Directory]::Exists($externalPath)) {
  $copy = Read-Host "Replace distro? [yN]"
  if ($copy -match '^yes|y|Y$') {
    Remove-Item $externalPath -Recurse -Force
  }
}

if ($copy -match '^yes|y|Y$') {
  Copy-Item $basePath -Destination $externalPath -Recurse
  wsl chmod +x "$internalPath/topath/d.sh"
  wsl chmod +x "$internalPath/init.sh"
}

$init_path = '{0}/init.sh' -f $internalPath
wsl $init_path ps1

$importCrt = Read-Host "Import nginx root certificate? [yN]"
if ($importCrt -match '^yes|y|Y$') {
  $path = '{0}\cfg\nginx\cert\NdeRootCA.crt' -f $externalPath

  $delCrt = Read-Host "Delete old root certificates? [Yn]"
  if (!($delCrt -match '^no|n|N$')) {
    Get-ChildItem Cert:\CurrentUser\Root |
    Where-Object { $_.Subject -match 'NDE-Root-CA' } |
    Remove-Item
  }

  Write-Output "Importing $path"
  Import-Certificate -FilePath $path -CertStoreLocation Cert:\CurrentUser\Root
}

if(!($args -eq 'script')){
  Write-Host -NoNewLine 'Ready!'
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
