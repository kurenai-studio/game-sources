using Microsoft.Extensions.DependencyInjection;
using Microsoft.Xna.Framework;
using System;
using TowerProtect.App.Backend;
using TowerProtect.App.Client;
using TowerProtect.App.Networking.Backend;
using TowerProtect.App.Networking.Client;
using TowerProtect.App.Networking.Connectors;
using TowerProtect.App.Root.App;
using TowerProtect.App.Root.Display;
using TowerProtect.Domain.Backend.Entities;
using TowerProtect.Domain.Backend.Worldgen;
using TowerProtect.Domain.Backend.Tiles;
using TowerProtect.Domain.Display.Tiles;
using TowerProtect.Framework.App;
using TowerProtect.Framework.Other;
using TowerProtect.Framework.Rendering;
using TowerProtect.Framework.Rendering.Textures;
using TowerProtect.Registry;
using TowerProtect.Scopes;
using TowerProtect.Domain.Inventions.Synchronization;
using TowerProtect.Domain.Inventions.Networking;
using TowerProtect.App.Networking.Routing.Backend;
using TowerProtect.App.Networking.Routing.Client;
using TowerProtect.App.Client.Input;
using TowerProtect.App.Backend.Entities;
using TowerProtect.Domain.Client.Entities;
using TowerProtect.App.Client.Receivers;
using TowerProtect.App.Client.Camera;
using TowerProtect.Domain.Rendering.Camera;
using TowerProtect.Domain.Backend.Entities.Bags;
using TowerProtect.App.Client.Interfaces;
using TowerProtect.Domain.Backend.Worldgen.Mazes;
using TowerProtect.Domain.Backend.Worldgen.Rooms;

namespace TowerProtect;

public static class Program
{
    [STAThread]
    static void Main()
    {
        var srv = new ServiceCollection();

        srv.InitializeScopes();
        srv.InitializeMonoGame();

        srv.AddMonoGameServices();
        srv.AddSingletonServices();
        srv.AddScopedServices();

        using var provider = srv.BuildServiceProvider();
        using var game = provider.GetRequiredService<Game>();

        game.AttachComponents(provider);
        game.Run();
    }

    private static void AddMonoGameServices(this IServiceCollection srv)
    {
        // --- Add components in execution order ---

        // 1. Early
        srv.AddMonoGameSingleton<SynchronizationComponent>();
        srv.AddMonoGameSingleton<InputComponent>();

        // 2. Logic (app & domain)
        srv.AddMonoGameSingleton<AppComponent>();

        // 3. Rendering
        srv.AddMonoGameSingleton<ScreenResizeComponent>();
        srv.AddMonoGameSingleton<RenderingComponent>();
        srv.AddMonoGameSingleton<LetterboxComponent>();
        srv.AddMonoGameSingleton<DiagnosticsComponent>();

        // 4. No update methods (no ordering required)
        srv.AddMonoGameSingleton<ITextureComponent, TextureComponent>();
        srv.AddMonoGameSingleton<IContourTextureComponent, ContourTextureComponent>();

        // 5. Late
        srv.AddMonoGameSingleton<ScopeComponent>();
    }

    private static void AddSingletonServices(this IServiceCollection srv)
    {
        // Rendering
        srv.AddSingleton<ICameraView, CameraView>();

        // Input / Output
        srv.ReassignSingleton<IInputSystem, InputComponent>();

        // Technical
        srv.AddSingleton<GameSynchronizationContext>();

        // Utilities
        srv.AddSingleton<INetInstance, NetInstance>();
        srv.AddSingleton<IPacketSerializer, PacketSerializer>();
    }

    private static void AddScopedServices(this IServiceCollection srv)
    {
        // Roots
        {
            srv.UseFullScoped<IAppRoot, LocalAppRoot, RemoteAppRoot, MenuAppRoot>();
            srv.UseFullScoped<IDisplayRoot, GameplayDisplayRoot, MenuDisplayRoot>();
        }

        // Networking
        {
            // Client networking
            srv.UseLocalScoped<IBackendRouter, BackendRouter>();
            {
                srv.UseLocalScoped<IBackendPipe, BackendPipe>();
                srv.ReassignScoped<IBackendFrontPipe, IBackendPipe>();
                srv.ReassignScoped<IBackendBackPipe, IBackendPipe>();
            }

            // Backend networking
            srv.UseGameplayScoped<IClientRouter, ClientRouter>();
            {
                srv.UseGameplayScoped<IClientPipe, ClientPipe>();
                srv.ReassignScoped<IClientFrontPipe, IClientPipe>();
                srv.ReassignScoped<IClientBackPipe, IClientPipe>();
            }

            // Connectors
            srv.UseLocalScoped<ILocalConnector, LocalConnector>();
        }

        // Backend
        {
            // Application
            srv.UseLocalScoped<IBackendOrchestrator, BackendOrchestrator>();
            srv.UseLocalScoped<IPlayerManager, PlayerManager>();
            srv.UseLocalScoped<IEnemyManager, EnemyManager>();
            srv.UseLocalScoped<IBroadcastSender, BroadcastSender>();

            // Domain
            srv.UseLocalScoped<IEntityBag, EntityBag>();
            srv.UseLocalScoped<IPlayerBag, PlayerBag>();
            srv.UseLocalScoped<IEnemyBag, EnemyBag>();
            srv.UseLocalScoped<ITilemap, Tilemap>();
            srv.UseLocalScoped<ITileFactory, TileFactory>();
            srv.UseLocalScoped<IMap, GeneratedMap>();
            srv.UseLocalScoped<IMazeGenerator, WilsonMazeGenerator>();
            srv.UseLocalScoped<IRoomPlacer, DefaultRoomPlacer>();
        }

        // Client
        {
            // Application
            srv.UseGameplayScoped<IClientOrchestrator, ClientOrchestrator>();
            srv.UseGameplayScoped<IInformationDivider, InformationDivider>();
            srv.UseGameplayScoped<ICameraControl, CameraControl>();
            srv.UseGameplayScoped<IInputSender, InputSender>();

            // Domain
            srv.UseGameplayScoped<IWorldDisplay, WorldDisplay>();
            srv.UseGameplayScoped<IEntitiesDisplay, EntitiesDisplay>();
            srv.UseGameplayScoped<ICameraFollow, CameraFollow>();
            srv.UseGameplayScoped<ICameraZoom, CameraZoom>();
        }
    }
}
