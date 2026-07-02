function MakeDir {
    param($Dir)
    if (-not (Test-Path $Dir)) {
        mkdir -Path $Dir | Out-Null
    }
}

function DownloadUrl {
    param($Url,$File)
    if (-not (Test-Path $File)) {
        $WebClient = New-Object System.Net.WebClient
        try {
            $Task = $WebClient.DownloadFileTaskAsync($Url, "$PSScriptRoot\$File")
            Register-ObjectEvent -InputObject $WebClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged | Out-Null
            Start-Sleep -Seconds 1
            While (-Not $Task.IsCompleted) {
                Start-Sleep -Seconds 1
                $EventData = Get-Event -SourceIdentifier WebClient.DownloadProgressChanged | Select-Object -ExpandProperty "SourceEventArgs" -Last 1
                $TotalPercent = $EventData | Select-Object -ExpandProperty "ProgressPercentage"
                Write-Progress -Activity "Downloading $File from $Url" -Status "Percent Complete: $($TotalPercent)%" -PercentComplete $TotalPercent
            }
        }
        catch [System.Net.WebException] {
            Write-Host("Cannot download $Url")
            if ($_.Exception.InnerException) {
                Write-Error $_.Exception.InnerException.Message
            } else {
                Write-Error $_.Exception.Message
            }
        }
        finally {
            Write-Progress -Activity "Downloading $File from $Url" -Completed
            Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
            $WebClient.Dispose()
        }
    }
}

function UnpackUrl {
    param($Url,$File,$UnpackDir,$TestPath,$ArgumentList)
    if (-not $File) {
        $File = $Url.Substring($Url.LastIndexOf("/") + 1)
    }
    $Output = "dist\downloads\$File"
    if (-not $TestPath) {
        $TestPath = $UnpackDir
    }
    if (-not (Test-Path "$TestPath")) {
        Write-Host "UnpackUrl: $Url -> $UnpackDir"
        DownloadUrl -Url $Url -File $Output
        switch ((Get-Item $Output).Extension) {
            '.zip' {
                $shell = New-Object -com shell.application
                $shell.Namespace([IO.Path]::Combine($pwd, $UnpackDir)).CopyHere($shell.Namespace([IO.Path]::Combine($pwd, $Output)).Items())
            }
            '.exe' {
                Start-Process $output -Wait -ArgumentList $ArgumentList
            }
        }
    }
}

# ──── Configurable URLs (verify these before building) ────────────────────

$WinPythonUrl = "https://github.com/winpython/winpython/releases/download/13.1.202502222final/Winpython64-3.12.9.0dot.exe"
$SevenZipUrl   = "https://www.7-zip.org/a/7z2602-x64.exe"
$FFmpegUrl     = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip"
$CheckpointUrl = "https://zenodo.org/record/4034264/files/CRNN_note_F1%3D0.9677_pedal_F1%3D0.9186.pth?download=1"
$SingleExeUrl  = "https://github.com/zenden2k/context-menu-launcher/releases/download/1.0/singleinstance.exe"

# PyTorch 2.7.1+cu128 — first stable release with Blackwell (RTX 50-series) support
$PyTorchIndex  = "https://download.pytorch.org/whl/cu128"
$PyTorchVer    = "2.7.1"

# librosa pinned to 0.9.x — compatible with piano_transcription_inference 0.0.5
# without needing the Nix patches (which are only required for librosa ≥ 0.10)
$LibrosaVer    = "0.9.2"

$Version       = "v1.1"

# ──── Setup directories ──────────────────────────────────────────────────

MakeDir build\
MakeDir dist\downloads\

# ──── 7-Zip 26.02 ────────────────────────────────────────────────────────

$7zDir = [IO.Path]::Combine($pwd, "build\7z")
UnpackUrl -Url $SevenZipUrl -ArgumentList "/S /D=$7zDir" -TestPath $7zDir

# ──── WinPython 3.12.9 (dot / minimal) ───────────────────────────────────
# NOTE: If this URL fails, download the latest Winpython64-*-dot.exe from
#       https://github.com/winpython/winpython/releases and place it in
#       dist\downloads\, then update $WinPythonUrl.

UnpackUrl -Url $WinPythonUrl `
    -ArgumentList "-y -obuild\" -TestPath build\python\

if (-not (Test-Path build\python\)) {
    $wpDir = Get-ChildItem build\ -Directory |
        Where-Object { $_.Name -like "WPy64-*" } |
        Select-Object -First 1
    if ($wpDir) {
        Rename-Item $wpDir.FullName build\python\
    } else {
        Write-Error "Cannot find WinPython extracted directory (expected WPy64-* under build\)"
        exit 1
    }
}

# Locate the versioned Python directory inside WinPython
$PythonDir = Get-ChildItem build\python\ -Directory |
    Where-Object { $_.Name -like "python-*" } |
    Select-Object -First 1
if (-not $PythonDir) {
    Write-Error "Cannot find python-* directory under build\python\"
    exit 1
}
$PythonExe  = Join-Path $PythonDir.FullName "python.exe"
$ScriptsDir = Join-Path $PythonDir.FullName "Scripts"
$LibsDir    = Join-Path $PythonDir.FullName "Lib\site-packages"

Write-Host "Python:   $PythonExe"
Write-Host "Scripts:  $ScriptsDir"
Write-Host "Libs:     $LibsDir"

MakeDir dist\downloads\pip\
$PipCacheDir = Resolve-Path dist\downloads\pip\ | select -ExpandProperty Path

MakeDir build\temp\
$TempDir = Resolve-Path build\temp\ | select -ExpandProperty Path
$env:TEMP = $TempDir

# ──── Install PyTorch 2.7.1 + CUDA 12.8 ──────────────────────────────────

if (-not (Test-Path $LibsDir\torch)) {
    Write-Host "Installing PyTorch $PyTorchVer + CUDA 12.8 (Blackwell support)..."
    & $PythonExe -m pip --cache-dir "$PipCacheDir" install torch==$PyTorchVer `
        --index-url $PyTorchIndex
}

# ──── Install piano_transcription_inference + librosa ────────────────────

if (-not (Test-Path $LibsDir\piano_transcription_inference)) {
    Write-Host "Installing librosa==$LibrosaVer and piano_transcription_inference..."
    & $PythonExe -m pip --cache-dir "$PipCacheDir" install `
        librosa==$LibrosaVer `
        piano_transcription_inference
}

# ──── Install PyInstaller ────────────────────────────────────────────────

if (-not (Test-Path $ScriptsDir\pyinstaller.exe)) {
    Write-Host "Installing PyInstaller..."
    & $PythonExe -m pip --cache-dir "$PipCacheDir" install pyinstaller
}

# ──── Freeze dependency list ─────────────────────────────────────────────

& $PythonExe -m pip freeze | Out-File -encoding UTF8 pip.txt

# ──── Build with PyInstaller ─────────────────────────────────────────────

if (-not (Test-Path build\dist\PianoTrans-$Version\)) {
    cp ..\PianoTrans.py, PianoTrans.spec build\
    & $PythonExe $ScriptsDir\pyinstaller.exe `
        --noconfirm `
        --distpath build\dist\ `
        --workpath build\build\ `
        --specpath build\ `
        build\PianoTrans.spec
    if (Test-Path build\dist\PianoTrans) {
        mv build\dist\PianoTrans build\dist\PianoTrans-$Version
    }
}

if (-not (Test-Path build\dist\PianoTrans-$Version\)) {
    Write-Error "PyInstaller build failed — PianoTrans directory not found."
    exit 1
}

# ──── Download model checkpoint ──────────────────────────────────────────

MakeDir build\dist\PianoTrans-$Version\piano_transcription_inference_data\
$CheckpointFile = 'note_F1=0.9677_pedal_F1=0.9186.pth'
$CheckpointLocal = "dist\downloads\$CheckpointFile"
if (-not (Test-Path $CheckpointLocal)) {
    Write-Host "Downloading model checkpoint..."
    DownloadUrl -Url $CheckpointUrl -File $CheckpointFile
}
$CheckpointDest = "build\dist\PianoTrans-$Version\piano_transcription_inference_data\$CheckpointFile"
if (-not (Test-Path $CheckpointDest)) {
    cp $CheckpointLocal $CheckpointDest
}

# ──── Bundle FFmpeg ──────────────────────────────────────────────────────

$FFmpegZip = "ffmpeg-master-latest-win64-gpl-shared.zip"
MakeDir build\dist\PianoTrans-$Version\ffmpeg\
if (-not (Test-Path build\dist\PianoTrans-$Version\ffmpeg\ffmpeg.exe)) {
    Write-Host "Downloading FFmpeg..."
    DownloadUrl -Url $FFmpegUrl -File $FFmpegZip

    # FFmpeg zip extracts to a versioned directory — find it
    $ffmpegExtractDir = [IO.Path]::Combine($pwd, "build\ffmpeg_extract")
    if (Test-Path $ffmpegExtractDir) { rm -r $ffmpegExtractDir }
    MakeDir $ffmpegExtractDir

    $shell = New-Object -com shell.application
    $shell.Namespace($ffmpegExtractDir).CopyHere(
        $shell.Namespace([IO.Path]::Combine($pwd, "dist\downloads\$FFmpegZip")).Items()
    )

    # Find ffmpeg.exe inside the extracted tree
    $ffmpegExe = Get-ChildItem $ffmpegExtractDir -Recurse -Filter "ffmpeg.exe" |
        Select-Object -First 1
    if ($ffmpegExe) {
        cp $ffmpegExe.FullName build\dist\PianoTrans-$Version\ffmpeg\
    } else {
        Write-Warning "ffmpeg.exe not found in extracted zip — check FFmpeg archive structure"
    }
    rm -r $ffmpegExtractDir
}

# ──── Context menu launcher ──────────────────────────────────────────────

DownloadUrl -Url $SingleExeUrl -File dist\downloads\singleinstance.exe
cp dist\downloads\singleinstance.exe build\dist\PianoTrans-$Version\

# ──── Copy supporting files ──────────────────────────────────────────────

MakeDir build\dist\PianoTrans-$Version\reg\
cp ..\README.md build\dist\PianoTrans-$Version\README.txt
cp PianoTrans-CPU.bat, RightClickMenuRegister.bat, RightClickMenuUnregister.bat build\dist\PianoTrans-$Version\
cp RightClickMenuRegister.reg.in, RightClickMenuUnregister.reg build\dist\PianoTrans-$Version\reg\

# ──── Package as 7z ──────────────────────────────────────────────────────

$SevenZipArchive = "dist\PianoTrans-$Version.7z"
if (-not (Test-Path $SevenZipArchive)) {
    Push-Location build\dist
    & $7zDir\7z.exe a ..\..\$SevenZipArchive PianoTrans-$Version
    Pop-Location
}

# ──── Done ───────────────────────────────────────────────────────────────

Write-Host "============================================"
Write-Host "Build complete: $SevenZipArchive"
Write-Host "============================================"
Read-Host "Done, press enter to exit"
