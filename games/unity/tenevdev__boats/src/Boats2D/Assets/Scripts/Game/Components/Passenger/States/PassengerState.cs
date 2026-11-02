using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public abstract class PassengerState
    {
        public PassengerState(Passenger passenger)
        {
            this.Passenger = passenger;
        }

        internal abstract void HandleShore(string shoreName);
        internal abstract void HandleBoat(Boat boat);
        internal virtual IEnumerator Move()
        {
            while (this.Passenger.movementSpeed != Vector2.zero)
            {
                this.Passenger.transform.Translate(this.Passenger.movementSpeed * Time.fixedDeltaTime);
                yield return new WaitForFixedUpdate();
            }
        }


        public Passenger Passenger { get; set; }
    }

    public enum PassengerStates
    {
        Approaching = 0,
        Waiting = 1,
        Leaving = 2,
        OnBoat = 3,
        Transported = 4
    }
}
