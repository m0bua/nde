Write-Output 'NDE init!'

$topath = $PSScriptRoot;
if([System.IO.Directory]::Exists("$topath\topath") -and [System.IO.File]::Exists("$topath\topath\d.ps1")){
  $topath += '\topath'
  $path = [Environment]::GetEnvironmentVariable("path", [System.EnvironmentVariableTarget]::User)
  if (!($path -match ($topath -replace "\\", "\\")) ) {
    [Environment]::SetEnvironmentVariable("path", "$path;$topath", [System.EnvironmentVariableTarget]::User)
  }
} else {Write-Output 'Path error!'}

if([System.IO.Directory]::Exists(('{0}\cfg' -f $PSScriptRoot))){
  $link = Read-Host "Rewrite configs? [yN]"
} else {$link = 'y'}
if($link -match '^yes|y$'){
  Get-ChildItem -Path "$PSScriptRoot\example\*" | Copy-Item -Destination $PSScriptRoot -Recurse -Container -Force
  (Get-Content $PSScriptRoot\cfg\dns.json).replace('"type": "CNAME"', '"type": "A"') | Set-Content $PSScriptRoot\cfg\dns.json
}

if([System.IO.File]::Exists(('{0}\cfg\nginx\cert\NdeRootCA.crt' -f $PSScriptRoot))){
  $crt = Read-Host "Generate nginx certificates? [yN]"
} else {$crt='y'}
if($crt -match '^yes|y$'){
  cd ('{0}\cfg\nginx\cert\' -f $PSScriptRoot)
  bash cert.sh
  $importCrt = Read-Host "Import nginx root certificate? [yN]"
  if($importCrt -match '^yes|y$'){
    Import-Certificate -FilePath ('{0}\cfg\nginx\cert\NdeRootCA.crt' -f $PSScriptRoot) -CertStoreLocation Cert:\CurrentUser\Root
  }
}

if(!($args -eq 'script')){
  Write-Host -NoNewLine 'Ready!'
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
