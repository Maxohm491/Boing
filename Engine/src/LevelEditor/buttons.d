module LevelEditor.buttons;

import LevelEditor.UI;
import bindbc.sdl;

class SceneButton : Button
{
    int sceneNum; /// which number this button selects for
    int* scene; /// The current selection
    void delegate(int) sceneSetter; /// Callback to use to set the scene
    SDL_Renderer* mRendererRef;
    SDL_Rect background1, background2; /// For bordering. Two of them to make a 2px thick border

    this(int thisScene, SDL_Renderer* r, int* scene, void delegate(int) sceneSetter, SDL_Rect location)
    {
        rect = location;
        sceneNum = thisScene;
        this.sceneSetter = sceneSetter;
        this.sceneNum = sceneNum;
        this.scene = scene;
        onClick = &Clicked;
        onDragOver = &Dragged;
        mRendererRef = r;
        background1 = SDL_Rect(rect.x - 3, rect.y - 3, rect.w + 6, rect.h + 6);
        background2 = SDL_Rect(rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4);
    }

    void Clicked(SDL_Point _)
    {
        sceneSetter(sceneNum);
    }

    void Dragged(SDL_Point _) { }

    override void Render()
    {
        // If selected, draw a red border
        if (*scene == sceneNum)
        {
            SDL_SetRenderDrawColor(mRendererRef, 255, 0, 0, SDL_ALPHA_OPAQUE);
            SDL_RenderDrawRect(mRendererRef, &background1);
            SDL_RenderDrawRect(mRendererRef, &background2);
            SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
        }
    }
}
