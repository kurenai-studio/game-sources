using UnityEngine;

[CreateAssetMenu(menuName = "State/ResourceModifier")]
public class ResourceModifier : AStateModifier
{
	public float food   = 0f;
	public float gold   = 0f;
	public int people   = 0;
	[Range(-1, 1)] public float piety  = 0f;

	public override void Apply(State state)
	{
		state.food   += food;
		state.gold   += gold;
		state.people += people;
		state.piety  += piety;
	}
}