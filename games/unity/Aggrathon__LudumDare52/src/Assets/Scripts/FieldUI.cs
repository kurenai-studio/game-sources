using UnityEngine;
using UnityEngine.UI;

public class FieldUI : MonoBehaviour
{

    public Field field;
    public Image harvested;
    public Image trampled;

    void Update()
    {
        harvested.fillAmount = (float)field.HarvestedCrops / field.TotalCrops;
        trampled.fillAmount = (float)field.TrampledCrops / field.TotalCrops;
    }
}
