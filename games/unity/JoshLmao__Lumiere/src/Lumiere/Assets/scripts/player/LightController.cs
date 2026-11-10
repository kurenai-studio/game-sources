using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightController : MonoBehaviour {

    [SerializeField]
    PlayerController m_player;

    public float MaxIntensity = 1f;
    public float MinIntensity = 0f;

    Light m_light;

	void Start ()
    {
        m_light = GetComponent<Light>();
        if (m_light == null)
            Debug.LogError("Can't get light on object");
	}

    void Update()
    {
        var percentage = (m_player.CurrentHealth / 100) * Constants.PLAYER_TOTAL_HEALTH;
        var range = MinIntensity + MaxIntensity;
        float betweenOneZero = (float)percentage / 100;
        m_light.intensity = range * betweenOneZero; //between 1 and 0
    }
}
