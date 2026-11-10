using UnityEngine;

[CreateAssetMenu(menuName = "State/ProductionModifier")]
public class ProductionModifier: AStateModifier
{
	[Range(0, 2)] public float foodModifier = 1f;
	[Range(0, 2)] public float goldModifier = 1f;
	[Range(0, 2)] public float fertilityModifier = 1f;
	[Range(0, 2)] public float pietyModifier = 1f;
	[Range(0, 2)] public float goldCostModifier = 1f;
	[Range(0, 2)] public float foodCostModifier = 1f;

	public override void Apply(State state)
	{
		state.foodMultiplier *= foodModifier;
		state.goldMultiplier *= goldModifier;
		state.fertility *= fertilityModifier;
		state.pietyDecay *= pietyModifier;
		state.goldCost *= goldCostModifier;
		state.foodCost *= foodCostModifier;
	}
}