using UnityEngine;

[CreateAssetMenu(fileName = "New Squad Data", menuName = "LD46/Squad Data/New", order = 1)]
public class SquadData : ScriptableObject
{
	public ESquadType SquadType;
	public Sprite UnitSprite;
	public int UnitsCount;
	public int MaxUnitsCount;
	public float SquadOccupiedSpace;
	[Range(1000f, 10000f)]
	public float SquadMovementSpeed;
}
