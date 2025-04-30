module GameCode.gameapplication;
import bindbc.sdl;
import GameCode.scene;
import engine;
import std.algorithm;

class GameApplication : Application
{
    SDL_Renderer* mRendererRef;
    bool running = false;

    Scene[] mScenes;
    int mCurrScene;

    this(SDL_Renderer* r)
    {
        mRendererRef = r;
    }

    void Input()
	{
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			// Either quit or let the scene handle it
			if (event.type == SDL_QUIT)
				running = false;
			else
				mScenes[mCurrScene].Input(event);
		}
	}

	void Render()
	{
		SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
		SDL_RenderClear(mRendererRef);

		mScenes[mCurrScene].Render();

		SDL_RenderPresent(mRendererRef);
	}

	void Update()
	{
		mScenes[mCurrScene].Update();
	}

	void AdvanceFrame()
	{
		Input();
		Update();
		Render();
	}

    void LoadScenesFromJsons() {
        // TEMPORARY
        // mScenes ~= new Scene();
    }

	void Run()
	{
		while (running)
		{
			// Cap frames
			int start = SDL_GetTicks();
			AdvanceFrame();

			int delay = start + 16 - int(SDL_GetTicks());
			SDL_Delay(max(delay, 0));
		}
	}

    override void Start()
    {
        running = true;
        // Run();
    }

    override void Stop()
    {
        running = false;
    }
}
