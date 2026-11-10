using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class TypeTheCommand : MonoBehaviour
{
    public GameObject infoText;
    public GameObject timer;
    public TMP_InputField inputField;
    private string command;

    public List<string> commands = new List<string>()
    {
        "/fix_all_errors",
        "-fix-all-errors",
        "FIX_ALL-ERRORS",
        "fix@llerrors",
        "f-i-x-a-l-l-e-r-r-o-r-s",
        "/fix/all/errors",
        "fix_all_errors;"
    };

    void Start()
    {
        GenCommandToType();
        inputField.onSubmit.AddListener(OnSubmitAction);
        inputField.ActivateInputField();
        inputField.Select();
        G.AllRepStopped += OnFailed;
    }

    void Update()
    {
        if (G.GetOvertimedBreakings().Contains(GetComponent<TaskChars>().breakingType))
        {
            OnFailed();
        }

        float time = 0f;
        if (G.breakings_timers.ContainsKey(GetComponent<TaskChars>().breakingType))
            time = (G.BREAKING_TIME - G.breakings_timers[GetComponent<TaskChars>().breakingType]);

        if (time < 0)
        {
            time = 0f;
            OnFailed();
        }

        timer.GetComponent<TextMeshProUGUI>().text = time.ToString("F1");
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Close();
        }
    }

    public void Submit()
    {
        Debug.Log(inputField.text);

        if (inputField.text == command)
        {
            G.breakings.Remove(gameObject.GetComponent<TaskChars>().breakingType);
            G.breakings_timers.Remove(gameObject.GetComponent<TaskChars>().breakingType);
            G.OnBreakingUpdated();
            G.OnSuccessed();
            Close();
        }
        else
        {
            G.OnErrored();
            Debug.LogError("WRONG!");
            GenCommandToType();
        }

        inputField.text = "";
        inputField.ActivateInputField();
        inputField.Select();
    }

    void OnSubmitAction(string text)
    {
        Submit();
    }

    private void GenCommandToType()
    {
        command = commands[Random.Range(0, commands.Count)];
        infoText.GetComponent<TextMeshProUGUI>().text = "Type the command\n\"" + command + "\"\nto fix all errors";
    }

    public void Close()
    {
        G.OnBreakingClosed();
        Destroy(gameObject);
    }

    private void OnFailed()
    {
        G.breakings.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.breakings_timers.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        Main2.BreakingsList.Remove(gameObject.GetComponent<TaskChars>().breakingType);
        G.player_hp -= 20;
        G.OnBreakingUpdated();
        G.OnFailed();
        Close();
    }
}
