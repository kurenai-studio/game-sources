using UnityEngine;
using System.Collections;

namespace Assets.Scripts.Helpers
{
    public class SpriteRepeater : MonoBehaviour
    {

        SpriteRenderer sprite;
        public int orderInLayer;

        void Awake()
        {
            // Get the current sprite with an unscaled size
            sprite = GetComponent<SpriteRenderer>();
            Vector2 spriteSize = new Vector2(sprite.bounds.size.x / transform.localScale.x, sprite.bounds.size.y / transform.localScale.y);
            Debug.Log(sprite.bounds.size);

            // Generate a child prefab of the sprite renderer
            GameObject childPrefab = new GameObject();
            SpriteRenderer childSprite = childPrefab.AddComponent<SpriteRenderer>();
            childPrefab.transform.position = this.transform.position;
            childSprite.sprite = sprite.sprite;
            childSprite.sortingLayerName = "Background";
            childSprite.sortingOrder = this.orderInLayer;

            int xRepeats = Mathf.RoundToInt(this.transform.localScale.x);
            int yRepeats = Mathf.RoundToInt(this.transform.localScale.y);

            GameObject child;

            for (int y = 0; y < yRepeats; y++)
            {
                for (int x = 0; x < xRepeats; x++)
                {
                    Vector3 position = new Vector3(x * spriteSize.x, -y * spriteSize.y, 0);
                    child = Instantiate(childPrefab) as GameObject;
                    child.transform.parent = this.transform;
                    Debug.Log("Parent " + child.transform.position);

                    child.transform.Translate(position);
                    Debug.Log("Set " + child.transform.position);

                }
            }

            this.sprite.enabled = false;
            childSprite.enabled = false;
        }
    }
}