using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player : MonoBehaviour
{
    private float moveHorizontal;
    private float moveVertical;
    private float speed = 10f;
    
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 position = transform.position;
        moveHorizontal = Input.GetAxisRaw("Horizontal");
        moveVertical = Input.GetAxisRaw("Vertical");

        position += new Vector3(moveHorizontal, moveVertical, 0) * speed * Time.deltaTime;
        position.x = Mathf.Clamp(position.x, -8.3f, 8.3f);
        position.y = Mathf.Clamp(position.y, -4.3f, 4.3f);
        transform.position = position;
    }
}
