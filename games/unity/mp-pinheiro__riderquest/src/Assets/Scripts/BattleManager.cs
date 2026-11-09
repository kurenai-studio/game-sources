using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class BattleManager : MonoBehaviour {
	public GameObject hit;
	static bool hitting;
	Animator anim;
	AudioSource hitAudio;
	public static GameObject playerParty;
	public static GameObject enemyParty;
	public GameObject tempGambPrefab;
	public GameObject tempGambPrefab2;
	static string previousScene;
	static Character chosenTarget;
	static Character attacker;

	EnemyParty liveEnemyParty;
	PlayerParty livePlayerParty;
	static BattleManager instance;

	public static void StartBattle(GameObject playerParty, GameObject enemyParty){
		//save previous scene
		previousScene = SceneManager.GetActiveScene().name;
		Player.SetPreviousPosition(Player.GetInstance().transform.position);

		//start battle
		BattleManager.playerParty = playerParty;
		BattleManager.enemyParty = enemyParty;
		SceneManager.LoadScene("battle");
	}

	void Awake(){
		instance = this;
		anim = hit.GetComponent<Animator>();
		hitAudio = hit.GetComponent<AudioSource>();
	}

	void Start(){
		//*
		//TODO deleta isso
		if(playerParty==null) playerParty = tempGambPrefab;
		if(enemyParty==null) enemyParty = tempGambPrefab2;
		if(previousScene==null) previousScene = "overworld";
		//*/

		livePlayerParty = Instantiate(playerParty).GetComponent<PlayerParty>();
		liveEnemyParty = Instantiate(enemyParty).GetComponent<EnemyParty>();
		StartCoroutine(BattleCycle());
	}

	IEnumerator BattleCycle(){
		yield return liveEnemyParty.BattleStart();

		while(!liveEnemyParty.IsDead()){
			//act
			yield return livePlayerParty.ChooseActions();
			yield return liveEnemyParty.ChooseActions();

			//check if player party is dead
			if(livePlayerParty.IsDead()){
				if(liveEnemyParty.unfailable){
					break;
				}else{
					yield return MessageManager.ShowMessage("", "Everyone died...");
					SceneManager.LoadScene("gameover");
				}
			}
		}

		yield return liveEnemyParty.BattleFinish();
		FinishBattle();
	}

	public static void FinishBattle(){
		SceneManager.LoadScene(previousScene);
	}
	
	public static IEnumerator ChooseTarget(Character exclude){
		ArrayList members = new ArrayList();
		foreach(Character m in instance.liveEnemyParty.GetMembers()){
			if(m!=exclude) members.Add(m.GetName());
		}
		foreach(Character m in instance.livePlayerParty.GetMembers()){
			if(m!=exclude) members.Add(m.GetName());
		}
		yield return MessageManager.ShowChoices("Choose a target:", (string[]) members.ToArray(typeof(string)));
		chosenTarget = GetMemberCharacter(MessageManager.GetChosenChoice());
	}

	public static void SetTarget(Character c){
		chosenTarget = c;
	}

	public static Character GetChosenTarget(){
		return chosenTarget;
	}

	public static void SetAttacker(Character c){
		attacker = c;
	}

	public static Transform GetMemberTransform(string name){
		Transform t = instance.livePlayerParty.GetMemberTransform(name);
		if(t!=null) return t;
		return instance.liveEnemyParty.GetMemberTransform(name);
	}

	public static Character GetMemberCharacter(string name){
		Character c = instance.livePlayerParty.GetMemberCharacter(name);
		if(c!=null) return c;
		return instance.liveEnemyParty.GetMemberCharacter(name);
	}

	public static void RemoveMember(Character c){
		instance.livePlayerParty.RemoveMember(c);
		instance.liveEnemyParty.RemoveMember(c);
	}

	public static IEnumerator AttackTarget(){
		//start hit animation
		Transform t = GetMemberTransform(chosenTarget.GetName());
		hitting = true;
		instance.anim.Play("Hit", -1, 0f);
		instance.hit.transform.position = t.position;
		instance.hitAudio.Play();

		//decrease target life
		Character c = GetMemberCharacter(chosenTarget.GetName());
		yield return MessageManager.ShowMessage("", attacker.GetName() + " attacks " + c.GetName() + "!", false);
		yield return new WaitWhile (()=> hitting);
		int damage = attacker.Attack(c);
		if(c.IsDead()){
			t.gameObject.SetActive(false);
			yield return MessageManager.ShowMessage("", c.GetName() + " died.");
			RemoveMember(chosenTarget);
		}else{
			yield return MessageManager.ShowMessage("", c.GetName() + " took " + damage + " damage.");
		}
	}

	public static void FinishAnimation(){
		hitting = false;
		instance.hit.transform.position = new Vector3(-20f, 0f, 0f);
	}

	public static Character[] GetPlayerMembers(){
		return instance.livePlayerParty.GetMembers();
	}

	public static Character[] GetEnemyMembers(){
		return instance.liveEnemyParty.GetMembers();
	}
}
