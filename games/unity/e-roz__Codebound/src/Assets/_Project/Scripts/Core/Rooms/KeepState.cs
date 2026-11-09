using System.Collections.Generic;

namespace Codebound.Core
{
    public sealed class GuardState
    {
        public GuardState(string name) => Name = name;

        public string Name { get; }
        public int ObjectId { get; internal set; }
        public bool IsNull { get; internal set; }
        public int? Value { get; internal set; }
    }

    public sealed class ChestState
    {
        public ChestState(int id, string typeName)
        {
            Id = id;
            TypeName = typeName;
        }

        public int Id { get; }
        public string TypeName { get; }
        readonly List<string> _items = new List<string>();
        readonly List<int> _itemObjects = new List<int>();

        // Plain items such as "Sword" (rooms 1.1 to 1.3).
        public IReadOnlyList<string> Items => _items;
        // Ids of item objects held by reference (room 1.4).
        public IReadOnlyList<int> ItemObjects => _itemObjects;
        public int ItemCount => _items.Count + _itemObjects.Count;

        internal void Add(string item) => _items.Add(item);
        internal void Remove(string item) => _items.Remove(item);
        public bool HoldsObject(int itemId)
        {
            foreach (var id in _itemObjects)
                if (id == itemId) return true;
            return false;
        }

        internal void AddObject(int itemId) => _itemObjects.Add(itemId);

        internal void ReplaceObject(int index, int itemId)
        {
            if (index >= 0 && index < _itemObjects.Count) _itemObjects[index] = itemId;
        }

        internal void CopyFrom(ChestState source)
        {
            _items.AddRange(source._items);
            _itemObjects.AddRange(source._itemObjects);
        }
    }

    // A bool variable with its current value.
    public sealed class BoolVariableState
    {
        public BoolVariableState(string name, bool value)
        {
            Name = name;
            Value = value;
        }

        public string Name { get; }
        public bool Value { get; internal set; }
    }

    // A number variable such as a loop counter.
    public sealed class NumberVariableState
    {
        public NumberVariableState(string name, int value)
        {
            Name = name;
            Value = value;
        }

        public string Name { get; }
        public int Value { get; internal set; }
    }

    // An array variable, shown as text such as "[Thea, Jean, Coco] (slots 0 to 2)".
    public sealed class ArrayVariableState
    {
        public ArrayVariableState(string name, string contents)
        {
            Name = name;
            Contents = contents;
        }

        public string Name { get; }
        public string Contents { get; internal set; }
    }

    // One worked-out step of a rule, such as "guest && pass" giving false.
    public sealed class EvaluationStep
    {
        public EvaluationStep(string expression, bool result)
        {
            Expression = expression;
            Result = result;
        }

        public string Expression { get; }
        public bool Result { get; }
    }

    // An object held inside a list, with one number field.
    public sealed class ItemObjectState
    {
        public ItemObjectState(int id, string typeName, string field, int value)
        {
            Id = id;
            TypeName = typeName;
            Field = field;
            Value = value;
        }

        public int Id { get; }
        public string TypeName { get; }
        public string Field { get; }
        public int Value { get; internal set; }

        public string Describe() => $"{TypeName} #{Id} ({Field} {Value})";
    }

    public enum ReportKind { Log, Error, Red, Green }

    // One line of the Log Reader or the Test Runner.
    public sealed class ReportLine
    {
        public ReportLine(string text, ReportKind kind)
        {
            Text = text;
            Kind = kind;
        }

        public string Text { get; }
        public ReportKind Kind { get; }
    }

    // What the Keep looks like after the trace events played so far. The view only draws this.
    public sealed class KeepState
    {
        readonly List<GuardState> _guards = new List<GuardState>();
        readonly List<ChestState> _chests = new List<ChestState>();
        readonly List<ItemObjectState> _itemObjects = new List<ItemObjectState>();
        readonly List<BoolVariableState> _boolVariables = new List<BoolVariableState>();
        readonly List<EvaluationStep> _steps = new List<EvaluationStep>();
        readonly List<string> _calls = new List<string>();
        readonly List<ReportLine> _report = new List<ReportLine>();
        readonly List<NumberVariableState> _numberVariables = new List<NumberVariableState>();
        readonly List<ArrayVariableState> _arrayVariables = new List<ArrayVariableState>();

        public IReadOnlyList<GuardState> Guards => _guards;
        public IReadOnlyList<ChestState> Chests => _chests;
        public IReadOnlyList<BoolVariableState> BoolVariables => _boolVariables;
        public IReadOnlyList<EvaluationStep> Steps => _steps;
        public IReadOnlyList<string> Calls => _calls;
        // The Log Reader / Test Runner panel. HasReport is true once it was opened, even with no lines.
        public IReadOnlyList<ReportLine> Report => _report;
        public bool HasReport { get; private set; }
        public IReadOnlyList<NumberVariableState> NumberVariables => _numberVariables;
        public IReadOnlyList<ArrayVariableState> ArrayVariables => _arrayVariables;
        // True when the Keep shows text rows (rooms about rules and loops) instead of guards and chests.
        public bool HasRows => _boolVariables.Count + _numberVariables.Count + _arrayVariables.Count + _steps.Count + _calls.Count > 0;
        public int CurrentLine { get; private set; }
        public string Output { get; private set; } = string.Empty;
        public string Error { get; private set; } = string.Empty;
        public string Caption { get; private set; } = string.Empty;

        public int ChestIndex(int objectId)
        {
            for (var i = 0; i < _chests.Count; i++)
                if (_chests[i].Id == objectId) return i;
            return -1;
        }

        public IReadOnlyList<string> DescribeItems(ChestState chest)
        {
            var items = new List<string>(chest.Items);
            foreach (var id in chest.ItemObjects)
            {
                var item = FindItemObject(id);
                if (item != null) items.Add(item.Describe());
            }
            return items;
        }

        string TypeName(int objectId)
        {
            var index = ChestIndex(objectId);
            return index >= 0 ? _chests[index].TypeName : "Chest";
        }

        string Noun(int objectId) => TypeName(objectId).ToLowerInvariant();

        public IReadOnlyList<string> WatchLines()
        {
            var lines = new List<string>();
            foreach (var guard in _guards)
                lines.Add(guard.Value.HasValue ? $"{guard.Name} = {guard.Value.Value}"
                    : guard.IsNull ? $"{guard.Name} -> null"
                    : guard.ObjectId != TraceEvent.NoObject ? $"{guard.Name} -> {Noun(guard.ObjectId)} #{guard.ObjectId}"
                    : $"{guard.Name} -> (nothing yet)");
            foreach (var item in _itemObjects)
            {
                var holders = new List<string>();
                foreach (var chest in _chests)
                    if (chest.HoldsObject(item.Id)) holders.Add($"list #{chest.Id}");
                if (holders.Count > 0)
                    lines.Add($"{item.TypeName.ToLowerInvariant()} #{item.Id}: {item.Field} {item.Value} (in {string.Join(" and ", holders)})");
            }
            foreach (var variable in _boolVariables)
                lines.Add($"{variable.Name} = {Word(variable.Value)}");
            foreach (var array in _arrayVariables)
                lines.Add($"{array.Name} = {array.Contents}");
            foreach (var number in _numberVariables)
                lines.Add($"{number.Name} = {number.Value}");
            for (var i = 0; i < _steps.Count; i++)
                lines.Add($"step {i + 1}: {_steps[i].Expression} = {Word(_steps[i].Result)}");
            lines.AddRange(_calls);
            return lines;
        }

        static string Word(bool value) => value ? "true" : "false";

        public void Clear()
        {
            _guards.Clear();
            _chests.Clear();
            _itemObjects.Clear();
            _boolVariables.Clear();
            _steps.Clear();
            _calls.Clear();
            _report.Clear();
            HasReport = false;
            _numberVariables.Clear();
            _arrayVariables.Clear();
            CurrentLine = 0;
            Output = string.Empty;
            Error = string.Empty;
            Caption = string.Empty;
        }

        public void Apply(TraceEvent e)
        {
            switch (e.Type)
            {
                case TraceEventType.LineExecuted:
                    CurrentLine = e.Line;
                    Caption = $"Line {e.Line} runs.";
                    break;
                case TraceEventType.VariableDeclared:
                    if (FindGuard(e.Variable) == null) _guards.Add(new GuardState(e.Variable));
                    Caption = $"{e.Variable} is a new guard. It holds nothing yet.";
                    break;
                case TraceEventType.ObjectCreated:
                    _chests.Add(new ChestState(e.ObjectId, e.Text));
                    Caption = $"A new {e.Text} appears (#{e.ObjectId}).";
                    break;
                case TraceEventType.ReferenceAssigned:
                    var target = FindGuard(e.Variable);
                    if (target != null)
                    {
                        target.ObjectId = e.ObjectId;
                        target.IsNull = false;
                    }
                    Caption = $"{e.Variable} now points to {Noun(e.ObjectId)} #{e.ObjectId}.";
                    break;
                case TraceEventType.NullAssigned:
                    var nulled = FindGuard(e.Variable);
                    if (nulled != null)
                    {
                        nulled.ObjectId = TraceEvent.NoObject;
                        nulled.IsNull = true;
                    }
                    Caption = $"{e.Variable} points to nothing (null).";
                    break;
                case TraceEventType.ObjectMutated:
                    var index = ChestIndex(e.ObjectId);
                    if (index >= 0) ApplyItemChange(_chests[index], e.Text);
                    Caption = $"{TypeName(e.ObjectId)} #{e.ObjectId}: {e.Text}.";
                    break;
                case TraceEventType.ValueSet:
                    var holder = FindGuard(e.Variable);
                    if (holder != null) holder.Value = e.Value;
                    Caption = $"{e.Variable} now holds {e.Value}.";
                    break;
                case TraceEventType.ItemObjectCreated:
                    _itemObjects.Add(new ItemObjectState(e.ObjectId, e.Text, e.Variable, e.Value));
                    Caption = $"A new {e.Text} appears (#{e.ObjectId}). {e.Variable} is {e.Value}.";
                    break;
                case TraceEventType.ItemAdded:
                    var holder1 = ChestIndex(e.ObjectId);
                    if (holder1 >= 0) _chests[holder1].AddObject(e.Other);
                    Caption = $"{ItemName(e.Other)} goes into list #{e.ObjectId}.";
                    break;
                case TraceEventType.ListCopied:
                    var source = ChestIndex(e.Other);
                    var copy = new ChestState(e.ObjectId, e.Text);
                    if (source >= 0) copy.CopyFrom(_chests[source]);
                    _chests.Add(copy);
                    Caption = $"List #{e.ObjectId} copies list #{e.Other}. It holds the same objects.";
                    break;
                case TraceEventType.ItemReplaced:
                    var owner = ChestIndex(e.ObjectId);
                    if (owner >= 0) _chests[owner].ReplaceObject(e.Value, e.Other);
                    Caption = $"List #{e.ObjectId} now holds {ItemName(e.Other)} in slot {e.Value}.";
                    break;
                case TraceEventType.FieldSet:
                    var changed = FindItemObject(e.ObjectId);
                    if (changed != null) changed.Value = e.Value;
                    Caption = $"{ItemName(e.ObjectId)}: {e.Variable} = {e.Value}.";
                    break;
                case TraceEventType.ScopeEnded:
                    _guards.Remove(FindGuard(e.Variable));
                    Caption = $"{e.Variable} goes away. The method has ended.";
                    break;
                case TraceEventType.BoolSet:
                    var flag = FindBool(e.Variable);
                    if (flag == null) _boolVariables.Add(new BoolVariableState(e.Variable, e.Value != 0));
                    else flag.Value = e.Value != 0;
                    Caption = $"{e.Variable} is {Word(e.Value != 0)}.";
                    break;
                case TraceEventType.Evaluated:
                    _steps.Add(new EvaluationStep(e.Text, e.Value != 0));
                    Caption = $"{e.Text} gives {Word(e.Value != 0)}.";
                    break;
                case TraceEventType.IntSet:
                    var number = FindNumber(e.Variable);
                    if (number == null) _numberVariables.Add(new NumberVariableState(e.Variable, e.Value));
                    else number.Value = e.Value;
                    Caption = $"{e.Variable} is {e.Value}.";
                    break;
                case TraceEventType.ArraySet:
                    var array = FindArray(e.Variable);
                    if (array == null) _arrayVariables.Add(new ArrayVariableState(e.Variable, e.Text));
                    else array.Contents = e.Text;
                    Caption = $"{e.Variable} holds {e.Text}.";
                    break;
                case TraceEventType.LogOpened:
                    HasReport = true;
                    Caption = "The log has no entries.";
                    break;
                case TraceEventType.LogAppended:
                    HasReport = true;
                    _report.Add(new ReportLine(e.Text, e.Text.StartsWith("ERROR") ? ReportKind.Error : ReportKind.Log));
                    Caption = $"The log says: {e.Text}.";
                    break;
                case TraceEventType.TestRan:
                    HasReport = true;
                    _report.Add(new ReportLine(e.Text, e.Value != 0 ? ReportKind.Green : ReportKind.Red));
                    Caption = $"Test {e.Text} is {(e.Value != 0 ? "green" : "red")}.";
                    break;
                case TraceEventType.CallReturned:
                    _calls.Add($"{e.Variable} returns {e.Text}");
                    Caption = $"{e.Variable} returns {e.Text}.";
                    break;
                case TraceEventType.TextSet:
                    var text = FindArray(e.Variable);
                    if (text == null) _arrayVariables.Add(new ArrayVariableState(e.Variable, e.Text));
                    else text.Contents = e.Text;
                    Caption = $"{e.Variable} is {e.Text}.";
                    break;
                case TraceEventType.OutputAppended:
                    Output = Output.Length == 0 ? e.Text : $"{Output}, {e.Text}";
                    Caption = $"The program prints {e.Text}.";
                    break;
                case TraceEventType.Output:
                    Output = e.Text;
                    Caption = $"The program prints {e.Text}.";
                    break;
                case TraceEventType.ExceptionThrown:
                    Error = e.Text;
                    Caption = $"{e.Text}! The program stops.";
                    break;
            }
        }

        // ObjectMutated text is written as "<item> added" or "<item> removed".
        static void ApplyItemChange(ChestState chest, string text)
        {
            const string added = " added";
            const string removed = " removed";
            if (text.EndsWith(added)) chest.Add(text.Substring(0, text.Length - added.Length));
            else if (text.EndsWith(removed)) chest.Remove(text.Substring(0, text.Length - removed.Length));
        }

        NumberVariableState FindNumber(string name)
        {
            foreach (var variable in _numberVariables)
                if (variable.Name == name) return variable;
            return null;
        }

        ArrayVariableState FindArray(string name)
        {
            foreach (var variable in _arrayVariables)
                if (variable.Name == name) return variable;
            return null;
        }

        BoolVariableState FindBool(string name)
        {
            foreach (var variable in _boolVariables)
                if (variable.Name == name) return variable;
            return null;
        }

        ItemObjectState FindItemObject(int id)
        {
            foreach (var item in _itemObjects)
                if (item.Id == id) return item;
            return null;
        }

        string ItemName(int id)
        {
            var item = FindItemObject(id);
            return item != null ? $"{item.TypeName} #{id}" : $"Object #{id}";
        }

        GuardState FindGuard(string name)
        {
            foreach (var guard in _guards)
                if (guard.Name == name) return guard;
            return null;
        }
    }
}
