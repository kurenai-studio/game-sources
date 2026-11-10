using AnatomyJam.Material;
using UnityEngine;

namespace AnatomyJam.SO
{
    [CreateAssetMenu(menuName = "ScriptableObject/SmithyInfo", fileName = "SmithyInfo")]
    public class SmithyInfo : ScriptableObject
    {
        public ResourceType[] StartingResources;
    }
}
