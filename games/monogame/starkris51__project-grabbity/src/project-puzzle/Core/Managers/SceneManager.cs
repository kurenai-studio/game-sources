using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Core;

public class SceneManager
{
    private readonly Stack<IScene> _stack = new();
    private readonly HashSet<IScene> _loaded = [];
    public IScene Current => _stack.Count > 0 ? _stack.Peek() : null!;

    public void Push(IScene scene)
    {
        if (!_loaded.Contains(scene))
        {
            scene.Load();
            _loaded.Add(scene);
        }
        _stack.Push(scene);
    }

    public void Pop()
    {
        if (_stack.Count == 0) return;
        var scene = _stack.Pop();
        scene.Unload();
        _loaded.Remove(scene);
    }

    public void Replace(IScene scene)
    {
        Pop();
        Push(scene);
    }

    public void Update(GameTime gameTime) => Current?.Update(gameTime);
    public void Draw(GameTime gameTime, SpriteBatch spriteBatch) => Current?.Draw(gameTime, spriteBatch);
}