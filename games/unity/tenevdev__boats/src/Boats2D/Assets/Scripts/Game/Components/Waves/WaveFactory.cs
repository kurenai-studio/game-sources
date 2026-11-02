using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public class WaveFactory : MonoBehaviour
    {
        public int waveCount;
        public float frequency;
        public Transform wave;

        public void Start()
        {
            StartCoroutine(this.CreateRipple());
        }

        private IEnumerator CreateRipple()
        {
            for (int i = 0; i < this.waveCount; i++)
            {
                CreateWave(this.transform.position);
                yield return new WaitForSeconds(frequency);
            }
            Destroy(this.gameObject);
        }

        private void CreateWave(Vector2 origin)
        {
            // Get position of origin
            Ray ray = Camera.main.ScreenPointToRay(origin);
            RaycastHit2D hit = Physics2D.Raycast(ray.origin, ray.direction);

            // Create wave
            Instantiate(this.wave, hit.point, Quaternion.identity);
        }
    }
}
