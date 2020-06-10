Function sudo ($command){
  &{ Start-Process powershell -ArgumentList $command -Verb RunAs -WindowStyle hidden}
}

Function get_setting($name){
  $content = Get-Content ("{0}\settings.yaml" -f (Split-Path -parent $PSScriptRoot))
  return [regex]::match($content,"$name\: ([^\s\n]*)").Groups[1].Value
}

Function set_setting($name, $val){
  if([System.IO.Directory]::Exists("{0}\settings.yaml" -f (Split-Path -parent $PSScriptRoot))){
    $content = Get-Content ("{0}\settings.yaml" -f (Split-Path -parent $PSScriptRoot))
    $old_val = [regex]::match($content,"$name\: ([^\s\n]*)").Value
  }
  if($old_val -and $val){$content = $content.replace("$old_val", ("{0}: {1}" -f $name, $val))}
  else{$content += "{0}: {1}" -f $name, $val}
  Set-Content -Path ("{0}\settings.yaml" -f (Split-Path -parent $PSScriptRoot)) -Value $content
}

Function first_config(){
  $script_path = $PSScriptRoot;
  if(($script_path -match '\\example\\topath$')){
    $script_path += '\..\..\topath'
    if(![System.IO.Directory]::Exists($script_path)){New-Item $script_path -ItemType "directory" > $null}
    $script_path = Resolve-Path $script_path
    if(![System.IO.File]::Exists("{0}\d.ps1" -f $script_path)){
      sudo "New-Item -ItemType SymbolicLink -Path $script_path\d.ps1 -Target $PSScriptRoot\d.ps1"
    }

    while(![System.IO.File]::Exists("{0}\d.ps1" -f $script_path)) { Start-Sleep -Milliseconds 100 }
    Invoke-Expression ("{0}\d.ps1 init" -f $script_path)
    exit
  }

  echo "   NDE init!"

  $path = [Environment]::GetEnvironmentVariable("path", [System.EnvironmentVariableTarget]::User)
  if (!($path -match ($script_path -replace "\\", "\\")) ) {
    [Environment]::SetEnvironmentVariable("path", "$path;$script_path", [System.EnvironmentVariableTarget]::User)
  }

  $prj_path = Read-Host "Put your projects folder path"
  if([System.IO.Directory]::Exists($prj_path)){set_setting "prj_path" $prj_path}

  exit
}

if(($PSScriptRoot -match '\\example\\topath$')){first_config}
if(($args[0] -eq 'init') -or ($args[0] -eq 'config')){first_config}

$dir = Split-Path -parent $PSScriptRoot;

try {
  Push-Location
  Set-Location -Path  $dir

  docker-compose $args | Tee-Object -Variable log

} finally {Pop-Location}
