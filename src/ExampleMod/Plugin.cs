using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using Game;
using UnityEngine;

namespace ExampleMod
{
    [BepInPlugin(MyPluginInfo.PLUGIN_GUID, MyPluginInfo.PLUGIN_NAME, MyPluginInfo.PLUGIN_VERSION)]
    public class Plugin : BaseUnityPlugin
    {
        internal static new ManualLogSource Logger;
        
        private void Awake()
        {
            Logger = base.Logger;
            
            // Apply Harmony patches
            var harmony = new Harmony(MyPluginInfo.PLUGIN_GUID);
            harmony.PatchAll();
            
            Logger.LogInfo($"{MyPluginInfo.PLUGIN_NAME} {MyPluginInfo.PLUGIN_VERSION} loaded successfully!");
        }
    }
}

// Example Harmony patch
[HarmonyPatch(typeof(Game.Game), nameof(Game.Game.Start))]
public class GameStartPatch
{
    static void Postfix()
    {
        ExampleMod.Plugin.Logger.LogInfo("Game started! Example mod is working.");
    }
}