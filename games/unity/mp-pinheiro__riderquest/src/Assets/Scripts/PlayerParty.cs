using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerParty : MonoBehaviour {
	public bool[] members;
	/*
	0: Player
	1: Father
	2: Green
	3: Stranger
	4: Friend
	*/
	static Character[] characters = null; //characters levels and stats are statically kept here
	Character character;
	public Transform[] transforms;
	Dictionary<string, int> memberByName;

	void Start(){
		//create characters if they don't exist
		if(characters==null){
			characters = new Character[5];
			characters[0] = new Character(Global.playerName, 3, 10); //player
			characters[1] = new Character(Global.fatherName, 40, 60); //father
			characters[2] = new Character(Global.greenName, 3, 10); //green
			characters[3] = new Character(Global.strangerName, 2, 10); //stranger
			characters[4] = new Character(Global.friendName, 2, 10); //friend
			//TODO re-set names in Global and in here if anything changes
			//TODO choose stats
		}

		memberByName = new Dictionary<string, int>();
		memberByName.Add(Global.playerName, 0);
		memberByName.Add(Global.fatherName, 1);
		memberByName.Add(Global.greenName, 2);
		//TODO add other transforms
	}

	public IEnumerator ChooseActions(){
		if(members[0]){
			character = characters[0];
			/*
			string[] actions = {"Attack", "Skill", "Item"};
			yield return MessageManager.ShowChoices("Choose an action:", actions);
			switch(MessageManager.GetChosenChoice()){
				//TODO
				case "Attack":
					yield return Attack();
					break;
				case "Skill":
					yield return MessageManager.ShowMessage("", "Skill!");
					break;
				case "Item":
					yield return MessageManager.ShowMessage("", "Item!");
					break;
			}
			*/
			yield return Attack(); //only attack for now
		}
		if(Global.killedDeer){ //father only attacks if deer already killed
			for(int i=1; i<members.Length; i++){
				if(members[i]){
					character = characters[i];
					Character[] enemyParty = BattleManager.GetEnemyMembers();
					if(enemyParty.Length==0) break; //stop acting if enemy party is dead
					BattleManager.SetAttacker(character);
					BattleManager.SetTarget(enemyParty[Random.Range(0, enemyParty.Length)]);
					yield return BattleManager.AttackTarget();
				}
			}
		}
	}

	IEnumerator Attack(){
		BattleManager.SetAttacker(character);
		yield return BattleManager.ChooseTarget(character);
		yield return BattleManager.AttackTarget();
	}

	public Character[] GetMembers(){
		ArrayList m = new ArrayList();
		for(int i=0; i<members.Length; i++){
			if(members[i]) m.Add(characters[i]);
		}
		return (Character[]) m.ToArray(typeof(Character));
	}

	public Transform GetMemberTransform(string name){
		int t;
		if(memberByName.TryGetValue(name, out t)){
			return transforms[t];
		}
		return null;
	}

	public Character GetMemberCharacter(string name){
		int t;
		if(memberByName.TryGetValue(name, out t)){
			return characters[t];
		}
		return null;
	}

	public void RemoveMember(Character c){
		int t;
		string name = c.GetName();
		if(memberByName.TryGetValue(name, out t)){
			members[t] = false;
			memberByName.Remove(name);
		}
	}

	public bool IsDead(){
		return GetMembers().Length==0;
	}
}
