
public abstract class SquadController : ITurnTaker
{
	protected int maxSquadsMoves = 4;
    protected int squadsMoved = 0;

	public int GetMovesLeft()
	{
		return this.maxSquadsMoves - this.squadsMoved;
	}

    public abstract void TakeTurn();
    public bool IsTurnFinished()
    {
		UIManager.Instance.SetMovesLeftText(GetMovesLeft());
		if (this.squadsMoved >= this.maxSquadsMoves)
		{
			this.squadsMoved = 0;
			return true;
		}
		else
		{
			return false;
		}
	}
}
