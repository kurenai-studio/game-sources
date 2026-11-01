using Box2D.NET;
using DerelictDimension.ECS.Drawing;
using Friflo.EcGui;
using Hexa.NET.ImGui;
using Monod.AssetsModule;
using Monod.Graphics.Settings;
using Monod.ModsModule;

namespace DerelictDimension;

public static class Settings
{
    public static bool ShowReloadWindow;
    public static bool ShowSettingsWindow;
    public static bool ShowDemoWindow;
    public static bool ShowInspector;
    public static bool ShowB2Debug;

    public static void Draw()
    {
        ImGuiIOPtr io = ImGui.GetIO();
        if (ShowSettingsWindow) DrawSettingsWindow();
        if (ShowReloadWindow) DrawReloadWindow(io);
        if (ShowDemoWindow) ImGui.ShowDemoWindow();
        if (ShowInspector)
        {
            EcGui.ExplorerWindow();
            EcGui.InspectorWindow();
        }
        if (ShowB2Debug) DrawB2DebugWindow();
    }


    private static void DrawSettingsWindow()
    {
        ImGui.Begin("Settings"u8);
        ImGui.BeginTabBar("Tab"u8);
        if (ImGui.BeginTabItem("Graphics"u8))
        {
            GraphicsMenu();
            ImGui.EndTabItem();
        }
        ImGui.EndTabBar();

        ImGui.End();
    }

    private static void GraphicsMenu()
    {
        WindowModeSelect();
        ImGui.SeparatorText("Display"u8);
        DisplaySelect();
        ImGui.Separator();
        WindowSettings();
    }

    private static void WindowModeSelect()
    {
        ImGui.SeparatorText("Window mode"u8);
        if (ImGui.RadioButton("Fullscreen"u8, GraphicsSettings.windowMode == WindowMode.Fullscreen))
        {
            GraphicsSettings.windowMode = WindowMode.Fullscreen;
            GraphicsSettings.ApplyWindowMode();
        }
        if (ImGui.RadioButton("Windowed"u8, GraphicsSettings.windowMode == WindowMode.Windowed))
        {
            GraphicsSettings.windowMode = WindowMode.Windowed;
            GraphicsSettings.ApplyWindowMode();
        }
        if (ImGui.RadioButton("Borderless"u8, GraphicsSettings.windowMode == WindowMode.Borderless))
        {
            GraphicsSettings.windowMode = WindowMode.Borderless;
            GraphicsSettings.ApplyWindowMode();
        }
        if (ImGui.RadioButton("Maximized"u8, GraphicsSettings.windowMode == WindowMode.Maximized))
        {
            GraphicsSettings.windowMode = WindowMode.Maximized;
            GraphicsSettings.ApplyWindowMode();
        }
    }

    private static void DisplaySelect()
    {
        DisplayInfo[] displays = GraphicsSettings.Displays;
        float listboxHeight = ImGui.GetFrameHeightWithSpacing() * displays.Length;
        if (ImGui.BeginListBox("", new System.Numerics.Vector2(0, listboxHeight)))
        {
            for (int i = 0; i < displays.Length; i++)
            {
                DisplayInfo display = displays[i];
                if (ImGui.Selectable(display.FancyName, i == GraphicsSettings.SelectedDisplay))
                {
                    GraphicsSettings.SelectedDisplay = i;
                    GraphicsSettings.ApplyWindowMode();
                }
            }

            ImGui.EndListBox();
        }
    }

    private static void WindowSettings()
    {
        if (ImGui.Checkbox("VSync"u8, ref GraphicsSettings.VSync))
            GraphicsSettings.ApplyVSync();

        bool windowed = GraphicsSettings.windowMode == WindowMode.Windowed;
        if (!windowed)
        {
            ImGui.BeginDisabled();
            ImGui.Text("Available only in windowed mode"u8);
            ImGui.Spacing();
        }
        ImGui.SeparatorText("Common window sizes"u8);
        ImGui.Text("16x9: "u8);
        WindowSizeSelector(GraphicsSettings.CommonResolutions16x9);
        ImGui.SeparatorText("Window settings"u8);
        if (ImGui.InputInt2("Window Size"u8, ref GraphicsSettings.WindowSize.X))
            GraphicsSettings.ApplyWindowSize();
        if (ImGui.InputInt2("Window Position"u8, ref GraphicsSettings.WindowPosition.X))
            GraphicsSettings.ApplyWindowPosition();
        if (ImGui.Checkbox("Center window"u8, ref GraphicsSettings.CenterWindow))
            GraphicsSettings.ApplyWindowPosition();

        if (ImGui.Checkbox("Lock mouse inside window"u8, ref GraphicsSettings.MouseLock))
            GraphicsSettings.ApplyMouseLock();

        if (!windowed) ImGui.EndDisabled();
    }

    private static void WindowSizeSelector(Point[] sizes)
    {
        for (int i = 0; i < sizes.Length; i++)
        {
            ImGui.SameLine();
            Point size = sizes[i];
            if (ImGui.Button($"{size.X}x{size.Y}"))
            {
                GraphicsSettings.WindowSize = size;
                GraphicsSettings.ApplyWindowSize();
            }
        }
    }

    private static void DrawReloadWindow(ImGuiIOPtr io)
    {
        ImGui.Begin("Reload"u8);
        if (ImGui.Button("Reload world"u8))
            TheGame.Instance.Reload();
        if (ImGui.Button("Reload asset users"u8))
            Assets.ReloadThisFrame = true;
        if (ImGui.Button("Reload assets"u8))
            foreach (var assetManager in Assets.Managers.Values)
                assetManager.LoadAssets();
        if (ImGui.Button("Reload all mods"u8))
            ModManager.EnqueueLoadAllMods();
        if (ImGui.Button("Reload enabled mods"u8))
            ModManager.EnqueueLoadEnabledMods();


        ImGui.End();
    }

    private static void DrawB2DebugWindow()
    {
        ref B2DebugDraw draw = ref DrawHitboxesSystem.draw;

        ImGui.Begin("B2 Debug"u8);

        ImGui.Checkbox("Enable box2d's debug draw"u8, ref DrawHitboxesSystem.Enabled);
        ImGui.Separator();

        ImGui.Checkbox("drawContacts"u8, ref draw.drawContacts);
        ImGui.SameLine();
        ImGui.TextDisabled("Option to draw contact points"u8);

        ImGui.Checkbox("drawAnchorA"u8, ref draw.drawAnchorA);
        ImGui.SameLine();
        ImGui.TextDisabled("Draw anchor A for contact points (instead of anchorB)"u8);

        ImGui.Checkbox("drawShapes"u8, ref draw.drawShapes);

        ImGui.Checkbox("drawChainNormals"u8, ref draw.drawChainNormals);
        ImGui.SameLine();
        ImGui.TextDisabled("Option to draw chain shape normals"u8);

        ImGui.Checkbox("drawJoints"u8, ref draw.drawJoints);

        ImGui.Checkbox("drawJointExtras"u8, ref draw.drawJointExtras);
        ImGui.SameLine();
        ImGui.TextDisabled("Option to draw additional information for joints"u8);

        ImGui.Checkbox("drawBounds"u8, ref draw.drawBounds);
        ImGui.SameLine();
        ImGui.TextDisabled("Option to draw the bounding boxes for shapes"u8);

        ImGui.Checkbox("drawMass"u8, ref draw.drawMass);
        ImGui.SameLine();
        ImGui.TextDisabled("Option to draw the mass and center of mass of dynamic bodies"u8);

        ImGui.Checkbox("drawBodyNames"u8, ref draw.drawBodyNames);

        ImGui.Checkbox("drawGraphColors"u8, ref draw.drawGraphColors);
        ImGui.SameLine();
        ImGui.TextDisabled("Option to visualize the graph coloring used for contacts and joints"u8);

        ImGui.Checkbox("drawContactFeatures"u8, ref draw.drawContactFeatures);
        ImGui.SameLine();
        ImGui.TextDisabled("Option to draw contact feature ids"u8);

        ImGui.Checkbox("drawContactNormals"u8, ref draw.drawContactNormals);

        ImGui.Checkbox("drawContactForces"u8, ref draw.drawContactForces);
        ImGui.SameLine();
        ImGui.TextDisabled("Option to draw contact normal forces"u8);

        ImGui.Checkbox("drawFrictionForces"u8, ref draw.drawFrictionForces);
        ImGui.SameLine();
        ImGui.TextDisabled("Option to draw contact friction forces"u8);

        ImGui.Checkbox("drawIslands"u8, ref draw.drawIslands);
        ImGui.SameLine();
        ImGui.TextDisabled("Option to draw islands as bounding boxes"u8);

        ImGui.InputFloat("forceScale"u8, ref draw.forceScale);
        ImGui.SameLine();
        ImGui.TextDisabled("Scale to use when drawing forces"u8);

        ImGui.InputFloat("jointScale"u8, ref draw.jointScale);
        ImGui.SameLine();
        ImGui.TextDisabled("Global scaling for joint drawing"u8);

        ImGui.End();
    }
}
