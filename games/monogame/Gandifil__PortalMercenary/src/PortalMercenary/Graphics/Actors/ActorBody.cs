using Microsoft.Xna.Framework;
using MonoGame.Extended.Graphics;

namespace PortalMercenary.Graphics.Actors;

public class ActorBody
{
    public Actor Actor { get; }
    public readonly ActorPart[] Parts, Legs;
    public readonly ActorPart Head, Body, Weapon;
    
    public ActorBody(Actor actor, Texture2DAtlas textureAtlas)
    {
        Actor = actor;
        Parts = new ActorPart[5];
        Legs = new ActorPart[2];

        var bootSprites = AtlasParser.GetBootSprites(textureAtlas);
        Parts[0] = Legs[0] = new ActorPart(actor, bootSprites)
        {
            Shift = new  Vector2(-10, 0),
        };
        
        Parts[1] = Legs[1] = new ActorPart(actor, bootSprites)
        {
            Shift = new  Vector2(10, 0)
        };

        Parts[2] = Body = new ActorPart(actor, AtlasParser.GetBodySprites(textureAtlas))
        {
            Shift = new  Vector2(0, -20f),
        };

        Parts[3] = Head = new ActorPart(actor, AtlasParser.GetHeadSprites(textureAtlas))
        {
            Shift = new  Vector2(0, -70f),
        };

        Parts[4] = Weapon = new ActorPart(actor, AtlasParser.GetWeaponSprites(textureAtlas))
        {
            Shift = new  Vector2(0, -20f),
        };
    }
}