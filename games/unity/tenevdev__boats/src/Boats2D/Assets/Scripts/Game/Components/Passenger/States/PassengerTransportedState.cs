using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public class PassengerTransportedState : PassengerState
    {
        public PassengerTransportedState(Passenger passenger)
            : base(passenger)
        {
            // TODO : Find counter object and increment
            LevelManagerBase.Instance.IncrementScore();

            this.Passenger.movementSpeed = this.Passenger.direction;

            this.Passenger.animator.Play("Approach");
            this.Passenger.StartCoroutine(this.Move());
        }

        internal override void HandleShore(string shoreName)
        {
            // Do nothing
        }

        internal override void HandleBoat(Boat boat)
        {
            // Do nothing
        }
    }
}
