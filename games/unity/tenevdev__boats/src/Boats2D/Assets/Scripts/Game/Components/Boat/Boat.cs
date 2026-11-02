using Assets.Scripts.Game.Core;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public class Boat : Creatable
    {
        public int passengerCount = 0;
        private Animator animator;

        public int capacity = 1;
        public HitPointsBar hitPointsBar;

        public override void Start()
        {
            base.Start();

            this.animator = this.GetComponent<Animator>();
            if (this.hitPointsBar == null)
            {
                this.hitPointsBar = this.GetComponentInChildren<HitPointsBar>();
            }

            // Control boat count
            LevelManagerBase.Instance.boatCount += 1;
            this.Dead += (s, e) =>
            {
                if (LevelManagerBase.Instance != null)
                    LevelManagerBase.Instance.BoatLost();
            };

            this.HitReceived += this.hitPointsBar.UpdateBar;
        }

        public override void OnCollisionEnter2D(Collision2D collision)
        {
            if (collision.gameObject.CompareTag("Obstacle"))
            {
                base.OnCollisionEnter2D(collision);
            }
        }

        protected override void PreDead(HitEventArgs args)
        {
            // Do not call base as it will raise dead immediately
            this.animator.SetBool("IsAlive", false);
        }

        public void Sunk()
        {
            // Raise dead to destroy boat
            this.OnDead(new DeadEventArgs(DeadReason.Killed));
        }
    }
}
