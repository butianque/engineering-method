# engineering-method — one-shot installer for Windows (PowerShell 5.1+ / 7+)
#
#   irm https://raw.githubusercontent.com/butianque/engineering-method/main/install.ps1 | iex
#
#   # with options
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/butianque/engineering-method/main/install.ps1))) -All
#
# Options:
#   -Agent <string[]>   claude,dsh,opencode,cursor,codex,gemini,agents   (default: auto-detect)
#   -All                install into every supported agent (even ones not detected)
#   -Project            install into .\.claude\skills etc. instead of $HOME
#   -Dir <path>         install into exactly this directory (it will contain SKILL.md)
#   -SkillsDir <path>   install into <path>\engineering-method (a skills parent dir)
#   -Force              reinstall even when the installed copy already matches
#   -DryRun             print what would happen, change nothing
#   -NoGeneric          skip the generic ~\.agents\skills fallback
#   -Uninstall          remove the skill from the same targets
#
# Exit codes: 0 ok, 1 failure, 2 usage error.
#
# Design note: identical behaviour whether run from a clone (`.\install.ps1`)
# or from a pipe (`irm … | iex`). A piped run has no script path, so the skill
# is fetched as a zip instead of copied. Both paths end in the same
# "copy one directory into place" step.

[CmdletBinding()]
param(
    [string[]]$Agent = @(),
    [switch]$All,
    [switch]$Project,
    [string]$Dir = "",
    [string]$SkillsDir = "",
    [switch]$Force,
    [switch]$DryRun,
    [switch]$NoGeneric,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$Repo   = 'butianque/engineering-method'
$Skill  = 'engineering-method'
$Branch = if ($env:EM_BRANCH) { $env:EM_BRANCH } else { 'main' }

function Say ($m)  { Write-Host $m }
function Ok  ($m)  { Write-Host "  ok    $m" -ForegroundColor Green }
function Warn2($m) { Write-Host "  warn  $m" -ForegroundColor Yellow }
function Fail2($m) { Write-Host "  FAIL  $m" -ForegroundColor Red }
function Die ($m)  { Fail2 $m; exit 1 }

$AllAgents = @('claude','dsh','opencode','cursor','codex','gemini','agents')

function Get-Base {
    if ($Project) { return '.' }
    return $env:USERPROFILE
}

function Get-TargetDir ([string]$a) {
    $b = Get-Base
    switch ($a) {
        'claude'   { return Join-Path $b '.claude\skills' }
        'dsh'      { return Join-Path $b '.dsh\skills' }
        'opencode' { return Join-Path $b '.config\opencode\skills' }
        'cursor'   { return Join-Path $b '.cursor\skills' }
        'codex'    { return Join-Path $b '.codex\skills' }
        'gemini'   { return Join-Path $b '.gemini\skills' }
        'agents'   { return Join-Path $b '.agents\skills' }
        default    { return $null }
    }
}

function Get-AgentParent ([string]$a) {
    $b = Get-Base
    switch ($a) {
        'claude'   { return Join-Path $b '.claude' }
        'dsh'      { return Join-Path $b '.dsh' }
        'opencode' { return Join-Path $b '.config\opencode' }
        'cursor'   { return Join-Path $b '.cursor' }
        'codex'    { return Join-Path $b '.codex' }
        'gemini'   { return Join-Path $b '.gemini' }
        'agents'   { return Join-Path $b '.agents' }
        default    { return $null }
    }
}

# ---------------------------------------------------------------- resolve list
$selected = @()
if ($Dir) {
    $selected = @('__explicit_dir__')
} elseif ($SkillsDir) {
    $selected = @('__explicit_parent__')
} elseif ($Agent.Count -gt 0) {
    foreach ($a in $Agent) {
        foreach ($one in ($a -split ',')) {
            $one = $one.Trim()
            if (-not $one) { continue }
            if ($one -eq 'all') { $All = $true; continue }
            if ($AllAgents -notcontains $one) { Die "unknown agent '$one' (valid: $($AllAgents -join ','))" }
            $selected += $one
        }
    }
} elseif ($All) {
    $selected = $AllAgents
} else {
    foreach ($a in $AllAgents) {
        if (Test-Path -LiteralPath (Get-AgentParent $a)) { $selected += $a }
    }
}

if (-not $NoGeneric -and -not $Dir -and -not $SkillsDir -and -not $Uninstall) {
    if ($selected -notcontains 'agents') { $selected += 'agents' }
}

$selected = @($selected | Where-Object { $_ } | Select-Object -Unique)
if ($selected.Count -eq 0) { Die 'no agent detected. Use -All, -Agent <list>, or -Dir <path>.' }

# ---------------------------------------------------------------- fetch source
$scriptDir = $null
try { if ($PSScriptRoot) { $scriptDir = $PSScriptRoot } } catch { }

$work = $null
$src  = $null

if ($scriptDir -and (Test-Path -LiteralPath (Join-Path $scriptDir "skills\$Skill"))) {
    $src = Join-Path $scriptDir "skills\$Skill"
    Say "source: local checkout ($src)"
} else {
    $work = Join-Path ([System.IO.Path]::GetTempPath()) ("em-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $zip = Join-Path $work 'src.zip'
    $url = "https://github.com/$Repo/archive/refs/heads/$Branch.zip"
    Say "source: $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    } catch {
        Die "download failed: $url ($($_.Exception.Message))"
    }
    Expand-Archive -LiteralPath $zip -DestinationPath $work -Force
    $found = Get-ChildItem -LiteralPath $work -Directory -Recurse -Depth 2 -Filter $Skill -ErrorAction SilentlyContinue |
             Where-Object { $_.Parent -and $_.Parent.Name -eq 'skills' } |
             Select-Object -First 1
    if (-not $found) { Die "the archive does not contain skills/$Skill" }
    $src = $found.FullName
}

# ---------------------------------------------------------------- fingerprint
function Get-TreeHash ([string]$path) {
    $files = Get-ChildItem -LiteralPath $path -Recurse -File | Sort-Object FullName
    $sb = New-Object System.Text.StringBuilder
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($path.Length).TrimStart('\','/') -replace '\\','/'
        $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        [void]$sb.Append("$rel $h`n")
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
}

$srcHash = Get-TreeHash $src
$version = (Select-String -LiteralPath (Join-Path $src 'SKILL.md') -Pattern '^\s+version:\s*"?([^"]+)"?' |
            Select-Object -First 1).Matches[0].Groups[1].Value
Say "skill version: $(if ($version) { $version } else { 'unknown' })  hash: $($srcHash.Substring(0,12))"
Say ''

# ---------------------------------------------------------------- install
$installed = 0; $skipped = 0; $failed = 0

function Invoke-One ([string]$parent, [string]$dest) {
    if (-not $parent) { $parent = Split-Path -Parent $dest }
    if ($Uninstall) {
        if (Test-Path -LiteralPath $dest) {
            if ($DryRun) { Ok "would remove $dest" }
            else { Remove-Item -LiteralPath $dest -Recurse -Force; Ok "removed $dest" }
        } else { Warn2 "not installed at $dest" }
        return
    }

    if ((Test-Path -LiteralPath $dest) -and -not $Force) {
        $have = Get-TreeHash $dest
        if ($have -eq $srcHash) { Ok "up to date: $dest"; $script:skipped++; return }
    }

    if ($DryRun) { Ok "would install: $dest"; return }

    try {
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
        Copy-Item -LiteralPath $src -Destination $dest -Recurse -Force
        Ok "installed: $dest"
        $script:installed++
    } catch {
        Fail2 "cannot install to $dest ($($_.Exception.Message))"
        $script:failed++
    }
}

foreach ($a in $selected) {
    if ($a -eq '__explicit_dir__') {
        Say '[explicit dir]'
        Invoke-One (Split-Path -Parent $Dir) $Dir
        continue
    }
    if ($a -eq '__explicit_parent__') {
        Say '[explicit skills dir]'
        Invoke-One $SkillsDir (Join-Path $SkillsDir $Skill)
        continue
    }
    Say "[$a]"
    $td = Get-TargetDir $a
    Invoke-One $td (Join-Path $td $Skill)
}

if ($work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }

Say ''
if ($Uninstall) { Say 'uninstall done.'; exit 0 }
if ($failed -gt 0) { Say "finished with $failed failure(s)"; exit 1 }

Write-Host "installed $installed, already current $skipped." -ForegroundColor Green
Write-Host @"

next:
  1. Restart the agent (or reload its skill list) so it picks up the new skill.
  2. Ask something like "帮我加个接口" — the skill should load and ask for 三定 first.
  3. Verify the machine gate by hand:
       bash <skills-dir>/$Skill/scripts/gate.sh <your-project> --steps 3

docs: https://github.com/$Repo#readme
"@
exit 0
