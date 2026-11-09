using Microsoft.Xna.Framework;
using MonoGame.Extended;
using PortalMercenary.Screens;

namespace PortalMercenary.Game.Controllers;

public class AiController: ICharacterController
{
    public void Update(Character character, float dt)
    {
        var player = G.Screen.Player;
        var playerShift = player.Position - character.Position;
        character.Actor.Shift = playerShift.NormalizedCopy();
        if (playerShift.Length() < character.Options.Attack.Distance)
            character.Attack();
    }
}