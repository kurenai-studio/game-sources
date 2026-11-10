using UnityEngine;

namespace AnatomyJam.SO
{
    [CreateAssetMenu(menuName = "ScriptableObject/RetreatInfo", fileName = "RetreatInfo")]
    public class RetreatInfo : ScriptableObject
    {
        [Header("Gameplay modifier")]
        public int RetreatChanceMinus;

        [Header("Fade data")]
        public float FadeTimeBackground;
        public float FadeTimeText;
        public float PercentTimer;
        public float TimeWait;
    }
}
