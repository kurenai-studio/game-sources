using UnityEngine;

[CreateAssetMenu(menuName = "State/RelativeModifier")]
public class RelativeModifier : AStateModifier
{
	[Range(0, 2)] public float food   = 1f;
	[Range(0, 2)] public float gold   = 1f;
	[Range(0, 2)] public float people = 1f;

	public override void Apply(State state)
	{
		state.food   *= food;
		state.gold   *= gold;
		state.people    = Mathf.FloorToInt(state.people * people);
		state.prisoners = Mathf.FloorToInt(state.prisoners * people);
		state.farmers   = Mathf.FloorToInt(state.farmers * people);
		state.miners    = Mathf.FloorToInt(state.miners * people);
		state.warriors  = Mathf.FloorToInt(state.warriors * people);
	}
}
