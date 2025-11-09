# GitHub Copilot Instructions for BepInX Modding Repository

## Code Quality Guidelines

### Character Encoding
- **NEVER use unicode characters in code files** (.yml, .cs, .ps1, .json, .xml, .targets, .props, etc.)
- Unicode symbols (✅❌🚀💯🎉⚡) break parsers, cause YAML syntax errors, and create encoding issues
- Use plain ASCII text only: `SUCCESS:`, `ERROR:`, `WARNING:`, `INFO:`
- Unicode is acceptable in markdown files, documentation, and chat communication

### File Type Specific Rules

#### YAML Files (.yml, .yaml)
- Use only ASCII characters to prevent parser failures
- Avoid multi-line strings with special characters
- Keep commit messages simple and single-line when embedded in YAML

#### PowerShell Scripts (.ps1)
- Plain ASCII output messages only
- Use `Write-Output`, `Write-Warning`, `Write-Error` with simple text
- No unicode in variable names or string literals

#### C# Code (.cs)
- Standard ASCII characters only
- Use clear English text for log messages and comments

#### MSBuild Files (.targets, .props, .csproj)
- ASCII only to ensure cross-platform compatibility
- Clear, simple property and target names

## Project Structure

### BepInX Modding
- This is a BepInX modding workspace for Unity game modding
- Target framework: .NET Framework 4.8 (required by Unity/BepInX)
- Use .NET 8 SDK for building (modern tooling, backward compatible)
- Follow BepInX plugin patterns with `BaseUnityPlugin` and `MyPluginInfo`

### Versioning
- Use semantic versioning (X.Y.Z)
- GitHub Actions automatically updates plugin versions from git tags
- Version validation prevents downgrades and duplicate releases

### Build System
- Uses Directory.Build.props/targets for shared configuration
- NuGet packages for game assemblies (follows `Author.GameName.GameAssemblies` pattern)
- Packaging creates proper BepInX folder structure: `BepInX/plugins/ModName/`

## Development Workflow

### For Contributors
- Clone, build, and code - no assembly processing needed
- Game assemblies provided via NuGet package

### For Maintainers
- Process game assemblies when game updates using `scripts/Process-Assemblies.ps1`
- Publish updated NuGet packages for contributors

### GitHub Actions
- Automatic building and releasing on git tags
- Version validation and duplicate prevention
- Clean BepInX-compatible packaging

## Error Prevention
- Always test YAML syntax in workflows
- Use plain ASCII to avoid encoding issues
- Validate MSBuild files for proper XML structure
- Keep PowerShell scripts simple and readable

Remember: **Code = ASCII only, Chat = Unicode party allowed!**