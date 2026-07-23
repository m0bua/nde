$initCommands = @('i', '-i', '-init', 'init', '--init')
if ($args.Count -gt 0 -and $initCommands -contains $args[0]) {
  $basePath = Split-Path -Parent $PSScriptRoot
  $initPath = Join-Path $basePath 'init.ps1'
  & $initPath @($args | Select-Object -Skip 1)
  exit $LASTEXITCODE
}

bash d @args
exit $LASTEXITCODE
