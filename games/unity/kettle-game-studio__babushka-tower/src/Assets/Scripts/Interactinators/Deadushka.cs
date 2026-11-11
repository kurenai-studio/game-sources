using TMPro;
using UnityEngine;

[RequireComponent(typeof(Animator))]
public class Deadushka : Interactinator
{
    public TextMeshPro text;
    public AudioClip smokeClip;
    public AudioClip[] yesClips;
    public AudioClip[] noClips;
    public AudioClip[] somethingClips;
    Animator animator;
    float nextBlink = 0;
    float nextSmoke = 0;
    AudioSource audioSource;
    void Start()
    {
        animator = GetComponent<Animator>();
        audioSource = GetComponent<AudioSource>();
    }

    string[] dudushkasStories = new string[]
    {
        "Today is a good day, Vnuchok, good day.",
        "Have I ever told you how I met your Babushka? No? And i will not.",
        "Never go inside our toilette, it's quite a dangerous place...",
        "My komrades and I will have a soviet book club meeting tomorrow",
        "I have built this house with my own two hands! And some tools stolen from the factory",
        "Wonder where did my moonshine go... I remember there were couple of bottles",
        "Good thing we live in the south, we can keep our windows open all day long",
        "Do you think the can with pickles will shatter if you drop it from high enough?",
        "Books are very good for your mind, even detective novels",
    };

    void Update()
    {
        if (Time.time > nextSmoke)
        {
            nextSmoke = Time.time + UnityEngine.Random.Range(10, 30);
            animator.SetTrigger("Smoke");
        }
        if (Time.time > nextBlink)
        {
            nextBlink = Time.time + UnityEngine.Random.Range(0.5f, 5);
            animator.SetTrigger("Blink");
        }
    }

    private AudioClip randomClip(AudioClip[] clips)
    {
        return clips[UnityEngine.Random.Range(0, clips.Length)];
    }
    protected override void Action(PlayerController player)
    {
        animator.SetTrigger("Speak");
        bool saySomething = false;
        var tooltip = player.gameState.nextThingToUnlock();
        if (tooltip != null)
        {
            audioSource.clip = randomClip(player.gameState.HasString($"{tooltip}_comment") ? noClips:yesClips);
            audioSource.Play();
            player.Say(player.gameState.GetString($"{tooltip}_request"), "You");
            player.Say(player.gameState.GetString($"{tooltip}_response"), this.tooltip);
            saySomething = true;
        }

        if (!saySomething)
        {
            audioSource.clip = randomClip(somethingClips);
            audioSource.Play();
            player.Say("How is your day, Dedushka?", "You");
            player.Say(dudushkasStories[Random.Range(0, dudushkasStories.Length - 1)], this.tooltip);
        }
    }

    public void StartSmoke(AnimationEvent ev)
    {
        if(audioSource.isPlaying) return;
        audioSource.clip = smokeClip;
        audioSource.Play();
    }

    public void TakeSound()
    {
        audioSource.clip = randomClip(yesClips);
        audioSource.Play();
    }
}
