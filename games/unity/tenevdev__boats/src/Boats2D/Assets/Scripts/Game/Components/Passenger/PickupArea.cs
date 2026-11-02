using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public class PickupArea : MonoBehaviour
    {
        private Passenger passenger;
        private bool boatDetected = false;

        public void Awake()
        {
            Physics2D.IgnoreCollision(this.GetComponent<CircleCollider2D>(), GameObject.FindWithTag("River").GetComponent<BoxCollider2D>());
            this.passenger = this.GetComponentInParent<Passenger>();
        }

        public void OnTriggerEnter2D(Collider2D collider)
        {
            // Check if there is a boat near the passenger
            if (collider.tag == "Boat" && !this.boatDetected)
            {
                this.boatDetected = true;
                Boat boat = collider.gameObject.GetComponent<Boat>();
                
                // Let the state of the passenger determine what to do with this boat
                this.passenger.State.HandleBoat(boat);
            }
            else if (collider.tag == this.passenger.destination)
            {
                // The passenger is on a boat and the passenger can get off
                this.passenger.State.HandleShore(collider.tag);
            }
        }
    }
}
