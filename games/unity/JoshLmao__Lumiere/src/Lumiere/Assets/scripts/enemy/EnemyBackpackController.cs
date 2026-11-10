using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class EnemyBackpackController : MonoBehaviour {

    [SerializeField]
    Image m_image;

    [SerializeField]
    EnemyBase m_enemy;

    void Start()
    {

    }

    void FixedUpdate()
    {
        var percentage = m_enemy.Health / m_enemy.TotalHealth;
        m_image.fillAmount = (float)percentage;
    }
}
