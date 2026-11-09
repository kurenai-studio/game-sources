using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RedParty : EnemyParty {

	protected override void Start(){
		base.Start();
		memberByName.Add("Red Car 1", 0);
		memberByName.Add("Red Car 2", 1);
		memberByName.Add("Red Car 3", 2);

		characters = new Character[]{
			new Character("Red Car 1", 1, 5),
			new Character("Red Car 2", 1, 5),
			new Character("Red Car 3", 1, 5),
		};

	}
	public override IEnumerator BattleStart () {
		yield return MessageManager.ShowMessage("Red Car 1", "I'm gonna show you what we do to thiefs around here!");
		yield return MessageManager.ShowMessage(Global.playerName, "What did you steal to make them so angry!?");
		yield return MessageManager.ShowMessage(Global.greenName, "Nothing! Well, something. But we have some more pressing matters as of now!");
	}
	
	public override IEnumerator BattleFinish(){
		Global.foundGreen = true;
		yield return MessageManager.ShowMessage("Red Car 3", "Let's get the hell out of here! That kid is insane!");
		yield return MessageManager.ShowMessage(Global.greenName, "Yeah, you better run!");
	}
}
