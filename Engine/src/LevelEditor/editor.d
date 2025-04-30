module LevelEditor.editor;

import constants;
import engine;
import bindbc.sdl;
import std.stdio;
import LevelEditor.UI;
import LevelEditor.grid;
import LevelEditor.tilemap;
import LevelEditor.brushbutton;
import constants;

// This will be the level editor/tilemap editor
class Editor : Application
{
    SDL_Renderer* mRendererRef;
    UserInterface ui;
    Texture background;
    Tilemap tilemap;
    SDL_Rect backgroundLocation;
    int brush = 1;
    Grid grid;

    immutable int START_X = 364; // start of grid
    bool running = false;
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
    }

    void SwitchSceneClicked()
    {

    }

    void SaveAndPlayClicked()
    {

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
        while (SDL_PollEvent(&event))
        {
            // Detect quits
            if (event.type == SDL_QUIT)
                running = false;
        }

        int mouseX, mouseY;
        int mask = SDL_GetMouseState(&mouseX, &mouseY);

        // Check if this was a click
        if (mask == SDL_BUTTON_LEFT || mask == SDL_BUTTON_RIGHT)
        {
            const clickPoint = SDL_Point(mouseX, mouseY);
            if (!clicked)
            {
                writeln(mouseX, " : ", mouseY);
            }
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
