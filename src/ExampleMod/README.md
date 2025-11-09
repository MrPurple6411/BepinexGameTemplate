# Example Mod

A template BepInX mod for {{GAME_DISPLAY_NAME}} demonstrating the automated build system.

## Features

- Logs when the game starts
- Shows proper BepInEx plugin structure
- Demonstrates Harmony patching
- Uses automated versioning from git tags

## Building

```bash
# Debug build (auto-copies to game)
dotnet build -c Debug

# Release build (creates ZIP package)
dotnet build -c Release
```

## Versioning

This mod uses automated versioning from git tags:

```bash
# Individual mod release
git tag ExampleMod-v1.1.0

# Multi-mod release (if other mods changed too)
git tag v2.0.0
```

## Structure

- `Plugin.cs` - Main plugin class with BepInEx integration
- `ExampleMod.csproj` - Project configuration with plugin metadata
- Built-in Harmony patching example