module LevelEditor.editor;

import constants;
import engine;
import bindbc.sdl;
import std.stdio;
import LevelEditor.UI;
import LevelEditor.tiles;
import LevelEditor.tilemap;
import constants;

// This will be the level editor/tilemap editor
class Editor : Application
{
    SDL_Renderer* mRendererRef;
    UserInterface ui;
    Texture background;
    SDL_Rect backgroundLocation;
    bool running = false;
    bool clicked = false;

    this(SDL_Renderer* r)
    {
        mRendererRef = r;

        ui = new UserInterface();

        background = new Texture();
        background.LoadTexture("assets/background.bmp", mRendererRef);
        backgroundLocation = SDL_Rect(0, 0, SCREEN_X, SCREEN_Y);
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
