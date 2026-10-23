using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// Đổi hình vũ khí cầm tay của Player theo món vũ khí đang mặc.
    /// Tự được gắn bởi EquipmentManager, không cần gắn tay.
    /// Không mặc gì (hoặc chơi lại) thì trả về thanh kiếm mặc định.
    /// </summary>
    public class PlayerWeaponVisual : MonoBehaviour
    {
        // Chỉnh các số này nếu vũ khí trông lệch tay
        private const float HoldOffsetX = 0.52f;   // khoảng cách từ người tới tâm vũ khí
        private const float HeldRotationZ = -90f;  // sprite vẽ mũi hướng lên, xoay -90 để hướng theo chiều ngắm

        private PlayerController _player;

        private bool _captured;
        private Sprite _origSprite;
        private Vector3 _origPos;
        private Quaternion _origRot;
        private Vector3 _origScale;
        private Color _origColor;

        private void Start()
        {
            _player = GetComponent<PlayerController>();

            var mgr = EquipmentManager.Instance;
            if (mgr == null) return;

            mgr.OnEquipmentChanged += HandleChanged;

            // Món đầu tiên có thể đã được mặc trước khi component này kịp đăng ký sự kiện
            Apply(mgr.GetEquipped(EquipSlot.Weapon));
        }

        private void OnDestroy()
        {
            if (EquipmentManager.Instance != null)
            {
                EquipmentManager.Instance.OnEquipmentChanged -= HandleChanged;
            }
        }

        private void HandleChanged(EquipSlot slot, EquipmentItem item)
        {
            if (slot == EquipSlot.Weapon) Apply(item);
        }

        private void Apply(EquipmentItem item)
        {
            if (_player == null || _player.weaponRenderer == null) return;

            var wr = _player.weaponRenderer;
            var t = wr.transform;

            // Lưu lại thanh kiếm gốc một lần để còn khôi phục
            if (!_captured)
            {
                _origSprite = wr.sprite;
                _origPos = t.localPosition;
                _origRot = t.localRotation;
                _origScale = t.localScale;
                _origColor = wr.color;
                _captured = true;
            }

            if (item == null)
            {
                wr.sprite = _origSprite;
                wr.color = _origColor;
                t.localPosition = _origPos;
                t.localRotation = _origRot;
                t.localScale = _origScale;
                return;
            }

            wr.sprite = EquipmentIcons.GetWeapon(item.weaponType);
            wr.color = item.RarityColor;
            t.localPosition = new Vector3(HoldOffsetX, 0f, 0f);
            t.localRotation = Quaternion.Euler(0f, 0f, HeldRotationZ);
            t.localScale = Vector3.one * ScaleFor(item.weaponType);
        }

        private static float ScaleFor(WeaponType type)
        {
            switch (type)
            {
                case WeaponType.Spear: return 1.35f;
                case WeaponType.Sword: return 1.1f;
                default: return 1f;
            }
        }
    }
}
