

# ffmpeg -i .\static\videos\self-forcing\40\block_0_2.mp4 -vf "setpts=2.0*PTS" -r 8 -c:a copy .\static\videos\self-forcing\37\block_0_2_slow.mp4


param(
    # [string]$Root = ".\static\videos\self-forcing",
    [string]$Root = ".\static\videos\causvid",
    [double]$Speed = 2.0,
    [int]$Fps = 8,
    [string]$OutputRoot = $null,   # if set, mirrors output under this root; otherwise writes next to input
    [switch]$Overwrite = $true
)

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "ffmpeg not found in PATH."
    exit 1
}

$numericDirs = Get-ChildItem -Path $Root -Directory -ErrorAction Stop |
    Where-Object { $_.Name -match '^\d+$' }

foreach ($dir in $numericDirs) {
    $inDir = $dir.FullName

    # Determine output directory (mirror or same)
    $outDir = if ($OutputRoot) { Join-Path -Path $OutputRoot -ChildPath $dir.Name } else { $inDir }
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

    Get-ChildItem -Path $inDir -Filter *.mp4 -File | ForEach-Object {
        # Skip files that already look slowed
        if ($_.BaseName -match '_slow$') { return }
        if ($_.BaseName -match '_Animation_$') { return }

        $inFile  = $_.FullName
        $outFile = Join-Path $outDir ($_.BaseName + '_slow' + $_.Extension)

        # Build ffmpeg args
        $args = @()
        if ($Overwrite) { $args += '-y' } else { $args += '-n' }
        $args += @(
            '-i', $inFile,
            '-vf', "setpts=$Speed*PTS",
            '-r',  $Fps,
            '-c:a','copy',
            $outFile
        )

        Write-Host "Processing: $inFile -> $outFile"
        & ffmpeg @args
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "ffmpeg failed for: $inFile"
        }
    }
}