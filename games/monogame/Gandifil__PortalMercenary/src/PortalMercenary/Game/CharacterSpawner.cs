using Microsoft.Xna.Framework;
using PortalMercenary.Game.Controllers;

namespace PortalMercenary.Game;

public class CharacterSpawner
{
    private readonly CharacterManager _characterManager;
    private Vector2 _position = Vector2.Zero;
    private ICharacterController _controller = null!;
    private string _characterKey = string.Empty;
    private Character _character;

    public CharacterSpawner(CharacterManager characterManager)
    {
        _characterManager = characterManager;
    }

    public CharacterSpawner WithPosition(Vector2 position)
    {
        _position = position;
        return this;
    }

    public CharacterSpawner MovePosition(Vector2 position)
    {
        _position += position;
        return this;
    }

    public CharacterSpawner WithController(ICharacterController controller)
    {
        _controller = controller;
        return this;
    }

    public CharacterSpawner WithKey(string key)
    {
        _characterKey = key;
        return this;
    }

    private CharacterSpawner Spawn()
    {
        var character = new Character(_position, G.Content.Characters[_characterKey])
        {
            Controller = _controller
        };
        _character = _characterManager.Add(character);
        return this;
    }

    public CharacterSpawner Spawn(string key) => WithKey(key).Spawn();

    public Character Last() => _character;
}
