module LevelEditor.buttons;

import LevelEditor.UI;
import bindbc.sdl;

/// A UI button that selects a specific scene in the level editor.
/// Visually highlights itself when selected and calls a delegate to update the current scene.
class SceneButton : Button
{
    int sceneNum;                       /// which number this button selects for
    int* scene;                         /// The current selection
    void delegate(int) sceneSetter;     /// Callback to use to set the scene
    SDL_Renderer* mRendererRef;
    SDL_Rect background1, background2;  /// For bordering. Two of them to make a 2px thick border


    /* Constructor: Initializes a SceneButton with the given scene number and position.
         Params:
             thisScene    = The scene number this button represents.
             r            = SDL renderer used to draw selection border.
             scene        = Pointer to the currently selected scene number.
             sceneSetter  = Delegate function to call when this scene is selected.
             location     = Screen coordinates and size of the button.
    */
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

        // Define border rectangles slightly larger than the button's bounds
        background1 = SDL_Rect(rect.x - 3, rect.y - 3, rect.w + 6, rect.h + 6);
        background2 = SDL_Rect(rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4);
    }
    
    /// Called when the button is clicked.
    /// Invokes the provided scene setter delegate with this button's scene number.
    void Clicked(SDL_Point _)
    {
        sceneSetter(sceneNum);
    }

    /// No-op for drag-over interaction. Included to fulfill expected interface.
    void Dragged(SDL_Point _) { }

    /// Renders a red border around this button if it represents the currently selected scene.
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
