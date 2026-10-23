using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

[CreateAssetMenu(fileName = "TetrominoTile", menuName = "Tiles/Tetromino", order = 1)]
public class TetrominoTile : TileBase
{
    [SerializeField] private Tetromino m_tetromino;
    [SerializeField] private Color m_color = Color.red;
    [SerializeField] private Tile m_tile;

    private Vector3Int m_oldPosition;

    /// <summary>
    /// Retrieves any tile rendering data from the scripted tile.
    /// </summary>
    /// <param name="position">Position of the tile on the Tilemap.</param>
    /// <param name="tilemap">The Tilemap the tile is present on.</param>
    /// <param name="tileData">Data to render the tile.</param>
    public override void GetTileData(Vector3Int position, ITilemap tilemap, ref TileData tileData)
    {
        var _tilemap = tilemap.GetComponent<Tilemap>();
        var _newTiles = new HashSet<Vector3Int>() { };
        var _oldTiles = new HashSet<Vector3Int>() { };

        foreach(var _cell in m_tetromino.Data.Cells)
        {
            if(_cell.x == 0 && _cell.y == 0)
                continue;

            _oldTiles.Add(m_oldPosition + new Vector3Int(_cell.x, _cell.y, 0));
            _newTiles.Add(position + new Vector3Int(_cell.x, _cell.y, 0));
        }

        // draw a tile for each cell in the tetromino
        foreach(var _cellPosition in _newTiles)
        {
            tileData.sprite = m_tile.sprite;
            tileData.color = m_color;
            _tilemap.SetTileFlags(_cellPosition, TileFlags.None);
            _tilemap.SetColor(_cellPosition, m_color);

            if(_cellPosition.x == 0 && _cellPosition.y == 0)
                continue;

            _tilemap.SetTile(_cellPosition, m_tile);
        }

        foreach(var _cellPosition in _oldTiles)
        {
            if(_newTiles.Contains(_cellPosition))
                continue;

            _tilemap.SetTile(_cellPosition, null);
        }

        m_oldPosition = position;
    }
}