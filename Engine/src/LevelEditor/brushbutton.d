module LevelEditor.brushbutton;

import bindbc.sdl;
import LevelEditor.UI;

// Select a brush on the left
class BrushButton : Button
{
    int brushType; // see grid for different values
    int* brush;
    SDL_Renderer* mRendererRef;
    SDL_Rect background1, background2; // For bordering. Two of them to make a 2px thick border

    this(int thisBrush, SDL_Renderer* r, int* brush, SDL_Rect location)
    {
        rect = location;
        brushType = thisBrush;
        this.brush = brush;
        onClick = &Clicked;
        onDragOver = &Dragged;
        mRendererRef = r;
        background1 = SDL_Rect(rect.x - 3, rect.y - 3, rect.w + 6, rect.h + 6);
        background2 = SDL_Rect(rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4);
    }

    void Clicked(SDL_Point _)
    {
        *brush = brushType;
    }

    void Dragged(SDL_Point _) { }

    override void Render()
    {
        // If selected, draw a red border
        if (*brush == brushType)
        {
            SDL_SetRenderDrawColor(mRendererRef, 255, 0, 0, SDL_ALPHA_OPAQUE);
            SDL_RenderDrawRect(mRendererRef, &background1);
            SDL_RenderDrawRect(mRendererRef, &background2);
            SDL_SetRenderDrawColor(mRendererRef, 0, 0, 0, SDL_ALPHA_OPAQUE);
        }
    }
}