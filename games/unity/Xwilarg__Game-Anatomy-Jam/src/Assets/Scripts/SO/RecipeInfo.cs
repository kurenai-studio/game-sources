using UnityEngine;

namespace AnatomyJam.SO
{
    [CreateAssetMenu(menuName = "ScriptableObject/RecipeInfo", fileName = "RecipeInfo")]
    public class RecipeInfo : ScriptableObject
    {
        public ObjectInfo Input, Output;        
    }
}
