using System.Xml.Serialization;

namespace GraveDefensor.Engine.Settings
{
    public class Path
    {
        [XmlAttribute]
        public string Id { get; set; }
        public Point[] Points { get; set; }
    }
}
