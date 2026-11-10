using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomPropertyDrawer(typeof(MazeManager.PrefabProbability))]
public class PrefabProbabilityDrawer : PropertyDrawer
{
    public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
    {
        EditorGUI.BeginProperty(position, null, property);
        Rect probPos = new Rect(position.x, position.y, position.width / 3, position.height);
        Rect prefabPos = new Rect(probPos.xMax + 5, position.y, position.width * 2 / 3 - 5, position.height);
        EditorGUI.PropertyField(probPos, property.FindPropertyRelative("prob"), GUIContent.none);
        EditorGUI.PropertyField(prefabPos, property.FindPropertyRelative("prefab"), GUIContent.none);
        EditorGUI.EndProperty();
    }
}

[CustomPropertyDrawer(typeof(Inventory.Capacity))]
public class CapacityDrawer : PropertyDrawer
{
    public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
    {
        EditorGUI.BeginProperty(position, null, property);
        float width = (position.width - 10) / 5;
        EditorGUI.LabelField(new Rect(position.x, position.y, width, position.height), label);
        EditorGUI.LabelField(new Rect(position.x + 5 + width, position.y, width, position.height), "Current:");
        EditorGUI.PropertyField(new Rect(position.x + 5 + width * 2, position.y, width, position.height), property.FindPropertyRelative("value"), GUIContent.none);
        EditorGUI.LabelField(new Rect(position.x + 10 + width * 3, position.y, width, position.height), "Max:");
        EditorGUI.PropertyField(new Rect(position.x + 10 + width * 4, position.y, width, position.height), property.FindPropertyRelative("max"), GUIContent.none);
        EditorGUI.EndProperty();
    }
}
