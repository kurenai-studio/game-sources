using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components.Spawners
{
    public class PassengerSpawner : Spawner
    {
        public string origin;
        public string destination;
        public Vector2 direction;

        public override UnityEngine.Object Create()
        {
            Passenger passenger = base.Create() as Passenger;

            // Set passenger origin and destination
            passenger.origin = this.origin;
            passenger.destination = this.destination;
            passenger.direction = this.direction;

            return passenger;
        }
    }
}
