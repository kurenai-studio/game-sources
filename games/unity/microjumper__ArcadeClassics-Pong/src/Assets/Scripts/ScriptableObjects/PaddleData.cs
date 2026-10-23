using UnityEngine;

namespace ScriptableObjects
{
    [CreateAssetMenu(fileName = "new PaddleData", menuName = "ScriptableObjects/PaddleData")]
    public class PaddleData : ScriptableObject
    {
        public float speed = 10f;
    }
}
