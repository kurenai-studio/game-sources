using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PushParticlesBehindSprites : MonoBehaviour {

	// Use this for initialization
	void Start ()
    {
       GetComponent<Renderer>().sortingLayerName = "Foreground";
    }
	
}
