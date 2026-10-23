using System;
using System.Collections.Generic;
using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// Gắn trên Player (tự thêm khi nhặt món đầu tiên). Mỗi ô trang bị giữ 1 món,
    /// cộng/trừ chỉ số trực tiếp lên CombatStats.
    /// </summary>
    public class EquipmentManager : MonoBehaviour
    {
        public static EquipmentManager Instance { get; private set; }

        private readonly Dictionary<EquipSlot, EquipmentItem> _equipped = new Dictionary<EquipSlot, EquipmentItem>();
        private CombatStats _stats;

        public event Action<EquipSlot, EquipmentItem> OnEquipmentChanged;

        /// <summary>Lấy manager; nếu chưa có thì tự gắn vào Player.</summary>
        public static EquipmentManager Get()
        {
            if (Instance != null) return Instance;
            if (PlayerController.Instance == null) return null;
            return PlayerController.Instance.gameObject.AddComponent<EquipmentManager>();
        }

        private void Awake()
        {
            Instance = this;
            _stats = GetComponent<CombatStats>();

            // Đổi hình vũ khí cầm tay theo món đang mặc
            if (GetComponent<PlayerWeaponVisual>() == null)
            {
                gameObject.AddComponent<PlayerWeaponVisual>();
            }
        }

        public EquipmentItem GetEquipped(EquipSlot slot)
        {
            _equipped.TryGetValue(slot, out var item);
            return item;
        }

        /// <summary>Mặc đồ nếu ô trống hoặc món mới mạnh hơn. Trả về true nếu đã mặc.</summary>
        public bool TryEquip(EquipmentItem item)
        {
            if (_stats == null || item == null) return false;

            if (_equipped.TryGetValue(item.slot, out var old))
            {
                if (item.Score <= old.Score) return false;
                Remove(old);
            }

            _equipped[item.slot] = item;
            Apply(item);
            _stats.RefreshHealthUI();
            OnEquipmentChanged?.Invoke(item.slot, item);
            return true;
        }

        /// <summary>
        /// Gọi khi chơi lại (sau ResetStats): xóa danh sách đồ mà KHÔNG trừ chỉ số,
        /// vì ResetStats đã đưa chỉ số về mặc định.
        /// </summary>
        public void ForgetAll()
        {
            _equipped.Clear();

            // Báo cho hình vũ khí quay về kiếm mặc định
            foreach (EquipSlot slot in Enum.GetValues(typeof(EquipSlot)))
            {
                OnEquipmentChanged?.Invoke(slot, null);
            }
        }

        private void Apply(EquipmentItem item)
        {
            _stats.baseDamage += item.damage;
            _stats.maxHealth += item.maxHealth;
            _stats.currentHealth += item.maxHealth;
            _stats.armor += item.armor;
            _stats.moveSpeed += item.moveSpeed;
            _stats.attackRate += item.attackRate;
            _stats.lifesteal += item.lifesteal;
            _stats.critChance += item.critChance;
        }

        private void Remove(EquipmentItem item)
        {
            _stats.baseDamage -= item.damage;
            _stats.maxHealth -= item.maxHealth;
            _stats.currentHealth = Mathf.Max(1f, Mathf.Min(_stats.currentHealth - item.maxHealth, _stats.maxHealth));
            _stats.armor -= item.armor;
            _stats.moveSpeed -= item.moveSpeed;
            _stats.attackRate -= item.attackRate;
            _stats.lifesteal -= item.lifesteal;
            _stats.critChance -= item.critChance;
        }
    }
}
