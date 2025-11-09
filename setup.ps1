# BepInEx Game Modding Template Setup Script
# This script converts the template into a working BepInEx modding workspace
# Compatible with PowerShell Core (cross-platform)

param(
    [switch]$Help,
    [string]$Author
)

if ($Help) {
    Write-Host @"
BepInEx Game Modding Template Setup

This script will:
1. Prompt for game and author information
2. Detect your game installation and validate compatibility
3. Replace template variables in all files
4. Optionally set up git repository
5. Clean up template files

Usage: 
  .\setup.ps1                    # Interactive mode
  .\setup.ps1 AuthorName         # Quick setup with author name

Quick Setup:
When you provide an author name, the script will auto-generate defaults
and ask for confirmation before proceeding.

Requirements:
- Game must use Mono (not IL2CPP) - we'll validate this
- PowerShell 5.1+ or PowerShell Core 6+
- Internet connection (for optional BepInEx download)

"@
    exit 0
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Write-Step($message) {
    Write-Host "`n==> $message" -ForegroundColor Cyan
}

function Write-Success($message) {
    Write-Host "SUCCESS: $message" -ForegroundColor Green
}

function Write-Error($message) {
    Write-Host "ERROR: $message" -ForegroundColor Red
}

function Write-Warning($message) {
    Write-Host "WARNING: $message" -ForegroundColor Yellow
}

function Get-UnityVersion($gameDirectory) {
    # Look for UnityPlayer.dll in the game directory
    $unityPlayerPath = Join-Path $gameDirectory "UnityPlayer.dll"
    
    if (-not (Test-Path $unityPlayerPath)) {
        Write-Warning "UnityPlayer.dll not found in game directory. Using default Unity version."
        return "2022.3.6"  # Fallback version
    }
    
    try {
        # Get file version info
        $versionInfo = Get-ItemProperty $unityPlayerPath | Select-Object VersionInfo
        $productVersion = $versionInfo.VersionInfo.ProductVersion
        
        Write-Host "Found Unity version info: $productVersion" -ForegroundColor Cyan
        
        # Extract version from format like "2022.3.6f2 (767c0088955a)"
        if ($productVersion -match '^(\d{4}\.\d+\.\d+)') {
            $unityVersion = $matches[1]
            Write-Success "Detected Unity version: $unityVersion"
            return $unityVersion
        } else {
            Write-Warning "Could not parse Unity version from: $productVersion"
            return "2022.3.6"  # Fallback
        }
    } catch {
        Write-Warning "Failed to read Unity version: $($_.Exception.Message)"
        return "2022.3.6"  # Fallback
    }
}

function Get-UserInput($prompt, $default = "") {
    if ($default) {
        $userInput = Read-Host "$prompt [$default]"
        if ($userInput) { 
            return $userInput 
        } else { 
            return $default 
        }
    } else {
        do {
            $userInput = Read-Host $prompt
        } while ([string]::IsNullOrWhiteSpace($userInput))
        return $userInput.Trim()
    }
}

function Get-YesNoInput($prompt, $default = "Y") {
    do {
        $userInput = Read-Host "$prompt [Y/n]"
        if ([string]::IsNullOrWhiteSpace($userInput)) { $userInput = $default }
        $userInput = $userInput.ToUpper()
    } while ($userInput -notin @("Y", "YES", "N", "NO"))
    return $userInput -in @("Y", "YES")
}

function Select-GameDataFolder {
    Write-Step "Select your game Data folder"
    Write-Host "Scanning for Unity games with BepInEx support...`n"
    
    # Auto-detect Unity games in Steam locations
    $steamPaths = @(
        "C:\Program Files (x86)\Steam\steamapps\common",
        "C:\Program Files\Steam\steamapps\common", 
        "$env:USERPROFILE\AppData\Local\Steam\steamapps\common",
        "D:\Steam\steamapps\common",
        "E:\Steam\steamapps\common"
    )
    
    $supportedGames = @()
    foreach ($steamPath in $steamPaths) {
        if (Test-Path $steamPath) {
            $gameFolders = Get-ChildItem $steamPath -Directory
            foreach ($gameFolder in $gameFolders) {
                # Look for Data folders
                $dataSubfolders = Get-ChildItem $gameFolder.FullName -Directory -ErrorAction SilentlyContinue | Where-Object { 
                    $_.Name -like "*_Data" -or $_.Name -eq "Data" 
                }
                
                foreach ($dataFolder in $dataSubfolders) {
                    # Check if it's a Unity game with Managed folder (BepInEx compatible)
                    $managedFolder = Join-Path $dataFolder.FullName "Managed"
                    if (Test-Path $managedFolder) {
                        $supportedGames += [PSCustomObject]@{
                            Game = $gameFolder.Name
                            DataPath = $dataFolder.FullName
                            DataFolderName = $dataFolder.Name
                            SteamPath = $steamPath
                        }
                    }
                }
            }
        }
    }
    
    # Remove duplicates (same game in multiple Steam locations)
    $supportedGames = $supportedGames | Sort-Object Game | Get-Unique -AsString
    
    if ($supportedGames.Count -gt 0) {
        Write-Host "Found supported Unity games:" -ForegroundColor Green
        for ($i = 0; $i -lt $supportedGames.Count; $i++) {
            Write-Host "  [$i] $($supportedGames[$i].Game) ($($supportedGames[$i].DataFolderName))"
        }
    } else {
        Write-Host "No supported Unity games found in common Steam locations." -ForegroundColor Yellow
    }
    
    # Add manual options at the end
    $browserOption = $supportedGames.Count
    $manualOption = $supportedGames.Count + 1
    
    Write-Host ""
    Write-Host "  [$browserOption] Browse with folder dialog"
    Write-Host "  [$manualOption] Type path manually"
    
    do {
        $maxOption = $supportedGames.Count + 1
        $selection = Read-Host "Select option [0-$maxOption]"
        $index = [int]$selection
    } while ($index -lt 0 -or $index -gt $maxOption)
    
    if ($index -lt $supportedGames.Count) {
        # Selected a detected game
        return $supportedGames[$index].DataPath
    } elseif ($index -eq $browserOption) {
        # Browse with folder dialog
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderBrowser.Description = 'Select the Data folder (typically ends with _Data)'
            $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
            $folderBrowser.SelectedPath = "C:\Program Files (x86)\Steam\steamapps\common"
            $folderBrowser.ShowNewFolderButton = $false
            
            $result = $folderBrowser.ShowDialog()
            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                return $folderBrowser.SelectedPath
            } else {
                Write-Error "Folder selection cancelled"
                exit 1
            }
        } catch {
            Write-Error "Could not open folder browser. Try manual path entry."
            return Get-UserInput "Enter full path to your game's Data folder"
        }
    } else {
        # Manual path entry
        return Get-UserInput "Enter full path to your game's Data folder"
    }
}

function Test-GameCompatibility($dataFolder) {
    Write-Step "Validating game compatibility"
    
    # Check if folder exists and is named correctly
    if (-not (Test-Path $dataFolder)) {
        Write-Error "Selected folder does not exist: $dataFolder"
        return $false
    }
    
    # Check for Managed folder (required for Mono games)
    $managedFolder = Join-Path $dataFolder "Managed"
    if (-not (Test-Path $managedFolder)) {
        Write-Error "Managed folder not found. This appears to be an IL2CPP game."
        Write-Host "IL2CPP games are not supported by this template." -ForegroundColor Red
        Write-Host "This template only works with Mono Unity games." -ForegroundColor Red
        return $false
    }
    
    Write-Success "Found Managed folder - game uses Mono runtime"
    
    # Look for main game assembly
    $assemblyFiles = Get-ChildItem $managedFolder -Filter "*.dll" | Where-Object { 
        $_.Name -notmatch "Unity|System|Microsoft|mscorlib|Newtonsoft" -and
        $_.Name -notmatch "^(netstandard|Mono\.|I18N)"
    }
    
    if (-not $assemblyFiles) {
        Write-Error "No game assemblies found in Managed folder"
        return $false
    }
    
    # Look for Assembly-CSharp.dll specifically
    $mainAssembly = $assemblyFiles | Where-Object { $_.Name -eq "Assembly-CSharp.dll" }
    if ($mainAssembly) {
        Write-Success "Found Assembly-CSharp.dll"
        return $mainAssembly.Name
    }
    
    # Fallback: let user pick from available assemblies
    Write-Warning "Assembly-CSharp.dll not found. Available game assemblies:"
    for ($i = 0; $i -lt $assemblyFiles.Count; $i++) {
        Write-Host "  [$i] $($assemblyFiles[$i].Name)"
    }
    
    do {
        $choice = Read-Host "Select main game assembly [0-$($assemblyFiles.Count - 1)]"
        $index = [int]$choice
    } while ($index -lt 0 -or $index -ge $assemblyFiles.Count)
    
    $selectedAssembly = $assemblyFiles[$index]
    Write-Success "Selected: $($selectedAssembly.Name)"
    return $selectedAssembly.Name
}

function Test-BepInExInstallation($gameDirectory) {
    $bepInExFolder = Join-Path $gameDirectory "BepInEx"
    $bepInExCore = Join-Path $bepInExFolder "core"
    $bepInExDll = Join-Path $bepInExCore "BepInEx.dll"
    
    if (Test-Path $bepInExDll) {
        # Try to detect version from file properties or changelog
        $changelogPath = Join-Path $bepInExFolder "changelog.txt"
        $detectedVersion = "5.4.21"  # default fallback
        
        if (Test-Path $changelogPath) {
            $changelog = Get-Content $changelogPath -ErrorAction SilentlyContinue
            $versionMatch = $changelog | Where-Object { $_ -match "^## (\d+\.\d+\.\d+\.\d+)" } | Select-Object -First 1
            if ($versionMatch -and ($versionMatch -match "## (\d+\.\d+\.\d+\.\d+)")) {
                $detectedVersion = $Matches[1]
            }
        }
        
        Write-Success "BepInEx $detectedVersion is already installed"
        return @{ Installed = $true; Version = $detectedVersion }
    } else {
        Write-Warning "BepInEx not found in game directory"
        return @{ Installed = $false; Version = $null }
    }
}

function Get-GameArchitecture($gameDirectory) {
    # Try to find game executable and check its architecture
    $exeFiles = Get-ChildItem $gameDirectory -Filter "*.exe" | Where-Object {
        $_.Name -notmatch "UnityCrashHandler|UnityPlayer|Uninstall"
    }
    
    if ($exeFiles.Count -gt 0) {
        $gameExe = $exeFiles[0].FullName
        try {
            # Read PE header to determine architecture
            $fileBytes = [System.IO.File]::ReadAllBytes($gameExe)
            $peOffset = [BitConverter]::ToInt32($fileBytes, 60)
            $machine = [BitConverter]::ToUInt16($fileBytes, $peOffset + 4)
            
            switch ($machine) {
                0x014c { return "x86" }  # IMAGE_FILE_MACHINE_I386
                0x8664 { return "x64" }  # IMAGE_FILE_MACHINE_AMD64
                default { return "unknown" }
            }
        } catch {
            Write-Warning "Could not determine game architecture from executable"
            return "unknown"
        }
    }
    return "unknown"
}

function Get-BepInExDownloadInfo($version, $gameArch) {
    $isWindows = $IsWindows -or ($PSVersionTable.PSVersion.Major -le 5)
    
    # Handle different filename formats for different versions
    if ($version -eq "5.4.21") {
        # 5.4.21 uses old filename format
        if ($isWindows) {
            if ($gameArch -eq "x86") {
                return @{
                    Platform = "win_x86"
                    FileName = "BepInEx_x86_5.4.21.0.zip"
                    Url = "https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_x86_5.4.21.0.zip"
                }
            } else {
                return @{
                    Platform = "win_x64"
                    FileName = "BepInEx_x64_5.4.21.0.zip"
                    Url = "https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_x64_5.4.21.0.zip"
                }
            }
        } elseif ($IsLinux -or $IsMacOS) {
            return @{
                Platform = "unix"
                FileName = "BepInEx_unix_5.4.21.0.zip"
                Url = "https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_unix_5.4.21.0.zip"
            }
        } else {
            # Fallback to Windows x64
            return @{
                Platform = "win_x64"
                FileName = "BepInEx_x64_5.4.21.0.zip"
                Url = "https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_x64_5.4.21.0.zip"
            }
        }
    } else {
        # Newer versions use the modern filename format
        if ($isWindows) {
            if ($gameArch -eq "x86") {
                return @{
                    Platform = "win_x86"
                    FileName = "BepInEx_win_x86_$version.zip"
                    Url = "https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_win_x86_$version.zip"
                }
            } else {
                return @{
                    Platform = "win_x64"
                    FileName = "BepInEx_win_x64_$version.zip"
                    Url = "https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_win_x64_$version.zip"
                }
            }
        } elseif ($IsLinux) {
            return @{
                Platform = "linux_x64"
                FileName = "BepInEx_linux_x64_$version.zip"
                Url = "https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_linux_x64_$version.zip"
            }
        } elseif ($IsMacOS) {
            return @{
                Platform = "macos_x64"
                FileName = "BepInEx_macos_x64_$version.zip"
                Url = "https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_macos_x64_$version.zip"
            }
        } else {
            # Fallback to Windows x64
            return @{
                Platform = "win_x64"
                FileName = "BepInEx_win_x64_$version.zip"
                Url = "https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_win_x64_$version.zip"
            }
        }
    }
}

function Install-BepInEx($gameDirectory, $version) {
    Write-Step "Installing BepInEx v$version"
    
    # Detect game architecture
    $gameArch = Get-GameArchitecture $gameDirectory
    Write-Host "Detected game architecture: $gameArch"
    
    # Get download info based on platform and architecture
    $downloadInfo = Get-BepInExDownloadInfo $version $gameArch
    Write-Host "Selected BepInEx variant: $($downloadInfo.Platform)"
    
    if ($gameArch -eq "unknown") {
        Write-Warning "Could not detect game architecture - defaulting to x64"
        Write-Warning "If BepInEx does not work, you may need to install the x86 version manually"
    }
    
    try {
        $tempZip = Join-Path $env:TEMP $downloadInfo.FileName
        
        Write-Host "Downloading BepInEx from GitHub..."
        Invoke-WebRequest -Uri $downloadInfo.Url -OutFile $tempZip -UseBasicParsing
        Write-Success "Downloaded BepInEx ($($downloadInfo.Platform))"
        
        # Extract to game directory
        Write-Host "Extracting to game directory..."
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $gameDirectory)
        
        # Cleanup
        Remove-Item $tempZip -Force
        Write-Success "BepInEx v$version installed successfully!"
        
        Write-Host "`nNext steps for BepInEx setup:" -ForegroundColor Yellow
        Write-Host "1. Run the game once to initialize BepInEx"
        Write-Host "2. Check BepInEx/LogOutput.log to verify it loaded correctly"
        
        if ($gameArch -eq "unknown") {
            Write-Host "\nArchitecture Detection Warning:" -ForegroundColor Yellow
            Write-Host "If the game does not start or BepInEx does not load:"
            Write-Host "- Download the x86 version manually and replace the files"
            Write-Host "- Visit: https://github.com/BepInEx/BepInEx/releases/tag/v$version"
        }
        
        return $true
    } catch {
        Write-Error "Failed to install BepInEx: $($_.Exception.Message)"
        Write-Host "\nManual installation options:" -ForegroundColor Yellow
        if ($version -eq "5.4.21") {
            Write-Host "- Windows x64: https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_x64_5.4.21.0.zip"
            Write-Host "- Windows x86: https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_x86_5.4.21.0.zip"
            Write-Host "- Unix (Linux/macOS): https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_unix_5.4.21.0.zip"
        } else {
            Write-Host "- Windows x64: https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_win_x64_$version.zip"
            Write-Host "- Windows x86: https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_win_x86_$version.zip"
            Write-Host "- Linux x64:   https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_linux_x64_$version.zip"
            Write-Host "- macOS x64:   https://github.com/BepInEx/BepInEx/releases/download/v$version/BepInEx_macos_x64_$version.zip"
        }
        return $false
    }
}

function Get-GameInfoFromPath($dataFolder) {
    $parentFolder = Split-Path $dataFolder -Parent
    $dataFolderName = Split-Path $dataFolder -Leaf
    
    # Extract game name from parent directory
    $gameName = Split-Path $parentFolder -Leaf
    
    # Try to find game executable for validation
    $exeFiles = Get-ChildItem $parentFolder -Filter "*.exe" | Where-Object {
        $_.Name -notmatch "UnityCrashHandler|UnityPlayer|Uninstall"
    }
    
    if ($exeFiles.Count -gt 1) {
        Write-Host "`nMultiple executables found:"
        for ($i = 0; $i -lt $exeFiles.Count; $i++) {
            Write-Host "  [$i] $($exeFiles[$i].Name)"
        }
        
        do {
            $choice = Read-Host "Select main game executable [0-$($exeFiles.Count - 1)]"
            $index = [int]$choice
        } while ($index -lt 0 -or $index -ge $exeFiles.Count)
        
        $gameExe = $exeFiles[$index].Name
    } elseif ($exeFiles.Count -eq 1) {
        $gameExe = $exeFiles[0].Name
    } else {
        Write-Warning "No game executable found - this is unusual but proceeding..."
        $gameExe = "$gameName.exe"
    }
    
    # Create display name (add spaces to camel case only if no spaces exist)
    if ($gameName -match '\s') {
        # Already has spaces - this is the game's official name format
        $displayName = $gameName
        $gameNameForTemplate = $gameName  # Keep spaces for legitimate game names
    } else {
        # No spaces, likely camelCase - add spaces between lowercase and uppercase
        $displayName = $gameName -replace '([a-z])([A-Z])', '$1 $2'
        $gameNameForTemplate = $gameName
    }

    return @{
        GameName = $gameNameForTemplate
        DisplayName = $displayName
        DataFolder = $dataFolderName
        ExecutableName = $gameExe
        GameDirectory = $parentFolder
        UnityVersion = (Get-UnityVersion $parentFolder)
    }
}

function Replace-TemplateVariables($templateVars) {
    Write-Step "Processing template files"
    
    # Find all .template files
    $templateFiles = Get-ChildItem -Recurse -Filter "*.template"
    
    if ($templateFiles.Count -eq 0) {
        Write-Warning "No .template files found"
        return
    }
    
    Write-Host "Found $($templateFiles.Count) template files to process"
    
    foreach ($templateFile in $templateFiles) {
        Write-Host "  Processing: $($templateFile.Name)"
        
        try {
            # Read file content
            $content = Get-Content $templateFile.FullName -Raw -Encoding UTF8
            
            # Replace all template variables
            foreach ($var in $templateVars.GetEnumerator()) {
                $placeholder = "{{$($var.Key)}}"
                $content = $content -replace [regex]::Escape($placeholder), $var.Value
            }
            
            # Write to new file without .template extension
            $newFileName = $templateFile.FullName -replace "\.template$", ""
            Set-Content -Path $newFileName -Value $content -Encoding UTF8 -NoNewline
            
            Write-Success "Created: $(Split-Path $newFileName -Leaf)"
        } catch {
            Write-Error "Failed to process $($templateFile.Name): $($_.Exception.Message)"
        }
    }
}

function Rename-SolutionFile($repoName) {
    Write-Step "Renaming solution file"
    
    # Look for the template-generated solution file
    $templateSln = "GameTemplate.sln"
    $newSln = "$repoName.sln"
    
    if (Test-Path $templateSln) {
        # Remove destination if it already exists
        if (Test-Path $newSln) {
            Remove-Item $newSln -Force
        }
        Rename-Item $templateSln $newSln
        Write-Success "Renamed solution: $newSln"
    } else {
        Write-Warning "Template solution file $templateSln not found"
    }
}

function Initialize-GitRepository($templateVars, $useHttps) {
    Write-Step "Setting up Git repository"
    
    try {
        # Initialize git if not already a repo
        if (-not (Test-Path ".git")) {
            git init
            Write-Success "Initialized Git repository"
        }
        
        # Set up remote URL
        $username = $templateVars["GITHUB_USERNAME"]
        $repoName = $templateVars["REPO_NAME"]
        
        if ($useHttps) {
            $remoteUrl = "https://github.com/$username/$repoName.git"
        } else {
            $remoteUrl = "git@github.com:$username/$repoName.git"
        }
        
        # Add remote (remove if exists)
        $existingRemote = git remote get-url origin 2>$null
        if ($existingRemote) {
            git remote set-url origin $remoteUrl
            Write-Success "Updated remote origin: $remoteUrl"
        } else {
            git remote add origin $remoteUrl
            Write-Success "Added remote origin: $remoteUrl"
        }
        
        # Create initial commit
        git add .
        git commit -m "Initial mod workspace setup"
        Write-Success "Created initial commit"
        
        Write-Host "`nGit setup complete!" -ForegroundColor Green
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Create repository on GitHub: https://github.com/$username/$repoName"
        Write-Host "2. Push your code: git push -u origin main"
        
    } catch {
        Write-Error "Git setup failed: $($_.Exception.Message)"
    }
}

function Remove-TemplateFiles($includeScript) {
    Write-Step "Cleaning up template files"
    
    # Remove .template files
    $templateFiles = Get-ChildItem -Recurse -Filter "*.template"
    foreach ($file in $templateFiles) {
        Remove-Item $file.FullName -Force
        Write-Success "Removed: $($file.Name)"
    }
    
    # Remove template plan
    if (Test-Path "TEMPLATE_CONVERSION_PLAN.md") {
        Remove-Item "TEMPLATE_CONVERSION_PLAN.md" -Force
        Write-Success "Removed: TEMPLATE_CONVERSION_PLAN.md"
    }
    
    # Remove setup script (handle self-deletion)
    if ($includeScript -and (Test-Path "setup.ps1")) {
        Write-Host "NOTE: setup.ps1 will be removed after the script completes." -ForegroundColor Yellow
        Write-Host "The script cannot delete itself while running." -ForegroundColor Yellow
        
        # Create a cleanup script that will run after this one exits
        $cleanupScript = @"
Start-Sleep -Seconds 2
if (Test-Path "setup.ps1") {
    Remove-Item "setup.ps1" -Force
    Write-Host "Removed: setup.ps1" -ForegroundColor Green
}
Remove-Item `$MyInvocation.MyCommand.Path -Force
"@
        Set-Content -Path "cleanup-temp.ps1" -Value $cleanupScript
        
        # Schedule the cleanup to run after this script exits
        Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "cleanup-temp.ps1" -WindowStyle Hidden
        
        Write-Success "Scheduled setup.ps1 removal after script completion"
    }
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

Write-Host @"
=============================================================================
    BepInEx Game Modding Template Setup
=============================================================================

This script will configure the template for your specific game.

"@ -ForegroundColor Cyan

# Step 1: Get game information
$dataFolder = Select-GameDataFolder
$mainAssembly = Test-GameCompatibility $dataFolder

if (-not $mainAssembly) {
    Write-Error 'Game compatibility check failed. Setup aborted.'
    exit 1
}

$gameInfo = Get-GameInfoFromPath $dataFolder

Write-Host '\nDetected game information:' -ForegroundColor Green
Write-Host "  Game Name: $($gameInfo.GameName)"
Write-Host "  Display Name: $($gameInfo.DisplayName)"
Write-Host "  Data Folder: $($gameInfo.DataFolder)"
Write-Host "  Main Assembly: $mainAssembly"

# Step 3: Check/Install BepInEx
$bepInExInfo = Test-BepInExInstallation $gameInfo.GameDirectory

if (-not $bepInExInfo.Installed) {
    if (Get-YesNoInput "`nWould you like to download and install BepInEx?") {
        $version = Get-UserInput "BepInEx version to install" "5.4.21"
        $installSuccess = Install-BepInEx $gameInfo.GameDirectory $version
        if (-not $installSuccess) {
            Write-Warning "Continuing with template setup, but you will need to install BepInEx manually later."
            $version = "5.4.21"  # fallback for template
        }
    } else {
        Write-Warning "BepInEx not installed. You will need to install it manually before using your mods."
        Write-Host "Download from: https://github.com/BepInEx/BepInEx/releases"
        $version = "5.4.21"  # fallback for template
    }
} else {
    # Use the detected version
    $version = $bepInExInfo.Version
}

# Step 2: Collect template variables
$templateVars = @{}

if ($Author) {
    Write-Step "Quick setup mode with author: $Author"
    
    # Auto-populate defaults
    $templateVars["AUTHOR"] = $Author
    $templateVars["GITHUB_USERNAME"] = $Author
    $templateVars["GAME_NAME"] = $gameInfo.GameName
    $templateVars["GAME_NAME_SAFE"] = $gameInfo.GameName -replace '[^\w]', ''
    $templateVars["GAME_DISPLAY_NAME"] = $gameInfo.DisplayName
    $templateVars["GAME_DATA_FOLDER"] = $gameInfo.DataFolder
    $gameNameForRepo = $templateVars["GAME_NAME"] -replace '\s+', ''
    $templateVars["REPO_NAME"] = $gameNameForRepo
    $templateVars["BEPINX_VERSION"] = $version
    $templateVars["UNITY_VERSION"] = $gameInfo.UnityVersion
    
    # Show preview and confirm
    Write-Host "`nAuto-generated template variables:" -ForegroundColor Green
    foreach ($var in $templateVars.GetEnumerator()) {
        Write-Host "  $($var.Key): $($var.Value)"
    }
    
    if (-not (Get-YesNoInput "`nUse these settings?")) {
        Write-Step "Collecting project information (interactive mode)"
        $templateVars = @{}  # Reset and fall through to manual collection
        $Author = $null      # Clear to trigger manual mode below
    }
}

if (-not $Author) {
    Write-Step "Collecting project information"
    
    # Author information
    $templateVars["AUTHOR"] = Get-UserInput "Author Name"
    $templateVars["GITHUB_USERNAME"] = Get-UserInput "GitHub Username" $templateVars["AUTHOR"]

    # Game information with smart defaults
    $templateVars["GAME_NAME"] = Get-UserInput "Game Name" $gameInfo.GameName
    $templateVars["GAME_NAME_SAFE"] = $templateVars["GAME_NAME"] -replace '[^\w]', ''
    $templateVars["GAME_DISPLAY_NAME"] = Get-UserInput "Game Display Name" $gameInfo.DisplayName
    $templateVars["GAME_DATA_FOLDER"] = Get-UserInput "Data Folder Name" $gameInfo.DataFolder

    # Project information
    $gameNameForRepo = $templateVars["GAME_NAME"] -replace '\s+', ''
    $defaultRepoName = $gameNameForRepo
    $templateVars["REPO_NAME"] = Get-UserInput "Repository Name" $defaultRepoName

    # Technical details
    # Use the version we detected or installed
    $templateVars["BEPINX_VERSION"] = $version
    
    # Use detected Unity version or ask user if detection failed
    if ($gameInfo.UnityVersion) {
        $templateVars["UNITY_VERSION"] = Get-UserInput "Unity Version" $gameInfo.UnityVersion
    } else {
        $templateVars["UNITY_VERSION"] = Get-UserInput "Unity Version" "2022.3.6"
    }
}

Write-Host "`nTemplate variables configured:" -ForegroundColor Green
foreach ($var in $templateVars.GetEnumerator()) {
    Write-Host "  $($var.Key): $($var.Value)"
}

# Confirm before processing (skip if already confirmed in quick setup)
if (-not $Author -and -not (Get-YesNoInput "`nProceed with template setup?")) {
    Write-Warning "Setup cancelled by user"
    exit 0
}

# Step 3: Process template files
Replace-TemplateVariables $templateVars
Rename-SolutionFile $templateVars["REPO_NAME"]

Write-Success "Template processing complete!"

# Step 4: Cleanup decision (ask before Git setup)
$removeTemplates = Get-YesNoInput "`nRemove template files and setup script?"

if ($removeTemplates) {
    Remove-TemplateFiles $true
}

# Step 5: Optional Git setup (after cleanup)
if (Get-YesNoInput "`nSet up Git repository?") {
    Write-Host "`nChoose Git remote URL format:"
    Write-Host "  HTTPS: https://github.com/username/repo.git (works everywhere)"
    Write-Host "  SSH:   git@github.com:username/repo.git (requires SSH key setup)"
    $useHttps = Get-YesNoInput "Use HTTPS remote URL?" "Y"
    Initialize-GitRepository $templateVars $useHttps
}

Write-Success "`nSetup complete! Your BepInEx modding workspace is ready."

# Step 6: Optional new mod creation
if (Get-YesNoInput "`nWould you like to create a new mod now?") {
    $modName = Get-UserInput "Enter your mod name (no spaces)"
    $modDescription = Get-UserInput "Enter mod description (optional)" ""
    
    Write-Host "`nCreating new mod alongside ExampleMod..." -ForegroundColor Cyan
    & ".\new-mod.ps1" -ModName $modName -ModDescription $modDescription
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Build your mod: dotnet build"
    Write-Host "2. Check the README.md for detailed instructions"
    Write-Host "3. Start coding your mod!"
} else {
    Write-Host "`nSetup complete!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Examine ExampleMod to understand the structure"
    Write-Host "2. Build the example: dotnet build src/ExampleMod/ExampleMod.csproj"
    Write-Host "3. Use new-mod.ps1 to create your own mods: .\new-mod.ps1 'YourModName'"
    Write-Host "4. Check the README.md for detailed instructions"
}

if (-not $removeTemplates) {
    Write-Host "`nTemplate files preserved for reference." -ForegroundColor Yellow
    Write-Host "You can manually delete .template files and TEMPLATE_CONVERSION_PLAN.md when ready."
}

Write-Host "`nHappy modding!" -ForegroundColor Green