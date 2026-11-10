using UnityEngine;

[CreateAssetMenu(menuName = "State/ArmyModifier")]
public class ArmyModifier : AStateModifier
{
	[Range(0, 2)] public float morale   = 1f;
	[Range(0, 2)] public float damage   = 1f;
	[Range(0, 2)] public float capture  = 1f;
	[Range(0, 2)] public float foodCost = 1f;
	[Range(0, 2)] public float goldCost = 1f;

	public override void Apply(State state)
	{
		state.armyMorale *= morale;
		state.armyDamage *= damage;
		state.foodCost *= foodCost;
		state.goldCost *= goldCost;
		state.armyCapture *= capture;
	}
}