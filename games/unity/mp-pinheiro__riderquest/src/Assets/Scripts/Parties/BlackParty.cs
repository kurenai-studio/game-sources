using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BlackParty : EnemyParty {

	protected override void Start(){
		base.Start();
		memberByName.Add("Black Car 1", 0);
		memberByName.Add("Black Car 2", 1);
		memberByName.Add("Black Car 3", 2);

		characters = new Character[]{
			new Character("Black Car 1", 30, 40), //black
			new Character("Black Car 2", 30, 40), //black
			new Character("Black Car 3", 30, 40), //black
		};

	}
	public override IEnumerator BattleStart () {
		yield return MessageManager.ShowMessage(Global.fatherName, "Where is my wife!?");
	}
	
	public override IEnumerator BattleFinish(){
		yield return MessageManager.ShowMessage(Global.fatherName, "Argh...");
		Global.fatherDied = true;
	}
}
