module LevelEditor.editor;

import constants;
import engine;
import bindbc.sdl;
import std.stdio;

// This will be the level editor/tilemap editor
class Editor : Application
{
    SDL_Renderer* mRendererRef;

    this(SDL_Renderer* r)
    {
        mRendererRef = r;
    }

    override void Start()
    {
        // TODO
        writeln("Started");
    }

    override void Stop()
    {
        // TODO
    }

    void AdvanceFrame()
    {
    }

    // TODO: Get rid of this and just call advance frame in 
    void Run()
    {
        while (true)
        {
            AdvanceFrame();
        }
    }
}
