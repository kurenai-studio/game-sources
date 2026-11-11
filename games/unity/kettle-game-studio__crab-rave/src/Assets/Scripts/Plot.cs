using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using TMPro;
using UnityEngine;
using UnityEngine.InputSystem;

public class Plot : MonoBehaviour
{
    public Collider OganesyanProtection;
    public PlayerController playerController;
    public TextMeshProUGUI shellText;
    public TextMeshProUGUI crabText;
    public TextMeshProUGUI questText;
    public AudioSource blablaAudio;
    public Credits credits;
    public int shells = 0;
    public int gems = 0;

    public int totalShells;
    public int totalGems;

    public void RemoveText()
    {
        shellText.enabled = false;
        crabText.enabled = false;
        questText.enabled = false;
    }

    public void ReturnText()
    {
        shellText.enabled = true;
        crabText.enabled = true;
        questText.enabled = true;
    }

    public void ShellCollected(Shell.ShellType shellType)
    {
        if (shellType == Shell.ShellType.Shell)
        {
            shells++;
        }
        if (shellType == Shell.ShellType.Gem)
        {
            gems++;
        }
        SetShellText();
    }

    void SetShellText()
    {
        shellText.text = $"Shells: {shells}/{totalShells}\nGems: {gems}/{totalGems}";
    }

    List<(string, float, float)> crabSays = new List<(string, float, float)>();
    void CrabSays(string text, float time)
    {

        // var crabTxt = new StringBuilder();
        // foreach (var ch in text)
        // {
        //     if (ch == ' ' || ch == '.' || ch == ',')
        //         crabTxt.Append(ch);
        //     else
        //         crabTxt.Append('k');
        // }

        crabSays.Add((text, time, time));

        // crabText.text = $"[Crab]: {}\n[Translation]: {text}";
    }

    void RenderCrabSays()
    {
        var txt = new StringBuilder();
        foreach (var (text, timeLeft, time) in crabSays)
        {
            var timeByte = (int)(timeLeft / time * 255);
            var hex = $"{timeByte:X}";
            if (hex.Length == 1)
            {
                hex = "0" + hex;
            }
            txt.Append($"<alpha=#{hex}>[Crab]: {text}\n");
        }

        crabText.text = txt.ToString();
    }

    bool hitWall = false;
    public void HitWall()
    {
        hitWall = true;
    }

    void Start()
    {
        foreach (var shell in UnityEngine.Object.FindObjectsByType<Shell>(FindObjectsSortMode.None))
        {
            if (shell.type == Shell.ShellType.Shell)
            {
                totalShells += 1;
            }
            else
            {
                totalGems += 1;
            }
        }

        SetShellText();
        StartCoroutine(PlotCoroutine());
    }

    void Update()
    {
        if (hitWall)
        {
            hitWall = false;
            CrabSays("No rope left, mate, pulling you out.", 2f);
        }

        UpdateQuestTest();
        if (crabSays.Count > 0 && !blablaAudio.isPlaying)
            blablaAudio.Play();
        else if (crabSays.Count == 0 && blablaAudio.isPlaying)
            blablaAudio.Stop();
        for (var i = 0; i < crabSays.Count;)
        {
            var time = crabSays[i].Item2 - Time.deltaTime;
            if (time < 0)
            {
                crabSays.RemoveAt(i);
            }
            else
            {
                crabSays[i] = (crabSays[i].Item1, time, crabSays[i].Item3);
                i++;
            }
            RenderCrabSays();
        }
    }

    void UpdateQuestTest()
    {
        var text = "";
        if (playerController.movedWithWasd < 100)
        {
            text += $"Swim on [Mouse/WASD/Space/Shift]: {(int)playerController.movedWithWasd}/100m\n";
        }
        if (playerController.movedWithBack < 100)
        {
            text += $"Return using airhose on [Hold RMB]: {(int)playerController.movedWithBack}/100m\n";
        }
        if (playerController.movedWithHook < 100)
        {
            text += $"Move using grappling hook on [Hold LMB]: {(int)playerController.movedWithHook}/100m";
        }

        questText.text = text;
    }

    IEnumerator PlotCoroutine()
    {
        // Debug.Log($"{0:X} {255:X}");

        CrabSays("Friend, we are stranded here together. I will hold the air hose, and you will collect rare sea shells.", 10);

        yield return new WaitForSeconds(5f);

        CrabSays("The hose has limited length though, i will roll it back a little if you are close to the end.", 5);

        yield return new WaitForSeconds(5f);
        playerController.AllowGrapplingHook();

        var timer = 0f;
        while (true)
        {
            timer -= Time.deltaTime;
            if (timer <= 0)
            {
                CrabSays("Let's try with a shorter radius for a test. Use this grappling hook to get the nearest shell.", 5);
                timer = 5f;
            }

            if (shells > 0)
            {
                OganesyanProtection.enabled = false;
                break;
            }
            yield return null;
        }


        CrabSays("Now, with the full length, go find us some shells!", 5);

        while (shells < 2)
        {
            yield return null;
        }

        CrabSays("Good find! I think, there are only two left", 5);

        while (shells < 3)
        {
            yield return null;
        }

        CrabSays("Precious little shell! It will make a fine house for some lucky crab", 5);

        while (shells < 4)
        {
            yield return null;
        }

        CrabSays("Kkkk! You've found all the shells, you lucky bastard", 5);

        yield return new WaitForSeconds(5f);

        credits.StartCredits();
    }
}
