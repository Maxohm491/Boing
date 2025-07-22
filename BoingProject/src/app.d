module app;

import std.stdio;
import bindbc.sdl;
import LevelEditor.editor;
import BoingGame.boinggame;
import Engine.gameapplication;
import constants;
import Engine.resourcemanager;
import core.memory;

// Both gameapplcation and editor extend this
// Both should be very self contained and call switchAppCallback() when they want to switch scenes
abstract class Application
{
    void delegate() switchAppCallback;
    void delegate() quitCallback;

    void Tick();
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
    bool active = true;

    this()
    {
        // Set up window
        mWindow = SDL_CreateWindow("Game", SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED, SCREEN_X, SCREEN_Y, SDL_WINDOW_SHOWN);
        mRenderer = SDL_CreateRenderer(mWindow, -1, SDL_RENDERER_ACCELERATED);

        // Create game application and editor application
        editor = new Editor(mRenderer);
        game = new BoingGameApp(mRenderer);
        editor.switchAppCallback = &SwitchRunningApp;
        game.switchAppCallback = &SwitchRunningApp;
        editor.quitCallback = &Quit;
        game.quitCallback = &Quit;
    }

    ~this()
    {
        SDL_DestroyRenderer(mRenderer);
        SDL_DestroyWindow(mWindow);
    }

    void Run()
    {
        while(active) {
            if(gameRunning)
                game.Tick();
            else
                editor.Tick();
        }
    }

    void SwitchRunningApp()
    {
        if (gameRunning)
        {
            game.Stop();
            editor.scene = game.mCurrScene + 1;
            editor.Start();
        }
        else
        {
            editor.Stop();
            game.mCurrScene  = editor.scene - 1;
            game.Start();
        }
        gameRunning = !gameRunning;
    }

    void Quit()
    {
        active = false;
    }
}

// Main entry point
void main()
{
    writeln("Welcome to Bamn Engine! Esc to edit levels.");
    MainApplication mainApp = new MainApplication();
    mainApp.Run();
    writeln("Goodbye!");
    ResourceManager.FreeAllTextures();
}

