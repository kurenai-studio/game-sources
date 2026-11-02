using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public class PassengerLeavingState : PassengerState
    {
        public PassengerLeavingState(Passenger passenger)
            : base(passenger)
        {
            // Start leaving
            this.Passenger.movementSpeed = -this.Passenger.direction;

            this.Passenger.animator.Play("Leave");
            this.Passenger.StartCoroutine(this.Move());
        }
        
        internal override void HandleShore(string shoreName)
        {
            // There should be no shore to handle
        }

        internal override void HandleBoat(Boat boat)
        {
            // Get on board
            this.Passenger.transform.position = Vector3.zero;
            this.Passenger.transform.SetParent(boat.transform, false);

            // Stop moving
            this.Passenger.movementSpeed = Vector2.zero;

            this.Passenger.SetState(PassengerStates.OnBoat);
        }
    }
}
