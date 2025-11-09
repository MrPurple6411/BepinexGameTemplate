# BepInEx Game Modding Template

A comprehensive, production-ready template for creating professional BepInEx modding workspaces for Unity games. Features automated setup, intelligent game detection, cross-platform support, and modern development workflows.

## 🚀 Quick Start

1. **Clone this template**:
   ```bash
   git clone https://github.com/MrPurple6411/BepinexGameTemplate.git MyGameMods
   cd MyGameMods
   ```

2. **Run the setup script**:
   ```powershell
   .\setup.ps1
   ```

3. **Follow the prompts** to configure for your specific game

4. **Start modding!**
```powershell
.\setup.ps1
```

## ✨ What You Get

### **Professional Development Environment**
- **Modern MSBuild architecture** with .NET 8 SDK targeting .NET Framework 4.8
- **Automated build system** with debug/release configurations
- **Assembly publicization** with BepInEx.AssemblyPublicizer.Cli
- **Smart game detection** and compatibility validation
- **Cross-platform support** (Windows, Linux, macOS)

### **GitHub Actions CI/CD**
- **Automated building** on every commit
- **Hybrid versioning system** - global releases (v1.2.3) and individual mod releases (ModName-v1.2.3)
- **Intelligent change detection** - only builds modified mods
- **Automatic packaging** - creates proper BepInEx folder structure for distribution
- **NuGet package publishing** for game assemblies

### **Developer Experience**
- **One-command setup** - fully automated template configuration
- **BepInEx auto-installation** with architecture detection
- **Log-based debugging workflow** optimized for Unity game modding
- **Hot-reload development** - automatic copying to game plugins folder
- **Git integration** with SSH/HTTPS support

## 🎯 Supported Games

This template works with any Unity game that supports BepInEx modding. Examples include:

- **Strategy Games**: City of Gangsters, Manor Lords
- **Simulation Games**: Cities: Skylines, Planet Coaster  
- **Survival Games**: Valheim, The Forest
- **Indie Games**: Cuphead, Ori and the Blind Forest
- **Many more Unity-based games**

### Requirements
- Game must use **Mono runtime** (not IL2CPP) - the setup script validates this
- BepInEx 5.4+ compatible
- Windows, Linux, or macOS

## 📋 Setup Process

The interactive setup script (`setup.ps1`) will:

### 1. **Game Detection & Validation**
- 📁 **Folder browser** to select your game's Data folder
- 🔍 **Auto-detects** game name, architecture (x86/x64), and platform
- ✅ **Validates compatibility** - ensures Mono runtime (rejects IL2CPP)
- 🎯 **Assembly detection** - finds main game assembly with fallback options

### 2. **BepInEx Installation** (Optional)
- 🌐 **Downloads** correct BepInEx version for your platform/architecture
- 📦 **Auto-extracts** to game directory
- ⚠️ **Smart fallbacks** if architecture detection fails
- 🔗 **Manual options** if download fails

### 3. **Template Configuration**
- 👤 **Author information** - your name and GitHub username
- 🎮 **Game details** - names, technical info, repository settings
- 🛠️ **Smart defaults** based on detected game information
- ✅ **Confirmation** before processing

### 4. **File Processing**
- 🔄 **Variable substitution** across all template files
- 📁 **File renaming** (solution files, etc.)
- 🧹 **Cleanup** - removes template artifacts

### 5. **Git Setup** (Optional)
- 🔧 **Repository initialization**
- 🌐 **Remote configuration** (HTTPS or SSH)
- 📝 **Initial commit**
- 📋 **Next steps guidance**

## 🏗️ Template Variables

The setup script configures these variables:

| Variable | Example | Description |
|----------|---------|-------------|
| `{{AUTHOR}}` | `MrPurple6411` | Your name/username |
| `{{GITHUB_USERNAME}}` | `MrPurple6411` | GitHub account name |
| `{{REPO_NAME}}` | `ValheimMods` | Repository name |
| `{{GAME_NAME}}` | `Valheim` | Compact game name (no spaces) |
| `{{GAME_DISPLAY_NAME}}` | `Valheim` | Full display name |
| `{{GAME_DATA_FOLDER}}` | `valheim_Data` | Game's data folder name |
| `{{BEPINX_VERSION}}` | `5.4.21` | Minimum BepInEx version |
| `{{EXAMPLE_MOD_NAME}}` | `ExampleMod` | Starter mod project name |
| `{{GAME_PUBLISHER}}` | `Iron Gate Studio` | Game developer/publisher |

## 💼 Generated Workspace Structure

After setup, you'll have a complete modding workspace:

```
MyGameMods/
├── .github/workflows/          # GitHub Actions CI/CD
├── src/                       # Your mod projects
│   └── ExampleMod/           # Starter mod template
├── lib/net48/                # Game assemblies (after processing)
├── scripts/                  # Assembly processing scripts
├── Directory.Build.props     # Global MSBuild properties
├── Directory.Build.targets   # Global MSBuild targets
├── MyGameMods.sln           # Solution file
└── README.md                # Project-specific documentation
```

## 🛠️ Development Workflow

### **Building Mods**
```bash
# Debug build (auto-copies to game plugins folder)
dotnet build src/MyMod/MyMod.csproj -c Debug

# Release build (creates distribution package)  
dotnet build src/MyMod/MyMod.csproj -c Release
```

### **Creating New Mods**
1. Copy the `src/ExampleMod` folder
2. Rename to your mod name
3. Update the project file with mod metadata
4. Start coding!

### **Assembly Processing** (Maintainers Only)
When the game updates:
```powershell
.\scripts\Process-Assemblies.ps1 1.2.3 -AutoPublish
```

### **GitHub Releases**
- **Individual mod**: Tag as `ModName-v1.0.0`
- **Multi-mod release**: Tag as `v1.0.0`

## 🔧 Advanced Features

### **MSBuild Targets**
- **`ZipPlugins`** - Create mod distribution packages

### **Version Management**
- **Plugin versions** auto-updated from git tags
- **Duplicate release prevention** with validation
- **Semantic versioning** enforcement

### **Assembly Publicization**
- **Smart processing** of game assemblies
- **Hash-based change detection**
- **NuGet package distribution**

## 📖 Documentation

- **Generated README** - Project-specific documentation after setup
- **Mod Template Guide** - [`Docs/ModTemplate.md`](Docs/ModTemplate.md)
- **Setup Script Help** - `.\setup.ps1 -Help`

## 🤝 Contributing to This Template

1. Fork this repository
2. Make your improvements
3. Test with different games
4. Submit a pull request

## 🙏 Acknowledgments

- **BepInEx Team** - For the excellent modding framework
- **Harmony** - For runtime patching capabilities

---

**Ready to start modding?** Clone this template and run `.\setup.ps1`!