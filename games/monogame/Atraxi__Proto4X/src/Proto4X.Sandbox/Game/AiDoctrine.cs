using Proto4X.Sandbox.Components;

namespace Proto4X.Sandbox.Game
{
    /// <summary>
    /// Every rule an AI faction plays by, and every number it acts on, in one place.
    /// </summary>
    /// <remarks>
    /// <para>The AI is spread over three systems - <c>ExpansionAiSystem</c> (where to put the next
    /// station), <c>EnemyProductionAiSystem</c> (what to spend on) and <c>EnemyFleetAiSystem</c>
    /// (where the fighters go). That split is right, because each one is scoped to a different
    /// archetype query. What it cost was answerability: "why did the enemy do that" meant reading
    /// three files and holding a dozen scattered <c>const</c>s in your head, and two of them
    /// (station spacing, wave size) silently interacted. The constants live here now, and the
    /// systems read them, so a tuning change is one edit in one file and the whole doctrine is
    /// visible at once.</para>
    ///
    /// <para><b>The rules, in the order they are applied.</b> Everything below is a priority
    /// ladder: a faction takes the first rule that fires each frame and ignores the rest.</para>
    ///
    /// <list type="number">
    /// <item><b>Never lose the economy.</b> Below <see cref="MinersKeptWorking"/> miners a faction
    /// builds miners out of any money it has, including money earmarked for a station. A faction
    /// that mines nothing is already dead; expanding cannot be allowed to cause that.</item>
    ///
    /// <item><b>Defend.</b> A hostile ship within <see cref="ThreatRadius"/> of any of a faction's
    /// stations recalls its whole fleet, overriding an attack already in flight. Defence outranks
    /// attack unconditionally - see <c>EnemyFleetAiSystem</c> for why the game decided itself in
    /// the first minute before this existed.</item>
    ///
    /// <item><b>Expand, whenever it can be afforded.</b> There is no station cap. A faction that
    /// holds a station's cost plus <see cref="ExpansionReserve"/>, has more than
    /// <see cref="MinersKeptWorking"/> miners, and can find a legal site sends its nearest free
    /// miner there and founds a base - and the miner is <em>consumed</em> doing it. While it is
    /// saving toward that, production is not allowed to spend the earmarked minerals (rule 4), so
    /// "as soon as it can afford one" is literally true rather than something that happens by
    /// accident when the build queue happens to be full.</item>
    ///
    /// <item><b>Staff the bases, then build a fleet.</b> Up to <see cref="TargetMinersPerStation"/>
    /// miners per station, and everything above that goes on fighters. Each station holds at most
    /// <see cref="MaximumQueueDepth"/> items so income is spent as it arrives rather than sunk into
    /// one station's queue.</item>
    ///
    /// <item><b>Attack once massed.</b> A faction commits to a wave at
    /// <see cref="BaseWaveStrength"/> fighters, plus <see cref="WaveStrengthPerExtraStation"/> per
    /// station beyond the first, capped at <see cref="MaximumWaveStrength"/>. It breaks off when
    /// reduced to a <see cref="WaveBreakOffDivisor"/>th of that. Otherwise fighters loiter at
    /// <see cref="LoiterRadius"/> around the nearest friendly station.</item>
    /// </list>
    ///
    /// <para><b>Site legality</b> is three distance tests, and is the one rule with no exceptions:
    /// a site must be at least <see cref="MinimumStationSpacing"/> from the faction's own stations
    /// <em>and</em> from any site one of its own miners is already flying to, and at least
    /// <see cref="MinimumDistanceFromRivalStations"/> from anyone else's. The second half of the
    /// first test is what actually stops clustering - the AI dispatches a miner frames before the
    /// station exists, so checking only against built stations let it found two bases on top of
    /// each other while the first one was still under construction.</para>
    ///
    /// <para>These rules bind AI factions only. The player may build a station anywhere, at any
    /// spacing, with any economy - the spacing rule is an AI competence floor, not a game rule, and
    /// applying it to the player would read as the UI refusing an order.</para>
    /// </remarks>
    public static class AiDoctrine
    {
        // ---- Expansion -----------------------------------------------------------------------

        /// <summary>
        /// Held on top of the station cost before a faction starts saving in earnest, so founding a
        /// base never leaves it with nothing to rebuild a lost miner with.
        /// </summary>
        public const int ExpansionReserve = 120;

        /// <summary>
        /// The minimum gap between one faction's own stations, and between a station and a site one
        /// of its miners is already travelling to. Closer than this isn't expansion, it's infill.
        /// </summary>
        public const float MinimumStationSpacing = 100f;

        /// <summary>Any nearer to a rival's station than this and we'd be founding a base inside their territory.</summary>
        public const float MinimumDistanceFromRivalStations = 600f;

        /// <summary>How close a miner must get to its build site before it starts assembling.</summary>
        public const float BuildSiteArrivalRadius = 70f;

        /// <summary>
        /// Miners that must still be working after the sacrifice. A faction expands only with
        /// <em>more</em> than this many, because founding a station eats the builder.
        /// </summary>
        /// <remarks>
        /// Doing double duty deliberately: it is also the point at which production stops respecting
        /// the expansion fund. The two readings agree - a faction at the floor is one that must
        /// rebuild before it may expand again - and that agreement is what stops the pair
        /// deadlocking. Saving would otherwise block the very miner that unblocks expanding.
        /// </remarks>
        public const int MinersKeptWorking = 4;

        /// <summary>
        /// How often the frontier scan re-runs. It's a linear sweep over every asteroid against
        /// every station, so it's the one genuinely non-trivial thing the AI does per frame - and a
        /// site that was good a fraction of a second ago is still good now. Cached answers are
        /// re-checked against the spacing rules before use, so a stale one can't be acted on.
        /// </summary>
        public const float SiteSearchIntervalSeconds = 5f;

        // ---- Production ----------------------------------------------------------------------

        public const int TargetMinersPerStation = 8;

        /// <summary>
        /// Items a single station will hold queued. Deliberately shallow: a deep queue is a pile of
        /// minerals committed to one building, which is exactly what the expansion fund wants back.
        /// </summary>
        public const int MaximumQueueDepth = 2;

        // ---- Fleet ---------------------------------------------------------------------------

        /// <summary>Fighters needed before a faction with a single station will commit to a wave.</summary>
        public const int BaseWaveStrength = 8;

        /// <summary>Extra fighters demanded per additional station - see <c>EnemyFleetAiSystem</c> for why stations and not miners.</summary>
        public const int WaveStrengthPerExtraStation = 4;

        /// <summary>Ceiling, so a sprawling empire doesn't set itself a target it can never reach.</summary>
        public const int MaximumWaveStrength = 100;

        /// <summary>A wave breaks off once ground down to this fraction of the strength it launched at.</summary>
        public const int WaveBreakOffDivisor = 3;

        public const float LoiterRadius = 150f;

        /// <summary>How close a hostile ship has to get to a station before the owner calls its fleet home.</summary>
        public const float ThreatRadius = 300f;

        /// <summary>True for the factions this doctrine governs. The player is bound by none of it.</summary>
        public static bool Governs(FactionId faction) => faction != FactionId.Player && faction != FactionId.Neutral;
    }
}
