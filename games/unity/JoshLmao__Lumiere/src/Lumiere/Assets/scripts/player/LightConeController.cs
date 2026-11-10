using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightConeController : MonoBehaviour {

    [SerializeField]
    PlayerController m_player;

    public float MinimumOpacity;
    public float MaximumOpacity;

    Material m_material;

	void Start ()
    {
        m_material = GetComponent<MeshRenderer>().materials[0];
	}
	
	void FixedUpdate()
    {
        var percentage = (m_player.CurrentHealth / 100) * Constants.PLAYER_TOTAL_HEALTH;
        var range = MinimumOpacity + MaximumOpacity;
        float betweenOneZero = (float)percentage / 100;

        var value = range * betweenOneZero;
        m_material.SetColor("_TintColor", new Color(0.5f, 0.5f, 0.5f, value / 256)); //between 1 and 0
    }
}
