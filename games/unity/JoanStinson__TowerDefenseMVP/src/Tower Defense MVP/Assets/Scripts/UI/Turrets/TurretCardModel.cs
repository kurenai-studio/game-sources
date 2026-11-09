using UnityEngine;

namespace JGM.UI.Turrets
{
    public class TurretCardModel
    {
        public string Id { get; private set; }
        public int Price { get; private set; }
        public Color Color { get; private set; }

        public TurretCardModel(string id, int price, Color color)
        {
            Id = id;
            Price = price;
            Color = color;
        }
    }
}
