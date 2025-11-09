# 🎯 BepInEx Modding Template Conversion Plan

## 📋 What We Built (Current State)
- **Professional BepInEx workspace** for City of Gangsters modding
- **Advanced GitHub Actions** with automatic version management, duplicate/downgrade protection
- **MSBuild architecture** using Directory.Build.props/targets pattern
- **NuGet pipeline** for game assembly distribution
- **ASCII-only code guidelines** with repository instructions

## 🔄 Files to Parameterize

### Core Build Files:
- `Directory.Build.props` - Game name, assembly references, plugin metadata
- `Directory.Build.targets` - Packaging paths and structure  
- `*.sln` - Solution name
- `NuGet.config` - Package source URLs
- `GameAssemblies.nuspec.csproj` - NuGet package metadata

### Scripts & Workflows:
- `.github/workflows/build.yml` - Repository references, package names
- `.github/workflows/Update-Nuget-Package.yml` - Game-specific assembly processing
- `scripts/Process-Assemblies.ps1` - Game paths and assembly names

### Documentation:
- `README.md` - Game name, setup instructions, template usage
- `.github/copilot-instructions.md` - Game-specific context

## 🎛️ Template Variables Needed (SIMPLIFIED)
```
{{GAME_NAME}} - "CityofGangsters" 
{{GAME_DISPLAY_NAME}} - "City of Gangsters"
{{GAME_DATA_FOLDER}} - "CoG_Data"
{{AUTHOR}} - "MrPurple6411"
{{REPO_NAME}} - "CityofGansters" 
{{GITHUB_USERNAME}} - "MrPurple6411"
{{UNITY_VERSION}} - "2020.3.28"
{{BEPINX_VERSION}} - "5.4.21"
```

**REMOVED VARIABLES** (made generic or eliminated):
- `{{GAME_PUBLISHER}}` - Not actually needed in most places
- `{{AUTHOR_LOWER}}` - Can be derived programmatically  
- `{{GAME_NAME_LOWER}}` - Can be derived programmatically
- `{{EXAMPLE_MOD_NAME}}` - Hardcoded as "ExampleMod"
- `{{GITHUB_EMAIL}}` - Handled by setup script only

## 🚀 Setup Script Requirements
1. **Interactive prompts** for all template variables
2. **File content replacement** across all parameterized files
3. **Folder/file renaming** (solution files, example mod)
4. **Assembly processing setup** with game-specific paths
5. **Git initialization** with proper .gitignore and SSH remote setup
6. **GitHub account configuration** (SSH vs HTTPS, user.name/user.email)

## ✨ Template Features to Preserve
- ✅ Automatic version management from git tags
- ✅ Downgrade/duplicate protection  
- ✅ Professional MSBuild structure
- ✅ NuGet assembly distribution
- ✅ ASCII-only code enforcement
- ✅ BepInEx packaging automation

## 📁 Template Structure Goal
```
BepInEx-Modding-Template/
├── setup.ps1                    # Interactive setup script
├── template-config.json         # Variable definitions
├── Directory.Build.props.template
├── src/{{EXAMPLE_MOD_NAME}}/
└── .github/
    ├── workflows/*.yml.template
    └── copilot-instructions.md.template
```

## 🎯 Key Implementation Steps
1. **Copy all files except .github to new location**
2. **Add .template extensions** to parameterized files
3. **Create setup.ps1 script** with interactive prompts
4. **Replace hardcoded values** with template variables
5. **Test template generation** with different game parameters
6. **Create GitHub template repository** for easy reuse

**Ready when you are in the new workspace!** 🚀