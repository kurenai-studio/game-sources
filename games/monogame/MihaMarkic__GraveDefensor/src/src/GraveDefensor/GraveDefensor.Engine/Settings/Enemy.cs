using System.Xml.Serialization;

namespace GraveDefensor.Engine.Settings
{
    public abstract class Enemy
    {
        [XmlAttribute]
        public string Name { get; set; }
        /// <summary>
        /// Expressed in pixels per second
        /// </summary>
        [XmlAttribute]
        public int Speed { get; set; }
        [XmlAttribute]
        public int Health { get; set; }
        [XmlAttribute]
        public int Award { get; set; }
    }
}
