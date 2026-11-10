using UnityEngine;
using UnityEngine.Events;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using TMPro;

public class GameManager : MonoBehaviour
{
	static GameManager instance;

	public float tickRate = 1f;
	public UnityEvent onTick;
	public State player;

	[Header("Pointers")]
	public GameObject looseScreenPiety;

	[Header("End Game")]
	public float endGameTime = 120f;
	public float endGameInterval = 10f;
	public State ship;
	public GameObject endScreen;


	float nextTick;
	float endTime;
	int endArmySize = 200;
	List<State> states;

	private void Awake()
	{
		instance = this;
		states = new List<State>();
	}

	void Start()
	{
		nextTick = Time.time + tickRate;
		endTime = Time.time + endGameTime;
	}
	
	void Update()
	{
		if (nextTick < Time.time)
		{
			for (int i = 0; i < states.Count; i++)
				states[i].Tick();
			onTick.Invoke();
			nextTick += tickRate;
		}
		if (player.piety < 0)
		{
			enabled = false;
			looseScreenPiety.SetActive(true);
		}
		if (endTime < Time.time)
		{
			ship.gameObject.SetActive(true);
			if (ship.warriors > endArmySize)
			{
				endTime = Time.time + endGameInterval;
				ship.Attack(player, endArmySize);
				endArmySize += 100;
			}
		}
	}

	public static void RegisterState(State state)
	{
		instance.states.Add(state);
	} 

	public static State GetRandomEnemyState(State self)
	{
		if (self == null)
			return instance.states[Random.Range(0, instance.states.Count)];
		int rnd = Random.Range(0, instance.states.Count-1);
		if (self == instance.states[rnd])
			rnd = instance.states.Count - 1;
		return instance.states[rnd];
	}

	public static void RegisterOnTick(UnityAction act)
	{
		instance.onTick.AddListener(act);
	}

	public void Restart()
	{
		SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
	}

	public static void EndGame()
	{
		instance.enabled = false;
		instance.endScreen.SetActive(true);
		int gold = Mathf.FloorToInt(instance.player.gold);
		var text = instance.endScreen.transform.GetChild(0).GetComponent<TextMeshProUGUI>();
		text.text = string.Format(text.text, instance.player.score + gold,
			instance.player.score, gold);
	}
}
