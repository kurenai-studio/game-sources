using System;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName = "Puzzle/Level Definition", fileName = "LevelDefinition")]
public class LevelDefinition : ScriptableObject
{
    [Header("Metadata")]
    public string levelName = "Level 1";

    [Header("Player Start (Grid Cell)")]
    public Vector2Int playerStartCell = Vector2Int.zero;

    [Header("Walls (Blocked Cells)")]
    public List<Vector2Int> wallCells = new();

    [Header("Doors")]
    public List<DoorPlacement> doors = new();

    [Header("Plates (Step-On Triggers)")]
    public List<PlateTrigger> plates = new();

    [Serializable]
    public class DoorPlacement
    {
        public string doorId = "DoorA";
        public Vector2Int cell;
        public bool startsClosed = true;
    }

    [Serializable]
    public class PlateTrigger
    {
        public Vector2Int cell;
        public List<string> togglesDoorIds = new();
    }
}
