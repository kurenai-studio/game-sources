using System;
using UnityEngine;

namespace Playfield
{
    public class GoalLine : MonoBehaviour
    {
        public static Action<Side> OnGoalScored;
        
        [SerializeField]
        private Side side;
        
        private void OnTriggerEnter2D(Collider2D other)
        {
            OnGoalScored?.Invoke(side);
        }
    }
}