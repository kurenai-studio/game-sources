using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.App.Client.Interfaces;

public interface IInputSystem
{
    Vec2Int ArrowsVector { get; }
    Vec2 MouseVector { get; }
    int ScrollSign { get; }

    bool IsKeyDown(string key);
    bool IsKeyPressed(string key);
    bool IsKeyUp(string key);

    bool IsMouseDown(int button);
    bool IsMousePressed(int button);
    bool IsMouseUp(int button);
}
