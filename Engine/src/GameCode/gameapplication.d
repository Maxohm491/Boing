module GameCode.gameapplication;
import engine;
import bindbc.sdl;

class GameApplication : Application
{
    SDL_Renderer* mRendererRef;

    this(SDL_Renderer* r)
    {
        mRendererRef = r;
    }

    override void Start()
    {
        // TODO
    }

    override void Stop()
    {
        // TODO
    }
}
