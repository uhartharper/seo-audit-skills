$SkillsDir = "$env:USERPROFILE\.claude\skills"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $SkillsDir)) {
    New-Item -ItemType Directory -Path $SkillsDir | Out-Null
}

$count = 0
Get-ChildItem -Path "$ScriptDir\skills" -Directory | ForEach-Object {
    $skillName = $_.Name
    $skillFile = Join-Path $_.FullName "SKILL.md"
    if (Test-Path $skillFile) {
        $destDir = Join-Path $SkillsDir $skillName
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir | Out-Null
        }
        Copy-Item -Path $skillFile -Destination (Join-Path $destDir "SKILL.md") -Force
        Write-Host "Installed: $skillName"
        $count++
    }
}

Write-Host "Done. $count skills installed to $SkillsDir"
