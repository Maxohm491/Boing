module LevelEditor.UI;

import bindbc.sdl;
import std.stdio;

// Makin a custom ui interface cause I don't feel like figuring out the libraries

/// A button object. Can be inherited from; make sure to set onClick.
class Button
{
    SDL_Rect rect;
    void delegate(SDL_Point) onClick;
    void delegate(SDL_Point) onDragOver;

    void Render() {}
}

/// Will work by storing an array of buttons and just seeing which is clicked
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
                else if (button.onDragOver !is null)
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
