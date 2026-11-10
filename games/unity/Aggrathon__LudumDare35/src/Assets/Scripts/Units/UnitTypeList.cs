using UnityEngine;
using System.Collections.Generic;

[CreateAssetMenu()]
public class UnitTypeList : ScriptableObject
{
	public UnitType[] types;
	public GameObject[] units;

	public static Dictionary<GameObject, UnitType> dict { get; protected set; }

	public void BuildDictionary()
	{
		dict = new Dictionary<GameObject, UnitType>();
		for (int i = 0; i < types.Length; i++)
		{
			dict.Add(units[i], types[i]);
		}
	}
}
