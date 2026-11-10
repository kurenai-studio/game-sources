using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

[System.Serializable]
public class Spell
{
   public GameObject spell;
   public Utils.SpellName name;
}

public class PlayerController : MonoBehaviour
{
    public Camera mainCamera;

    public float moveSpeed;
    public List<Spell> spells;
    public List<Spell> debugSpells;
    public Vector2 wandTipOnSprite;
    public int rayCount;
    public LayerMask wallLayers;

    private Vector2 mousePos;
    private Vector2 wandTipPosition;
    private BoxCollider2D boxCollider;
    private Vector2 movementInput;
    private LineRenderer targetingLine;
    private Animator animator;
    private Vector2 lastPos;
    private GameObject nextSpell;
    private Health health;

    private UIManager uiManager;
    private HUDManager hudManager;

    public bool visible = true;
    public bool invulnerable = false;
    private bool castingDisabled = false;
    private bool movementDisabled = false;
    public bool dead = false;

    AudioSource audioSource;
    public AudioClip dieSound;

    // Start is called before the first frame update
    void Start()
    {
        boxCollider = GetComponent<BoxCollider2D>();
        targetingLine = GetComponentInChildren<LineRenderer>();
        audioSource = GetComponent<AudioSource>();
        animator = GetComponent<Animator>();
        health = GetComponent<Health>();
        uiManager = GameObject.FindWithTag("UI").GetComponent<UIManager>();
        hudManager = GameObject.FindWithTag("HUD").GetComponent<HUDManager>();
        nextSpell = spells[0].spell;
        hudManager.SetSpell(spells[0].name);
        UpdateNextSpell();
    }

    public void Die() {
        animator.SetTrigger("Death");
        targetingLine.enabled = false;
        dead = true;
        uiManager.GameOver();
        hudManager.SetHP(health);
        audioSource.PlayOneShot(dieSound, 1f);
    }

    public void OnMove(InputValue value)
    {
        movementInput = value.Get<Vector2>();
    }

    public void TeleportOut()
    {
        animator.SetTrigger("Teleport Out");
        movementDisabled = true;
        invulnerable = true;
        visible = false;
        castingDisabled = true;
        targetingLine.enabled = false;
    }

    public void TeleportIn()
    {
        animator.SetTrigger("Teleport In");
        movementDisabled = false;
        invulnerable = false;
        visible = true;
        castingDisabled = false;
        targetingLine.enabled = true;
    }

    void UpdateNextSpell()
    {
        Spell newSpell = debugSpells.Count > 0
            ? debugSpells[0]
            : spells[Random.Range(0, spells.Count)];
        hudManager.SetSpell(newSpell.name);
        nextSpell = newSpell.spell;
    }

    void CastNextSpell()
    {
        if (!castingDisabled) {
            Debug.Log(nextSpell);
            GameObject newSpell = Instantiate(nextSpell, wandTipPosition, Quaternion.identity);
            newSpell.GetComponent<IProjectileSpell>().target = mousePos;
            newSpell.GetComponent<IProjectileSpell>().caster = this;
            UpdateNextSpell();
        }
    }

    public void OnFire(InputValue value)
    {
        if (!castingDisabled && !dead) {
            CastNextSpell();
        }
    }

    void FixedUpdate() {
        if (!dead) {
            lastPos = transform.position;
            Utils.Move(gameObject, moveSpeed, wallLayers, movementInput);
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (!dead) {
            if ( lastPos != (Vector2)transform.position ) {
                animator.SetBool("Walking", true);
            } else {
                animator.SetBool("Walking", false);
            }

            mousePos = mainCamera.ScreenToWorldPoint((Vector2)Mouse.current.position.ReadValue());

            if ( mousePos.x < transform.position.x) {
                transform.localScale = new Vector2(-1, 1); 
                wandTipPosition.x = transform.position.x - wandTipOnSprite.x;
            } else {
                transform.localScale = new Vector2(1, 1); 
                wandTipPosition.x = transform.position.x + wandTipOnSprite.x;
            }
            wandTipPosition.y = transform.position.y + wandTipOnSprite.y;
            Vector3[] linePoints = new Vector3[] { wandTipPosition, mousePos };
            targetingLine.SetPositions(linePoints);

            hudManager.SetHP(health);
        }
    }
}
