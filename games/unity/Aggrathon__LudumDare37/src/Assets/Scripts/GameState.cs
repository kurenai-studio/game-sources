using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class GameState : MonoBehaviour {

	[Header("Objects")]
	public FPSController player;

	[Header("UI")]
	public bool startInMenu = false;

	[Header("Events")]
	public UnityEvent onPlayerDeath;

	public static GameState instance;

	void Awake()
	{
		SetMenuActive(startInMenu);
		instance = this;
	}

	public static void SetMenuActive(bool state)
	{
		if(state)
		{
			Time.timeScale = 0f;
			Cursor.lockState = CursorLockMode.None;
			Cursor.visible = true;
		}
		else
		{
			Time.timeScale = 1f;
			Cursor.lockState = CursorLockMode.Locked;
			Cursor.visible = false;
		}
	}

	void OnDestroy()
	{
		instance = null;
		Time.timeScale = 1f;
		Cursor.lockState = CursorLockMode.None;
		Cursor.visible = true;
	}
}
