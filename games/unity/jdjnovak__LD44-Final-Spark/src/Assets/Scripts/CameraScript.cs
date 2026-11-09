using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraScript : MonoBehaviour
{
    private GameObject player;

    // Start is called before the first frame update
    void Start()
    {
        Init();
    }

    // Update is called once per frame
    void Update()
    {
        PositionUpdate();
    }

    void Init() {
        player = GameObject.FindGameObjectWithTag("Player");
    }

    void PositionUpdate() {
        float x = gameObject.transform.position.x;
        float y = gameObject.transform.position.y;
        if (player.transform.position.x <= 4.9f && player.transform.position.x >= -4.9f) {
            x = player.transform.position.x;
        }
        if (player.transform.position.y <= 6f && player.transform.position.y >= -6f) {
            y = player.transform.position.y;
        }
        gameObject.transform.position = new Vector3(x, y, -2.5f);
    }
}
