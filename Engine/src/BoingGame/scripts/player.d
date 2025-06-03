module scripts.player;

import Engine.component;
import Engine.tilemapcomponents;
import Engine.gameobject;
import scripts.script;
import constants;
import bindbc.sdl;
import std.math;
import std.stdio;
import std.algorithm;
import physics;

class Player : ScriptComponent {
    enum PlayerState {
        JUMPING,
        FREEFALL,
        GROUNDED,
        COYOTE
    }

    PlayerState state = PlayerState.FREEFALL;
    GameObject mOwner;
    TransformComponent mTransformRef;
    ColliderComponent mColliderRef;
    Actor actor;
    SpriteComponent mSpriteRef;
    InputComponent mInputRef;
    TilemapCollider mTilemap;
    float runSpeed = 0.7;
    float minJumpSpeed = 0.7;
    float maxJumpSpeed = 1.7; // To make a nice fun jump set max when they hit space and min when they let go
    float maxVertSpeed = 2.2;
    float gravity = 0.075;
    float vel_y = 0; // Positive is up
    float vel_x = 0; // Positive is right
    int jumpBufferCounter = -1; // Used to buffer jumps
    int bufferFrames = 5; // How many frames we can buffer a jump
    int coyoteTime = 0; // Used to allow jumps after leaving the ground
    int coyoteFrames = 5; // How many frames we can jump after leaving the ground
    bool wasJumpPressed = false;
    bool grounded = false;

    this(GameObject owner) {
        mOwner = owner;

        mTransformRef = cast(TransformComponent) owner.GetComponent(ComponentType.TRANSFORM);
        mColliderRef = cast(ColliderComponent) owner.GetComponent(ComponentType.COLLIDER);
        mInputRef = cast(InputComponent) mOwner.GetComponent(ComponentType.INPUT);
        mSpriteRef = cast(SpriteComponent) mOwner.GetComponent(ComponentType.SPRITE);
        actor = new Actor(mTransformRef, mColliderRef);

        mSpriteRef.SetAnimation("idle");
    }

    override void Update() {
        HandleCollisions();
        HandleJumpMotion();
        HandleDashMotion();

        // Horizontal movement and jump
        vel_x = runSpeed * mInputRef.GetDir();
        if (vel_x != 0)
            mSpriteRef.flipped = vel_x < 0;

        if (state != PlayerState.GROUNDED)
            vel_y -= gravity;

        vel_y = clamp(vel_y, -maxVertSpeed, maxVertSpeed);
        actor.MoveX(vel_x, &OnSideCollision);
        actor.MoveY(-vel_y, &OnVerticalCollision);
    }

    void HandleDashMotion() {
    }

    void HandleJumpMotion() {
        // Switch between states
        switch (state) {
        case PlayerState.JUMPING:
            if (!mInputRef.upPressed // button now up
                && vel_y > minJumpSpeed) { // and going upward
                vel_y = minJumpSpeed; // stop jump
                state = PlayerState.FREEFALL;
            }
            else if(vel_y < minJumpSpeed) {
                state = PlayerState.FREEFALL;
            }
            break;
        case PlayerState.FREEFALL:
            jumpBufferCounter--;
            break;
        case PlayerState.GROUNDED:
            if (!actor.IsOnGround) {
                // if we walk off a ledge this triggers
                state = PlayerState.COYOTE;
                coyoteTime = 0;
            } else {
                vel_y = 0; // Reset vertical velocity when grounded
            }
            break;
        case PlayerState.COYOTE:
            jumpBufferCounter--;
            coyoteTime++;
            if (coyoteTime > 5) {
                state = PlayerState.FREEFALL;
            }
            break;
        default:
            assert(0, "Unknown player state");
        }

        // Actually detect jump
        if (mInputRef.upPressed && !wasJumpPressed) {
            if (state == PlayerState.GROUNDED || state == PlayerState.COYOTE)
                DoJump();
            else if (state == PlayerState.FREEFALL)
                jumpBufferCounter = bufferFrames;
        }

        wasJumpPressed = mInputRef.upPressed; // store for next frame
    }

    void DoJump() {
        jumpBufferCounter = -1;
        vel_y = maxJumpSpeed;
        state = PlayerState.JUMPING;
    }

    void BecomeGrounded() {
        if (state == PlayerState.GROUNDED)
            return;

        state = PlayerState.GROUNDED;
        vel_y = 0; // Reset vertical velocity

        // Check for buffered jump
        if (jumpBufferCounter >= 0) {
            jumpBufferCounter = -1; // Reset jump buffer
            DoJump();
        }
    }

    void OnVerticalCollision() {
        if (vel_y > 0) // going up
        {
            vel_y = 0;
        } else // going down
        {
            BecomeGrounded();
        }
    }

    void OnSideCollision() {
        vel_x = 0;
    }

    void HandleCollisions() {
        // auto collidedWith = mColliderRef.GetCollisions();
        // foreach(obj; collidedWith)
        // {
        //     if(obj == "spike" || obj == "arrow")
        //         mOwner.alive = false;
        //     else if(obj.startsWith("apple"))
        //     {
        //         GameObject.GetGameObject(obj).alive = false;
        //     }
        // }
    }
}
