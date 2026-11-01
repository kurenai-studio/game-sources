using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PaddleController : MonoBehaviour
{
    private bool shouldMove = false;
    private bool moveUp = true; //if false move down

    //Can be changed/adjusted from Editor
    public float moveSpeed = 5.0f;
    public float paddleSize = 1.5f;

    public void Initialize()
    {
        var size = transform.localScale;
        size.y = paddleSize;
        transform.localScale = size;
        resetPosition();
    }

    void Update()
    {
        //screen height check
        if (Mathf.Abs(transform.position.y) <= 4.25f){
            if (shouldMove){
                if (moveUp){
                    transform.Translate(Vector2.up * Time.deltaTime * moveSpeed);
                } else {
                    transform.Translate(Vector2.down * Time.deltaTime * moveSpeed);
                }
            }
        } else {
            //prevents paddle from being stuck
            var pos = transform.position;
            pos.y = pos.y > 0 ? pos.y - 0.01f : pos.y + 0.01f;
            transform.position = pos; 
        }
    }

    public void MoveStatus(float input)
    {
        if (input == 0){
            shouldMove = false;
        } else {
            shouldMove = true;
            //Arrow up gives positive input, down - negative
            moveUp = (input > 0);
        }
    }

    public float getHeightPosition()
    {
        return transform.position.y;
    }

    public void resetPosition()
    {
        transform.localPosition = new Vector3(transform.localPosition.x, 0f, 10f);
    }
}
