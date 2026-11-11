using UnityEditor;
using UnityEngine;

public class Comment : Interactinator
{
    protected override void Action(PlayerController player)
    {
        player.Say(player.gameState.GetString($"{tooltip}_comment"));
    }
}
