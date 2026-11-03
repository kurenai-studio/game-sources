using System.Collections.Immutable;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.Diagnostics;

namespace Analyzers;

/// <summary>
/// Flags calls to a `ref T`-returning method (e.g. ArchetypeChunk.Get&lt;T&gt;) whose result is
/// captured by value instead of by reference — the classic "silent struct copy" bug where mutations
/// never reach the backing component array.
/// </summary>
[DiagnosticAnalyzer(LanguageNames.CSharp)]
public sealed class RefReturnCopyAnalyzer : DiagnosticAnalyzer
{
    public const string DiagnosticId = "P4X001";

    private static readonly DiagnosticDescriptor Rule = new(
        DiagnosticId,
        title: "Ref-returning call captured by value",
        messageFormat: "'{0}' returns a ref but the result is captured by value here; writes to the local won't reach the underlying storage. Use 'ref var x = ref ...', mutate through the call directly, or pass it with 'ref'.",
        category: "Reliability",
        defaultSeverity: DiagnosticSeverity.Error,
        isEnabledByDefault: true,
        description: "Component accessors that return 'ref T' over array-backed storage must be consumed via a ref local, a ref argument, or a direct member-access/assignment chain. Assigning the result to a plain local silently copies the struct.");

    public override ImmutableArray<DiagnosticDescriptor> SupportedDiagnostics => ImmutableArray.Create(Rule);

    public override void Initialize(AnalysisContext context)
    {
        context.ConfigureGeneratedCodeAnalysis(GeneratedCodeAnalysisFlags.None);
        context.EnableConcurrentExecution();
        context.RegisterSyntaxNodeAction(AnalyzeInvocation, SyntaxKind.InvocationExpression);
    }

    private static void AnalyzeInvocation(SyntaxNodeAnalysisContext context)
    {
        var invocation = (InvocationExpressionSyntax)context.Node;

        if (context.SemanticModel.GetSymbolInfo(invocation, context.CancellationToken).Symbol is not IMethodSymbol { ReturnsByRef: true } method)
        {
            return;
        }

        // Unwrap `ref someCall()` — the RefExpression is what marks an intentional by-ref capture
        // in a local declaration or assignment.
        ExpressionSyntax effectiveNode = invocation;
        SyntaxNode? parent = invocation.Parent;
        var isRefWrapped = false;
        if (parent is RefExpressionSyntax refExpr)
        {
            effectiveNode = refExpr;
            parent = refExpr.Parent;
            isRefWrapped = true;
        }

        switch (parent)
        {
            // ref var x = ref Get<T>(i);   vs.   var x = Get<T>(i);
            case EqualsValueClauseSyntax { Parent: VariableDeclaratorSyntax { Parent: VariableDeclarationSyntax varDecl } }:
                var isRefLocal = varDecl.Type is RefTypeSyntax;
                if (isRefLocal != isRefWrapped)
                {
                    // `ref var x = Get<T>(i)` and `var x = ref Get<T>(i)` are both compile errors
                    // (CS8172 / CS8374) — nothing to add on top of what the compiler already says.
                    return;
                }
                if (!isRefLocal)
                {
                    Report(context, invocation, method);
                }
                break;

            // x = ref Get<T>(i);   vs.   x = Get<T>(i);
            // (Get<T>(i) = newValue, i.e. our call as the assignment TARGET, mutates storage
            // directly and correctly falls through to the default: no diagnostic.)
            case AssignmentExpressionSyntax { Right: var right } when right == effectiveNode:
                if (!isRefWrapped)
                {
                    Report(context, invocation, method);
                }
                break;

            // Foo(Get<T>(i))  vs.  Foo(ref Get<T>(i))
            case ArgumentSyntax argument:
                if (argument.RefKindKeyword.IsKind(SyntaxKind.None))
                {
                    Report(context, invocation, method);
                }
                break;

            // Anything else — Get<T>(i).Field = x, Get<T>(i) = newValue, return ref Get<T>(i),
            // a ref foreach source, etc. — touches the storage directly. Nothing to flag.
            default:
                break;
        }
    }

    private static void Report(SyntaxNodeAnalysisContext context, InvocationExpressionSyntax invocation, IMethodSymbol method)
    {
        context.ReportDiagnostic(Diagnostic.Create(Rule, invocation.GetLocation(), method.Name));
    }
}
