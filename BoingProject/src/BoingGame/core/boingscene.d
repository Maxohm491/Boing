module BoingGame.gamescene;

import Engine.scene;
import Engine.component;
import Engine.tilemapcomponents;
import Engine.gameobject;
import Engine.gameapplication;
import Engine.camerascript;
import BoingGame.boingcamera;
import physics;
import core.factories;
import scripts;
import constants;
import std.algorithm;
import bindbc.sdl;
import std.json;
import std.format;
import std.conv;
import std.file;
import std.random;
import std.math;

import std.stdio;

class BoingScene : Scene {
    SDL_Point mSpawnPoint;
    GameObject tilemap;
    ColliderComponent[] solids; // For collision detection
    Actor[] actors;

    this(SDL_Renderer* r, int sceneIndex, void delegate() onComplete) {
        super(r, onComplete);

        LoadSceneFromJson("./assets/scenes/scene" ~ to!string(sceneIndex) ~ ".json");
    }

    override void Input(SDL_Event event) {
        // Handle input specific to BoingGame
        super.Input(event);
    }

    override void Update() {
        // Update logic specific to BoingGame
        super.Update();
        // Check if player is missing, respawn if needed
        bool playerExists = false;
        foreach (obj; gameObjects) {
            if (obj.GetName() == "player") {
                playerExists = true;
            }
        }
        if (!playerExists) {
            actors.length = 0;
            AddGameObject(MakePlayer());
        }

        // Check if any apple is missing, call completion if needed
        bool appleExists = false;
        foreach (obj; gameObjects) {
            if (obj.GetName().startsWith("apple")) {
                appleExists = true;
                break;
            }
        }
        if (!appleExists) {
            mOnComplete();
        }
    }

    GameObject MakePlayer() {
        player = null;
        player = MakeSprite("player");
        TransformComponent transform = cast(TransformComponent) player.GetComponent(
            ComponentType.TRANSFORM);
        TextureComponent texture = cast(TextureComponent) player.GetComponent(
            ComponentType.TEXTURE);
        SpriteComponent sprite = cast(SpriteComponent) player.GetComponent(ComponentType.SPRITE);
        ColliderComponent collider = cast(ColliderComponent) player.GetComponent(
            ComponentType.COLLIDER);

        transform.SetPos(mSpawnPoint.x, mSpawnPoint.y);

        texture.LoadTexture("./assets/images/character3.bmp", mRendererRef);
        sprite.LoadMetaData("./assets/images/character3.json");

        sprite.mRendererRef = mRendererRef;

        collider.rect.w = 5;
        collider.rect.h = 4;
        collider.offset.x = 0;
        collider.offset.y = 1;
        collider.rect.x = transform.x;
        collider.rect.y = transform.y;
        // collider.rect.w = PIXELS_PER_TILE;
        // collider.rect.h = (PIXELS_PER_TILE * 5) / 8;
        // collider.offset.x = 0;
        // collider.offset.y = (PIXELS_PER_TILE * 3) / 8;

        collider.solids = &solids; // Set the pointer to the dynamic array of solids
        collider.tilemap = &tilemap;

        auto input = new InputComponent(player);
        player.AddComponent!(ComponentType.INPUT)(input);

        auto playScript = new JumpPlayer(player);
        // playScript.mScene = this;
        playScript.mTilemap = cast(TilemapCollider) tilemap.GetComponent(
            ComponentType.TILEMAP_COLLIDER);
        player.AddComponent!(ComponentType.SCRIPT)(playScript);

        actors ~= playScript.actor;

        return player;
    }

    GameObject MakeApple(SDL_Point location) {
        GameObject apple = MakeCollider("apple" ~ to!string(GameObject.sGameObjectCount + 1));
        TransformComponent transform = cast(TransformComponent) apple.GetComponent(
            ComponentType.TRANSFORM);
        ColliderComponent collider = cast(ColliderComponent) apple.GetComponent(
            ComponentType.COLLIDER);

        transform.SetPos(location.x, location.y);

        collider.rect.w = PIXELS_PER_TILE;
        collider.rect.h = PIXELS_PER_TILE; // be generous
        collider.solids = &solids; // Set the pointer to the dynamic array of solids
        collider.tilemap = &tilemap;

        return apple;
    }

    GameObject MakeSpike(SDL_Point location, bool up) {
        GameObject spike = MakeCollider("spike");
        TransformComponent transform = cast(TransformComponent) spike.GetComponent(
            ComponentType.TRANSFORM);
        ColliderComponent collider = cast(ColliderComponent) spike.GetComponent(
            ComponentType.COLLIDER);

        transform.SetPos(location.x, location.y);

        collider.rect.w = PIXELS_PER_TILE;
        collider.rect.h = PIXELS_PER_TILE / 2; // be generous
        if (up) {
            collider.offset.y = PIXELS_PER_TILE / 2;
        }
        collider.solids = &solids; // Set the pointer to the dynamic array of solids
        collider.tilemap = &tilemap;

        return spike;
    }

    GameObject MakeShooter(SDL_Point location, bool right) {
        GameObject shooter = MakeTransform("shooter");
        TransformComponent transform = cast(TransformComponent) shooter.GetComponent(
            ComponentType.TRANSFORM);

        transform.SetPos(location.x, location.y);

        Shooter script = new Shooter(shooter);
        script.mTilemap = cast(TilemapCollider) tilemap.GetComponent(
            ComponentType.TILEMAP_COLLIDER);
        script.right = right;
        script.mRendererRef = mRendererRef;
        script.spawnFunction = &AddGameObject;
        shooter.AddComponent!(ComponentType.SCRIPT)(script);

        return shooter;
    }

    /// Loads a scene from a JSON file, creating GameObjects based on tile definitions.
    ///
    /// Params:
    ///     filename = Path to the scene JSON file.
    void LoadSceneFromJson(string filename) {
        camera = new Camera();
        camera.PositionCamera(-50, 0);

        tilemap = GameObjectFactory!(ComponentType.TRANSFORM, ComponentType.TEXTURE,
            ComponentType.TILEMAP_COLLIDER, ComponentType.TILEMAP_SPRITE)("tilemap");

        auto textIn = readText(filename);
        auto root = parseJSON(textIn);
        auto obj = root.object;

        int[][] buf;

        auto tilesArray = obj["tiles"].array;
        buf.length = tilesArray.length;
        foreach (i, ref row; buf)
            row.length = tilesArray[i].array.length;

        size_t y = 0;
        foreach (rowVal; tilesArray) {
            size_t x = 0;
            foreach (cell; rowVal.array) {
                int value = cell.get!int;
                if (value == 19) // Start tile
                {
                    mSpawnPoint = SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x));
                    value = 16;
                } else if (value == 20) // End tile
                {
                    value = 28; // apple
                    AddGameObject(MakeApple(SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x))));
                } else if (value == 17) // up spike
                    AddGameObject(MakeSpike(SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x)), true));
                else if (value == 23) // down spike
                    AddGameObject(MakeSpike(SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x)), false));
                else if (value == 18) // left shooter 
                    AddGameObject(MakeShooter(SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x)), false));
                else if (value == 26) // right shooter 
                    AddGameObject(MakeShooter(SDL_Point(cast(int)(PIXELS_PER_TILE * y), cast(int)(
                            PIXELS_PER_TILE * x)), true));
                buf[y][x++] = value;
            }
            y++;
        }

        TransformComponent transform = cast(TransformComponent) tilemap.GetComponent(
            ComponentType.TRANSFORM);
        TextureComponent texture = cast(TextureComponent) tilemap.GetComponent(
            ComponentType.TEXTURE);
        TilemapSprite sprite = cast(TilemapSprite) tilemap.GetComponent(
            ComponentType.TILEMAP_SPRITE);
        TilemapCollider collider = cast(TilemapCollider) tilemap.GetComponent(
            ComponentType.TILEMAP_COLLIDER);

        transform.SetPos(0, 0); // Always 0, 0 but needs to be here for camera purposes

        texture.LoadTexture("./assets/images/tilemapblank.bmp", mRendererRef);
        sprite.LoadMetaData("./assets/images/tilemap.json");

        sprite.mRendererRef = mRendererRef;
        sprite.LoadTiles(buf);
        collider.LoadTiles(buf);

        AddGameObject(tilemap);
        AddGameObject(MakePlayer());

        auto plat = CreateMovingSolid("movingSolid1", SDL_Point(0, 0), SDL_Point(64, 0), mRendererRef);
        AddGameObject(plat);
        solids ~= cast(ColliderComponent) plat.GetComponent(ComponentType.COLLIDER);
        (cast(MovingPlatform) plat.GetComponent(ComponentType.SCRIPT)).solid.actors = &actors;

        cameraScript = new BoingCamera();
        (cast(BoingCamera) cameraScript).left = 0; // Set the min camera position
        (cast(BoingCamera) cameraScript).right = cast(int)(tilesArray.length * 8 - GRID_X * 8); //(buf.length * PIXELS_PER_TILE) - SCREEN_X; //
        cameraScript.camera = camera; // Set the camera reference for the script
    }
}
