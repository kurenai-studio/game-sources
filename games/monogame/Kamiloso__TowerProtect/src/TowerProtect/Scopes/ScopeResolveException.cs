using System;
using TowerProtect.Domain.Model.Scopes;

namespace TowerProtect.Scopes;

public class ScopeResolveException(Type type, ScopeType scopeType)
    : InvalidOperationException($"Type '{type}' is not allowed in the '{scopeType}' scope");
