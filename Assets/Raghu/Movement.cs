using UnityEngine;
//using UnityEngine.InputSystem;

public class Movement : MonoBehaviour
{
    [Header("Inputs")]
    //private PlayerInputs playerinputs;
    private bool isSprinting;

    [Header("Movement")]
    [SerializeField] private float rotationSpeed = 250f; // Degrees per second
    private Vector2 DirectionInput;
    private Vector3 MovementDirection;
    private bool Turn_Animate;
    private float turnAngle;

    private bool isCrouching;

    [Header("Ground_Check")]
    [SerializeField] private bool isGrounded;
    [SerializeField] private Transform GroundCheck_object;
    [SerializeField] private float GroundCheck_Sphere_radius;
    [SerializeField] private LayerMask GroundMask;

    public float JumpHeight;
    public float JumpSpeed;
    public float gravity;
    private bool isJumping;
    private Vector3 velocity;

    private Vector3 RootMotion;

    private Animator anim;
    private CharacterController controller;

    private void Awake()
    {
        //playerinputs = new PlayerInputs();
        anim = GetComponent<Animator>();
        controller = GetComponent<CharacterController>();
    }

    // private void OnEnable()
    // {
    //     playerinputs.PlayerLocomotion.Enable();
    //     playerinputs.PlayerWeapon.Enable();
    // }
    // private void OnDisable()
    // {
    //     playerinputs.PlayerLocomotion.Disable();
    //     playerinputs.PlayerWeapon.Disable();
    // }

    // private void Start()
    // {
    //     playerinputs.PlayerLocomotion.Crouch.performed += Crouch;
    //     playerinputs.PlayerLocomotion.Jump.performed += Jump;
    // }

    private void Update()
    {
        PlayerMovement();
        HandleAnimation();
        GroundCheck();
        Jumping();
         isSprinting = Input.GetKey(KeyCode.LeftShift);
         if (Input.GetKeyDown(KeyCode.LeftControl)){isCrouching = !isCrouching;}

          if (Input.GetKeyDown(KeyCode.Space) && !isCrouching && isGrounded)
        {
            isJumping = true;
            velocity = anim.velocity * JumpSpeed;
            velocity.y = Mathf.Sqrt(2 * gravity * JumpHeight);
        }

        //isSprinting = playerinputs.PlayerLocomotion.Sprint.IsPressed();

        controller.Move(RootMotion);
        RootMotion = Vector3.zero;
    }

    private void OnAnimatorMove()
    {
        RootMotion += anim.deltaPosition;

        // Apply root rotation by blending with manual rotation
        if (Turn_Animate)
        {
            transform.rotation *= anim.deltaRotation;
        }
    }

    private void PlayerMovement()
    {
        //DirectionInput = playerinputs.PlayerLocomotion.Movement.ReadValue<Vector2>();
        MovementDirection = new Vector3(Input.GetAxis("Horizontal"), 0,Input.GetAxis("Vertical") ).normalized;


        if (Turn_Animate) { return; }

        //***** Roataion *****//
        if (MovementDirection.magnitude > 0.1f)
        {
            
            Vector3 camDirection = Camera.main.transform.forward;
            MovementDirection = Quaternion.LookRotation(new Vector3(camDirection.x, 0, camDirection.z)) * MovementDirection;

            //***** Turn Angle *****//
            turnAngle = Vector3.SignedAngle(transform.forward, MovementDirection, Vector3.up);

            if (Mathf.Abs(turnAngle) > 150 && !isCrouching)
            {
                if (isSprinting)
                {
                    Turn_Animate = true;
                    anim.Play("Run_Turn_180");
                }
                else
                {
                    Turn_Animate = true;
                    anim.Play("Walk_Turn_180");
                }
            }

            // Smoothly rotate the player towards the movement direction
            Quaternion targetRotation = Quaternion.LookRotation(MovementDirection);
            transform.rotation = Quaternion.RotateTowards(transform.rotation, targetRotation, rotationSpeed * Time.deltaTime);
        }

    }

    private void HandleAnimation()
    {
        if (MovementDirection.magnitude > 0.1f)
        {
            if (isSprinting && !isCrouching)
            {
                anim.SetBool("Run", true);
            }
            else
            {
                if (anim.GetBool("isCrouching"))// Crouch Walk //
                {
                    anim.SetBool("CrouchWalk", true);
                }
                else
                {
                    anim.SetBool("Walk", true);
                    anim.SetBool("Run", false);
                }

            }
        }
        else
        {
            if (anim.GetBool("isCrouching"))// Crouch idle //
            {
                anim.SetBool("CrouchWalk", false);
            }
            else
            {
                anim.SetBool("Run", false);
                anim.SetBool("Walk", false);
            }
        }


        // (Idle to Crouch) & (Crouching to Idle)//
        if (isCrouching)
        {
            anim.SetBool("isCrouching", true);
        }
        else
        {
            anim.SetBool("isCrouching", false);
            // anim.SetBool("CrouchWalk", false);
        }
    }

    // private void Crouch(InputAction.CallbackContext context)
    // {
    //     if (context.performed)
    //     {
    //         isCrouching = !isCrouching;
    //         // Collider_Setting(isCrouching);
    //     }
    // }

    private void GroundCheck()
    {
        isGrounded = Physics.CheckSphere(GroundCheck_object.position, GroundCheck_Sphere_radius, GroundMask);
    }

    // private void Jump(InputAction.CallbackContext context)
    // {
    //     if (context.performed && !isCrouching && isGrounded)
    //     {
    //         isJumping = true;
    //         velocity = anim.velocity * JumpSpeed;
    //         velocity.y = Mathf.Sqrt(2 * gravity * JumpHeight);
    //     }
    // }

    private void Jumping()
    {
        if (!isCrouching)
        {
            if (isJumping)// in Air //
            {
                velocity.y -= gravity * Time.deltaTime;
                controller.Move(velocity * Time.deltaTime);
                isJumping = !controller.isGrounded;
                RootMotion = Vector3.zero;
                anim.SetBool("isJump", true);
            }
            else // on ground //
            {
                controller.Move(RootMotion + Vector3.down * controller.stepOffset);
                RootMotion = Vector3.zero;
                anim.SetBool("isJump", false);
            }

        }
    }


    public void ResetJump()
    {
        anim.SetBool("isJump", false);
    }

    public void ResetRotation()
    {
        Turn_Animate = false;
    }
}
