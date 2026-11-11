using System;
using UnityEngine;

public class Interactinator : MonoBehaviour
{
    public string tooltip = "";
    public bool locked = false;

    public void Interact(PlayerController player)
    {
        if (locked)
        {
            if (player.gameState.TouchObject(tooltip))
            {
                Action(player);
                locked = false;
            }
            else
            {
                player.Say(player.gameState.GetString($"{tooltip}_lock"));
            }
        }
        else
        {
            Action(player);
        }
    }

    protected virtual void Action(PlayerController player)
    {
        player.Say("interacted!!", name);
    }
}
