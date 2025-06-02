module physics.actor;

import std.math;
import Engine.component;
import bindbc.sdl;
import std.conv;

class Actor {
    float xRemainder = 0.0f;
    float yRemainder = 0.0f;
    TransformComponent transform;
    ColliderComponent collider; 

    public void MoveX(float amount, void delegate() onCollide) {
        xRemainder += amount;
        int move = cast(int) floor(xRemainder);
        if (move != 0) {
            xRemainder -= move;
            int sign = sgn(move);
            while (move != 0) {

                transform.x += sign;
                // TODO: move collider too
                if (collider.CollidesWithSolid()) { 
                    // Hit a solid!
                    // Undo the move
                    transform.x -= sign;
                    xRemainder = 0.0f;

                    if (onCollide != null)
                        onCollide();
                    

                    break;
                }
                move -= sign;
            }
        }
    }

    public void MoveY(float amount, void delegate() onCollide) {
        yRemainder += amount;
        int move = cast(int) floor(yRemainder);
        if (move != 0) {
            yRemainder -= move;
            int sign = sgn(move);
            while (move != 0) {
                transform.y += sign;
                if (collider.CollidesWithSolid()) { 
                    // Hit a solid!
                    // Undo the move
                    transform.y -= sign;
                    yRemainder = 0.0f;

                    if (onCollide != null)
                        onCollide();
                    

                    break;
                }
                move -= sign;
            }
        }
    }
}
