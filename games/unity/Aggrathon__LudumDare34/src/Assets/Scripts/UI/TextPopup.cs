using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class TextPopup : MonoBehaviour {
	private Text text;

	public float startDelay = 2.0f;
	public float lineDelay = 1.0f;
	
	void Start () {
		text = GetComponent<Text>();
		StartCoroutine(Popup());
	}
	
	IEnumerator Popup ()
	{
		string[] lines = text.text.Split('\n');
		text.text = "";
		yield return new WaitForSeconds(startDelay);
		for (int i = 0; i < lines.Length; i++)
		{
			string str = "";
			int j;
            for (j = 0; j < i; j++)
			{
				str += lines[j] + '\n';
			}
			str += lines[j];
			for (int k = j+1; k < lines.Length; k++)
			{
				str += '\n';
			}
			text.text = str;
			yield return new WaitForSeconds(lineDelay);
		} 
	}
}
