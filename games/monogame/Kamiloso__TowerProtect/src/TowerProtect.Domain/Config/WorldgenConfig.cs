namespace TowerProtect.Domain.Config;

public static class WorldgenConfig
{
    public const int CellRange = 2;
    public const int CellSize = 2 * CellRange + 1;
    public const int MazeRange = 30;
    public const int TilemapRange = CellRange + 1 + MazeRange * (CellSize + 1);
}
