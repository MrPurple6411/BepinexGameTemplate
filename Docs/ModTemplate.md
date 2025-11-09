# Game Mod Template

Use this template to create new mods using the automated build system.

## Quick Start

1. **Copy this template**:
   ```bash
   cp -r src/ExampleMod src/YourModName
   ```

2. **Update the project file** (`YourModName.csproj`):
   ```xml
   <PropertyGroup>
     <AssemblyTitle>Your Mod Name</AssemblyTitle>
     <AssemblyDescription>Description of what your mod does</AssemblyDescription>
     <AssemblyVersion>1.0.0.0</AssemblyVersion>

     <!-- BepInEx Plugin Metadata -->
     <PluginGuid>your.unique.modid</PluginGuid>
     <PluginName>Your Mod Name</PluginName>
     <PluginVersion>1.0.0</PluginVersion>
   </PropertyGroup>
   ```

3. **Update the Plugin.cs file**:
   - Change the namespace from `ExampleMod` to `YourModName`
   - Update the BepInPlugin attribute with your GUID/name/version
   - Implement your mod functionality
   - Add Harmony patches as needed

4. **Add to solution**:
   ```bash
   dotnet sln add src/YourModName/YourModName.csproj
   ```

## Building Your Mod

### Local Development
```bash
# Debug build (auto-copies to game plugins folder)
dotnet build src/YourModName/YourModName.csproj -c Debug

# Release build (creates ZIP package)
dotnet build src/YourModName/YourModName.csproj -c Release
```

### Automated Releases

#### Individual Mod Release
```bash
git add .
git commit -m "Update YourModName features"
git tag YourModName-v1.1.0
git push --tags
```

#### Multi-Mod Release
```bash
git add .
git commit -m "Update multiple mods"
git tag v2.0.0
git push --tags
```

## Project Structure

```
src/YourModName/
├── YourModName.csproj    # Project configuration with plugin metadata
├── Plugin.cs             # Main plugin class
├── README.md             # Mod documentation
└── [Additional classes]  # Your mod implementation
```

## Key Features

- **Automatic versioning** from git tags (hybrid support: individual `ModName-v1.0.0` or global `v1.0.0`)
- **Debug auto-copy** to game plugins folder via BepInEx.targets
- **BepInEx integration** with automatic plugin metadata generation
- **Harmony patching** ready with HarmonyLib reference
- **Professional build system** with ZIP packaging for releases
- **GitHub Actions** for automated CI/CD builds
- **Assembly processing** with BepInEx.AssemblyPublicizer for internal API access

## Plugin Metadata

The build system automatically generates MyPluginInfo from your project properties:

```csharp
// Uses the PluginGuid, PluginName, PluginVersion from your .csproj
[BepInPlugin(MyPluginInfo.PLUGIN_GUID, MyPluginInfo.PLUGIN_NAME, MyPluginInfo.PLUGIN_VERSION)]
public class Plugin : BaseUnityPlugin
{
    // Plugin implementation
}
```

## Common Patterns

### Basic Harmony Patch
```csharp
[HarmonyPatch(typeof(SomeGameClass), nameof(SomeGameClass.SomeMethod))]
public class SomeMethodPatch
{
    static void Postfix()
    {
        // Your patch logic here
        Plugin.Log.LogInfo("Method was called!");
    }
}
```

### Configuration
```csharp
private void Awake()
{
    // Create config entries
    var enableFeature = Config.Bind("General", "EnableFeature", true, "Enable the main feature");
    
    // Use the config
    if (enableFeature.Value)
    {
        // Enable feature
    }
}
```

## Tips

- Use meaningful commit messages for better changelogs
- Test in Debug mode before releasing
- Keep your GUID format consistent: `author.gamename.modname`
- Version numbers follow semantic versioning: `Major.Minor.Patch`