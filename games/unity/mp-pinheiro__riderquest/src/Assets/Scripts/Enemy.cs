using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Enemy : MonoBehaviour {

	public GameObject playerParty;
	public GameObject enemyParty;
	
	void OnCollisionEnter2D(Collision2D other)
	{
		if(other.collider.tag=="Player"){
			StartBattle();
		}
	}

	public void StartBattle(){
		StartCoroutine(BattleRoutine());
	}

	IEnumerator BattleRoutine(){
		AudioSource audio = GetComponent<AudioSource>();
		audio.Play();
		Time.timeScale = 0f;
		yield return new WaitWhile (()=> audio.isPlaying);
		Time.timeScale = 1f;
		BattleManager.StartBattle(playerParty, enemyParty);
	}
}
