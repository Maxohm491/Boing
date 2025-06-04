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
        COYOTE,
        DASHING
    }

    PlayerState state = PlayerState.FREEFALL;
    GameObject mOwner;
    TransformComponent mTransformRef;
    ColliderComponent mColliderRef;
    Actor actor;
    SpriteComponent mSpriteRef;
    InputComponent input;
    TilemapCollider mTilemap;
    float runSpeed = 0.7;
    float minJumpSpeed = 0.7;
    float maxJumpSpeed = 1.7; // To make a nice fun jump set max when they hit space and min when they let go
    float maxVertSpeed = 2.2;
    // float gravity = 0.075; // old jump gravity
    float gravity = 0.1; // old jump gravity
    float vel_y = 0; // Positive is up
    float vel_x = 0; // Positive is right
    int jumpBufferCounter = -1; // Used to buffer jumps
    int bufferFrames = 5; // How many frames we can buffer a jump
    int coyoteTime = 0; // Used to allow jumps after leaving the ground
    int coyoteFrames = 5; // How many frames we can jump after leaving the ground
    bool wasJumpPressed = false;
    bool grounded = false;

    float horiDashVelocityMax = 2; // max speeds from a dash
    float vertDashVelocityMax = 2;
    float diagDashVelocityMax = 1.4; // per direction
    int dashLengthFrames = 7;
    int dashCounter = 0; // How many frames we've been dashing
    int dashFreezeFrames = 3;

    this(GameObject owner) {
        mOwner = owner;

        mTransformRef = cast(TransformComponent) owner.GetComponent(ComponentType.TRANSFORM);
        mColliderRef = cast(ColliderComponent) owner.GetComponent(ComponentType.COLLIDER);
        input = cast(InputComponent) mOwner.GetComponent(ComponentType.INPUT);
        mSpriteRef = cast(SpriteComponent) mOwner.GetComponent(ComponentType.SPRITE);
        actor = new Actor(mTransformRef, mColliderRef);

        mSpriteRef.SetAnimation("idle");
    }

    override void Update() {
        HandleCollisions();
        // HandleJumpMotion();
        HandleDashMotion();

        // Horizontal movement
        // vel_x = runSpeed * input.GetDir();
        // if (vel_x != 0)
        //     mSpriteRef.flipped = vel_x < 0;

        // if (state != PlayerState.GROUNDED)
        //     vel_y -= gravity;
        if (state != PlayerState.DASHING)
            vel_y -= gravity;

        vel_y = clamp(vel_y, -maxVertSpeed, maxVertSpeed);
        actor.MoveX(vel_x, &OnSideCollision);
        actor.MoveY(-vel_y, &OnVerticalCollision);
    }

    void HandleDashMotion() {
        switch (state) {
        case PlayerState.DASHING:
            writeln("Dashing");
            dashCounter++;
            if (dashCounter > dashLengthFrames)
                state = PlayerState.FREEFALL; // End dash
            break;
        default:
            writeln("Not");
            // I think this is nifty but maybe not the best way
            int dashCode = 0;
            if (input.leftPressed)
                dashCode += 1;
            if (input.rightPressed)
                dashCode += 2;
            if (input.upPressed)
                dashCode += 4;
            if (input.downPressed)
                dashCode += 8;
            switch (dashCode) {
            case 0: // No dash
                break;
            case 1: // Left
            case 13:
                vel_x = min(-horiDashVelocityMax, vel_x);
                vel_y = 0;
                break;
            case 2:
            case 14:
                vel_x = max(horiDashVelocityMax, vel_x);
                vel_y = 0;
                break;
                break;
            case 5: // Diagonal
            case 6:
            case 9:
            case 10:
                vel_x = (input.leftPressed ? min(-diagDashVelocityMax, vel_x) : max(diagDashVelocityMax, vel_x));
                vel_y = (input.downPressed ? min(-diagDashVelocityMax, vel_y) : max(diagDashVelocityMax, vel_y));
                break;
            case 4: // Vertical
            case 8:
            case 7:
            case 11:
                writeln("vertical");
                break;
            default:
                writeln("in place");
                break;
            }

            if (dashCode != 0) {
                state = PlayerState.DASHING;
                dashCounter = 0;
            }
            break;
        }

        //maybe if contradictary input, dash "in place"
    }

    void HandleJumpMotion() {
        // Switch between states
        switch (state) {
        case PlayerState.JUMPING:
            if (!input.upPressed // button now up
                && vel_y > minJumpSpeed) { // and going upward
                vel_y = minJumpSpeed; // stop jump
                state = PlayerState.FREEFALL;
            } else if (vel_y < minJumpSpeed) {
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
        if (input.upPressed && !wasJumpPressed) {
            if (state == PlayerState.GROUNDED || state == PlayerState.COYOTE)
                DoJump();
            else if (state == PlayerState.FREEFALL)
                jumpBufferCounter = bufferFrames;
        }

        wasJumpPressed = input.upPressed; // store for next frame
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
        auto collidedWith = mColliderRef.GetCollisions();
        foreach (obj; collidedWith) {
            if (obj == "spike" || obj == "arrow")
                mOwner.alive = false;
            else if (obj.startsWith("apple")) {
                GameObject.GetGameObject(obj).alive = false;
            }
        }
    }
}
