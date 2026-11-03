using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

using System.Collections.Generic;

namespace org.flauschhaus.Panza {

public class Runner : Game {

private GraphicsDeviceManager _graphics;
private SpriteBatch _spriteBatch;
private Tank[] _tanks;

public Runner()
{
  _graphics = new GraphicsDeviceManager(this);
  Content.RootDirectory = "Content";
  IsMouseVisible = true;
}

protected override 
void Initialize()
{
  Vector2 windowSize = new Vector2 (
    this.Window.ClientBounds.Width,
    this.Window.ClientBounds.Height
  );
  _tanks = new Tank[2] { 
    new Tank(0,windowSize),
    new Tank(1,windowSize)
  };

  base.Initialize();
}

protected override 
void LoadContent()
{
  _spriteBatch = new SpriteBatch(GraphicsDevice);

  for(int i = 0; i < _tanks.Length; ++i)
  {
    var tank = _tanks[i];
    var defaultTank = DefaultTank.GetTank(i);
    tank.TankSprite = Content.Load<Texture2D>(defaultTank.TankFileName);
    tank.GunSprite = Content.Load<Texture2D>(defaultTank.GunFileName);
  }
}

protected override
void Update(GameTime gameTime)
{
  if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed ||
      Keyboard.GetState().IsKeyDown(Keys.Escape))
    Exit();

  // TODO: Add your update logic here

  base.Update(gameTime);
}

protected override 
void Draw(GameTime gameTime)
{
  GraphicsDevice.Clear(Color.CornflowerBlue);

  _spriteBatch.Begin();
  foreach(Tank tank in _tanks)
    _spriteBatch.Draw(tank.TankSprite, tank.Position, Color.White);
  _spriteBatch.End();

  base.Draw(gameTime);
}

} // Runner

} // ns
