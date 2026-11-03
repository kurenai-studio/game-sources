using System.Xml.Serialization;

namespace GraveDefensor.Engine.Settings
{
    public abstract class Weapon
    {
        [XmlAttribute]
        public string Name { get; set; }
        [XmlAttribute]
        public int Price { get; set; }
        [XmlAttribute]
        public int FiringRange { get; set; }
        [XmlAttribute]
        public int TrackingRange { get; set; }
        [XmlAttribute]
        public int Power { get; set; }
        [XmlAttribute]
        public bool AirCapability { get; set; }
        [XmlAttribute]
        public bool GroundCapability { get; set; }
        /// <summary>
        /// Reload time in milliseconds
        /// </summary>
        [XmlAttribute]
        public int ReloadTime { get; set; }
        /// <summary>
        /// Total time of firing in milliseconds
        /// </summary>
        [XmlAttribute]
        public int FiringTime { get; set; }
    }

    public abstract class RotationalWeapon: Weapon
    {
        /// <summary>
        /// Rounds per second
        /// </summary>
        [XmlAttribute]
        public int RotationalSpeed { get; set; }
        //[XmlAttribute]
        public int? CenterOffsetX { get; set; }
        //[XmlAttribute]
        public int? CenterOffsetY { get; set; }
    }

    public class MiniGun : RotationalWeapon
    {

    }

    public class Vulcan : RotationalWeapon
    {

    }

    public class Cannon : RotationalWeapon
    {

    }
}
