using System.Collections.Immutable;
using Analyzers;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.Diagnostics;

// Mirrors the real shape of ArchetypeChunk.Get<T>: a struct-backed, ref-returning accessor.
// Kept inline so this harness needs no reference to the game project at all.
const string Prelude = """
    struct Position
    {
        public float X;
        public float Rotation;
    }

    class Chunk
    {
        private Position[] _values = new Position[8];

        public ref Position Get(int index) => ref _values[index];

        public ref T GetGeneric<T>(int index) where T : struct => throw new System.NotSupportedException();

        public System.Span<T> GetSpan<T>() where T : struct => throw new System.NotSupportedException();
    }

    """;

TestCase[] cases =
[
    new("FlagsPlainLocalCapture", true, """
        class C
        {
            void M(Chunk chunk)
            {
                var pos = chunk.Get(0);
                pos.X = 5;
            }
        }
        """),

    new("FlagsPlainAssignment", true, """
        class C
        {
            void M(Chunk chunk)
            {
                Position field = default;
                field = chunk.Get(1);
            }
        }
        """),

    new("FlagsByValueArgument", true, """
        class C
        {
            static void ArgByValue(Position p) { }

            void M(Chunk chunk)
            {
                ArgByValue(chunk.Get(2));
            }
        }
        """),

    new("AllowsRefLocal", false, """
        class C
        {
            void M(Chunk chunk)
            {
                ref var live = ref chunk.Get(3);
                live.X = 5;
            }
        }
        """),

    new("AllowsDirectMemberMutation", false, """
        class C
        {
            void M(Chunk chunk)
            {
                chunk.Get(4).X = 5;
            }
        }
        """),

    new("AllowsWholeStructAssignmentThroughCall", false, """
        class C
        {
            void M(Chunk chunk)
            {
                chunk.Get(5) = new Position { X = 1 };
            }
        }
        """),

    new("AllowsRefArgument", false, """
        class C
        {
            static void ArgByRef(ref Position p) { }

            void M(Chunk chunk)
            {
                ArgByRef(ref chunk.Get(6));
            }
        }
        """),

    new("AllowsRefReassignment", false, """
        class C
        {
            void M(Chunk chunk)
            {
                ref var reassign = ref chunk.Get(7);
                reassign = ref chunk.Get(0);
            }
        }
        """),

    new("FlagsGenericByValueCapture", true, """
        class C
        {
            void M(Chunk chunk)
            {
                var pos = chunk.GetGeneric<Position>(0);
                pos.X = 5;
            }
        }
        """),

    new("AllowsGenericRefLocal", false, """
        class C
        {
            void M(Chunk chunk)
            {
                ref var pos = ref chunk.GetGeneric<Position>(0);
                pos.X = 5;
            }
        }
        """),

    // --- Known, documented analyzer gap below (not an endorsement) ---
    //
    // Span<T>'s indexer (`span[i]`) also returns `ref T`, exactly like Get<T>(index) does — but it's
    // an ElementAccessExpressionSyntax bound to an IPropertySymbol, not an InvocationExpressionSyntax
    // bound to an IMethodSymbol. RefReturnCopyAnalyzer only walks invocations, so a by-value capture
    // through a span indexer compiles clean and is silently wrong today. (Foreach over the same span
    // without `ref` is *not* a gap: C#'s CS1654 "cannot modify members of a foreach iteration variable"
    // already blocks that at the source, independent of this analyzer.)
    //
    // Extending the analyzer to cover ElementAccessExpressionSyntax/IPropertySymbol is a known, scoped
    // follow-up — this case exists to make the gap explicit and regression-visible rather than silent.
    new("KnownGap_SpanIndexerByValueCapture", false, """
        class C
        {
            void M(Chunk chunk, int i)
            {
                var pos = chunk.GetSpan<Position>()[i];
                pos.X = 5;
            }
        }
        """),
];

var failures = 0;

foreach (var testCase in cases)
{
    var (analyzerDiagnostics, compileErrors) = await AnalyzeAsync(Prelude + testCase.Source);

    if (compileErrors.Length > 0)
    {
        Fail(testCase.Name, $"snippet does not compile: {string.Join("; ", compileErrors.Select(d => d.ToString()))}");
        continue;
    }

    var flagged = analyzerDiagnostics.Any(d => d.Id == RefReturnCopyAnalyzer.DiagnosticId);

    if (flagged != testCase.ExpectDiagnostic)
    {
        Fail(testCase.Name, testCase.ExpectDiagnostic
            ? "expected P4X001, but the analyzer stayed silent"
            : $"expected no diagnostic, but got: {string.Join("; ", analyzerDiagnostics.Select(d => d.ToString()))}");
        continue;
    }

    Pass(testCase.Name);
}

Console.WriteLine();
Console.WriteLine(failures == 0
    ? $"All {cases.Length} cases passed."
    : $"{failures}/{cases.Length} cases FAILED.");

return failures == 0 ? 0 : 1;

void Pass(string name) => Console.WriteLine($"  PASS  {name}");

void Fail(string name, string reason)
{
    failures++;
    Console.WriteLine($"  FAIL  {name}: {reason}");
}

static async Task<(ImmutableArray<Diagnostic> AnalyzerDiagnostics, ImmutableArray<Diagnostic> CompileErrors)> AnalyzeAsync(string source)
{
    var tree = CSharpSyntaxTree.ParseText(source);
    var compilation = CSharpCompilation.Create(
        assemblyName: "AnalyzerHarness",
        syntaxTrees: [tree],
        references: SystemReferences.All.Value,
        options: new CSharpCompilationOptions(OutputKind.DynamicallyLinkedLibrary));

    var compileErrors = compilation.GetDiagnostics()
        .Where(d => d.Severity == DiagnosticSeverity.Error)
        .ToImmutableArray();

    var withAnalyzers = compilation.WithAnalyzers([new RefReturnCopyAnalyzer()]);
    var analyzerDiagnostics = await withAnalyzers.GetAnalyzerDiagnosticsAsync();

    return (analyzerDiagnostics, compileErrors);
}

file static class SystemReferences
{
    // Pull every assembly the running SDK already has loaded rather than adding a reference-assemblies
    // package: the harness only ever needs to compile plain structs/classes over core BCL types.
    public static readonly Lazy<ImmutableArray<MetadataReference>> All = new(() =>
        ((string)AppContext.GetData("TRUSTED_PLATFORM_ASSEMBLIES")!)
            .Split(Path.PathSeparator)
            .Select(path => (MetadataReference)MetadataReference.CreateFromFile(path))
            .ToImmutableArray());
}

record TestCase(string Name, bool ExpectDiagnostic, string Source);
