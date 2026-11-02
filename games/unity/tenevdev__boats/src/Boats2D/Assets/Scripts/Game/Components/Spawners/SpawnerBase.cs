using Assets.Scripts.Game.Core;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public abstract class SpawnerBase : MonoBehaviour, ICreator
    {
        public float creationFrequency;
        public Vector2 creationArea;

        public virtual void Start()
        {
            this.StartCoroutine(this.Run());
        }

        public IEnumerator Run()
        {
            while (true)
            {
                this.Create();
                yield return new WaitForSeconds(this.creationFrequency);
            }
        }

        public abstract UnityEngine.Object Create();

        protected virtual Vector3 Position()
        {
            float x = UnityEngine.Random.Range(-this.creationArea.x, this.creationArea.x);
            float y = UnityEngine.Random.Range(-this.creationArea.y, this.creationArea.y);

            Vector3 position = new Vector3(this.transform.position.x + x, this.transform.position.y + y, 0);

            return position;
        }
    }
}
