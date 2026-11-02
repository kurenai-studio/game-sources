
using UnityEngine;

public class Exit : MonoBehaviour
{
    public GameObject destinationRoom;
    public string entranceName;

    private RoomManager _roomManager;

    void Start()
    {
        _roomManager = GameObject.Find("RoomManager").GetComponent<RoomManager>();
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.gameObject.CompareTag("Player"))
        {
            _roomManager.ChangeRoom(destinationRoom,  entranceName);
            
        }
    }
}