using Assets.Scripts.Game.Core;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Components
{
    public class Passenger : Creatable
    {
        private Dictionary<PassengerStates, PassengerState> states = new Dictionary<PassengerStates,PassengerState>();
        public void SetState(PassengerStates state)
        {
            if (this.states.ContainsKey(state))
            {
                this.State = this.states[state];
            }
            else
            {
                switch (state)
                {
                    case PassengerStates.Approaching:
                        this.State = new PassengerApproachingState(this);
                        this.states.Add(PassengerStates.Approaching, this.State);
                        break;
                    case PassengerStates.Waiting:
                        this.State = new PassengerWaitingState(this);
                        this.states.Add(PassengerStates.Waiting, this.State);
                        break;
                    case PassengerStates.Leaving:
                        this.State = new PassengerLeavingState(this);
                        this.states.Add(PassengerStates.Leaving, this.State);
                        break;
                    case PassengerStates.OnBoat:
                        this.State = new PassengerOnBoatState(this);
                        this.states.Add(PassengerStates.OnBoat, this.State);
                        break;
                    case PassengerStates.Transported:
                        this.State = new PassengerTransportedState(this);
                        this.states.Add(PassengerStates.Transported, this.State);
                        break;
                    default:
                        break;
                }
            }
        }

        internal Animator animator;

        public Vector2 movementSpeed;
        public string destination;
        public string origin;
        public Vector2 direction;

        public override void Start()
        {
            base.Start();

            this.animator = this.GetComponent<Animator>();

            // Passengers should start moving to shore
            this.SetState(PassengerStates.Approaching);

        }

        public void OnTriggerEnter2D(Collider2D collider)
        {
            // Check if the passenger has reached a shore
            if (collider.tag == this.origin)
            {
                this.State.HandleShore(collider.tag);
            }
        }

        public PassengerState State { get; set; }
    }

    //public enum PassengerState
    //{
    //    Moving = 0,
    //    Waiting = 1,
    //    OnBoard = 2,
    //    Drowning = 3,
    //    Transported = 4
    //}
}
