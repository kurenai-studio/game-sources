using UnityEngine;

[CreateAssetMenu(fileName = "Event", menuName = "Event", order = 0)]
public class GameEvent : ScriptableObject
{
    [Multiline]
    public string description;
    [Range(0f, 4f)]
    public float probability = 1f;

    [Header("Effects")]
    [Range(-0.5f, 0.5f)]
    public float powerDemand = 0f;
    [Range(-1f, 1f)]
    public float wind = 0f;
    [Range(-1f, 1f)]
    public float rain = 0f;
    [Range(0f, 1f)]
    public float heat = 0f;
    [Range(0f, 1f)]
    public float carbonTax = 0.0f;
    [Range(-0.25f, 0.5f)]
    public float gasPrice = 0f;
    [Range(0f, 1f)]
    public float powerIncrese = 0.0f;

    public Action action = Action.None;

    public enum Action
    {
        None,
        Tutorial,
        Victory,
        Build
    }
}