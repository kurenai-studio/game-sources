using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

public class GridWorld : MonoBehaviour
{
    public Tilemap terrain;
    public Tilemap decorators;


    public CustomTile.TileInfo GetTileInfo(Vector3Int pos)
    {
        var terrainTile = terrain.GetTile<CustomTile>(pos);
        var ti = new CustomTile.TileInfo(terrainTile);
        var otherTile = decorators.GetTile<CustomTile>(pos);
        if (otherTile != null)
            ti.Combine(otherTile);
        ti.energy = Mathf.Max(0, ti.energy);
        return ti;
    }

    public Vector3 SnapToTile(Vector3 pos)
    {
        return terrain.CellToWorld(terrain.WorldToCell(pos));
    }

    public Vector3 SnapToTile(Vector3Int pos)
    {
        return terrain.CellToWorld(pos);
    }

    public Vector3Int GetTile(Vector3 pos)
    {
        return terrain.WorldToCell(pos);
    }

    public CustomTile.TileInfo GetTileCost(Vector3 pos)
    {
        return GetTileInfo(GetTile(pos));
    }

    public Vector3Int LeftOf(Vector3Int pos)
    {
        return terrain.WorldToCell(SnapToTile(pos) + new Vector3(-0.7f, 0.5f, 0f));
    }
    public Vector3Int LeftOf(Vector3 pos)
    {
        return terrain.WorldToCell(pos + new Vector3(-0.7f, 0.5f, 0f));
    }

    public Vector3Int RightOf(Vector3Int pos)
    {
        return terrain.WorldToCell(SnapToTile(pos) + new Vector3(0.7f, 0.5f, 0f));
    }

    public Vector3Int RightOf(Vector3 pos)
    {
        return terrain.WorldToCell(pos + new Vector3(0.7f, 0.5f, 0f));
    }

    public Vector3Int TopOf(Vector3Int pos)
    {
        pos.x++;
        return pos;
    }
}
