using UnityEngine;

namespace AnatomyJam.Material
{
    public class Armor : MonoBehaviour
    {
        [SerializeField]
        private float _value;

        public float Value
        {
            set => _value = value;
            get => _value;
        }
    }
}
