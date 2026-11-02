using UnityEngine;


public class Room : MonoBehaviour
{
    
    public Vector3 GetEntranceSpawnPoint(string entranceName)
    {
        //Try level 1
        Transform entranceTransform = transform.Find(entranceName);
        if (entranceTransform != null) return entranceTransform.position;
        
        //Try descendents of Entrances
        Transform entrancesTransform = transform.Find("Entrances");
        if (entrancesTransform != null)
        {
            entranceTransform = entrancesTransform.Find(entranceName);
            if (entranceTransform != null) return entranceTransform.position;
        }

        return Vector3.zero;
    }
    
}