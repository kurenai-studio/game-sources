using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.UI
{
    public class DigitTile : MonoBehaviour
    {
        private Animator animator;

        public void Start()
        {
            this.animator = this.GetComponent<Animator>();

            this.Set(this.Current);
        }

        public int Current { get; set; }

        public void Increase()
        {
            this.animator.SetTrigger("Increase");
            if (this.Current < 9)
            {
                this.Current += 1;
            }
            else
            {
                this.Current = 0;
            }
        }

        public void Decrease()
        {
            this.animator.SetTrigger("Decrease");
            if (this.Current > 0)
            {
                this.Current -= 1;
            }
            else
            {
                this.Current = 9;
            }
        }

        public void Set(int digit)
        {
            string digitState = Enum.GetName(typeof(Digits), digit).ToString();
            this.animator.Play(digitState);
        }
    }

    enum Digits
    {
        Zero = 0,
        One = 1,
        Two = 2,
        Three = 3,
        Four = 4,
        Five = 5,
        Six = 6,
        Seven = 7,
        Eight = 8,
        Nine = 9
    }
}
