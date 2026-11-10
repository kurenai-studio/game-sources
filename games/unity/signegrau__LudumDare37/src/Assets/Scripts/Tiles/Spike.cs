using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Spike : MonoBehaviour
{
    private Animator _animator;

    private void Start()
    {
        _animator = GetComponent<Animator>();
    }

    private void OnEnable()
    {
        GameManager.paused += GameManagerOnPaused;
        GameManager.resume += GameManagerOnResume;
    }

    private void OnDisable()
    {
        GameManager.paused -= GameManagerOnPaused;
        GameManager.resume -= GameManagerOnResume;
    }

    private void GameManagerOnResume(float timeStart, float timeAdd)
    {
        _animator.enabled = true;
    }

    private void GameManagerOnPaused()
    {
        _animator.enabled = false;
    }
}
