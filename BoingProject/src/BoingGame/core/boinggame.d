module BoingGame.boinggame;

import Engine.gameapplication;
import BoingGame.gamescene;
import bindbc.sdl;

class BoingGameApp : GameApplication {
    this(SDL_Renderer* r) {
        super(r);

        // Initialize BoingGame specific components, scenes, etc.
        mScenes ~= new BoingScene(r, 1, &AdvanceScene);
		mScenes ~= new BoingScene(r, 2, &AdvanceScene);
		mScenes ~= new BoingScene(r, 3, &AdvanceScene);
    }

    override void Start()
	{
		LoadScenesFromJsons();
	}
    
    void LoadScenesFromJsons()
	{
		mScenes = null;

		mScenes ~= new BoingScene(mRendererRef, 1, &AdvanceScene);
		mScenes ~= new BoingScene(mRendererRef, 2, &AdvanceScene);
		mScenes ~= new BoingScene(mRendererRef, 3, &AdvanceScene);
	}

    void AdvanceScene()
	{
		mCurrScene++;
		if (mCurrScene > 2)
		{
			mCurrScene = 0;
			switchAppCallback();
		}
	}
}