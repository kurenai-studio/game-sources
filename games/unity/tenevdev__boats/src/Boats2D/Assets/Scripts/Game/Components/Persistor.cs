using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public class Persistor : MonoBehaviour
    {
        public void Awake()
        {
            // There should be only one persistor
            if (GameObject.FindGameObjectsWithTag(this.tag).Count() != 1)
            {
                Destroy(this.transform.gameObject);
            }
            else
            {
                // Keep object alive on all scenes
                DontDestroyOnLoad(this.gameObject);
            }
        }
    }
}
