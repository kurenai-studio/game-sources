using UnityEngine;

[RequireComponent(typeof(Animator))]
public class Door : Interactinator
{
    Animator animator;
    AudioSource audio;

    private bool DoorSecondFactorLocked = true;

    void Start()
    {
        animator = GetComponent<Animator>();
        audio = GetComponent<AudioSource>();
    }

    public void UnlockSecondFactor()
    {
        locked = false;
        DoorSecondFactorLocked = false;
    }

    protected override void Action(PlayerController player)
    {
        if (DoorSecondFactorLocked)
        {
            player.Say(player.gameState.GetString($"{tooltip}_comment"));
            return;
        }

        bool isOpen = animator.GetBool("Open");
        animator.SetBool("Open", !isOpen);
        audio.Stop();
        audio.pitch = isOpen ? -1f : 1f;
        audio.timeSamples = isOpen ? audio.clip.samples - 1 : 0;
        audio.Play();
    }
}
