
using System.Diagnostics;
using System.Xml.Serialization;

namespace GraveDefensor.Engine.Settings
{
    [DebuggerDisplay("{Id,nq}")]
    public class EnemySet
    {
        [XmlAttribute]
        public string Id { get; set; }
        [XmlAttribute]
        public string PathId { get; set; }
        [XmlAttribute]
        public string EnemyId { get; set; }
        [XmlAttribute]
        public int StartTimeOffset { get; set; }
        /// <summary>
        /// Expressed in milliseconds
        /// </summary>
        [XmlAttribute]
        public int Interval { get; set; }
        [XmlAttribute]
        public int EnemiesCount { get; set; }
    }
}
