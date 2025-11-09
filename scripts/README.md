# Assembly Processing Scripts

This directory contains scripts for processing game assemblies locally with intelligent duplicate prevention.

## Process-Assemblies.ps1

PowerShell script that handles the local processing of game assemblies. This script:

1. **Checks for duplicates** - Verifies tag doesn't exist on remote, compares hashes
2. **Locates the game directory** automatically or via parameter
3. **Publicizes assemblies** - Makes internal types/members public using BepInEx.AssemblyPublicizer
4. **Strips assemblies** - Removes unnecessary code while maintaining runtime safety
5. **Tracks changes** - Saves hashes to prevent reprocessing identical assemblies
6. **Auto-publishes** - Optional automated git commit/tag/push workflow

### Usage

```powershell
# Basic usage with positional parameter
.\scripts\Process-Assemblies.ps1 1.4.4

# Full auto-publish workflow  
.\scripts\Process-Assemblies.ps1 1.4.4 -AutoPublish

# Force reprocess even if no changes
.\scripts\Process-Assemblies.ps1 1.4.4 -Force

# Custom game directory
.\scripts\Process-Assemblies.ps1 1.0.0 -GameDir "C:\Games\YourGameName"

# Help
.\scripts\Process-Assemblies.ps1 -Help
```

### Smart Duplicate Prevention

The script prevents unnecessary processing by checking:
- **Remote tags** - Skips if `assemblies-v1.4.4` already exists on GitHub
- **Local hashes** - Compares processed DLL hashes against previous runs
- **Force override** - Use `-Force` to bypass all checks

### Requirements

The script automatically installs:
- **BepInEx.AssemblyPublicizer.Cli** - Official BepInEx tool for publicizing assemblies

### Output Structure

```
lib/net48/                         # Processed assemblies for mod development
├── Assembly-CSharp.dll             # Main game logic (publicized + stripped)  
└── Assembly-CSharp-firstpass.dll   # First-pass scripts (publicized + stripped)

assembly-hashes.json               # Hash tracking for duplicate prevention
```

### Legal Considerations

- Processes only **core game assemblies** needed for modding
- Uses **official BepInEx tooling** for processing
- Applies **stripping** to minimize redistributed content
- **Does NOT include** Unity modules (use official Unity packages)
- **Does NOT include** third-party libraries (licensing issues)
- Processed files are **development dependencies only**