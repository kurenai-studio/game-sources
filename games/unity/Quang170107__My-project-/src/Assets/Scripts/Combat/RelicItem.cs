using System;
using UnityEngine;

namespace SimpleRPG
{
    public enum RelicType
    {
        ThunderConduit,  // ⚡ Sét truyền: đòn đánh tạo tia sét nhảy qua tối đa 3 quái gần đó
        ToxicFang,       // 🧪 Nanh độc: đòn đánh gây sát thương độc trong 3 giây
        FrostCore,       // ❄️ Lõi băng: đòn chí mạng làm chậm quái 50%
        DivineAegis,     // 🛡️ Khiên thần: tạo lớp chắn chặn hoàn toàn 1 đòn đánh, hồi sau 12s
        BloodChalice,    // 🩸 Chén huyết: hạ quái có tỉ lệ rơi ngọc máu hồi 15 HP
        CombustionSigil  // 💥 Dấu ấn nổ: quái chết phát nổ gây sát thương diện rộng
    }

    [System.Serializable]
    public class RelicItem
    {
        public RelicType type;
        public string relicName;
        public string description;
        public Color themeColor;
        public string iconSymbol;

        public RelicItem(RelicType t)
        {
            type = t;
            switch (t)
            {
                case RelicType.ThunderConduit:
                    relicName = "Thunder Conduit";
                    description = "Hits zap chain lightning to up to 3 nearby foes.";
                    themeColor = new Color(0.3f, 0.85f, 1f);
                    iconSymbol = "⚡";
                    break;
                case RelicType.ToxicFang:
                    relicName = "Toxic Fang";
                    description = "Attacks inflict corrosive poison dealing damage over 3s.";
                    themeColor = new Color(0.4f, 0.95f, 0.2f);
                    iconSymbol = "🧪";
                    break;
                case RelicType.FrostCore:
                    relicName = "Frost Core";
                    description = "Critical strikes freeze enemies, slowing movement by 50%.";
                    themeColor = new Color(0.6f, 0.9f, 1f);
                    iconSymbol = "❄️";
                    break;
                case RelicType.DivineAegis:
                    relicName = "Divine Aegis";
                    description = "Forms a sacred barrier absorbing 1 hit every 12 seconds.";
                    themeColor = new Color(1f, 0.85f, 0.3f);
                    iconSymbol = "🛡️";
                    break;
                case RelicType.BloodChalice:
                    relicName = "Blood Chalice";
                    description = "Slain foes have a 25% chance to drop blood orbs healing 15 HP.";
                    themeColor = new Color(0.95f, 0.2f, 0.3f);
                    iconSymbol = "🩸";
                    break;
                case RelicType.CombustionSigil:
                    relicName = "Combustion Sigil";
                    description = "Defeated monsters detonate in a fiery burst damaging adjacent foes.";
                    themeColor = new Color(1f, 0.45f, 0.1f);
                    iconSymbol = "💥";
                    break;
            }
        }
    }
}
