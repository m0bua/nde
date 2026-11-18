$hostMarkerStart = '# NDE managed hosts start'
$hostMarkerEnd = '# NDE managed hosts end'

function Write-NdeHostsBlock {
  param([string[]]$Block)

  $start = [array]::IndexOf($Block, $hostMarkerStart)
  $end = [array]::IndexOf($Block, $hostMarkerEnd)
  if ($start -ne 0 -or $end -ne ($Block.Length - 1) -or $Block.Count -lt 3) {
    throw 'The WSL d --view output is not a valid NDE hosts block.'
  }
  foreach ($line in $Block[1..($Block.Length - 2)]) {
    if ($line -notmatch '^127\.0\.0\.1\s+[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.local$') {
      throw 'The WSL d --view output contains an invalid hosts entry.'
    }
  }

  $hostsPath = Join-Path $env:windir 'System32\drivers\etc\hosts'
  $content = @(Get-Content -LiteralPath $hostsPath)
  $starts = @((0..($content.Length - 1)) | Where-Object { $content[$_] -eq $hostMarkerStart })
  $ends = @((0..($content.Length - 1)) | Where-Object { $content[$_] -eq $hostMarkerEnd })
  if ($starts.Count -gt 1 -or $ends.Count -gt 1 -or (($starts.Count -eq 1) -xor ($ends.Count -eq 1))) {
    throw 'The NDE block in Windows hosts is incomplete or duplicated; the file was left unchanged.'
  }
  if ($starts.Count -eq 1) {
    $before = if ($starts[0] -gt 0) { @($content[0..($starts[0] - 1)]) } else { @() }
    $after = if ($ends[0] -lt $content.Length - 1) { @($content[($ends[0] + 1)..($content.Length - 1)]) } else { @() }
    $outside = @($before) + @($after)
  } else {
    $outside = @($content)
  }
  $outsideLines = New-Object 'System.Collections.Generic.List[string]'
  foreach ($line in $outside) { $outsideLines.Add($line) }
  while ($outsideLines.Count -gt 0 -and $outsideLines[$outsideLines.Count - 1] -match '^\s*$') {
    $outsideLines.RemoveAt($outsideLines.Count - 1)
  }
  $content = @($outsideLines.ToArray()) + @('') + @($Block)
  if ($content -notcontains '127.0.0.1 localhost') { $content = @('127.0.0.1 localhost') + @($content) }
  if ($content -notcontains '::1 localhost') { $content += '::1 localhost' }

  $tempPath = "$hostsPath.nde.tmp"
  Set-Content -LiteralPath $tempPath -Value $content -Encoding ascii
  Move-Item -LiteralPath $tempPath -Destination $hostsPath -Force
  Clear-DnsClientCache
  Write-Output "Updated Windows hosts with $($Block.Count - 2) NDE domains."
}

function Remove-NdeHostsBlock {
  $hostsPath = Join-Path $env:windir 'System32\drivers\etc\hosts'
  $content = @(Get-Content -LiteralPath $hostsPath)
  $starts = @((0..($content.Length - 1)) | Where-Object { $content[$_] -eq $hostMarkerStart })
  $ends = @((0..($content.Length - 1)) | Where-Object { $content[$_] -eq $hostMarkerEnd })
  if ($starts.Count -eq 0 -and $ends.Count -eq 0) { Write-Output 'No NDE hosts block found.'; return }
  if ($starts.Count -ne 1 -or $ends.Count -ne 1 -or $ends[0] -lt $starts[0]) {
    throw 'The NDE hosts block is incomplete or ambiguous; hosts was left unchanged.'
  }
  $before = if ($starts[0] -gt 0) { @($content[0..($starts[0] - 1)]) } else { @() }
  $after = if ($ends[0] -lt $content.Length - 1) { @($content[($ends[0] + 1)..($content.Length - 1)]) } else { @() }
  $remaining = New-Object 'System.Collections.Generic.List[string]'
  foreach ($line in (@($before) + @($after))) { $remaining.Add($line) }
  while ($remaining.Count -gt 0 -and $remaining[$remaining.Count - 1] -match '^\s*$') {
    $remaining.RemoveAt($remaining.Count - 1)
  }
  $tempPath = "$hostsPath.nde.tmp"
  Set-Content -LiteralPath $tempPath -Value $remaining.ToArray() -Encoding ascii
  Move-Item -LiteralPath $tempPath -Destination $hostsPath -Force
  Clear-DnsClientCache
  Write-Output 'Removed the NDE hosts block.'
}

function Invoke-NdeElevatedPayload {
  param([string]$Payload)

  $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Payload))
  $sudoCommand = Get-Command sudo.exe -ErrorAction SilentlyContinue
  if ($sudoCommand) {
    & $sudoCommand.Source powershell.exe -NoProfile -EncodedCommand $encoded
    if ($LASTEXITCODE -eq 0) { return 0 }
  }

  $process = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -ArgumentList @('-NoProfile', '-EncodedCommand', $encoded)
  return $process.ExitCode
}

function Invoke-NdeHostsAction {
  param([ValidateSet('sync', 'clean')][string]$Action)

  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )
  if ($Action -eq 'clean') {
    if ($isAdmin) { Remove-NdeHostsBlock; return }
    $scriptPath = $PSCommandPath.Replace("'", "''")
    $payload = "& '$scriptPath' clean-hosts"
    $exitCode = Invoke-NdeElevatedPayload -Payload $payload
    if ($exitCode -ne 0) { exit $exitCode }
    return
  }

  $encodedView = (wsl.exe -d Ubuntu --exec bash -lc 'set -o pipefail; d --view | base64 -w0' 2>$null) -join ''
  if ($LASTEXITCODE -ne 0 -or !$encodedView) { throw 'Could not get the hosts block from d --view in WSL.' }
  try { $view = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedView.Trim())) } catch {
    throw 'Could not decode d --view output from WSL.'
  }
  $block = @($view -split "`r?`n" | Where-Object { $_ -ne '' })
  if ($isAdmin) { Write-NdeHostsBlock -Block $block; return }

  $blockFile = Join-Path ([IO.Path]::GetTempPath()) ("nde-hosts-{0}.txt" -f [guid]::NewGuid())
  try {
    Set-Content -LiteralPath $blockFile -Value $block -Encoding ascii
    $scriptPath = $PSCommandPath.Replace("'", "''")
    $blockPath = $blockFile.Replace("'", "''")
    $payload = "& '$scriptPath' apply-hosts '$blockPath'"
    $exitCode = Invoke-NdeElevatedPayload -Payload $payload
    if ($exitCode -ne 0) { exit $exitCode }
  } finally {
    Remove-Item -LiteralPath $blockFile -Force -ErrorAction SilentlyContinue
  }
}

$command = if ($args.Count -gt 0) { $args[0] } else { '' }
switch ($command) {
  'apply-hosts' {
    Write-NdeHostsBlock -Block @(Get-Content -LiteralPath $args[1])
    exit 0
  }
  'clean-hosts' {
    Remove-NdeHostsBlock
    exit 0
  }
  { $_ -in @('s', '-s', '--sync') } {
    Invoke-NdeHostsAction sync
    exit 0
  }
  { $_ -in @('c', '-c', '--clean') } {
    Invoke-NdeHostsAction clean
    exit 0
  }
  { $_ -in @('i', '-i', '-init', 'init', '--init') } {
    $basePath = Split-Path -Parent $PSScriptRoot
    $initPath = Join-Path $basePath 'init.ps1'
    & $initPath @($args | Select-Object -Skip 1)
    exit $LASTEXITCODE
  }
  default {
    wsl.exe -d Ubuntu --exec bash -lc 'exec "$HOME/nde/topath/d.sh" "$@"' nde.ps1 @args
    exit $LASTEXITCODE
  }
}
