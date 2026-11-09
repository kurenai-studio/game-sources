using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyParty : MonoBehaviour {
	public Transform[] transforms;
	public bool unfailable;
	protected Dictionary<string, int> memberByName;
	protected Character[] characters;
	Character character;

	protected virtual void Start(){
		memberByName = new Dictionary<string, int>();
	}

	public virtual IEnumerator BattleStart () {
		yield return new WaitUntil(()=> true);
	}

	public virtual IEnumerator ChooseActions(){
		foreach(Character c in GetMembers()){
			character = c;
			yield return Attack(); //only attack for now
		}
	}

	IEnumerator Attack(){
		Character[] playerParty = BattleManager.GetPlayerMembers();
		BattleManager.SetAttacker(character);
		BattleManager.SetTarget(playerParty[Random.Range(0, playerParty.Length)]);
		yield return BattleManager.AttackTarget();
	}

	public virtual IEnumerator BattleFinish(){
		yield return new WaitUntil(()=> true);
	}

	public Character[] GetMembers(){
		ArrayList m = new ArrayList();
		foreach(KeyValuePair<string, int> p in memberByName){
			m.Add(characters[p.Value]);
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
			memberByName.Remove(name);
		}
	}

	public bool IsDead(){
		return GetMembers().Length==0;
	}
}
