using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// Món đồ rơi trên sàn. Người chơi đi vào sẽ tự mặc nếu mạnh hơn đồ hiện tại,
    /// không thì tự bán lấy vàng.
    /// </summary>
    public class EquipmentPickup : MonoBehaviour
    {
        private EquipmentItem _item;
        private bool _picked;
        private float _baseY;

        /// <summary>Gọi từ code quái khi chết.</summary>
        public static void TryDrop(Vector3 pos, float chance, int floor, bool guaranteed = false)
        {
            if (!guaranteed && Random.value > chance) return;
            Spawn(pos, EquipmentGenerator.Generate(floor));
        }

        public static EquipmentPickup Spawn(Vector3 pos, EquipmentItem item)
        {
            var go = new GameObject("Drop_" + item.itemName);
            go.transform.position = pos;
            go.transform.localScale = Vector3.one * 0.7f;

            // Gắn vào Loot_Container để tự dọn khi sang tầng mới
            if (DungeonManager.Instance != null && DungeonManager.Instance.lootContainer != null)
            {
                go.transform.SetParent(DungeonManager.Instance.lootContainer, true);
            }

            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = EquipmentIcons.Get(item);
            sr.color = item.RarityColor;
            sr.sortingOrder = 9; // trên sàn(0), tường(7), cột(8)

            var col = go.AddComponent<CircleCollider2D>();
            col.isTrigger = true;
            col.radius = 1f;

            var pickup = go.AddComponent<EquipmentPickup>();
            pickup._item = item;
            pickup._baseY = pos.y;
            return pickup;
        }

        private void Update()
        {
            // Nhấp nhô nhẹ cho dễ thấy
            var p = transform.position;
            p.y = _baseY + Mathf.Sin(Time.time * 4f) * 0.08f;
            transform.position = p;
        }

        private void OnTriggerEnter2D(Collider2D other)
        {
            if (_picked || _item == null) return;
            if (!other.CompareTag("Player")) return;

            var stats = other.GetComponentInParent<CombatStats>();
            if (stats == null) return;

            var mgr = EquipmentManager.Get();
            if (mgr == null) return;

            _picked = true;

            if (mgr.TryEquip(_item))
            {
                GameUI.Instance?.ShowBanner("EQUIPPED: " + _item.Describe(), 2.5f);
                AudioManager.Instance?.PlaySound("levelup");
            }
            else
            {
                int gold = _item.SellValue;
                stats.AddGold(gold);
                GameUI.Instance?.ShowBanner($"Sold {_item.itemName} for {gold} gold", 1.8f);
            }

            Destroy(gameObject);
        }
    }
}
