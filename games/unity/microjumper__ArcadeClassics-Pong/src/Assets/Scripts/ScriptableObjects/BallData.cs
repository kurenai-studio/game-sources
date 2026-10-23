using UnityEngine;

namespace ScriptableObjects
{
    [CreateAssetMenu(fileName = "new BallData", menuName = "ScriptableObjects/BallData")]
    public class BallData : ScriptableObject
    {
        public float speed = 5f;
        public float speedIncrease = 1.05f;
        public float maxSpeed = 10f;
        public float maxBounceAngleInDegrees = 45f;
    }
}
