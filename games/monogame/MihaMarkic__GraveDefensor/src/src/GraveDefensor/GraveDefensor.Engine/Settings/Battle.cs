
using System.Xml.Serialization;

namespace GraveDefensor.Engine.Settings
{
    public class Battle
    {
        [XmlAttribute]
        public string Background { get; set; }
        [XmlAttribute]
        public int Health { get; set; }
        [XmlAttribute]
        public int Amount { get; set; }
        public Path[] Paths { get; set; }
        public WeaponPod[] WeaponPlaces { get; set; }
        public EnemyWave[] Waves { get; set; }
        public string[] WeaponNames { get; set; }
    }
}
