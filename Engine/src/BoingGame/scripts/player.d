module scripts.player;

import Engine.component;
import Engine.tilemapcomponents;
import Engine.scene;
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
    Scene mScene;
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
    float crawlSpeed = 0.6; // Speed when crawling

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

        if (!bouncy) {
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
    }

    void GroundedMotion() {
        // Default to no motion
        vel_x = 0;
        vel_y = 0;

        bool[4] walls = actor.SolidsAround(); // [left, right, up, down]
        bool[4] corners = actor.SolidCornersAround(); // [UL, UR, DL, DR]

        bool[4] canMove = [
            (!walls[0]) && (walls[2] || walls[3] || corners[2] || corners[0]), // left
            (!walls[1]) && (walls[2] || walls[3] || corners[1] || corners[3]), // right
            (!walls[2]) && (walls[0] || walls[1] || corners[0] || corners[1]), // up
            (!walls[3]) && (walls[0] || walls[1] || corners[2] || corners[3]), // down
        ];

        if (canMove[0] && input.leftPressed)
            vel_x = -crawlSpeed;
        if (canMove[1] && input.rightPressed)
            vel_x = crawlSpeed;
        if (canMove[2] && input.upPressed)
            vel_y = crawlSpeed;
        if (canMove[3] && input.downPressed)
            vel_y = -crawlSpeed;

        if (vel_x != 0 && vel_y != 0) {
            // Never crawl diagonally, vertical precedence
            vel_x = 0;
        }

        // switch (solids) {
        // case 1: // L, R, LR
        // case 2:
        // case 3:
        //     vel_y = (input.downPressed ? -crawlSpeed : 0) + (input.upPressed ? crawlSpeed : 0);
        //     break;
        // case 4: // U, D, UD
        // case 8:
        // case 12:
        //     vel_x = (input.leftPressed ? -crawlSpeed : 0) + (input.rightPressed ? crawlSpeed : 0);
        //     break;
        // case 13: // LUD
        //     vel_x = (input.rightPressed ? crawlSpeed : 0);
        //     break;
        // case 14: // RUD
        //     vel_x = (input.leftPressed ? -crawlSpeed : 0);
        //     break;
        // case 7: // URL
        //     vel_y = (input.downPressed ? -crawlSpeed : 0);
        //     break;
        // case 11: // DRL
        //     vel_y = (input.upPressed ? crawlSpeed : 0);
        //     break;
        // case 5: // LU
        // case -8: // DR corner
        //     if (input.rightPressed && input.downPressed) {
        //         break;
        //     }
        //     vel_x = (input.rightPressed ? crawlSpeed : 0);
        //     vel_y = (input.downPressed ? -crawlSpeed : 0);
        //     break;
        // case 9: // LD, UR corner
        // case -2:
        //     if (input.rightPressed && input.upPressed) {
        //         break;
        //     }
        //     vel_x = (input.rightPressed ? crawlSpeed : 0);
        //     vel_y = (input.upPressed ? crawlSpeed : 0);
        //     break;
        // case 6: // RU, DL corner
        // case -4:
        //     if (input.leftPressed && input.downPressed) {
        //         break;
        //     }
        //     vel_x = (input.leftPressed ? -crawlSpeed : 0);
        //     vel_y = (input.downPressed ? -crawlSpeed : 0);
        //     break;
        // case 10: // RD, UL corner
        // case -1:
        //     if (input.leftPressed && input.upPressed) {
        //         break;
        //     }
        //     vel_x = (input.leftPressed ? -crawlSpeed : 0);
        //     vel_y = (input.upPressed ? crawlSpeed : 0);
        //     break;
        // case 15: // All walls
        //     break;
        //     // UL = -1, UR = -2, DL = -4, DR = -8
        //     // TODO: unimplemented cases of multiple corners

        // default:
        //     assert(0, "Unknown solids around player");
        //     break;
        // }
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
                GroundedMotion();
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
            writeln("left dash");
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
            return false; // No valid dash direction
            //if contradictary input, dash "in place" maybe
            // vel_x = 0;
            // vel_y = 0;
            break;
        }

        state = PlayerState.DASHING;
        dashCounter = 0;

        mScene.SetFreezeFrames(dashFreezeFrames); // Freeze the game for a few frames
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
            state = PlayerState.FREEFALL; // Bounce ends dash
        } else {
            BecomeGrounded();
        }
    }

    void OnSideCollision() {
        if (bouncy) {
            vel_x = -vel_x;
            state = PlayerState.FREEFALL; // Bounce ends dash

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
