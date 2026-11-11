using UnityEngine;

public class TileScript : MonoBehaviour
{
    public MeshRenderer[] Tiles;

    void Start()
    {
        var id = Random.Range(0, Tiles.Length);
        for (var i = 0; i < Tiles.Length; i++) {
            Tiles[i].enabled = i == id;
        }

        transform.rotation = Quaternion.Euler(0, Random.Range(0, 4) * 90, 0);
    }
}
