using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class MenuController : MonoBehaviour {
  public static bool GameIsPaused = false;
  public UnityEngine.GameObject menuUI;
  public void PlayGame(int level) {
    SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex + level);
  }
  public void QuitMenu() {
    SceneManager.LoadScene(Globals.MainMenu);
  }
  public void Resume() {
    menuUI.SetActive(false);
  }
}
