using DerelictDimension.ECS.Ai;
using DerelictDimension.ECS.Drawing;
using DerelictDimension.ECS.PhysicsModule;
using DerelictDimension.ECS.PhysicsModule.Components;
using DerelictDimension.ECS.Prefabs;
using DerelictDimension.ECS.Rewinding;
using FontStashSharp;
using Friflo.EcGui;
using MLEM.Extended.Font;
using MLEM.Font;
using Monod;
using Monod.AssetsModule;
using Monod.ECS.DefaultComponents;
using Monod.Graphics;
using Monod.Graphics.ECS.Sprite;
using Monod.Graphics.Fonts;
using Monod.InputModule;
using Monod.ModsModule;
using Monod.Utils.Extensions;
using SoLoud;
using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;

namespace DerelictDimension;

/// <summary>
/// Entry point of the game, that manages update and render.
/// </summary>
public class TheGame : MonodGame
{
    /// <summary>
    /// Static singleton instance of the <see cref="TheGame"/>.
    /// </summary>
    public static TheGame Instance;

    public string text = "None";

    public string errors = "";

    public Point offset = Point.Zero;

    public Key pressed;
    public Key released;
    public RebindMenu Rebind;

    public HashSet<string> ModsToToggle = [];
    public int Page = 0;

    public static Vector2 GameSize;
    public static Entity entity;
    public static float WantedFPS = 60;

    public Wav? LightPiano;
    public Wav? DarkPiano;
    public uint LightPianoH;
    public uint DarkPianoH;



    /// <summary>
    /// Creates a new <see cref="TheGame"/>.
    /// </summary>
    [SetsRequiredMembers]
    public TheGame()
    {
        IsMouseVisible = true;
        Instance = this;
        GameSize = new(1280, 720);
        IsFixedTimeStep = true;
        MaxElapsedTime = TimeSpan.FromMilliseconds(1000f / WantedFPS * 60);
        TargetElapsedTime = TimeSpan.FromMilliseconds(1000f / WantedFPS);
        PrefabsStore = new(PidType.RandomPids);
    }


    protected override void Initialize()
    {
        base.Initialize();
        InputActions.Initialize();
        EcGui.AddExplorerStore("Main", Store);
        EcGui.AddExplorerStore("Prefabs", PrefabsStore);
    }

    public override void CreateStore() => Store = new(PidType.RandomPids);

    ///<inheritdoc/>
    protected override void LoadContent()
    {
        MainAssetManager.LoadAsset("Fonts/m6x11plus.ttf");

        LoadFont();
        base.LoadContent();

        Renderer.deviceManager.PreferMultiSampling = true;
        Assets.OnLoad += LoadFont;
        Assets.OnLoad += OnAssetsLoaded;
        InitWorld();
    }

    public void InitWorld()
    {
        ClearStore();

        var player = CodePrefabs.CreateHuman(new(3, 1), 0, "Sprites/Player/", out var body, out _, out var leftLeg, out _);
        player.Name.value = "Player";
        player.AddComponent(new PlayerAi());
        body.AddTag<LookAtMouseTag>();
        body.GetComponent<PhysicsShapeComponent>().CollisionCategories = CollisionLayer.Player;
        var kickLeg = Store.CreateEntity(new EntityName("Kick leg"), new PhysicsShapeComponent(isSensor: true, categories: CollisionLayer.PlayerAttacks, mask: CollisionLayer.Walls | CollisionLayer.Enemy | CollisionLayer.EnemyAttacks), new HitboxComponent(new OrientedRect(-.14f, -.28f, .14f, .38f)) { Collidable = false }, new KickLegComponent(leftLeg.Pid), new AnimatedSpriteComponent("Sprites/Player/leg_kick", [0, 1, 2, 1], timeBetweenFrames: 0.1f), new Transform2D(), new RenderDepth(0.25f), new DamagerComponent());
        body.AddChild(kickLeg);

        CodePrefabs.CreateHuman(new(3, 2), 0, "Sprites/Swordsman/", out _, out _, out _, out _);
        CodePrefabs.CreateHuman(new(2, 3), 0, "Sprites/Swordsman/", out _, out _, out _, out _);
        CodePrefabs.CreateHuman(new(4, 3), 0, "Sprites/Swordsman/", out _, out _, out _, out _);


        Store.CreateEntity(new Transform2D(5, 5), new Sprite2D("Sprites/Wall"), new RenderDepth(0.05f), new NineSliceComponent(new(255, 100)), new PhysicsBodyComponent(), new HitboxComponent(new OrientedRect(0, 0, 2.55f, 1)), new PhysicsShapeComponent(categories: CollisionLayer.Walls));
        Store.CreateEntity(new Transform2D(8, 3, rotation: (float)Math.PI / 6), new Sprite2D("Sprites/Wall", spriteEffects: SpriteEffects.FlipHorizontally), new RenderDepth(0.05f), new NineSliceComponent(new(30, 200)), new PhysicsBodyComponent(), new HitboxComponent(new OrientedRect(0, 0, 0.3f, 2)), new PhysicsShapeComponent(categories: CollisionLayer.Walls));
        //var json = entitySerializer.WriteEntity(entity);
        //Log.Information($"\n{json}");

        InitializeSystems();
    }

    private static void ClearStore()
    {
        var commandBuffer = Store.GetCommandBuffer();
        foreach (var entity in Store.Entities)
            commandBuffer.DeleteEntity(entity.Id);
        commandBuffer.Playback();
    }

    public void InitializeSystems()
    {
        LogicSystemRoot.RemoveAllSystems();
        DrawSystemRoot.RemoveAllSystems();


        LogicSystemRoot.Add(new PlayerAiSystem());
        LogicSystemRoot.Add(new KickLegSystem());
        LogicSystemRoot.Add(new PhysicsSystem());
        LogicSystemRoot.Add(new DamageSystem());
        LogicSystemRoot.Add(new ParentVelocityDirSystem());
        LogicSystemRoot.Add(new LegsSystem());
        LogicSystemRoot.Add(new BodySystem());
        LogicSystemRoot.Add(new LookAtMouseSystem());

        LogicSystemRoot.Add(new DamageCleaupSystem());

        LogicSystemRoot.Add(new AnimatedSpriteSystem());
        LogicSystemRoot.Add(new UpdateSpriteSystem());

        DrawSystem drawSystem = new();
        drawSystem.Add(new DrawSpriteSystem());
        drawSystem.Add(new DrawHitboxesSystem());

        DrawSystemRoot.Add(drawSystem);
    }

    public void Reload()
    {
        InitWorld();
        Rewind.RecordedComponents.Clear();
        Rewind.CurrentFrame = 0;
    }

    public void OnAssetsLoaded()
    {
        LightPiano = Assets.Get<Wav>("Audio/LightPiano");
        LightPiano.setLooping(1);
        //LightPianoH = soloud.play(LightPiano);

        DarkPiano = Assets.Get<Wav>("Audio/DarkPiano");
        DarkPiano.setLooping(1);
        //DarkPianoH = soloud.play(DarkPiano);
    }

    ///<inheritdoc/>
    protected static void LoadFont()
    {
        FontSystem defaultFontSystem = new();
        byte[] font = Assets.Get<byte[]>("Fonts/m6x11plus");
        defaultFontSystem.AddFont(font);
        GlobalFonts.MenuFont = new GenericStashFont(defaultFontSystem.GetFont(18));
        GlobalFonts.ShapeMenuFont = new(font);
    }

    ///<inheritdoc/>
    protected override void UpdateM()
    {
        if (Input.KeyPressed(Key.R)) Reload();

        /* Mod manager:
         * 
         * int i = 0;

        if (Input.KeyPressed(Key.D)) Page++;
        else if (Input.KeyPressed(Key.A)) Page--;

        foreach (var mod in ModManager.Mods.Values.Skip(Page * 10).Take(10))
        {
            if (Input.KeyPressed(Key.D0 + i))
                ModsToToggle.ToggleValue(mod.GetName());
            i++;
        }

        if (Input.KeyPressed(Key.Enter) && ModsToToggle.Count != 0)
        {
            ModManager.EnqueueToggleMods(ModsToToggle);
            ModsToToggle.Clear();
        }*/

        if (Input.KeyPressed(Key.F1)) Settings.ShowDemoWindow = !Settings.ShowDemoWindow;
        if (Input.KeyPressed(Key.F2)) Settings.ShowSettingsWindow = !Settings.ShowSettingsWindow;
        if (Input.KeyPressed(Key.F3)) Settings.ShowInspector = !Settings.ShowInspector;
        if (Input.KeyPressed(Key.F4)) Settings.ShowB2Debug = !Settings.ShowB2Debug;
        if (Input.KeyPressed(Key.F5)) Settings.ShowReloadWindow = !Settings.ShowReloadWindow;

        if (Input.KeyPressed(Key.M))
        {
            float lightPianoVol = soloud.getVolume(LightPianoH);
            soloud.fadeVolume(LightPianoH, 1 - lightPianoVol, 0.5);
        }

        Rebind?.Update();

        if (Input.KeyboardKeysPressed.Count > 0) pressed = Input.KeyboardKeysPressed.ElementAt(0);
        if (Input.KeyboardKeysReleased.Count > 0) released = Input.KeyboardKeysReleased.ElementAt(0);

        UpdateLogicSystems();
    }

    /// <inheritdoc/>
    protected override void DrawM()
    {
        Renderer.Clear(new(0, 0, 0));
        UpdateDrawSystems();
        //GenericFont? font = GlobalFonts.MenuFont;
        //DrawModMenu(font, ref transform);
    }

    public override void DrawImGui()
    {
        base.DrawImGui();
        Settings.Draw();
    }

    private void DrawModMenu(GenericFont font, ref Vector2 pos)
    {
        font.DrawString(Renderer.spriteBatch, $"Found all mods: {ModManager.ModsFound}", pos, Color.White);
        pos.Y += 16;

        foreach (var brokenMod in ModManager.BrokenMods)
        {
            font.DrawString(Renderer.spriteBatch, brokenMod.ManifestPath, pos, Color.Red);
            pos.Y += 16;
            font.DrawString(Renderer.spriteBatch, brokenMod.FailureReason.Message, pos, Color.Orange);
            pos.Y += 32;
        }

        pos.Y += 16;

        //font.DrawString(Renderer.spriteBatch, $"Page: {Page}", transform, Color.White);
        //transform.Y += 16;

        int i = 0;

        foreach (var mod in ModManager.Mods.Values.Skip(Page * 10).Take(10))
        {
            Color color;
            switch (mod.Status)
            {
            case ModStatus.Enabled:
                if (ModsToToggle.Contains(mod.GetName()))
                {
                    color = Color.DarkSlateBlue;
                    break;
                }
                color = Color.White;
                break;

            case ModStatus.Disabled:
                if (ModsToToggle.Contains(mod.GetName()))
                {
                    color = Color.Green;
                    break;
                }
                color = Color.Gray;
                break;

            default:
                color = Color.Orange;
                break;
            }
            font.DrawString(Renderer.spriteBatch, $"{i}. {mod.GetName()}", pos, color);
            pos.Y += 16;
            i++;
        }
    }
}
