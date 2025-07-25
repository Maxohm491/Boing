module Engine.scene;

import Engine.component;
import Engine.tilemapcomponents;
import std.algorithm;
import Engine.gameobject;
import Engine.gameapplication;
import Engine.camerascript;
import constants;
import bindbc.sdl;
import std.json;
import std.format;
import std.conv;
import std.file;
import std.random;
import std.math;

import std.stdio;

class Camera {
    SDL_Point pos;
    alias pos this;

    void PositionCamera(int x, int y) {
        pos.x = x;
        pos.y = y;
    }
}

interface IGameObjectCollection {
    GameObject[] getGameObjects();
    void RemoveDead();
}

// Inherit this to allow for the categorization of game objects
// Each scene has one
// Base collection that works for any enum
class GameObjectCollection(P)  {
    alias Property = P;

    GameObject[] gameObjects;
    GameObject[][Property] categorizedObjects;

    this() {
        foreach (prop; EnumMembers!Property)
            categorizedObjects[prop] = [];
    }

    void AddGameObject(GameObject go, Property[] props = Property[]) {
        gameObjects ~= go;

        foreach (prop; props)
            categorizedObjects[prop] ~= go;
    }

    void RemoveDead() {
        for (int i = gameObjects.length - 1; i >= 0; i--) {
            if (!gameObjects[i].alive) {
                foreach (prop; EnumMembers!Property) {
                    auto arrPtr = prop in categorizedObjects;
                    if (arrPtr !is null) {
                        auto arr = arrPtr;
                        foreach (j, obj; *arr) {
                            if (obj is gameObjects[i]) {
                                *arr = (*arr)[0 .. j] ~ (*arr)[j + 1 .. $];
                                break;
                            }
                        }
                    }
                }
                gameObjects = gameObjects[0 .. i] ~ gameObjects[i + 1 .. $];
            }
        }
    }

    GameObject[]* AccessCategory(Property prop) {
        return &categorizedObjects[prop];
    }
}

enum BaseProps { COLLIDABLE }

alias BaseCollection = GameObjectCollection!BaseProps;

/// Represents a scene containing game objects 
class Scene {
    GameObject[] gameObjects; // Don't use a scene tree bc that's complicated
    GameObject player;
    Camera camera;
    CameraScript cameraScript; // custom camera behavior

    int freezeFrames = 0; // freeze the whole game for this many frames

    SDL_Renderer* mRendererRef;

    void delegate() mOnComplete;

    this(SDL_Renderer* r, void delegate() onComplete) {
        mRendererRef = r;
        mOnComplete = onComplete;
    }

    void Input(SDL_Event e) {
        foreach (obj; gameObjects) {
            obj.Input(e);
        }
    }

    void Update() {
        if (freezeFrames > 0) {
            freezeFrames -= 1;
            return;
        }

        foreach (obj; gameObjects) {
            obj.Update();
        }

        auto collider = cast(ColliderComponent) player.GetComponent(
            ComponentType.COLLIDER);

        if (collider !is null)
            collider.CheckCollisions(gameObjects);

        // Check deaths
        for (auto i = gameObjects.length; i > 0; i -= 1) {
            if (!gameObjects[i - 1].alive) {
                if (gameObjects[i - 1] is player) {
                    player = null; // Player is dead, reset it
                }
                gameObjects = gameObjects.remove(i - 1);
            }
        }
    }

    void Render() {
        auto playerTransform = cast(TransformComponent) player.GetComponent(
            ComponentType.TRANSFORM);

        cameraScript.UpdateCamera(playerTransform.x, playerTransform.y);

        // Set each objects local pos based on camera
        foreach (obj; gameObjects) {
            auto transform = cast(TransformComponent) obj.GetComponent(
                ComponentType.TRANSFORM);
            if (transform !is null) {
                transform.UpdateScreenPos(camera.pos);
            }
        }
        foreach (obj; gameObjects) {
            obj.Render();
        }
    }

    void AddGameObject(GameObject go) {
        gameObjects ~= go;
    }

    void SetFreezeFrames(int frames) {
        freezeFrames = frames;
    }
}
