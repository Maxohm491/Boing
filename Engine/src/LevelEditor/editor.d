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
class Editor : Application
{
    SDL_Renderer* mRendererRef;
    UserInterface ui;
    Texture background;
    Tilemap tilemap;
    SDL_Rect backgroundLocation;
    int scene = 1; /// Which scene is selected. 1, 2, or 3.
    int brush = 1; /// Which brush is currently active
    Grid grid; /// The grid of tiles

    immutable int START_X = 364; /// The x-coord of the start of grid
    bool running = false; /// Whether the editor is currently running
    bool clicked = false;

    this(SDL_Renderer* r)
    {
        mRendererRef = r;

        ui = new UserInterface();

        background = new Texture();
        background.LoadTexture("assets/images/editor_background.bmp", mRendererRef);
        backgroundLocation = SDL_Rect(0, 0, SCREEN_X, SCREEN_Y);

        // Load tilemap
        Texture tileTexture = new Texture();
        tileTexture.LoadTexture("assets/images/tilemap.bmp", mRendererRef);
        tilemap = new Tilemap("assets/images/tilemap.json", mRendererRef, tileTexture);

        grid = new Grid(mRendererRef, START_X, tilemap, &brush);
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
    }

    void SwitchScene(int newScene)
    {
        SaveCurrentScene(scene);
        scene = newScene;
        LoadScene(scene);
    }

    void SaveAndPlayClicked()
    {

    }

    void LoadScene(int scene_num)
    {
        auto textIn = readText("src/Scenes/scene" ~ to!string(scene_num) ~ ".json");
        auto root = parseJSON(textIn);
        auto obj = root.object;

        int[GRID_Y][GRID_X] buf; // temporary

        size_t y = 0;
        foreach (rowVal; obj["tiles"].array)
        {
            size_t x = 0;
            foreach (cell; rowVal.array)
                buf[y][x++] = cell.get!int; // or `integer` accessor
            y++;
        }

        grid.start_x = obj["start_x"].get!int; 
        grid.start_y = obj["start_y"].get!int; 
        grid.end_x = obj["end_x"].get!int; 
        grid.end_y = obj["end_y"].get!int;
        grid.tiles = buf; // This is fine since the static array is stored by value

    }

    /// Save the currently loaded scene to the correct scene number file
    void SaveCurrentScene(int scene_num)
    {
        JSONValue[] outer; // rows
        foreach (row; grid.tiles)
        {
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

        std.file.write("src/Scenes/scene" ~ to!string(scene_num) ~ ".json", root.toString());
    }

    void Render()
    {
        SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
        SDL_RenderClear(mRendererRef);
        background.Render(&backgroundLocation);
        ui.Render();
        SDL_RenderPresent(mRendererRef);
    }

    void Input()
    {
        SDL_Event event;
        int mouseX, mouseY;
        while (SDL_PollEvent(&event))
        {
            // Detect quits
            if (event.type == SDL_QUIT)
                running = false;
            if (event.type == SDL_MOUSEBUTTONDOWN)
            {
                mouseX = event.button.x;
                mouseY = event.button.y;

                // Check if this was a click
                if (event.button.state == SDL_PRESSED)
                {
                    const clickPoint = SDL_Point(mouseX, mouseY);
                    ui.CheckClick(&clickPoint, false); // if not clicked then it wasn't clicked last frame and was just pressed
                }
            }
        }

        // Handle drags
        int mask = SDL_GetMouseState(&mouseX, &mouseY);

        // Check if this was a click
        if (mask == SDL_BUTTON_LEFT || mask == SDL_BUTTON_RIGHT)
        {
            const clickPoint = SDL_Point(mouseX, mouseY);
            ui.CheckClick(&clickPoint, !clicked); // if not clicked then it wasn't clicked last frame and was just pressed
        }
        clicked = mask == SDL_BUTTON_LEFT || mask == SDL_BUTTON_RIGHT;
    }

    void Run()
    {
        while (running)
        {
            Render();
            Input();
        }
    }

    override void Start()
    {
        running = true;
        Run();
    }

    override void Stop()
    {
        running = false;
    }
}
