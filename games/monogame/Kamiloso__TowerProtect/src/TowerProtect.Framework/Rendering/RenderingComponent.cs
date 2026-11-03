using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;
using TowerProtect.App.Scopes;
using TowerProtect.Domain.Model.Vectors;
using TowerProtect.Framework.Extensions;
using TowerProtect.Framework.Rendering.Model;
using TowerProtect.App.Root.Display;
using TowerProtect.Framework.Rendering.Textures;
using TowerProtect.Domain.Rendering.Camera;
using TowerProtect.Domain.Rendering.Model;
using TowerProtect.Domain.Rendering.Sprites;

namespace TowerProtect.Framework.Rendering;

internal class RenderingComponent(
    Game game,
    ITextureComponent textureComponent,
    ICameraView cameraView,
    Dynamic<IDisplayRoot> displayRoot) : DrawableGameComponent(game)
{
    private RectangleF ScreenBounds => (RectangleF)GraphicsDevice.Viewport.Bounds;

    private SpriteBatch _spriteBatch = null!;
    private readonly List<MonoSprite> _monoSprites = [];

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        base.LoadContent();
    }

    public override void Draw(GameTime gameTime)
    {
		cameraView.AspectRatio = ScreenBounds.Width / ScreenBounds.Height;

        Rect cameraBounds = cameraView.VisionArea;
        Rect screenBounds = ScreenBounds.ToRect();

        _monoSprites.Clear();
        foreach (var sprite in displayRoot.Current.DrawNextFrame())
        {
            var monoSprite = ToMonoSprite(sprite, cameraBounds, screenBounds);
            _monoSprites.Add(monoSprite);
        }

        GraphicsDevice.Clear(Color.CornflowerBlue);
        _spriteBatch.Begin(SpriteSortMode.FrontToBack, BlendState.AlphaBlend);

		foreach (var monoSprite in _monoSprites)
        {
            _spriteBatch.Draw(
                texture: monoSprite.Texture,
                position: monoSprite.CenterPosition,
                sourceRectangle: null,
                color: Color.White,
                rotation: monoSprite.Rotation,
                origin: monoSprite.Origin,
                scale: monoSprite.Scale,
                effects: SpriteEffects.None,
                layerDepth: monoSprite.DepthLayer
            );
        }

        _spriteBatch.End();

        base.Draw(gameTime);
    }

    private MonoSprite ToMonoSprite(Sprite sprite, Rect cameraBounds, Rect screenBounds)
    {
        Rect cameraTextureArea = sprite.TextureArea;
        Rect screenTextureArea = Rect.MapRect(cameraTextureArea, cameraBounds, screenBounds);

        return new MonoSprite(
            textureComponent.Get(sprite.TextureName),
            screenTextureArea.ToRectangleF(),
            sprite.DisplayLayer.ToDepthLayer(),
            (float)sprite.Rotation
        );
    }
}
