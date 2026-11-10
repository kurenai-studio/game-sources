using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.InputSystem;
using System.Collections;

public class Sewing : Minigame.AMiniGameManager
{
    [SerializeField]
    private Slider _slider;

    [SerializeField]
    private AnimationCurve _curve;

    [SerializeField]
    private TMPro.TMP_Text textField;

    private float _mov = 0;

    private float inputSpeed = 0.05f;
    private float penaltyTime = 1f;

    private float baseTime = 4f;
    private float targetTime = 10f;

    private bool safe = false;

    private Minigame.MinigameCallBack _cb;
    private AudioSource _source;

    private void FixedUpdate()
    {
        if (!gameObject.activeSelf)
            return;
        var curveEffct = _curve.Evaluate(Time.time);
        _slider.value -= curveEffct * 0.75f;

        _slider.value += _mov;

        if (!safe && (_slider.value <= 0 || _slider.value >= 1))
        {
            StartCoroutine(ChangeBackColor());
        }
        if (Time.time >= targetTime)
        {
            _source.Stop();
            _cb();
            gameObject.SetActive(false);
        }
        textField.text = String.Format("{0:F2}",targetTime - Time.time);
    }

    public void Hit(InputAction.CallbackContext value)
    {
        _mov = value.ReadValue<Vector2>().x * inputSpeed;
    }

    public override void RunMinigame(Minigame.MinigameCallBack cb_result, float difficultyFactor)
    {
        targetTime = Time.time + baseTime;
        _slider.value = 0.5f;
        _cb = cb_result;
        _source = GetComponent<AudioSource>();

        base.RunMinigame(cb_result, difficultyFactor);
        _source.Play();
    }
    public IEnumerator ChangeBackColor()
    {
        targetTime += penaltyTime;
        textField.color = new Color(0.9f, 0.01f, 0.2f);
        safe = true;

        yield return new WaitForSeconds(0.5f);

        textField.color = Color.white;
        safe = false;
    }
}