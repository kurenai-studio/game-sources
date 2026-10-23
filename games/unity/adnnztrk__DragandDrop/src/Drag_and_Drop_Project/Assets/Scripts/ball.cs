using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ball : MonoBehaviour
{
    Vector3 offset;
    void OnMouseDown()
    {
        offset = gameObject.transform.position - Camera.main.ScreenToWorldPoint(new Vector3(Input.mousePosition.x, Input.mousePosition.y));
    }
    void OnMouseDrag()
    {
        Vector3 Position = new Vector3(Input.mousePosition.x, Input.mousePosition.y);
        transform.position = Camera.main.ScreenToWorldPoint(Position) + offset;
    }
    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (collision.gameObject.tag.Equals("finish"))
        {
            Destroy(this.gameObject);
        }
    }
}
