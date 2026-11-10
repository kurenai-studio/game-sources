using AnatomyJam.Material;
using AnatomyJam.SO;
using UnityEngine;

namespace AnatomyJam.SceneObjects
{
    public class SceneObject : MonoBehaviour
    {
        public GameObject GameObject { set; get; }
        public ResourceType Resource { set; get; }
        public Gem Gem { private set; get; }
        public Metal Metal { private set; get; }

        public void Init(ObjectInfo info, GameObject gameObject)
        {
            Resource = info.ResourceType;
            Gem = info.Gem;
            Metal = info.Metal;
            GameObject = gameObject;
        }

        public void DestroyObject()
        {
            Destroy(GameObject);
            GameObject = null;
        }
    }
}
