using UnityEngine;

namespace Minigame
{
    public delegate void MinigameCallBack();
    public abstract class AMiniGameManager : MonoBehaviour
    {
        public virtual void RunMinigame(MinigameCallBack cb_result, float difficultyFactor)
        {
            gameObject.SetActive(true);
        }
    }
}
