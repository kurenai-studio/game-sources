using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Core
{
    public class Hittable : Movable, IHittable, IHitter
    {
        protected int startHitPoints;

        public int hitPoints;
        public int hitPower;

        public int HitPoints
        {
            get
            {
                return this.hitPoints;
            }
            set
            {
                this.hitPoints = value;
            }
        }
        public int HitPower
        {
            get
            {
                return this.hitPower;
            }
            set
            {
                this.hitPower = value;
            }
        }

        public override void Start()
        {
            base.Start();
            this.startHitPoints = this.HitPoints;
        }

        public virtual void ReceiveHit(Hittable hitter)
        {
            // Receive damage from hit object
            this.HitPoints -= hitter.HitPower;

            // Raise hit event
            OnHitReceived(new HitEventArgs(this.startHitPoints, this.HitPoints, hitter));
        }

        public virtual void OnCollisionEnter2D(Collision2D collision)
        {
            if (collision.collider.tag != "Wave")
            {
                Hittable hitter = collision.gameObject.GetComponent<Hittable>();
                if (hitter != null)
                {
                    this.ReceiveHit(hitter);
                }
            }
        }


        public event HitReceivedEventHandler HitReceived;
        protected virtual void OnHitReceived(HitEventArgs e)
        {
            if (HitReceived != null)
            {
                HitReceived(this, e);
                if (e.HitPointsLeft <= 0)
                {
                    PreDead(e);
                }
            }
        }

        protected virtual void PreDead(HitEventArgs args)
        {
            OnDead(new KilledEventArgs(args.Hitter));
        }
    }
}
