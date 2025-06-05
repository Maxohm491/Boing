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
        FREEFALL,
        GROUNDED,
        DASHING,
    }

    bool bouncy = false;

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
    // float gravity = 0.075; // old jump gravity
    float gravity = 0.15;
    float vel_y = 0; // Positive is up
    float vel_x = 0; // Positive is right

    float horizonalAirResistance = 0.07222222222f; // How much to slow down horizontal movement in the air per frame
    float airAcceleration = 0.27777777777f;
    float fastestManualAirSpeedHorizontal = 1.5; // The point after which we stop accelerating horizontally in the air

    float maxVertSpeed = 2;

    float horiDashVelocityMax = 2; // max speeds from a dash
    float vertDashVelocityMax = 2;
    float diagDashVelocityMax = 1.4; // per direction
    int dashLengthFrames = 12;
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
        bouncy = input.bouncyPressed;

        HandleCollisions();
        HandleMotion();

        writeln("vel_x: ", vel_x, " vel_y: ", vel_y, " state: ", state);
        actor.MoveX(vel_x, &OnSideCollision);
        actor.MoveY(-vel_y, &OnVerticalCollision);
    }

    void FreefallMotion() {
        // Apply gravity
        vel_y -= gravity;

        if (!bouncy)
            vel_y = clamp(vel_y, -maxVertSpeed, maxVertSpeed); // TODO: more complex check

        if (input.leftPressed && vel_x >= -fastestManualAirSpeedHorizontal) {
            vel_x = max(-fastestManualAirSpeedHorizontal, vel_x - airAcceleration);
        } else if (input.rightPressed && vel_x <= fastestManualAirSpeedHorizontal) {
            vel_x = min(fastestManualAirSpeedHorizontal, vel_x + airAcceleration);
        } else {
            if (vel_x > 0) {
                vel_x = max(0, vel_x - horizonalAirResistance);
            } else if (vel_x < 0) {
                vel_x = min(0, vel_x + horizonalAirResistance);
            }
        }
    }

    void HandleMotion() {
        switch (state) {
        case PlayerState.DASHING:
            dashCounter++;
            if (dashCounter > dashLengthFrames)
                state = PlayerState.FREEFALL; // End dash
            break;
        case PlayerState.FREEFALL:
            if (!StartDash())
                FreefallMotion();
            break;
        case PlayerState.GROUNDED:
            if (!StartDash())
                writeln("Grounded");
            break;
        default:
            break;
        }
    }

    // Check for dash input and perform dash if applicable
    // Returns true if a dash was performed, false otherwise
    bool StartDash() {
        if (!input.dashPressed)
            return false;

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
            vel_x = 0;
            vel_y = (input.downPressed ? min(-vertDashVelocityMax, vel_y) : max(vertDashVelocityMax, vel_y));
            break;
        default:
            writeln("in place");
            //if contradictary input, dash "in place" maybe
            // vel_x = 0;
            // vel_y = 0;
            break;
        }

        state = PlayerState.DASHING;
        dashCounter = 0;

        return true;
    }

    void BecomeGrounded() {
        if (state == PlayerState.GROUNDED)
            return;

        state = PlayerState.GROUNDED;
        vel_y = 0; // Reset velocity
        vel_x = 0;
    }

    void OnVerticalCollision() {
        if (bouncy) {
            vel_y = -vel_y;
        } else {
            BecomeGrounded();
        }
    }

    void OnSideCollision() {
        if (bouncy) {
            vel_x = -vel_x;
        } else {
            BecomeGrounded();
        }
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
