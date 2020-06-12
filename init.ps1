echo 'NDE init!'

$topath = $PSScriptRoot;
if([System.IO.Directory]::Exists("$topath\topath") -and [System.IO.File]::Exists("$topath\topath\d.ps1")){
  $topath += '\topath'
  $path = [Environment]::GetEnvironmentVariable("path", [System.EnvironmentVariableTarget]::User)
  if (!($path -match ($topath -replace "\\", "\\")) ) {
    [Environment]::SetEnvironmentVariable("path", "$path;$topath", [System.EnvironmentVariableTarget]::User)
  }
} else {echo 'Path error!'}

if(!($PSScriptRoot -eq ('{0}\nde' -f $env:USERPROFILE))){
  $link_path = ('{0}\nde' -f $env:USERPROFILE)
  sudo "New-Item -ItemType SymbolicLink -Path $link_path -Target $PSScriptRoot"
}

$prj_path = Read-Host "Put your projects folder path"
if([System.IO.Directory]::Exists($prj_path)){
  $link_path = ('{0}\prj' -f $env:USERPROFILE)
  sudo "New-Item -ItemType SymbolicLink -Path $link_path -Target $prj_path"
} else {echo 'Projects path error! Skipping...'}

if([System.IO.Directory]::Exists(('{0}\cfg' -f $PSScriptRoot))){
  $link = Read-Host "Rewrite configs? [nY]"
} else {$link = 'y'}
if($link -match '^yes|y$'){
  Copy-Item -Force -Path "$PSScriptRoot\example\*" -Destination $PSScriptRoot
}

if(!$args -eq 'script'){
  Write-Host -NoNewLine 'Ready!'
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}