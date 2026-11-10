using System;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameLoop : MonoBehaviour {
	private static int levelIndex = 1;

	private static int awokenEnemies;
	private static bool hasBeatenStage;

	private static bool loading;

	void Awake() {
		if (SceneManager.GetActiveScene().buildIndex != 0) levelIndex = SceneManager.GetActiveScene().buildIndex;

		DontDestroyOnLoad(gameObject);
		SceneManager.sceneLoaded += OnSceneLoaded;
	}

	void Update() {
		if (hasBeatenStage && Input.anyKeyDown) ForceNextLevel();
	}

	public static void NextLevel() {
		if (awokenEnemies > 0) return;

		hasBeatenStage = true;

		Replay.StartReplay();
	}

	public static void LoadlLevel(int level) {
		SceneManager.LoadScene(level);
	}

	private void ForceNextLevel() {
		if (loading) return;

		loading = true;
		SceneManager.LoadScene(++levelIndex);
		hasBeatenStage = false;
	}

	public void OnSceneLoaded(Scene scene, LoadSceneMode mode) {
		loading = false;
		Replay.ResetReplay();
	}

	public static void CloseGame() {
		Application.Quit();
	}

	public static void EnemyDead() {
		awokenEnemies--;
	}

	public static void EnemySeen() {
		awokenEnemies++;
	}

	internal static void RestartLevel() {
		SceneManager.LoadScene(levelIndex);
		Replay.ResetReplay();
		hasBeatenStage = false;
	}
}
