using UnityEngine;

public class Takablinator : Interactinator
{
    protected override void Action(PlayerController player)
    {
        player.Take(transform);
    }
}
