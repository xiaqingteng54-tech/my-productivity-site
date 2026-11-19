$root = "D:\quartz-site\content"
$hits = @()

Get-ChildItem -LiteralPath $root -Recurse -Filter *.md | ForEach-Object {
    $p = $_.FullName
    $lines = Get-Content -LiteralPath $p -Encoding UTF8
    $inFm = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -eq 0 -and $lines[$i].Trim() -eq '---') { $inFm = $true; continue }
        if ($inFm -and $lines[$i].Trim() -eq '---') { $inFm = $false; continue }
        if ($inFm -and $lines[$i] -match '^\s*([A-Za-z_][A-Za-z0-9_-]*)\s*:\s*-\s*$') {
            $hits += [pscustomobject]@{ Path = $p; Line = $i + 1; Field = $matches[1] }
        }
    }
}

if ($hits.Count -eq 0) {
    Write-Host "No bare dash found. You can publish now." -ForegroundColor Green
    return
}

Write-Host ("Found {0} issue(s):" -f $hits.Count) -ForegroundColor Yellow
$hits | ForEach-Object { Write-Host ("{0}  line {1}  {2}: -" -f $_.Path, $_.Line, $_.Field) }

$ans = Read-Host "Type Y to fix them all"
if ($ans.Trim().ToUpper() -ne 'Y') { Write-Host "Cancelled. Nothing changed."; return }

foreach ($g in ($hits | Group-Object Path)) {
    $p = $g.Name
    $lines = Get-Content -LiteralPath $p -Encoding UTF8
    $inFm = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -eq 0 -and $lines[$i].Trim() -eq '---') { $inFm = $true; continue }
        if ($inFm -and $lines[$i].Trim() -eq '---') { $inFm = $false; continue }
        if ($inFm -and $lines[$i] -match '^\s*([A-Za-z_][A-Za-z0-9_-]*)\s*:\s*-\s*$') {
            $lines[$i] = $matches[1] + ': ""'
        }
    }
    [System.IO.File]::WriteAllLines($p, $lines, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ("Fixed: {0}" -f $p) -ForegroundColor Green
}

Write-Host "Done. Run update-site.bat now." -ForegroundColor Green
