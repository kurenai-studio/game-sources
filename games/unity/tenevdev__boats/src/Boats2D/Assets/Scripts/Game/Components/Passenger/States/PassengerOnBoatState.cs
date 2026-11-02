using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public class PassengerOnBoatState : PassengerState
    {
        public PassengerOnBoatState(Passenger passenger)
            : base(passenger)
        {
            this.Passenger.animator.Play("Stand");
        }
        
        internal override void HandleShore(string shoreName)
        {
            // Get off boat
            if (shoreName == this.Passenger.destination)
            {
                var shore = GameObject.FindWithTag(this.Passenger.destination);
                Bounds bounds = shore.GetComponent<SpriteRenderer>().bounds;

                this.Passenger.transform.parent.GetComponent<Boat>().passengerCount -= 1;

                this.Passenger.transform.parent = null;
                this.Passenger.transform.position = (Vector2)bounds.ClosestPoint(this.Passenger.transform.position) + this.Passenger.direction;
                this.Passenger.transform.rotation = Quaternion.identity;

                this.Passenger.SetState(PassengerStates.Transported);
            }

            // Increment transported passengers count
        }

        internal override void HandleBoat(Boat boat)
        {
            // Do nothing
        }
    }
}
