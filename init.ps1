echo 'NDE init!'

$topath = $PSScriptRoot;
if([System.IO.Directory]::Exists("$topath\topath") -and [System.IO.File]::Exists("$topath\topath\d.ps1")){
  $topath += '\topath'
  $path = [Environment]::GetEnvironmentVariable("path", [System.EnvironmentVariableTarget]::User)
  if (!($path -match ($topath -replace "\\", "\\")) ) {
    [Environment]::SetEnvironmentVariable("path", "$path;$topath", [System.EnvironmentVariableTarget]::User)
  }
} else {echo 'Path error!'}

if([System.IO.Directory]::Exists(('{0}\cfg' -f $PSScriptRoot))){
  $link = Read-Host "Rewrite configs? [yN]"
} else {$link = 'y'}
if($link -match '^yes|y$'){
  Get-ChildItem -Path "$PSScriptRoot\example\*" | Copy-Item -Destination $PSScriptRoot -Recurse -Container -Force
  (Get-Content $PSScriptRoot\cfg\dns.json).replace('"type": "CNAME"', '"type": "A"') | Set-Content $PSScriptRoot\cfg\dns.json
  # $prj_path = Read-Host "Put your projects folder path"
  # $prj_path = ($prj_path -replace "/", "\")
  # if([System.IO.Directory]::Exists($prj_path)){
  #   (Get-Content docker-compose.yml).replace('~/prj', $prj_path) | Set-Content docker-compose.yml
  # } else {
  #   if($prj_path){$echo = "$prj_path is not a folder. "}
  #   echo "${echo}Will keep default (~/prj)"
  # }
}

if(!($args -eq 'script')){
  Write-Host -NoNewLine 'Ready!'
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}