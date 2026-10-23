using UnityEngine;

public class GameController : MonoBehaviour {

  protected float updateInterval = 1.5f;

  public bool gameIsOver = false;

  void Start() {
    Time.fixedDeltaTime = updateInterval;
  }

  void Update() {
    if (Input.GetKeyDown(KeyCode.Escape)) {
      Debug.Log("Escape");
    }
  }

  public void FastForvard() {
    if (!gameIsOver) {
      Time.timeScale = 30f;
    }
  }

  public void SetFixedInterval(float interval) {
    Time.fixedDeltaTime = interval;
  }

  public void SetDefaultDropInterval() {
    if (!gameIsOver) {
      Time.timeScale = 1f;
    };
  }

  public void GameOver() {
    Time.timeScale = 0f;
    gameIsOver = true;
    Debug.Log("gameover");
  }
}
