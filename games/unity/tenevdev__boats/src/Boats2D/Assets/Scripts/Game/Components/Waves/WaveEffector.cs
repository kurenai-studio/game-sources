using UnityEngine;
using System.Collections;

namespace Assets.Scripts.Game.Components
{
    /// <summary>
    /// Used to control the expansion and force of a wave game object
    /// Should modify the radius of the circle collider to expand the wave
    /// Should modify the force magnitude of the area effector to reduce the force in time
    /// When the force magnitude becomes too small destroy the wave object
    /// </summary>
    public class WaveEffector : MonoBehaviour
    {

        private SurfaceEffector2D surfaceEffector;

        public float expansion = 0.6f;
        public float dispersion = 3f;

        // Use this for initialization
        public void Start()
        {
            this.surfaceEffector = this.GetComponent<SurfaceEffector2D>();
        }

        // Update is called once per frame
        public void FixedUpdate()
        {
            if (this.transform.localScale.x > dispersion)
            {
                Destroy(this.gameObject);
            }
            else
            {
                this.transform.localScale += new Vector3(this.surfaceEffector.speed * this.expansion, this.surfaceEffector.speed * this.expansion, 0);
            }
        }
    }
}
