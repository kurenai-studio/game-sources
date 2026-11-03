using ImGuiNET;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MineDirt.Src.Chunks;
using MineDirt.Src.Scene;
using MonoGame.ImGuiNet;
using System;
using System.Diagnostics;
using Nvec3 = System.Numerics.Vector3;

namespace MineDirt.Src;

public class Debug
{
    public ImGuiRenderer GuiRenderer;

    private bool hasFirstDrawFinished = false;
    
    private TimeSpan timeToShowDebugWindow = new(0, 0, 1);

    // Get the current process
    Process currentProcess = Process.GetCurrentProcess();

    // Retrieve memory usage information
    long workingSet = 0;
    long privateMemory = 0; 

    private float fps = 0f;
    private float ups = 0f;
    private float fpsTimer = 0f;
    private float upsTimer = 0f;
    private int frameCount = 0;
    private int updateCount = 0;

    private int chunkCount = 0;

    private Vector3 TeleportPos = new(0, 0, 0);

    private Vector3 cameraChunkPosition = Vector3.Zero;

    private float cameraSpeed = Camera.MovementUnitsPerSecond;

    private bool RenderWireframes = false;

#region Environment

    EnvironmentSystem env;

    private Nvec3 fogColor = Color.CornflowerBlue.ToVector3().ToNumerics();
    private Nvec3 skylightColor = Nvec3.One;
    private float fogDensity = 0.005f;
    private Nvec3 sundir = new Nvec3(15f,15f,0f);

    private Nvec3 dc;
    private Nvec3 dbc;
    private Nvec3 sc;
    private Nvec3 sbc;
    private Nvec3 nc;
    private Nvec3 nbc;

#if DEBUG
    private int sky_disp = 0;
#endif

#endregion

    private RasterizerState wireFrameRasterizeState = new()
    {
        FillMode = FillMode.WireFrame,
        CullMode = CullMode.None,
    };

    private RasterizerState defaultRasterizeState = new()
    {
        FillMode = FillMode.Solid,
        CullMode = CullMode.CullCounterClockwiseFace,
    };

    public void Initialize()
    {
        GuiRenderer = new ImGuiRenderer(MineDirtGame.Instance);
    }

    public void LoadContent()
    {
        GuiRenderer.RebuildFontAtlas();
        env = World.Environment;
        Matrix rot = Matrix.CreateFromYawPitchRoll(
        MathHelper.ToRadians(sundir.X), 
        MathHelper.ToRadians(sundir.Y), 
            0f
        );
        env.SunDirection = Vector3.TransformNormal(Vector3.Forward,rot);

        dc  = env.Sky.DayColor.ToVector3().ToNumerics();
        dbc = env.Sky.DayBottomColor.ToVector3().ToNumerics();
        sc  = env.Sky.SunsetColor.ToVector3().ToNumerics();
        sbc = env.Sky.SunsetBottomColor.ToVector3().ToNumerics();
        nc  = env.Sky.NightColor.ToVector3().ToNumerics();
        nbc = env.Sky.NightBottomColor.ToVector3().ToNumerics();
    }

    public void Update(GameTime gameTime)
    {
        float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;

        cameraChunkPosition = MineDirtGame.Camera.Position.ToChunkPosition();

        // Update UPS (Updates Per Second)
        upsTimer += deltaTime;
        updateCount++;
        if (upsTimer >= 1f) // Update every second
        {
            ups = updateCount;
            upsTimer -= 1f;  // Reset the timer
            updateCount = 0;

            chunkCount = World.Chunks.Count;

            currentProcess = Process.GetCurrentProcess();

            workingSet = currentProcess.WorkingSet64; // Physical memory usage in bytes
            privateMemory = currentProcess.PrivateMemorySize64; // Private memory in bytes
        }
    }

    public void EndDraw(GameTime gameTime)
    {
        if(gameTime.TotalGameTime < timeToShowDebugWindow)
            return; 

        GuiRenderer.BeginLayout(gameTime);

        // Calculate FPS (Frames Per Second)
        fpsTimer += (float)gameTime.ElapsedGameTime.TotalSeconds;
        frameCount++;
        if (fpsTimer >= 1f) // Update every second
        {
            fps = frameCount;
            fpsTimer -= 1f; // Reset the timer
            frameCount = 0;
        }

        // Create an ImGui window for camera coordinates
        if (ImGui.Begin("Debug", ImGuiWindowFlags.NoFocusOnAppearing))
        {
            // Create an ImGui window for camera coordinates
            if (!hasFirstDrawFinished)
            {
                ImGui.SetWindowSize(new System.Numerics.Vector2(400, 320));
            }

            // Display the pointed block 
            ImGui.Text($"Pointed Block: {MineDirtGame.Camera.PointedBlock.Type}");
            ImGui.Text($"Pointed Block Coords: {MineDirtGame.Camera.PointedBlockPosition}");
            ImGui.Text($"Pointed Block Face: {MineDirtGame.Camera.PointedBlockFace}");

            // Display the camera's position in the window
            ImGui.Text($"X: {MineDirtGame.Camera.Position.X}, Y: {MineDirtGame.Camera.Position.Y}, Z: {MineDirtGame.Camera.Position.Z}");

            // Display the camera's chunk position in the window
            ImGui.Text($"Abs Chunk X: {cameraChunkPosition.X}, Y: {cameraChunkPosition.Y}, Z: {cameraChunkPosition.Z}");

            // Display the camera's chunk normalized position in the window
            ImGui.Text($"Nor Chunk X: {cameraChunkPosition.X / Chunk.Width}, Y: {cameraChunkPosition.Y / Chunk.Width}, Z: {cameraChunkPosition.Z / Chunk.Width}");

            // Display FPS and UPS
            ImGui.Text($"FPS: {fps}");
            ImGui.Text($"UPS: {ups}");

            // Display chunk count
            ImGui.Text($"Chunks Count: {chunkCount}");

            // Display memory usage information in GB
            ImGui.Text($"Working Set: {(double)workingSet / 1024 / 1024 / 1024:0.###} GB");
            ImGui.Text($"Private Memory: {(double)privateMemory / 1024 / 1024 / 1024:0.###} GB");

            // Checkbox 
            ImGui.Checkbox("Render Wireframes", ref RenderWireframes);

            // Add button to reload chunks
            if (ImGui.Button("Reload Chunks"))
            {
                World.ReloadChunks();
            }

            // Slider for movement speed
            ImGui.SliderFloat("Movement Speed", ref cameraSpeed, 0.1f, 50f);

            Camera.MovementUnitsPerSecond = cameraSpeed;
        }

        ImGui.End();

        if(ImGui.Begin("Teleport"))
        {
            // Create an ImGui window for camera coordinates
            if (!hasFirstDrawFinished)
            {
                ImGui.SetWindowSize(new System.Numerics.Vector2(400, 320));
            }

            ImGui.InputFloat("X", ref TeleportPos.X);
            ImGui.InputFloat("Y", ref TeleportPos.Y);
            ImGui.InputFloat("Z", ref TeleportPos.Z);
            if (ImGui.Button("Teleport"))
            {
                MineDirtGame.Camera.Position = TeleportPos;
                MineDirtGame.Camera.UpdateView();
            }
        }

        if(ImGui.Begin("Environment"))
        {
            // Create an ImGui window for camera coordinates
            if (!hasFirstDrawFinished)
            {
                ImGui.SetWindowSize(new System.Numerics.Vector2(400, 320));
            }

            if(ImGui.SliderFloat("Fog density",ref fogDensity, 0f, 0.1f)){
                env.FogDensity = fogDensity;
            }
            ImGui.Separator();
            if(ImGui.SliderFloat3("Sun direction",ref sundir, 0f, 360f)){

                Matrix rot = Matrix.CreateFromYawPitchRoll(
                    MathHelper.ToRadians(sundir.X), 
                    MathHelper.ToRadians(sundir.Y), 
                    MathHelper.ToRadians(sundir.Z)
                );
                env.SunDirection = Vector3.TransformNormal(Vector3.Forward,rot);
            }

#if DEBUG
            if(ImGui.Combo("Sky debug display",ref sky_disp, [
                "None", "Position", "X axis", "Y axis", "Z axis", "Astro UV"
            ], 6)){
                World.Sky.DisplayMode = (Sky.DebugDisplayMode)sky_disp;
            }
#endif

            if(ImGui.CollapsingHeader("Fog color")){
                if(ImGui.ColorPicker3("Fog color: ", ref fogColor)){
                    env.FogColor = new Color(fogColor);
                }
            }

            if(ImGui.CollapsingHeader("Sky light color")){
                if(ImGui.ColorPicker3("Sky light color: ", ref skylightColor)){
                    env.SkyLightColor = new Color(skylightColor);
                }
            }

            if(ImGui.CollapsingHeader("Day colors")){
                if(ImGui.ColorPicker3("Top", ref dc)){
                    env.Sky.DayColor = new Color(dc);
                }
                if(ImGui.ColorPicker3("Bottom", ref dbc)){
                    env.Sky.DayBottomColor = new Color(dbc);
                }
            }

            if(ImGui.CollapsingHeader("Sunset colors")){
                if(ImGui.ColorPicker3("Top", ref sc)){
                    env.Sky.SunsetColor = new Color(sc);
                }
                if(ImGui.ColorPicker3("Bottom", ref sbc)){
                    env.Sky.SunsetBottomColor = new Color(sbc);
                }
            }

            if(ImGui.CollapsingHeader("Night colors")){
                if(ImGui.ColorPicker3("Top", ref nc)){
                    env.Sky.NightColor = new Color(nc);
                }
                if(ImGui.ColorPicker3("Bottom", ref nbc)){
                    env.Sky.NightBottomColor = new Color(nbc);
                }
            }

        }

        GuiRenderer.EndLayout();

        hasFirstDrawFinished = true;
    }

    public void BeginDraw(GameTime gameTime)
    {
        if (RenderWireframes)
            MineDirtGame.Graphics.GraphicsDevice.RasterizerState = wireFrameRasterizeState;
        else
            MineDirtGame.Graphics.GraphicsDevice.RasterizerState = defaultRasterizeState;
    }
}
