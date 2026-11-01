using System.Collections.Generic;
using UnityEngine;

namespace AstroDrift
{
	public class GameManager : MonoBehaviour
	{
		public GameObject playerPrefab;
		public GameObject asteroidPrefab;
		public int startingAsteroids = 4;
		public int startingLives = 3;

		private int _score;
		private int _lives;
		private int _wave = 1;
		private readonly int[] _scoreForSize = { 100, 50, 20 };
		private readonly List<AsteroidController> _asteroids = new();
		private GameObject _player;
		private Camera _cam;

		void Start()
		{
			_cam = Camera.main;
			StartGame();
		}

		void StartGame()
		{
			_score = 0;
			_lives = startingLives;
			_wave = 1;
			SpawnPlayer();
			SpawnWave();
		}

		void SpawnPlayer()
		{
			if (_player != null) Destroy(_player);
			if (playerPrefab == null) return;
			_player = Instantiate(playerPrefab, Vector3.zero, Quaternion.identity);
		}

		void SpawnWave()
		{
			int count = startingAsteroids + _wave - 1;
			for (int i = 0; i < count; i++) SpawnAsteroidAtEdge();
		}

		void SpawnAsteroidAtEdge()
		{
			if (asteroidPrefab == null || _cam == null) return;
			Vector3 edgeView = Random.value < 0.5f
				? new Vector3(Random.value, Random.value < 0.5f ? -0.1f : 1.1f, 10f)
				: new Vector3(Random.value < 0.5f ? -0.1f : 1.1f, Random.value, 10f);
			Vector3 worldPos = _cam.ViewportToWorldPoint(edgeView);
			worldPos.z = 0f;
			var obj = Instantiate(asteroidPrefab, worldPos, Quaternion.identity);
			var ctl = obj.GetComponent<AsteroidController>();
			if (ctl != null)
			{
				ctl.size = AsteroidController.SizeTier.Large;
				Vector3 toCenter = (Vector3.zero - worldPos).normalized;
				float angle = Mathf.Atan2(toCenter.y, toCenter.x) + Random.Range(-0.5f, 0.5f);
				ctl.velocity = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * Random.Range(2f, 4f);
				ctl.spin = Random.Range(-2f, 2f);
				ctl.onDestroyed += OnAsteroidDestroyed;
				_asteroids.Add(ctl);
			}
		}

		void OnAsteroidDestroyed(AsteroidController a)
		{
			_score += _scoreForSize[(int)a.size];
			_asteroids.Remove(a);
			if (_asteroids.Count == 0)
			{
				_wave++;
				SpawnWave();
			}
		}

		void OnGUI()
		{
			GUI.Label(new Rect(12, 8, 400, 28), $"Score: {_score}    Lives: {_lives}    Wave: {_wave}");

			const string controls = "← → rotate   |   ↑ thrust   |   ↓ brake   |   Del fire   |   End restart   |   Esc quit";
			var style = new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter };
			style.normal.textColor = new Color(0.62f, 0.7f, 0.85f);
			GUI.Label(new Rect(0, Screen.height - 26, Screen.width, 22), controls, style);
		}
	}
}
