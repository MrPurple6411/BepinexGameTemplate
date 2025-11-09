# New Mod Project Creation Script
# Creates a new mod project in the workspace based on the ExampleMod template

param(
    [Parameter(Mandatory = $true)]
    [string]$ModName,
    
    [string]$ModDescription = "",
    [string]$ModVersion = "1.0.0",
    [switch]$Help,
    [switch]$DebugMode
)

if ($Help) {
    Write-Host @"
New Mod Project Creator

Creates a new BepInEx mod project in the current workspace.

Usage: .\new-mod.ps1 <ModName> [options]

Parameters:
  ModName          Name of the new mod (required)
  -ModDescription  Description for the mod (optional)
  -ModVersion      Starting version (default: 1.0.0)
  -Help            Show this help message
  -DebugMode       Simulate operations without creating files

Examples:
  .\new-mod.ps1 "AwesomeMod"
  .\new-mod.ps1 "QualityOfLife" -ModDescription "Improves game experience" -ModVersion "0.1.0"
  .\new-mod.ps1 "TestMod" -DebugMode  # Simulate without creating files

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

function Write-Debug($message) {
    if ($DebugMode) {
        Write-Host "DEBUG: $message" -ForegroundColor Magenta
    }
}

function Write-DebugPath($operation, $source, $target) {
    if ($DebugMode) {
        Write-Host "DEBUG PATH: $operation" -ForegroundColor Magenta
        Write-Host "  Source: $source" -ForegroundColor DarkMagenta
        Write-Host "  Target: $target" -ForegroundColor DarkMagenta
        Write-Host "  Source exists: $(Test-Path $source)" -ForegroundColor DarkMagenta
    }
}

function Test-ValidModName($name) {
    # Check for valid C# identifier (no spaces, special chars, etc.)
    if ($name -notmatch '^[A-Za-z][A-Za-z0-9]*$') {
        return $false
    }
    
    # Check for reserved C# keywords
    $reservedKeywords = @(
        "abstract", "as", "base", "bool", "break", "byte", "case", "catch", "char", "checked",
        "class", "const", "continue", "decimal", "default", "delegate", "do", "double", "else",
        "enum", "event", "explicit", "extern", "false", "finally", "fixed", "float", "for",
        "foreach", "goto", "if", "implicit", "in", "int", "interface", "internal", "is",
        "lock", "long", "namespace", "new", "null", "object", "operator", "out", "override",
        "params", "private", "protected", "public", "readonly", "ref", "return", "sbyte",
        "sealed", "short", "sizeof", "stackalloc", "static", "string", "struct", "switch",
        "this", "throw", "true", "try", "typeof", "uint", "ulong", "unchecked", "unsafe",
        "ushort", "using", "virtual", "void", "volatile", "while"
    )
    
    if ($reservedKeywords -contains $name.ToLower()) {
        return $false
    }
    
    return $true
}

function Get-WorkspaceInfo() {
    # Read workspace configuration from Directory.Build.props
    if (-not $DebugMode -and -not (Test-Path "Directory.Build.props")) {
        Write-Error "Directory.Build.props not found. This script must be run from a configured BepInX workspace."
        exit 1
    } elseif ($DebugMode) {
        Write-Debug "Would read workspace info from Directory.Build.props"
        return @{
            Author = "DebugAuthor"
            GameName = "DebugGame"
        }
    }
    
    $buildProps = Get-Content "Directory.Build.props" -Raw
    
    # Extract key information
    $author = if ($buildProps -match '<Author>(.*?)</Author>') { $matches[1] } else { "Unknown" }
    $gameName = if ($buildProps -match '<GameName>(.*?)</GameName>') { $matches[1] } else { "Game" }
    
    return @{
        Author = $author
        GameName = $gameName
    }
}

function Copy-ModTemplate($sourcePath, $targetPath, $modName, $workspaceInfo) {
    Write-Step "Creating mod project structure"
    
    # Resolve absolute paths
    $absoluteSourcePath = Resolve-Path $sourcePath
    $absoluteTargetPath = Join-Path (Get-Location) $targetPath
    
    Write-Debug "Template copy operation:"
    Write-DebugPath "Copy-ModTemplate" $absoluteSourcePath $absoluteTargetPath
    
    if (-not $DebugMode) {
        # Create target directory
        New-Item -ItemType Directory -Path $absoluteTargetPath | Out-Null
    } else {
        Write-Debug "Would create directory: $absoluteTargetPath"
    }
    
    # Copy all files from template
    $sourceFiles = Get-ChildItem $absoluteSourcePath -Recurse -File
    Write-Debug "Found $($sourceFiles.Count) files in template"
    
    foreach ($file in $sourceFiles) {
        # Calculate relative path properly
        $relativePath = $file.FullName.Substring($absoluteSourcePath.Path.Length + 1)
        $targetFilePath = Join-Path $absoluteTargetPath $relativePath
        
        Write-DebugPath "File copy" $file.FullName $targetFilePath
        
        # Create target directory if needed
        $targetDir = Split-Path $targetFilePath -Parent
        if (-not $DebugMode) {
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir | Out-Null
            }
        } else {
            Write-Debug "Would create directory: $targetDir"
        }
        
        # Read file content
        if (-not $DebugMode) {
            $content = Get-Content $file.FullName -Raw -Encoding UTF8
        } else {
            Write-Debug "Would read content from: $($file.FullName)"
            $content = "[DEBUG: Content would be read and processed]"
        }
        
        # Replace template variables
        $originalContent = $content
        $content = $content -replace '{{EXAMPLE_MOD_NAME}}', $modName
        $content = $content -replace 'ExampleMod', $modName
        $content = $content -replace '{{AUTHOR}}', $workspaceInfo.Author
        $content = $content -replace '{{GAME_NAME}}', $workspaceInfo.GameName
        
        if ($DebugMode -and $content -ne $originalContent) {
            Write-Debug "Template variables would be replaced in: $($file.Name)"
        }
        
        # Rename files that contain ExampleMod in the name
        if ($file.Name -match 'ExampleMod') {
            $newFileName = $file.Name -replace 'ExampleMod', $modName
            $targetFilePath = Join-Path (Split-Path $targetFilePath -Parent) $newFileName
            Write-Debug "File would be renamed: $($file.Name) -> $newFileName"
        }
        
        # Write to target file
        if (-not $DebugMode) {
            Set-Content -Path $targetFilePath -Value $content -Encoding UTF8 -NoNewline
        } else {
            Write-Debug "Would write file: $targetFilePath"
        }
    }
    
    if ($DebugMode) {
        Write-Success "[DEBUG] Would copy template files to src/$modName"
    } else {
        Write-Success "Copied template files to src/$modName"
    }
}

function Update-ProjectFile($projectPath, $modName, $modDescription, $modVersion, $workspaceInfo) {
    Write-Step "Configuring project file"
    
    if (-not (Test-Path $projectPath)) {
        Write-Error "Project file not found: $projectPath"
        return $false
    }
    
    $content = Get-Content $projectPath -Raw -Encoding UTF8
    
    # Update project metadata
    $content = $content -replace '`<AssemblyTitle`>.*?`</AssemblyTitle`>', "`<AssemblyTitle`>$modName`</AssemblyTitle`>"
    $content = $content -replace '`<PluginName`>.*?`</PluginName`>', "`<PluginName`>$modName`</PluginName`>"
    $content = $content -replace '`<PluginVersion`>.*?`</PluginVersion`>', "`<PluginVersion`>$modVersion`</PluginVersion`>"
    
    if ($modDescription) {
        $content = $content -replace '`<AssemblyDescription`>.*?`</AssemblyDescription`>', "`<AssemblyDescription`>$modDescription`</AssemblyDescription`>"
    } else {
        $content = $content -replace '`<AssemblyDescription`>.*?`</AssemblyDescription`>', "`<AssemblyDescription`>A BepInEx mod for $($workspaceInfo.GameName)`</AssemblyDescription`>"
    }
    
    # Update PluginGuid to be unique
    $pluginGuid = "$($workspaceInfo.Author).$($workspaceInfo.GameName).$($modName.ToLower())"
    $content = $content -replace '`<PluginGuid`>.*?`</PluginGuid`>', "`<PluginGuid`>$pluginGuid`</PluginGuid`>"
    
    Set-Content -Path $projectPath -Value $content -Encoding UTF8 -NoNewline
    Write-Success "Updated project metadata"
    
    return $true
}

function Add-ToSolution($solutionPath, $projectPath, $modName) {
    Write-Step "Adding project to solution"
    
    Write-DebugPath "Add-ToSolution" $projectPath $solutionPath
    
    if (-not $DebugMode -and -not (Test-Path $solutionPath)) {
        Write-Warning "Solution file not found: $solutionPath"
        Write-Host "You'll need to manually add the project to your solution."
        return
    } elseif ($DebugMode) {
        Write-Debug "Would check if solution exists: $solutionPath"
    }
    
    if ($DebugMode) {
        Write-Debug "Would run: dotnet sln $solutionPath add [relative-path-to-project]"
        Write-Success "[DEBUG] Would add $modName to solution"
    } else {
        try {
            # Use dotnet CLI to add project to solution
            $relativePath = Resolve-Path $projectPath -Relative
            dotnet sln $solutionPath add $relativePath
            Write-Success "Added $modName to solution"
        } catch {
            Write-Warning "Failed to add project to solution automatically: $($_.Exception.Message)"
            Write-Host "You can manually add it with: dotnet sln add $projectPath"
        }
    }
}

function Update-README($modName, $modDescription) {
    $readmePath = "src/$modName/README.md"
    
    Write-DebugPath "Update-README" "N/A" $readmePath
    
    if (-not $DebugMode -and (Test-Path $readmePath)) {
        Write-Step "Updating mod README"
        
        $content = Get-Content $readmePath -Raw -Encoding UTF8
        $content = $content -replace 'ExampleMod', $modName
        
        if ($modDescription) {
            $content = $content -replace 'An example mod.*', $modDescription
        }
        
        Set-Content -Path $readmePath -Value $content -Encoding UTF8 -NoNewline
        Write-Success "Updated mod README"
    } elseif ($DebugMode) {
        Write-Step "Updating mod README"
        Write-Debug "Would update README: $readmePath"
        Write-Debug "Would replace 'ExampleMod' with '$modName'"
        if ($modDescription) {
            Write-Debug "Would update description to: $modDescription"
        }
        Write-Success "[DEBUG] Would update mod README"
    }
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

if ($DebugMode) {
    Write-Host @"
=============================================================================
    New BepInX Mod Creator - DEBUG MODE
=============================================================================

DEBUG: Simulating creation of mod: $ModName
No files will be created or modified.

"@ -ForegroundColor Magenta
} else {
    Write-Host @"
=============================================================================
    New BepInX Mod Creator
=============================================================================

Creating new mod: $ModName

"@ -ForegroundColor Cyan
}

# Validate mod name
if (-not (Test-ValidModName $ModName)) {
    Write-Error "Invalid mod name: '$ModName'"
    Write-Host "Mod name must:"
    Write-Host "- Start with a letter"
    Write-Host "- Contain only letters and numbers"
    Write-Host "- Not be a C# reserved keyword"
    Write-Host "`nExamples of valid names: AwesomeMod, QualityOfLife, ModUtils"
    exit 1
}

# Check if mod already exists
$modPath = "src/$ModName"
if (-not $DebugMode -and (Test-Path $modPath)) {
    Write-Error "Mod '$ModName' already exists in src/$ModName"
    exit 1
} elseif ($DebugMode) {
    Write-Debug "Would check if mod exists: $modPath (exists: $(Test-Path $modPath))"
}

# Check if ExampleMod exists to use as template
$templatePath = "src/ExampleMod"
if (-not (Test-Path $templatePath)) {
    Write-Error "ExampleMod template not found in src/ExampleMod"
    Write-Host "This script requires the ExampleMod template project to exist."
    exit 1
}

# Get workspace information
$workspaceInfo = Get-WorkspaceInfo

Write-Host "Workspace info:" -ForegroundColor Green
Write-Host "  Author: $($workspaceInfo.Author)"
Write-Host "  Game: $($workspaceInfo.GameName)"
Write-Host "  New mod: $ModName"
if ($ModDescription) {
    Write-Host "  Description: $ModDescription"
}
Write-Host "  Version: $ModVersion"

# Create the mod
Copy-ModTemplate $templatePath $modPath $ModName $workspaceInfo

# Update project file
$projectFile = "src/$ModName/$ModName.csproj"
Update-ProjectFile $projectFile $ModName $ModDescription $ModVersion $workspaceInfo

# Update README if it exists
Update-README $ModName $ModDescription

# Add to solution
$solutionFiles = Get-ChildItem -Filter "*.sln"
if ($solutionFiles.Count -eq 1) {
    Add-ToSolution $solutionFiles[0].FullName $projectFile $ModName
} elseif ($solutionFiles.Count -gt 1) {
    Write-Warning "Multiple solution files found. Please manually add the project to your solution."
} else {
    Write-Warning "No solution file found. Please manually add the project to your solution."
}

if ($DebugMode) {
    Write-Success "`n[DEBUG] Simulation complete for mod '$ModName'!"
    Write-Host "`nDEBUG SUMMARY:" -ForegroundColor Magenta
    Write-Host "- Would create directory: src/$ModName"
    Write-Host "- Would copy and process template files"
    Write-Host "- Would update project file: src/$ModName/$ModName.csproj"
    Write-Host "- Would update README.md"
    Write-Host "- Would add to solution file"
    Write-Host "`nTo actually create the mod, run without -Debug flag" -ForegroundColor Yellow
} else {
    Write-Success "`nMod '$ModName' created successfully!"
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Open src/$ModName/Plugin.cs and start coding"
    Write-Host "2. Build and test: dotnet build src/$ModName/$ModName.csproj -c Debug"
    Write-Host "3. Check the auto-copied files in your game's BepInX/plugins folder"
    
    Write-Host "`nHappy modding!" -ForegroundColor Green
}
