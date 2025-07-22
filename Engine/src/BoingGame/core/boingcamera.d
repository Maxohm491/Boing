module BoingGame.boingcamera;

import Engine.camerascript;
import Engine.scene;
import constants;
import std.stdio;

class BoingCamera : CameraScript {
    int left, right;

    override void UpdateCamera(int playerX, int playerY) {
        // Center on the player
        this.camera.pos.x = playerX - (GRID_X * 4); // 8 /2

        // Clamp the camera position to the defined min and max
        if (camera.pos.x < left)
            camera.pos.x = left;
        else if (camera.pos.x > right)
            camera.pos.x = right;
    }
}
