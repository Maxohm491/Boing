module scripts.jumpplayer;

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

class JumpPlayer : ScriptComponent {
    enum PlayerState {
        JUMPING,
        FREEFALL,
        GROUNDED,
        WALLED
    }

    PlayerState state = PlayerState.FREEFALL;
    GameObject mOwner;
    TransformComponent mTransformRef;
    ColliderComponent mColliderRef;
    Actor actor;
    SpriteComponent mSpriteRef;
    InputComponent mInputRef;
    TilemapCollider mTilemap;

    bool leftWalled = false; // only meaningful when state == PlayerState.WALLEd
    int coyoteWallTime = 0;
    float runSpeed = 1.2;
    float runAccel = 0.31;
    float airAccel = 0.31;
    float minJumpSpeed = 0.9;
    float maxJumpSpeed = 2.7; // To make a nice fun jump set max when they hit space and min when they let go
    float maxVertSpeed = 2.7;
    float airFriction = 0.09;
    float groundFriction = 0.2;
    float jumpBoost = 1.3;
    float gravity = 0.09;
    float vel_y = 0; // Positive is up
    float vel_x = 0; // Positive is right
    int jumpBufferCounter = -1; // Used to buffer jumps
    int bufferFrames = 5; // How many frames we can buffer a jump
    int coyoteTime = 0; // Used to allow jumps after leaving the ground
    int coyoteFrames = 6; // How many frames we can jump after leaving the ground
    int coyoteWallFrames = 6; // How many frames we can jump after leaving the wall
    bool wasJumpPressed = false;
    bool grounded = false;

    this(GameObject owner) {
        mOwner = owner;

        mTransformRef = cast(TransformComponent) owner.GetComponent(ComponentType.TRANSFORM);
        mColliderRef = cast(ColliderComponent) owner.GetComponent(ComponentType.COLLIDER);
        mInputRef = cast(InputComponent) mOwner.GetComponent(ComponentType.INPUT);
        mSpriteRef = cast(SpriteComponent) mOwner.GetComponent(ComponentType.SPRITE);
        actor = new Actor(mTransformRef, mColliderRef);

        mSpriteRef.SetAnimation("fall");
    }

    override void Update() {
        HandleCollisions();
        HandleJumpMotion();

        // Horizontal movement
        int inputDir = mInputRef.GetDir();
        if (inputDir == 0) {
            // Apply friction when not moving
            if (state == PlayerState.GROUNDED)
                vel_x = vel_x - min(groundFriction, abs(vel_x)) * sgn(vel_x);
            else if (state == PlayerState.FREEFALL || state == PlayerState.JUMPING)
                vel_x = vel_x - min(airFriction, abs(vel_x)) * sgn(vel_x);

        } else {
            if (state == PlayerState.GROUNDED)
                vel_x = clamp(vel_x + runAccel * mInputRef.GetDir(), -runSpeed, runSpeed);
            else if (state == PlayerState.FREEFALL || state == PlayerState.JUMPING)
                vel_x = clamp(vel_x + airAccel * mInputRef.GetDir(), -runSpeed, runSpeed);
        }

        if (vel_x != 0 && state != PlayerState.WALLED)
            mSpriteRef.flipped = vel_x < 0;

        if (state != PlayerState.GROUNDED && state != PlayerState.WALLED)
            vel_y -= gravity;

        vel_y = clamp(vel_y, -maxVertSpeed, maxVertSpeed);
        actor.MoveX(vel_x, &OnSideCollision);
        actor.MoveY(-vel_y, &OnVerticalCollision);
    }

    void HandleJumpMotion() {
        bool didJump = mInputRef.upPressed && !wasJumpPressed;
        wasJumpPressed = mInputRef.upPressed; // store for next frame

        // Switch between states
        switch (state) {
        case PlayerState.JUMPING:
            if (!mInputRef.upPressed // button now up
                && vel_y > minJumpSpeed) { // and going upward
                vel_y = minJumpSpeed; // stop jump
                state = PlayerState.FREEFALL;
            } else if (vel_y < minJumpSpeed) {
                state = PlayerState.FREEFALL;
            }
            break;
        case PlayerState.FREEFALL:
            coyoteWallTime++;
            coyoteTime++;
            jumpBufferCounter--;

            if (didJump) {
                if (coyoteTime <= coyoteFrames)
                    GroundJump();
                else if (coyoteWallTime <= coyoteWallFrames)
                    WallJump(leftWalled);
                else
                    jumpBufferCounter = bufferFrames;
            }

            break;
        case PlayerState.GROUNDED:
            if (!actor.IsOnGround) {
                // if we walk off a ledge this triggers
                state = PlayerState.FREEFALL;
                mSpriteRef.SetAnimation("fall");

                coyoteTime = 0;
            } else {
                vel_y = 0; // Reset vertical velocity when grounded
            }

            if (didJump)
                GroundJump();

            break;
        case PlayerState.WALLED:
            vel_y = 0;

            if (didJump) {
                WallJump(leftWalled);
            }

            if ((mInputRef.rightPressed && leftWalled) || (mInputRef.leftPressed && !leftWalled) || mInputRef
                .downPressed) {
                // If we press left or right, we leave the wall
                state = PlayerState.FREEFALL;
                coyoteWallTime = 0;
                mSpriteRef.SetAnimation("fall");
            }
            break;

        default:
            assert(0, "Unknown player state");
        }
    }

    void GroundJump() {
        jumpBufferCounter = -1;
        vel_y = maxJumpSpeed;
        coyoteTime = coyoteFrames + 1;
        coyoteWallTime = coyoteWallFrames + 1;

        state = PlayerState.JUMPING;
        mSpriteRef.SetAnimation("fall");
    }

    void WallJump(bool leftWall) {
        jumpBufferCounter = -1;
        vel_y = maxJumpSpeed;
        vel_x = leftWall ? jumpBoost : -jumpBoost;
        coyoteTime = coyoteFrames + 1;
        coyoteWallTime = coyoteWallFrames + 1;
        mSpriteRef.SetAnimation("fall");

        state = PlayerState.JUMPING;
    }

    void BecomeGrounded() {
        if (state == PlayerState.GROUNDED)
            return;

        state = PlayerState.GROUNDED;
        vel_y = 0; // Reset vertical velocity
        mSpriteRef.SetAnimation("idle");
    }

    void OnVerticalCollision() {
        if (vel_y > 0) // going up
        {
            vel_y = 0;
        } else // going down
        {
            BecomeGrounded();
            // Check for buffered jump
            if (jumpBufferCounter >= 0) {
                jumpBufferCounter = -1; // Reset jump buffer
                GroundJump();
            }
        }
    }

    void OnSideCollision() {
        if (mInputRef.downPressed) {
            // If we press down don't stick to walls
            vel_x = 0;
            return;
        }
        if (vel_x < 0) {
            leftWalled = true;
            mSpriteRef.flipped = false;
            mSpriteRef.SetAnimation("leftWall");
        } else {
            leftWalled = false;
            mSpriteRef.flipped = false;
            mSpriteRef.SetAnimation("rightWall");
        }

        vel_x = 0;

        state = PlayerState.WALLED; // Reset to walled state
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
