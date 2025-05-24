module LevelEditor.editor;

import constants;
import engine;
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

    immutable int START_X = 364; /// The x-coord of the start of grid
    immutable int END_Y = 686; /// The y-coord of the end of grid
    bool running = false; /// Whether the editor is currently running

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
        tileTexture.LoadTexture("./assets/images/tilemap.bmp", mRendererRef);
        tilemap = new Tilemap("./assets/images/tilemap.json", mRendererRef, tileTexture);

        // Initialize the editable tile grid
        grid = new Grid(mRendererRef, START_X, END_Y, tilemap, &brush);
        grid.SetDimensions(GRID_X, GRID_Y);
        ui.AddButton(grid);

        // Make brush buttons manually
        ui.AddButton(new BrushButton(1, mRendererRef, &brush, SDL_Rect(20, 100, 290, 144)));
        ui.AddButton(new BrushButton(2, mRendererRef, &brush, SDL_Rect(20, 256, 290, 144)));
        ui.AddButton(new BrushButton(3, mRendererRef, &brush, SDL_Rect(20, 396, 290, 98)));
        ui.AddButton(new BrushButton(4, mRendererRef, &brush, SDL_Rect(20, 494, 303, 144)));
        ui.AddButton(new BrushButton(5, mRendererRef, &brush, SDL_Rect(20, 636, 303, 144)));
        ui.AddButton(new BrushButton(0, mRendererRef, &brush, SDL_Rect(20, 780, 290, 128)));

        // Make scene buttons
        ui.AddButton(new SceneButton(1, mRendererRef, &scene, &SwitchScene, SDL_Rect(669, 734, 75, 84)));
        ui.AddButton(new SceneButton(2, mRendererRef, &scene, &SwitchScene, SDL_Rect(781, 734, 75, 84)));
        ui.AddButton(new SceneButton(3, mRendererRef, &scene, &SwitchScene, SDL_Rect(894, 734, 75, 84)));

        // Make play button
        Button button = new Button();
        button.onClick = &PlayClicked;
        button.rect = SDL_Rect(669, 837, 270, 84);
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
            if (event.type == SDL_MOUSEBUTTONDOWN) {
                mouseX = event.button.x;
                mouseY = event.button.y;

                // Check if this was a click
                if (event.button.state == SDL_PRESSED) {
                    const clickPoint = SDL_Point(mouseX, mouseY);
                    ui.CheckClick(&clickPoint, true); // if not clicked then it wasn't clicked last frame and was just pressed
                }
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

    /// Main tick loop: renders frame and handles input.
    override void Tick() {
        Render();
        Input();
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
