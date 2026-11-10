using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class Game : MonoBehaviour {

    [SerializeField]
    GameObject canvas;

    [SerializeField]
    Player player;
    [SerializeField]
    Conveyor conveyor;
    [SerializeField]
    BoxSpawner spawner;

    [SerializeField]
    AnimationCurve minimumBoxSpawnTimeCurve;
    [SerializeField]
    AnimationCurve maximumBoxSpawnTimeCurve;
    [SerializeField]
    AnimationCurve boxSpawnAmountCurve;

    [SerializeField]
    AnimationCurve conveyorSpeedCurve;
    [SerializeField]
    AnimationCurve conveyorKickCurve;

    [SerializeField]
    float secondsUntilMaxDifficulty = 300;

    private bool gameOver = false;
    [SerializeField]
    private Text deathText;
    [SerializeField]
    private Text boxesBurnedText;
    private int boxesBurned = 0;


    private void Start() {
        
    }

    private void Update() {
        if (!player.Alive && !this.gameOver) {
            this.GameOver();
        }

        if (!this.gameOver) {
            this.spawner.AdjustMinimumSpawnTime(this.minimumBoxSpawnTimeCurve.Evaluate(Time.timeSinceLevelLoad / this.secondsUntilMaxDifficulty));
            this.spawner.AdjustMaximumSpawnTime(this.maximumBoxSpawnTimeCurve.Evaluate(Time.timeSinceLevelLoad / this.secondsUntilMaxDifficulty));
            this.spawner.AdjustSpawnAmount(this.boxSpawnAmountCurve.Evaluate(Time.timeSinceLevelLoad / this.secondsUntilMaxDifficulty));
            this.conveyor.AdjustConveyorSpeed(this.conveyorSpeedCurve.Evaluate(Time.timeSinceLevelLoad / this.secondsUntilMaxDifficulty));
            this.conveyor.AdjustConveyorKick(this.conveyorKickCurve.Evaluate(Time.timeSinceLevelLoad / this.secondsUntilMaxDifficulty));
        }
    }

    public void BoxBurned() {
        this.boxesBurned++;
        this.boxesBurnedText.text = "Boxes burned: " + this.boxesBurned;
    }

    void GameOver() {
        this.gameOver = true;

        this.spawner.GameOver = true;
        this.conveyor.GameOver = true;

        if (player.KilledBy == "burner") {
            this.deathText.text = "Don't stand in the fire!";
        }
        else if (player.KilledBy == "head") {
            this.deathText.text = "Watch your head!";
        }

        this.canvas.SetActive(true);
    }

    public void loadMenu() {
        SceneManager.LoadScene(0);
    }

    public void loadGame() {
        SceneManager.LoadScene(SceneManager.GetActiveScene().name);
    }

}
