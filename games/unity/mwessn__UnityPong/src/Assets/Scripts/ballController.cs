using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ballController : MonoBehaviour
{
    public float ballSize = 0.5f;
    public float startSpeed = 10.0f;

    private float ballSpeed;

    public PaddleController rightPaddle;
    public PaddleController leftPaddle;

    public GameController controller;

    //ball movement vector
    private float vectorX = 0f;
    private float vectorY = 0f;

    private Renderer renderer;

    public void Initialize()
    {
        transform.localScale = new Vector3(ballSize, ballSize, ballSize);

        ballSpeed = startSpeed;

        renderer = this.GetComponent<Renderer>();

        resetPosition();
    }

    // Random color assigned every time ball hits paddle or screen border
    void Update()
    {
        transform.Translate(new Vector2(vectorX, vectorY).normalized * Time.deltaTime * ballSpeed);

        //4.75 - local height limit
        if (Mathf.Abs(transform.localPosition.y) >= 4.75f){
            vectorY *= -1.0f;
            renderer.material.color = Random.ColorHSV(0f, 1f, 0f, 1f, 0.5f, 1f);
        }

        //no Unity physics used, so ball just checks if there's a paddle coordinates in the way
        // 8.4 - local width limit
        if (Mathf.Abs(transform.localPosition.x) >= 8.4f){
            if (transform.localPosition.x > 0){
                if (transform.localPosition.y >= rightPaddle.getHeightPosition() - rightPaddle.paddleSize/2 && transform.localPosition.y <= rightPaddle.getHeightPosition() + rightPaddle.paddleSize/2){
                    vectorX *= -1.0f;
                } else {
                    controller.increaseScore(false);
                }
            } else {
                if (transform.localPosition.y >= leftPaddle.getHeightPosition() - leftPaddle.paddleSize/2 && transform.localPosition.y <= leftPaddle.getHeightPosition() + leftPaddle.paddleSize/2){
                    vectorX *= -1.0f;
                } else {
                    controller.increaseScore(true);
                }
            }

            //On each paddle hit increase ball speed (just for fun)
            ballSpeed += 1.0f;
            renderer.material.color = Random.ColorHSV(0f, 1f, 0f, 1f, 0.5f, 1f);
        }
    }

    public void resetPosition()
    {
        transform.localPosition = new Vector3(0f, 0f, 10f);

        ballSpeed = startSpeed;

        vectorX = Random.Range(-1.0f, 1.0f);
        vectorY = Random.Range(-1.0f, 1.0f);
    }
}
