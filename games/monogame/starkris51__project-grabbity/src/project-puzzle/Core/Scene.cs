using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Core;

public interface IScene
{
    void Load();
    void Unload();
    void Update(GameTime gameTime);
    void Draw(GameTime gameTime, SpriteBatch spriteBatch);
}