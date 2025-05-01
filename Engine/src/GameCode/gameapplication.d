module GameCode.gameapplication;
import bindbc.sdl;
import GameCode.scene;
import engine;
import std.algorithm;
import std.stdio;

class GameApplication : Application
{
    SDL_Renderer* mRendererRef;

    Scene[] mScenes;
    int mCurrScene = 0;

    this(SDL_Renderer* r)
    {
        mRendererRef = r;
		mScenes ~= new Scene(r, 1);
    }

    void Input()
	{
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			// Either quit or let the scene handle it
			if (event.type == SDL_QUIT)
				quitCallback();
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

	override void Tick() {
		int start = SDL_GetTicks();
		AdvanceFrame();

		int delay = start + 16 - int(SDL_GetTicks());
		SDL_Delay(max(delay, 0)); // Make sure no overflows
	}

    override void Start()
    {
		mScenes[0] = new Scene(mRendererRef, 1);
    }

    override void Stop()
    {
    }
}
