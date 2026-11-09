using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class AIController : SquadController
{
    private Squad selectedSquad;
    private Vector2 attackDirection = new Vector2();

    private List<Squad> squads = new List<Squad>();
    private List<Squad> targetSquads = new List<Squad>();
    private Squad targetSquad = null;

    public AIController(List<Squad> squadsUnderAICommand)
    {
        this.squads = squadsUnderAICommand;
    }

    public override void TakeTurn()
    {
        ClearDefeatedSquads();
        SelectSquad();
        if (this.selectedSquad != null)
        {
            PrepareAttack();
            Attack();
        }
        else
        {
            this.squadsMoved = this.maxSquadsMoves; // No squad selected -> all squads defeated, finish turn.
        }
    }

    private void ClearDefeatedSquads()
    {
        List<Squad> activeSquads = new List<Squad>();
        foreach (Squad squad in this.squads)
        {
            if (!squad.IsDeafeated)
            {
                activeSquads.Add(squad);
            }
        }

        this.squads = activeSquads;
    }

    private void SelectSquad()
    {
        if (this.squads.Count > 0)
        {
            int selectedSquadIndex = Random.Range(0, this.squads.Count);
            this.selectedSquad = this.squads[selectedSquadIndex];
        }
    }

    private void PrepareAttack()
    {
        if(SearchForTargets())
        {
            this.targetSquad = GetTargetSquad();
        }
    }

    private void Attack()
    {
        if (this.targetSquad != null)
        {
            this.selectedSquad.Move(1f, this.attackDirection.normalized); // Attack at full speed!
        }
        else
        {
            this.selectedSquad.Move(1, new Vector3(Random.value, Random.value, Random.value)); // Random wandering.
        }
        this.squadsMoved++;
    }

    private bool SearchForTargets()
    {
        Collider2D[] hits = Physics2D.OverlapCircleAll(this.selectedSquad.transform.position, this.selectedSquad.GetSquadMovementSpeed(), LayerMask.NameToLayer("Player"));
        foreach (Collider2D hit in hits)
        {
            Squad foundSquad = hit.GetComponent<Squad>();
            if (foundSquad != null)
            {
                this.targetSquads.Add(foundSquad);
            }
        }
        return this.targetSquads.Count > 0;
    }

    private Squad GetTargetSquad()
    {
        int nearestTargetIndex = 0;
        float distanceToNearestTarget = this.selectedSquad.GetSquadMovementSpeed();
        for (int i = 0; i < this.targetSquads.Count; ++i)
        {
            if (this.targetSquads[i].GetSquadType() == ESquadType.King) // If King's in sight, target him
            {
                nearestTargetIndex = i;
                break;
            }
            else // Look for a nearest target squad
            {
                Vector2 toTarget = this.targetSquads[i].transform.position - this.selectedSquad.transform.position;
                if (toTarget.sqrMagnitude < distanceToNearestTarget)
                {
                    distanceToNearestTarget = toTarget.sqrMagnitude;
                    nearestTargetIndex = i;
                }
            }
        }
        this.attackDirection = this.targetSquads[nearestTargetIndex].transform.position - this.selectedSquad.transform.position;
        return this.targetSquads[nearestTargetIndex];
    }
}
