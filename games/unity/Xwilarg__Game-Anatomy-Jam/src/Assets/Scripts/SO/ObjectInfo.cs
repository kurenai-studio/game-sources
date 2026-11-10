using AnatomyJam.Material;
using UnityEngine;

namespace AnatomyJam.SO
{
    [CreateAssetMenu(menuName = "ScriptableObject/ObjectInfo", fileName = "ObjectInfo")]
    public class ObjectInfo : ScriptableObject
    {
        public string Name;

        [Tooltip("Prefab that will be instanciated for this object")]
        public GameObject GameObject;

        [Tooltip("Resource associated with the object")]
        public ResourceType ResourceType;

        public Gem Gem;
        public Metal Metal;
    }
}
