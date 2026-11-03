using System;

namespace TowerProtect.Domain.Backend.Worldgen.Mazes;

internal interface IMazeGenerator
{
    void Fill(Maze maze, Random rng);
}
