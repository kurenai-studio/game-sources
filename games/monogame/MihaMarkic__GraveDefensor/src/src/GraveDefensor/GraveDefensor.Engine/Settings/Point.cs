using System.Xml.Serialization;

namespace GraveDefensor.Engine.Settings
{
    public class Point
    {
        [XmlAttribute]
        public int X { get; set; }
        [XmlAttribute]
        public int Y { get; set; }
    }
}
