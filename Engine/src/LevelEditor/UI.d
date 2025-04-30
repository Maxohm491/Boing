module LevelEditor.UI;

import bindbc.sdl;

// Makin a custom ui interface cause I don't feel like figuring out the libraries

// Mostly for tracking where each button is
abstract class Button
{
    SDL_Rect rect;
    void delegate(SDL_Point) onClick;
    void delegate(SDL_Point) onDragOver;

    void Render();
}

// class LevelButton : Button
// {
//     void function(bool) globalLevelSetter; // bad dependent code
//     bool isBottomButton;
//     bool* mIsBottomOn;

//     SDL_Renderer* mRendererRef;
//     SDL_Rect background1, background2;

//     this(void function(bool) setter, bool isBottomButton, SDL_Rect location, SDL_Renderer* r, bool* isBottomOn)
//     {
//         rect = location;
//         // Two more backgrounds for thicker border
//         background1 = SDL_Rect(rect.x - 1, rect.y - 1, rect.w + 2, rect.h + 2);
//         background2 = SDL_Rect(rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4);
//         globalLevelSetter = setter;
//         this.isBottomButton = isBottomButton;
//         mRendererRef = r;
//         mIsBottomOn = isBottomOn;
//         onClick = &Click;
//         onDragOver = &Click;
//     }

//     void Click()
//     {
//         globalLevelSetter(isBottomButton);
//     }

//     override void Render()
//     {
//         if (isBottomButton == *mIsBottomOn)
//         {
//             SDL_SetRenderDrawColor(mRendererRef, 255, 0, 0, SDL_ALPHA_OPAQUE);
//             SDL_RenderDrawRect(mRendererRef, &rect);
//             SDL_RenderDrawRect(mRendererRef, &background1);
//             SDL_RenderDrawRect(mRendererRef, &background2);
//             SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
//         }
//     }
// }

// Will work by storing an array of buttons and just seeing which is clicked
class UserInterface
{
    Button[] mButtons;
    void AddButton(Button newButton)
    {
        mButtons ~= newButton;
    }

    // Process a click at coords x ,y. Pass if the mouse was just clicked then
    void CheckClick(const SDL_Point* point, bool justPressed)
    {
        foreach (button; mButtons)
        {
            if (SDL_PointInRect(point, &(button.rect)))
            {
                if (justPressed)
                    button.onClick(*point);
                else
                    button.onDragOver(*point);
                return;
            }
        }
    }

    void Render()
    {
        foreach (button; mButtons)
        {
            button.Render();
        }
    }
}
