using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DeerParty : EnemyParty {

	protected override void Start(){
		base.Start();
		memberByName.Add("Deer", 0);

		characters = new Character[]{
			new Character("Deer", 1, 10) //deer
		};

	}
	public override IEnumerator BattleStart () {
		yield return MessageManager.ShowMessage(Global.fatherName, "Nice going, son! Now it's time to subdue it. This is how battle looks like! Can you feel the blood pumping in your veins?");
		yield return MessageManager.ShowMessage(Global.playerName, "It's just a deer, dad.");
		yield return MessageManager.ShowMessage(Global.fatherName, "Don't let that fool you! Those are vicious creatures. Come on, attack it!");
	}
	
	public override IEnumerator BattleFinish(){
		yield return MessageManager.ShowMessage(Global.fatherName, "That was great, son! You are going to grow up into an amazing fighter one day. Now let's go back to your mother.");
		Global.killedDeer = true;
	}
}
