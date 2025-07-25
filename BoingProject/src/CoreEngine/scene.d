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
import std.traits;

import std.stdio;

class Camera {
    SDL_Point pos;
    alias pos this;

    void PositionCamera(int x, int y) {
        pos.x = x;
        pos.y = y;
    }
}

// Each scene has one
interface IGameObjectCollection {
    ref GameObject[] getGameObjects();
    void AddGameObject(GameObject go);
    void RemoveDead();
}

// Implement this to allow for the categorization of game objects
// Base collection that works for any enum
class GameObjectCollection(P) : IGameObjectCollection {
    alias Property = P;

    GameObject[] gameObjects;
    GameObject[][Property] categorizedObjects;

    this() {
        foreach (prop; EnumMembers!Property)
            categorizedObjects[prop] = [];
    }

    ref GameObject[] getGameObjects() {
        return gameObjects;
    }

    // Add without properties
    void AddGameObject(GameObject go) {
        gameObjects ~= go; 
    }

    void AddGameObject(GameObject go, Property[] props) {
        gameObjects ~= go;

        foreach (prop; props)
            categorizedObjects[prop] ~= go;
    }

    void RemoveDead() {
        for (auto i = gameObjects.length; i > 0; i--) {
            if (!gameObjects[i-1].alive) {
                foreach (prop; EnumMembers!Property) {
                    auto arrPtr = prop in categorizedObjects;
                    if (arrPtr !is null) {
                        auto arr = arrPtr;
                        foreach (j, obj; *arr) {
                            if (obj is gameObjects[i-1]) {
                                *arr = (*arr)[0 .. j] ~ (*arr)[j + 1 .. $];
                                break;
                            }
                        }
                    }
                }
                gameObjects = gameObjects[0 .. i - 1] ~ gameObjects[i .. $];
            }
        }
    }

    GameObject[]* AccessCategory(Property prop) {
        return &categorizedObjects[prop];
    }
}

/// Represents a scene containing game objects 
class Scene {
    IGameObjectCollection gameObjs;
    // GameObject[] gameObjects;
    GameObject player; // The object that the camera moves relative to
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
        foreach (obj; gameObjs.getGameObjects()) {
            obj.Input(e);
        }
    }

    void Update() {
        if (freezeFrames > 0) {
            freezeFrames -= 1;
            return;
        }

        foreach (obj; gameObjs.getGameObjects()) {
            obj.Update();
        }

        // auto collider = cast(ColliderComponent) player.GetComponent(
        //     ComponentType.COLLIDER);

        // if (collider !is null)
        //     collider.CheckCollisions(gameObjects);

        // Check deaths
        // for (auto i = gameObjects.length; i > 0; i -= 1) {
        //     if (!gameObjects[i - 1].alive) {
        //         if (gameObjects[i - 1] is player) {
        //             player = null; // Player is dead, reset it
        //         }
        //         gameObjects = gameObjects.remove(i - 1);
        //     }
        // }
        gameObjs.RemoveDead();
    }

    void Render() {
        auto playerTransform = cast(TransformComponent) player.GetComponent(
            ComponentType.TRANSFORM);
        assert(playerTransform !is null, "Player must have a TransformComponent");

        cameraScript.UpdateCamera(playerTransform.x, playerTransform.y);

        // Set each objects local pos based on camera
        foreach (obj; gameObjs.getGameObjects()) {
            auto transform = cast(TransformComponent) obj.GetComponent(
                ComponentType.TRANSFORM);
            if (transform !is null) {
                transform.UpdateScreenPos(camera.pos);
            }
        }
        foreach (obj; gameObjs.getGameObjects()) {
            obj.Render();
        }
    }

    void AddGameObject(GameObject go) {
        // gameObjects ~= go;
        gameObjs.AddGameObject(go);
    }

    void SetFreezeFrames(int frames) {
        freezeFrames = frames;
    }
}
