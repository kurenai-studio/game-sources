
public interface IReplayable {
	public void ReplayData(int frame, object[] data);
	public object[] CollectData();
	public void ReplayReset();
	public void ReplayEnded();
}
