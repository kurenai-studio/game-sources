using UnityEngine;

public abstract class AStateModifier : ScriptableObject
{
	public float time = 10f;
	public float cooldown = 20f;
	[Range(0, 1)] public float cost = 0.5f;
	[TextArea] public string description;

	public abstract void Apply(State state);
}