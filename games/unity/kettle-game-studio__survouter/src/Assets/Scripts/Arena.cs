using UnityEngine;
using UnityEngine.AI;

public class Arena : MonoBehaviour
{
    private PlayerController _player;
    public Transform[] FlyingSpots;
    private int spotIdx = 0;

    public PlayerController GetPlayer()
    {
        if (_player == null)
            _player = FindObjectsByType<PlayerController>(FindObjectsSortMode.None)[0];

        return _player;
    }

    public Transform NextFlyingSpot()
    {
        var spot = FlyingSpots[spotIdx];
        spotIdx = (spotIdx + 1) % FlyingSpots.Length;
        return spot;
    }
}
