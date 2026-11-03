using System.Diagnostics;
using System.Xml.Serialization;

namespace GraveDefensor.Engine.Settings
{
    [DebuggerDisplay("{Id,nq}")]
    public class EnemyWave
    {
        [XmlAttribute]
        public string Id { get; set; }
        /// <summary>
        /// Time to start after previous wave finishes in milliseconds.
        /// </summary>
        [XmlAttribute]
        public int TimeOffsetToPrevious { get; set; }
        public EnemySet[] Sets { get; set; }
    }
}
