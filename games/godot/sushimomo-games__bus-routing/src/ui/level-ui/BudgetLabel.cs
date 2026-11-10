using Godot;
using System;
using static LevelState;

public partial class BudgetLabel : Label
{
    public override void _Ready()
    {
        OnBudgetChanged += UpdateBudgetLabel;
        UpdateBudgetLabel(Budget); // Set initial value
    }

    public override void _ExitTree()
    {
        OnBudgetChanged -= UpdateBudgetLabel;
    }

    private void UpdateBudgetLabel(uint newBudget)
    {
        Text = $"${newBudget}";
    }
}
