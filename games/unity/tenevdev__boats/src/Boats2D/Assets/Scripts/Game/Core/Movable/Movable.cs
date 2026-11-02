using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Core
{
    public class Movable : MonoBehaviour, IMovable
    {
        public virtual void Start()
        {
            this.Dead += this.Destroy;
        }

        public void OnBecameInvisible()
        {
            this.OnDead(new DeadEventArgs(DeadReason.OutOfScene));
        }

        public void Destroy(Movable sender, DeadEventArgs args)
        {
            UnityEngine.Object.Destroy(this.gameObject);
        }


        public event DeadEventHandler Dead;
        protected virtual void OnDead(DeadEventArgs e)
        {
            if (Dead != null)
            {
                Dead(this, e);
            }
        }
    }
}
