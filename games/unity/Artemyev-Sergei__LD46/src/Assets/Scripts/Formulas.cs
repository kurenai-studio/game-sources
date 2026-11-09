using UnityEngine;

public class Formulas
{
    /// <summary>
    /// Return amount of units killed
    /// </summary>
    /// <param name="attackingSquad"></param>
    /// <param name="defendingSquad"></param>
    /// <returns></returns>
    public static int CalculateDamage(Squad attackingSquad, Squad defendingSquad)
    {
		int currentDamage = attackingSquad.GetSquadDamage();
		ModifyDamage(ref currentDamage, attackingSquad.GetSquadType(), defendingSquad.GetSquadType());
		Debug.LogWarningFormat("Who attacks: {0}, Who defends: {1}, Units Killed: {2}", attackingSquad.gameObject.tag, defendingSquad.gameObject.tag, currentDamage);
		return currentDamage;
    }

	private static void ModifyDamage(ref int currentAttackingSquadDamage, ESquadType attackingSquadType, ESquadType defendingSquadType)
	{
		if (attackingSquadType == ESquadType.Horsemen)
		{
			switch (defendingSquadType)
			{
				case ESquadType.Swordsmen:
					currentAttackingSquadDamage *= 2;
					break;
				default:
					break;
			}
		}

		if (attackingSquadType == ESquadType.Spearmen)
		{
			switch (defendingSquadType)
			{
				case ESquadType.Horsemen:
					currentAttackingSquadDamage *= 2;
					break;
				default:
					break;
			}
		}

		if (attackingSquadType == ESquadType.King)
		{
			currentAttackingSquadDamage *= 5;
		}
	}
}
