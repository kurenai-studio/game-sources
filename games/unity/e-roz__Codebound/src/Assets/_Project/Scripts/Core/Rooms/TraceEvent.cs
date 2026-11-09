namespace Codebound.Core
{
    public enum TraceEventType
    {
        LineExecuted,
        VariableDeclared,
        ObjectCreated,
        ReferenceAssigned,
        ObjectMutated,
        NullAssigned,
        Output,
        ExceptionThrown,
        ValueSet,
        ItemObjectCreated,
        ItemAdded,
        ListCopied,
        ItemReplaced,
        FieldSet,
        ScopeEnded,
        BoolSet,
        Evaluated,
        IntSet,
        ArraySet,
        OutputAppended,
        TextSet,
        CallReturned,
        LogOpened,
        LogAppended,
        TestRan
    }

    public sealed class TraceEvent
    {
        public const int NoObject = 0;

        TraceEvent(TraceEventType type, int line, string variable, int objectId, string text, int value = 0,
            int other = 0)
        {
            Type = type;
            Line = line;
            Variable = variable ?? string.Empty;
            ObjectId = objectId;
            Text = text ?? string.Empty;
            Value = value;
            Other = other;
        }

        public TraceEventType Type { get; }
        public int Line { get; }
        public string Variable { get; }
        public int ObjectId { get; }
        public string Text { get; }
        public int Value { get; }
        // A second object id, for events that involve two objects (a list and an item, or a list and its source).
        public int Other { get; }

        public static TraceEvent ValueSet(int line, string variable, int value) =>
            new TraceEvent(TraceEventType.ValueSet, line, variable, NoObject, null, value);

        public static TraceEvent LineExecuted(int line) =>
            new TraceEvent(TraceEventType.LineExecuted, line, null, NoObject, null);

        public static TraceEvent VariableDeclared(int line, string variable) =>
            new TraceEvent(TraceEventType.VariableDeclared, line, variable, NoObject, null);

        public static TraceEvent ObjectCreated(int line, int objectId, string typeName) =>
            new TraceEvent(TraceEventType.ObjectCreated, line, null, objectId, typeName);

        public static TraceEvent ReferenceAssigned(int line, string variable, int objectId) =>
            new TraceEvent(TraceEventType.ReferenceAssigned, line, variable, objectId, null);

        public static TraceEvent ObjectMutated(int line, int objectId, string description) =>
            new TraceEvent(TraceEventType.ObjectMutated, line, null, objectId, description);

        public static TraceEvent NullAssigned(int line, string variable) =>
            new TraceEvent(TraceEventType.NullAssigned, line, variable, NoObject, null);

        public static TraceEvent Output(int line, string text) =>
            new TraceEvent(TraceEventType.Output, line, null, NoObject, text);

        public static TraceEvent ExceptionThrown(int line, string exceptionName) =>
            new TraceEvent(TraceEventType.ExceptionThrown, line, null, NoObject, exceptionName);

        // An object that lives inside a list (a Sword), with one number field (Damage).
        public static TraceEvent ItemObjectCreated(int line, int itemId, string typeName, string field, int value) =>
            new TraceEvent(TraceEventType.ItemObjectCreated, line, field, itemId, typeName, value);

        public static TraceEvent ItemAdded(int line, int listId, int itemId) =>
            new TraceEvent(TraceEventType.ItemAdded, line, null, listId, null, 0, itemId);

        // A new list that holds the same item objects as the source list (a shallow copy).
        public static TraceEvent ListCopied(int line, int newListId, int sourceListId, string typeName) =>
            new TraceEvent(TraceEventType.ListCopied, line, null, newListId, typeName, 0, sourceListId);

        public static TraceEvent ItemReplaced(int line, int listId, int index, int newItemId) =>
            new TraceEvent(TraceEventType.ItemReplaced, line, null, listId, null, index, newItemId);

        // A variable goes away, for example a method parameter when the method returns.
        public static TraceEvent ScopeEnded(int line, string variable) =>
            new TraceEvent(TraceEventType.ScopeEnded, line, variable, NoObject, null);

        // A bool variable is declared or changed (a gate rule input or result).
        public static TraceEvent BoolSet(int line, string variable, bool value) =>
            new TraceEvent(TraceEventType.BoolSet, line, variable, NoObject, null, value ? 1 : 0);

        // One step of a rule is worked out, for example "guest && pass" gives false.
        public static TraceEvent Evaluated(int line, string expression, bool result) =>
            new TraceEvent(TraceEventType.Evaluated, line, null, NoObject, expression, result ? 1 : 0);

        // A number variable is declared or changed (a loop counter).
        public static TraceEvent IntSet(int line, string variable, int value) =>
            new TraceEvent(TraceEventType.IntSet, line, variable, NoObject, null, value);

        // An array variable with its contents shown as text, for example "[Thea, Jean, Coco]".
        public static TraceEvent ArraySet(int line, string variable, string contents) =>
            new TraceEvent(TraceEventType.ArraySet, line, variable, NoObject, contents);

        // One more printed item. The output keeps all of them, separated by commas.
        // A variable shown as text, such as a decimal (3.5) that IntSet cannot hold.
        public static TraceEvent TextSet(int line, string variable, string text) =>
            new TraceEvent(TraceEventType.TextSet, line, variable, NoObject, text);

        // A method call and the value it hands back, such as Heal(50) returning 70.
        public static TraceEvent CallReturned(int line, string call, string result) =>
            new TraceEvent(TraceEventType.CallReturned, line, call, NoObject, result);

        // The Log Reader opens. If nothing was logged it shows an empty log.
        public static TraceEvent LogOpened(int line) =>
            new TraceEvent(TraceEventType.LogOpened, line, null, NoObject, null);

        // One line written to the log. Text that starts with ERROR is drawn in red.
        public static TraceEvent LogAppended(int line, string text) =>
            new TraceEvent(TraceEventType.LogAppended, line, null, NoObject, text);

        // One result in the Test Runner: red (failed) or green (passed).
        public static TraceEvent TestRan(int line, string name, bool passed) =>
            new TraceEvent(TraceEventType.TestRan, line, null, NoObject, name, passed ? 1 : 0);

        public static TraceEvent OutputAppended(int line, string text) =>
            new TraceEvent(TraceEventType.OutputAppended, line, null, NoObject, text);

        public static TraceEvent FieldSet(int line, int itemId, string field, int value) =>
            new TraceEvent(TraceEventType.FieldSet, line, field, itemId, null, value);
    }
}
