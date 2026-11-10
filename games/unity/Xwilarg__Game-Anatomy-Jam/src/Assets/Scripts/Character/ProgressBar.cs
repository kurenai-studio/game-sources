using UnityEngine;

namespace AnatomyJam.Character
{
    public class ProgressBar : MonoBehaviour
    {
        [SerializeField]
        private RectTransform _bar;

        /// <summary>
        /// Set the value of the progress bar
        /// </summary>
        /// <param name="value">Value to set, between 0 and 1</param>
        public void SetValue(float value)
        {
            _bar.anchorMax = new Vector2(value, 1f);
        }
    }
}
