module LevelEditor.editor;

import constants;
import app;
import bindbc.sdl;
import std.stdio;
import LevelEditor.UI;
import LevelEditor.grid;
import LevelEditor.tilemap;
import LevelEditor.brushbutton;
import LevelEditor.buttons;
import constants;
import std.json;
import std.file;
import std.conv;
import std.string;
import std.algorithm;

struct Camera {
    SDL_Point pos; /// The position of the camera on the grid, in screen coordinates relative to the grid portion of the screen.
    alias pos this;
    float zoom = 1.0f;

    /// Positions the camera at the given coordinates.
    void PositionCamera(int x, int y) {
        pos.x = x;
        pos.y = y;
    }
}

// This will be the level editor/tilemap editor
class Editor : Application {
    SDL_Renderer* mRendererRef;
    UserInterface ui;
    Texture background;
    Tilemap tilemap;
    SDL_Rect backgroundLocation;
    int scene = 1; /// Which scene is selected. 1, 2, or 3.
    int brush = 1; /// Which brush is currently active
    Grid grid; /// The grid of tiles

    immutable int START_X = cast(int)(364 * SCALE_FROM_720); /// The x-coord of the start of grid
    immutable int END_Y = cast(int)(512 * SCALE_FROM_720); /// The y-coord of the end of grid
    bool running = false; /// Whether the editor is currently running
    immutable float scrollSpeed = 0.1f;
    immutable int moveSpeed = 1;

    bool leftPressed = false;
    bool rightPressed = false;
    bool upPressed = false;
    bool downPressed = false;
    bool plusPressed = false;
    bool minusPressed = false;
    bool wasPlusPressed = false;
    bool wasMinusPressed = false;
    bool lbPressed = false;
    bool rbPressed = false;
    bool wasLbPressed = false;
    bool wasRbPressed = false;

    Camera camera;

    /// Constructor: initializes the editor, its UI, and scene data.
    this(SDL_Renderer* r) {
        mRendererRef = r;

        ui = new UserInterface();

        // Load background image
        background = new Texture();
        background.LoadTexture("./assets/images/editor_background.bmp", mRendererRef);
        backgroundLocation = SDL_Rect(0, 0, SCREEN_X, SCREEN_Y);

        // Load tilemap
        Texture tileTexture = new Texture();
        tileTexture.LoadTexture("./assets/images/tilemapblank.bmp", mRendererRef);
        tilemap = new Tilemap("./assets/images/tilemap.json", mRendererRef, tileTexture);

        // Initialize the editable tile grid
        grid = new Grid(mRendererRef, START_X, END_Y, tilemap, &brush, &camera);
        ui.AddButton(grid);

        // Make brush buttons manually
        ui.AddButton(new BrushButton(1, mRendererRef, &brush, ScaleRect(SDL_Rect(32, 78, 258, 106), SCALE_FROM_720)));
        ui.AddButton(new BrushButton(2, mRendererRef, &brush, ScaleRect(SDL_Rect(32, 195, 258, 106), SCALE_FROM_720)));
        ui.AddButton(new BrushButton(3, mRendererRef, &brush, ScaleRect(SDL_Rect(32, 299, 253, 80), SCALE_FROM_720)));
        ui.AddButton(new BrushButton(4, mRendererRef, &brush, ScaleRect(SDL_Rect(32, 376, 258, 98), SCALE_FROM_720)));
        ui.AddButton(new BrushButton(5, mRendererRef, &brush, ScaleRect(SDL_Rect(32, 482, 258, 98), SCALE_FROM_720)));
        ui.AddButton(new BrushButton(0, mRendererRef, &brush, ScaleRect(SDL_Rect(32, 586, 290, 128), SCALE_FROM_720)));

        // Make scene buttons
        ui.AddButton(new SceneButton(1, mRendererRef, &scene, &SwitchScene, ScaleRect(SDL_Rect(669, 549, 74, 68), SCALE_FROM_720)));
        ui.AddButton(new SceneButton(2, mRendererRef, &scene, &SwitchScene, ScaleRect(SDL_Rect(781, 549, 74, 68), SCALE_FROM_720)));
        ui.AddButton(new SceneButton(3, mRendererRef, &scene, &SwitchScene, ScaleRect(SDL_Rect(894, 549, 74, 68), SCALE_FROM_720)));

        // Make play button
        Button button = new Button();
        button.onClick = &PlayClicked;
        button.rect = ScaleRect(SDL_Rect(669, 626, 304, 68), SCALE_FROM_720);
        ui.AddButton(button);
    }

    /// Called when the "Play" button is clicked.
    /// Saves the current scene and switches back to the main app.
    void PlayClicked(SDL_Point _) {
        SaveCurrentScene(scene);
        switchAppCallback();
    }

    /// Callback to switch scenes, invoked by SceneButtons.
    void SwitchScene(int newScene) {
        SaveCurrentScene(scene);
        scene = newScene;
        LoadScene(scene);
    }

    /// Load a scene to the correct scene number file
    void LoadScene(int scene_num) {
        auto textIn = readText("./assets/scenes/scene" ~ to!string(scene_num) ~ ".json");
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
            foreach (cell; rowVal.array)
                buf[y][x++] = cell.get!int;
            y++;
        }

        grid.start_x = obj["start_x"].get!int;
        grid.start_y = obj["start_y"].get!int;
        grid.end_x = obj["end_x"].get!int;
        grid.end_y = obj["end_y"].get!int;
        grid.SetDimensions(cast(int) buf.length, cast(int) buf[0].length);
        grid.tiles = buf; // This is fine but might break someday
    }

    /// Save the currently loaded scene to the correct scene number file
    void SaveCurrentScene(int scene_num) {
        JSONValue[] outer; // rows
        foreach (row; grid.tiles) {
            JSONValue[] inner; // cols
            foreach (v; row)
                inner ~= JSONValue(v); // scalar number
            outer ~= JSONValue(inner);
        }

        JSONValue[string] obj;
        obj["start_x"] = JSONValue(grid.start_x);
        obj["start_y"] = JSONValue(grid.start_y);
        obj["end_x"] = JSONValue(grid.end_x);
        obj["end_y"] = JSONValue(grid.end_y);
        obj["tiles"] = JSONValue(outer);

        auto root = JSONValue(obj);

        std.file.write("./assets/scenes/scene" ~ to!string(scene_num) ~ ".json", root.toString());
    }

    /// Renders the full editor UI and background.
    void Render() {
        SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
        SDL_RenderClear(mRendererRef);
        background.Render(&backgroundLocation);
        ui.Render();
        SDL_RenderPresent(mRendererRef);
    }

    /// Processes SDL input events, including mouse clicks and drags.
    void Input() {
        SDL_Event event;
        int mouseX, mouseY;
        while (SDL_PollEvent(&event)) {
            // Detect quits
            if (event.type == SDL_QUIT)
                quitCallback();
            else if (event.type == SDL_MOUSEBUTTONDOWN) {
                mouseX = event.button.x;
                mouseY = event.button.y;

                // Check if this was a click
                if (event.button.state == SDL_PRESSED) {
                    const clickPoint = SDL_Point(mouseX, mouseY);
                    ui.CheckClick(&clickPoint, true); // if not clicked then it wasn't clicked last frame and was just pressed
                }
            } else if (event.type == SDL_MOUSEWHEEL) {
                camera.zoom = clamp(camera.zoom + event.wheel.y * scrollSpeed, 0.1f, 10.0f);
                grid.RecalculateSquareSize();
            } else if (event.type == SDL_KEYDOWN) {
                auto key = event.key.keysym.sym;
                // Should probably be another switch but oh well
                if (key == SDLK_a || key == SDLK_LEFT)
                    leftPressed = true;
                else if (key == SDLK_d || key == SDLK_RIGHT)
                    rightPressed = true;
                else if (key == SDLK_w || key == SDLK_UP)
                    upPressed = true;
                else if (key == SDLK_s || key == SDLK_DOWN)
                    downPressed = true;
                else if (key == SDLK_EQUALS)
                    plusPressed = true;
                else if (key == SDLK_MINUS)
                    minusPressed = true;
                else if (key == SDLK_LEFTBRACKET)
                    lbPressed = true;
                else if (key == SDLK_RIGHTBRACKET)
                    rbPressed = true;

            } else if (event.type == SDL_KEYUP) {
                auto key = event.key.keysym.sym;
                if (key == SDLK_a || key == SDLK_LEFT)
                    leftPressed = false;
                else if (key == SDLK_d || key == SDLK_RIGHT)
                    rightPressed = false;
                else if (key == SDLK_w || key == SDLK_UP)
                    upPressed = false;
                else if (key == SDLK_s || key == SDLK_DOWN)
                    downPressed = false;
                else if (key == SDLK_EQUALS)
                    plusPressed = false;
                else if (key == SDLK_MINUS)
                    minusPressed = false;
                else if (key == SDLK_LEFTBRACKET)
                    lbPressed = false;
                else if (key == SDLK_RIGHTBRACKET)
                    rbPressed = false;
            }
        }

        // Handle drags
        int mask = SDL_GetMouseState(&mouseX, &mouseY);

        // Check if this was a click
        if (mask == SDL_BUTTON_LEFT || mask == SDL_BUTTON_RIGHT) {
            const clickPoint = SDL_Point(mouseX, mouseY);
            ui.CheckClick(&clickPoint, false); // if not clicked then it wasn't clicked last frame and was just pressed
        }
    }

    SDL_Rect ScaleRect(SDL_Rect rect, float scale) {
        return SDL_Rect(
            cast(int)(rect.x * scale),
            cast(int)(rect.y * scale),
            cast(int)(rect.w * scale),
            cast(int)(rect.h * scale)
        );
    }

    /// Main tick loop: renders frame and handles input.
    override void Tick() {
        Render();
        Input();

        int moveAmount = max(1, cast(int)(camera.zoom * moveSpeed));
        // Move camera based on input
        if (leftPressed)
            camera.x = cast(int) max(0, camera.x - moveAmount);
        if (rightPressed)
            camera.x = cast(int) min(grid.width * grid.square_size, camera.x + moveAmount);
        if (upPressed)
            camera.y = cast(int) max(0, camera.y - moveAmount);
        if (downPressed)
            camera.y = cast(int) min(grid.height * grid.square_size, camera.y + moveAmount);

        // Resize grid
        if (plusPressed && !wasPlusPressed)
            grid.AddColumn();

        if (minusPressed && !wasMinusPressed)
            grid.RemoveColumn();

        if (lbPressed && !wasLbPressed)
            grid.RemoveRow();

        if (rbPressed && !wasRbPressed)
            grid.AddRow();   

        wasPlusPressed = plusPressed;
        wasMinusPressed = minusPressed;
        wasLbPressed = lbPressed;
        wasRbPressed = rbPressed;
    }

    /// Called when the editor is started. Loads the currently selected scene.
    override void Start() {
        LoadScene(scene);
    }

    /// Called when the editor is stopped. Saves the current scene state.
    override void Stop() {
        SaveCurrentScene(scene);
    }
}
