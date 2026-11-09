using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Player : Car {
	static GameObject instance;
	static Vector3 previousPosition;
	static bool usePreviousPosition;

	protected override void Awake(){
		base.Awake();
		instance = gameObject;

		//load previous position
		if(usePreviousPosition){
			transform.position = previousPosition;
			usePreviousPosition = false;
		}
	}

	// Update is called once per frame
	protected override void Update () {
		base.Update();
		if(Time.timeScale==0f){
			StopTime();
			return;
		}

		if(Input.GetKey(KeyCode.LeftArrow)){
			TurnLeft();
		}else if(Input.GetKey(KeyCode.RightArrow)){
			TurnRight();
		}else{
			StopTurning();
		}
		if(Input.GetKey(KeyCode.UpArrow)){
			Accelerate();
		}else{
			StopAccelerating();
		}
		if(Input.GetKey(KeyCode.DownArrow)){
			Reverse();
		}
	}

	public static GameObject GetInstance(){
		return instance;
	}

	public static void SetPreviousPosition(Vector3 pos){
		previousPosition = pos;
		usePreviousPosition = true;
	}

	public static void Teleport(string scene, float x, float y){
		SetPreviousPosition(new Vector2(x, y));
		SceneManager.LoadScene(scene);
	}
}
