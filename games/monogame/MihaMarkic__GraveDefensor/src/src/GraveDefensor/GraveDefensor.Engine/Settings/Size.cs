using System;
using System.Xml.Serialization;

namespace GraveDefensor.Engine.Settings
{
    public class Size
    {
        [XmlAttribute]
        public int Width { get; set; }
        [XmlAttribute]
        public int Height { get; set; }
    }
}
