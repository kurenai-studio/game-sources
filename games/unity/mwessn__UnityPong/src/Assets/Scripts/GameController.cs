using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class GameController : MonoBehaviour
{
    public TextMeshProUGUI UIRightScore;
    public TextMeshProUGUI UILeftScore;

    private int rightScore = 0;
    private int leftScore = 0;

    public PaddleController rightPaddle;
    public PaddleController leftPaddle;

    public ballController ball;

    void Start()
    {
        rightPaddle.Initialize();
        leftPaddle.Initialize();

        ball.Initialize();

        UILeftScore.text = "0";
        UIRightScore.text = "0";
    }

    void Update()
    {
        leftPaddle.MoveStatus(Input.GetAxis("Vertical"));
        rightPaddle.MoveStatus(Input.GetAxis("Vertical2"));

        if(Input.GetKeyDown("escape")){
            Application.Quit();
        }
    }

    public void increaseScore(bool right)//if parameter is false increase left
    {
        if (right){
            rightScore++;
            UIRightScore.text = "" + rightScore;
        } else {
            leftScore++;
            UILeftScore.text = "" + leftScore;
        }
        reloadScene();
    }

    void reloadScene()
    {
        rightPaddle.resetPosition();
        leftPaddle.resetPosition();
        ball.resetPosition();
    }
}
