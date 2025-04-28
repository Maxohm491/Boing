module engine;

import std.stdio;
import bindbc.sdl;
import LevelEditor.editor;
import GameCode.gameapplication;
import constants;

// Both gameapplcation and editor extend this
// Both hould be very self contained and call switchAppCallback() when they want to switch scenes
abstract class Application
{
    void delegate() switchAppCallback;

    void Start();
    void Stop();
}

// This is everything that should be in this class probably don't add more
class MainApplication
{
    SDL_Window* mWindow = null;
    SDL_Renderer* mRenderer = null;

    Editor editor = null;
    GameApplication game = null;

    bool gameRunning = true; // If this is false, then editor is running

    this()
    {
        // Set up window
        mWindow = SDL_CreateWindow("Game", SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED, SCREEN_X, SCREEN_Y, SDL_WINDOW_SHOWN);
        mRenderer = SDL_CreateRenderer(mWindow, -1, SDL_RENDERER_ACCELERATED);

        // Create game application and editor application
        editor = new Editor(mRenderer);
        game = new GameApplication(mRenderer);
        editor.switchAppCallback = &SwitchRunningApp;
        game.switchAppCallback = &SwitchRunningApp;
    }

    ~this()
    {
        SDL_DestroyRenderer(mRenderer);
        SDL_DestroyWindow(mWindow);
    }

    void Run()
    {
        game.Start();
    }

    void SwitchRunningApp()
    {
        if (gameRunning)
        {
            game.Stop();
            editor.Start();
        }
        else
        {
            editor.Stop();
            game.Start();
        }

        gameRunning = !gameRunning;
    }
}

// Main entry point
void main()
{
    MainApplication mainApp = new MainApplication();
    mainApp.Run();
    
    // TEMPORARILY just run editor by defauly
    mainApp.SwitchRunningApp();
}
