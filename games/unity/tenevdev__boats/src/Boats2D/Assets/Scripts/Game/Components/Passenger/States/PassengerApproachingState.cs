using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public class PassengerApproachingState : PassengerState
    {
        public PassengerApproachingState(Passenger passenger) : base(passenger) 
        {
            // Start approaching
            this.Passenger.movementSpeed = this.Passenger.direction;

            this.Passenger.animator.Play("Approach");
            this.Passenger.StartCoroutine(this.Move());
        }

        internal override void HandleShore(string shoreName)
        {
            // Start waiting for a boat
            this.Passenger.movementSpeed = Vector2.zero;
            this.Passenger.SetState(PassengerStates.Waiting);
        }

        internal override void HandleBoat(Boat boat)
        {
            // Get on board
            if (boat.passengerCount < boat.capacity)
            {
                boat.passengerCount += 1;

                this.Passenger.transform.position = Vector3.zero;
                this.Passenger.transform.SetParent(boat.transform, false);

                // Stop moving
                this.Passenger.movementSpeed = Vector2.zero;

                this.Passenger.SetState(PassengerStates.OnBoat);
            }
        }
    }
}
