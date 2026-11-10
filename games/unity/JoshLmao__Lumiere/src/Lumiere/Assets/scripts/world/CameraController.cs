using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour {

    public float ZDistance = -10f;

    PlayerController m_player;
    GameController m_game;

	void Start ()
    {
        m_game = FindObjectOfType<GameController>();

    }
	
	void FixedUpdate()
    {
        if(m_player == null)
            m_player = m_game.Player;

        transform.position = new Vector3(m_player.transform.position.x, 0f, ZDistance);
	}
}
