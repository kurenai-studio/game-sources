using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WitchParty : EnemyParty
{

    protected override void Start()
    {
        base.Start();
        memberByName.Add("Teal", 0);

        characters = new Character[]{
            new Character("Teal", 1, 15),
        };

    }

    public override IEnumerator BattleFinish()
    {
        yield return MessageManager.ShowMessage(Global.greenName, "Yes!");
        yield return MessageManager.ShowMessage(Global.playerName, "Take that you car seat destroyer!");

        yield return MessageManager.ShowMessage("Fairfruit", "This is the end of car meme game.");
    }
}
