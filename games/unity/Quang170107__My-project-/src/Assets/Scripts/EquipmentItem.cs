using System.Text;
using UnityEngine;

namespace SimpleRPG
{
    public enum EquipSlot { Weapon, Armor, Boots, Ring }
    public enum Rarity { Common, Rare, Epic, Legendary }
    public enum WeaponType { Sword, Blade, Axe, Spear }

    /// <summary>Một món trang bị (dữ liệu thuần, không phải MonoBehaviour).</summary>
    [System.Serializable]
    public class EquipmentItem
    {
        public string itemName;
        public EquipSlot slot;
        public Rarity rarity;
        public WeaponType weaponType; // chỉ dùng khi slot = Weapon

        // Chỉ số cộng thêm
        public float damage;
        public float maxHealth;
        public float armor;
        public float moveSpeed;
        public float attackRate;
        public float lifesteal;
        public float critChance; // vũ khí: cộng thêm tỉ lệ chí mạng (0.05 = 5%)

        /// <summary>Điểm sức mạnh, dùng để so sánh với đồ đang mặc.</summary>
        public float Score =>
            damage * 1f + maxHealth * 0.3f + armor * 4f +
            moveSpeed * 6f + attackRate * 8f + lifesteal * 100f + critChance * 80f;

        /// <summary>Số vàng nhận được nếu bán món đồ (khi không mặc).</summary>
        public int SellValue => Mathf.RoundToInt(Score * 0.5f) + 5;

        public Color RarityColor
        {
            get
            {
                switch (rarity)
                {
                    case Rarity.Rare: return new Color(0.3f, 0.6f, 1f);
                    case Rarity.Epic: return new Color(0.7f, 0.3f, 1f);
                    case Rarity.Legendary: return new Color(1f, 0.6f, 0.1f);
                    default: return new Color(0.85f, 0.85f, 0.85f);
                }
            }
        }

        public string Describe()
        {
            var sb = new StringBuilder();
            sb.Append(itemName);
            if (damage > 0) sb.Append($"  +{damage} DMG");
            if (maxHealth > 0) sb.Append($"  +{maxHealth} HP");
            if (armor > 0) sb.Append($"  +{armor} ARM");
            if (moveSpeed > 0) sb.Append($"  +{moveSpeed} SPD");
            if (attackRate > 0) sb.Append($"  +{attackRate} ATK/s");
            if (lifesteal > 0) sb.Append($"  +{Mathf.RoundToInt(lifesteal * 100)}% LS");
            if (critChance > 0) sb.Append($"  +{Mathf.RoundToInt(critChance * 100)}% CRIT");
            return sb.ToString();
        }
    }

    public static class EquipmentGenerator
    {
        private static readonly string[] WeaponNames = { "Sword", "Blade", "Axe", "Spear" };
        private static readonly string[] ArmorNames = { "Plate", "Mail", "Vest", "Cuirass" };
        private static readonly string[] BootsNames = { "Boots", "Greaves", "Sandals", "Treads" };
        private static readonly string[] RingNames = { "Ring", "Band", "Signet", "Loop" };

        private static readonly string[] CommonPrefix = { "Rusty", "Worn", "Plain", "Sturdy" };
        private static readonly string[] RarePrefix = { "Fine", "Tempered", "Keen", "Reinforced" };
        private static readonly string[] EpicPrefix = { "Runed", "Shadow", "Storm", "Arcane" };
        private static readonly string[] LegendaryPrefix = { "Void", "Dragon", "Eternal", "Sovereign's" };

        public static EquipmentItem Generate(int floor)
        {
            var item = new EquipmentItem();
            item.slot = (EquipSlot)Random.Range(0, 4);

            // Độ hiếm: 3% huyền thoại, 10% sử thi, 27% hiếm, còn lại thường
            float roll = Random.value;
            if (roll < 0.03f) item.rarity = Rarity.Legendary;
            else if (roll < 0.13f) item.rarity = Rarity.Epic;
            else if (roll < 0.40f) item.rarity = Rarity.Rare;
            else item.rarity = Rarity.Common;

            float rarityMult;
            switch (item.rarity)
            {
                case Rarity.Rare: rarityMult = 1.5f; break;
                case Rarity.Epic: rarityMult = 2.2f; break;
                case Rarity.Legendary: rarityMult = 3.2f; break;
                default: rarityMult = 1f; break;
            }

            // Tầng càng cao đồ càng mạnh
            float m = rarityMult * (1f + (Mathf.Max(1, floor) - 1) * 0.12f);

            switch (item.slot)
            {
                case EquipSlot.Weapon:
                    item.damage = Mathf.Round(6f * m);
                    item.attackRate = Mathf.Min(2f, R1(0.2f * m));
                    item.critChance = Mathf.Min(0.2f, Mathf.Round(0.02f * m * 100f) / 100f);
                    break;
                case EquipSlot.Armor:
                    item.armor = R1(1.2f * m);
                    item.maxHealth = Mathf.Round(10f * m);
                    break;
                case EquipSlot.Boots:
                    item.moveSpeed = Mathf.Min(2.5f, R1(0.3f * m));
                    item.maxHealth = Mathf.Round(6f * m);
                    break;
                case EquipSlot.Ring:
                    item.lifesteal = Mathf.Min(0.15f, Mathf.Round(0.02f * m * 100f) / 100f);
                    item.attackRate = Mathf.Min(2f, R1(0.25f * m));
                    break;
            }

            string baseName;
            if (item.slot == EquipSlot.Weapon)
            {
                // WeaponNames có thứ tự trùng với enum WeaponType
                int w = Random.Range(0, WeaponNames.Length);
                item.weaponType = (WeaponType)w;
                baseName = WeaponNames[w];
            }
            else
            {
                baseName = Pick(BaseNamesFor(item.slot));
            }
            item.itemName = Pick(PrefixFor(item.rarity)) + " " + baseName;
            return item;
        }

        private static float R1(float v) => Mathf.Round(v * 10f) / 10f;
        private static string Pick(string[] arr) => arr[Random.Range(0, arr.Length)];

        private static string[] PrefixFor(Rarity r)
        {
            switch (r)
            {
                case Rarity.Rare: return RarePrefix;
                case Rarity.Epic: return EpicPrefix;
                case Rarity.Legendary: return LegendaryPrefix;
                default: return CommonPrefix;
            }
        }

        private static string[] BaseNamesFor(EquipSlot s)
        {
            switch (s)
            {
                case EquipSlot.Weapon: return WeaponNames;
                case EquipSlot.Armor: return ArmorNames;
                case EquipSlot.Boots: return BootsNames;
                default: return RingNames;
            }
        }
    }
}
