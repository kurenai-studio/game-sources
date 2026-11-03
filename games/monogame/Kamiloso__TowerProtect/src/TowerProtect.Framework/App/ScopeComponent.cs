using Microsoft.Xna.Framework;
using System;
using TowerProtect.App.Scopes;
using TowerProtect.Domain.Model.Scopes;
using TowerProtect.Domain.Rendering.Camera;
using TowerProtect.App.Client.Interfaces;

namespace TowerProtect.Framework.App;

internal class ScopeComponent(
    Game game,
    IInputSystem inputSystem, // temorary
    IScopeSwitcher scopeSwitcher, // temporary
    IScopeExchanger scopeExchanger,
    ICameraView cameraView) : GameComponent(game)
{
    public override void Update(GameTime gameTime)
    {
        // TODO: Remove
        if (inputSystem.IsKeyDown("Space"))
            scopeSwitcher.SwitchScope(new StartLocalData("Username"));
        // END TEMPORARY

        if (scopeExchanger.ExchangeScopeIfDelayed())
        {
            cameraView.ResetTransform();
        }

        base.Update(gameTime);
    }
}
