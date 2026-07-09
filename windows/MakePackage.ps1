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

# 鈹€鈹€鈹€鈹€ Configurable URLs (verify these before building) 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

$WinPythonUrl = "https://github.com/winpython/winpython/releases/download/13.1.202502222final/Winpython64-3.12.9.0dot.exe"
$SevenZipUrl   = "https://www.7-zip.org/a/7z2602-x64.exe"
$FFmpegUrl     = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
$CheckpointUrl = "https://zenodo.org/record/4034264/files/CRNN_note_F1%3D0.9677_pedal_F1%3D0.9186.pth?download=1"
$SingleExeUrl  = "https://github.com/zenden2k/context-menu-launcher/releases/download/1.0/singleinstance.exe"

# PyTorch 2.7.1+cu128 鈥?first stable release with Blackwell (RTX 50-series) support
$PyTorchIndex  = "https://download.pytorch.org/whl/cu128"
$PyTorchVer    = "2.7.1"

# librosa pinned to 0.9.x 鈥?compatible with piano_transcription_inference 0.0.5
# without needing the Nix patches (which are only required for librosa 鈮?0.10)
$LibrosaVer    = "0.9.2"

$Version       = "v1.1"

# 鈹€鈹€鈹€鈹€ Setup directories 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

MakeDir build\
MakeDir dist\downloads\

# 鈹€鈹€鈹€鈹€ 7-Zip 26.02 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

$7zDir = [IO.Path]::Combine($pwd, "build\7z")
UnpackUrl -Url $SevenZipUrl -ArgumentList "/S /D=$7zDir" -TestPath $7zDir

# 鈹€鈹€鈹€鈹€ WinPython 3.12.9 (dot / minimal) 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
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

# 鈹€鈹€鈹€鈹€ Install PyTorch 2.7.1 + CUDA 12.8 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

if (-not (Test-Path $LibsDir\torch)) {
    Write-Host "Installing PyTorch $PyTorchVer + CUDA 12.8 (Blackwell support)..."
    & $PythonExe -m pip --cache-dir "$PipCacheDir" install torch==$PyTorchVer `
        --index-url $PyTorchIndex
}

# 鈹€鈹€鈹€鈹€ Install piano_transcription_inference + librosa 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

if (-not (Test-Path $LibsDir\piano_transcription_inference)) {
    Write-Host "Installing librosa==$LibrosaVer and piano_transcription_inference..."
    & $PythonExe -m pip --cache-dir "$PipCacheDir" install `
        librosa==$LibrosaVer `
        piano_transcription_inference
}

# 鈹€鈹€鈹€鈹€ Install PyInstaller 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

if (-not (Test-Path $ScriptsDir\pyinstaller.exe)) {
    Write-Host "Installing PyInstaller..."
    & $PythonExe -m pip --cache-dir "$PipCacheDir" install pyinstaller
}

# 鈹€鈹€鈹€鈹€ Freeze dependency list 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

& $PythonExe -m pip freeze | Out-File -encoding UTF8 pip.txt

# 鈹€鈹€鈹€鈹€ Build with PyInstaller 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

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
    Write-Error "PyInstaller build failed 鈥?PianoTrans directory not found."
    exit 1
}

# 鈹€鈹€鈹€鈹€ Download model checkpoint 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

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

# 鈹€鈹€鈹€鈹€ Bundle FFmpeg 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

$FFmpegZip = "ffmpeg-master-latest-win64-gpl-shared.zip"
MakeDir build\dist\PianoTrans-$Version\ffmpeg\
if (-not (Test-Path build\dist\PianoTrans-$Version\ffmpeg\ffmpeg.exe)) {
    Write-Host "Downloading FFmpeg..."
    DownloadUrl -Url $FFmpegUrl -File $FFmpegZip

    # FFmpeg zip extracts to a versioned directory 鈥?find it
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
        Write-Warning "ffmpeg.exe not found in extracted zip 鈥?check FFmpeg archive structure"
    }
    rm -r $ffmpegExtractDir
}

# 鈹€鈹€鈹€鈹€ Context menu launcher 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

DownloadUrl -Url $SingleExeUrl -File dist\downloads\singleinstance.exe
cp dist\downloads\singleinstance.exe build\dist\PianoTrans-$Version\

# 鈹€鈹€鈹€鈹€ Copy supporting files 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

MakeDir build\dist\PianoTrans-$Version\reg\
cp ..\README.md build\dist\PianoTrans-$Version\README.txt
cp PianoTrans-CPU.bat, RightClickMenuRegister.bat, RightClickMenuUnregister.bat build\dist\PianoTrans-$Version\
cp RightClickMenuRegister.reg.in, RightClickMenuUnregister.reg build\dist\PianoTrans-$Version\reg\

# 鈹€鈹€鈹€鈹€ Package as 7z 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

$SevenZipArchive = "dist\PianoTrans-$Version.7z"
if (-not (Test-Path $SevenZipArchive)) {
    Push-Location build\dist
    & $7zDir\7z.exe a ..\..\$SevenZipArchive PianoTrans-$Version
    Pop-Location
}

# 鈹€鈹€鈹€鈹€ Done 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

Write-Host "============================================"
Write-Host "Build complete: $SevenZipArchive"
Write-Host "============================================"
Read-Host "Done, press enter to exit"

