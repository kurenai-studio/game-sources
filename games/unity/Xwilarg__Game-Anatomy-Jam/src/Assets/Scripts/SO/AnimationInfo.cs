using UnityEngine;

namespace AnatomyJam.SO
{
    /// <summary>
    /// Represent a zone the character are going through on the 2D view
    /// Party go to the next zone once they beat the boss of the current one
    /// </summary>
    [CreateAssetMenu(menuName = "ScriptableObject/AnimationInfo", fileName = "AnimationInfo")]
    public class AnimationInfo : ScriptableObject
    {
        public float[] Duration;
    }
}
