using System;
using UnityEngine;

public class RoomManager : MonoBehaviour
{
    public Transform playerTransform;
    public GameObject startingRoom;
    
    private GameObject currentRoom;
    void Start()
    {
        Debug.Log("GameManager Start:  Instantiating startingRoom");
        currentRoom = Instantiate(startingRoom, Vector3.zero, Quaternion.identity);
    }

    public void ChangeRoom(GameObject newRoom, string entranceName)
    {
        Debug.Log("GameManager ChangeRoom");
        Destroy(currentRoom);
        currentRoom = Instantiate(newRoom, Vector3.zero, Quaternion.identity);
        
        Vector3 entranceSpawnPoint = currentRoom.GetComponent<Room>().GetEntranceSpawnPoint(entranceName);
        playerTransform.position = entranceSpawnPoint;
    }


}
