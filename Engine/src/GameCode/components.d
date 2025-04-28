module component;
import sprite; 
import std.math;
import std.random;

import bindbc.sdl;


enum COMPONENTS {SCRIPT}; 

abstract class IComponent{
	Sprite self;
    void delegate() input;
    void delegate() update;
}

class ScriptComponent : IComponent{
    //input and update functions
    
    //constructor
    this(Sprite owner){
        self = owner;
        //type 1 is ENEMY, 2 is PLAYER, 3 is BULLET
        if(owner.type == 1){
            input = &enemyInput;
            update = &enemyUpdate;
        } else if (owner.type == 2){
            input = &playerInput;
            update = &playerUpdate;
        } else if (owner.type == 3){
            input = &bulletInput;
            update = &bulletUpdate;
        } else if (owner.type == 4){
            input = &meteorInput;
            update = &meteorUpdate;
        } 
    }

    void playerInput(){
        const Uint8* state = SDL_GetKeyboardState(null);

        if(state[SDL_SCANCODE_W]){
            self.velocity_x = 2 * sin(self.angle * PI / 180.0f);
            self.velocity_y = 2 * cos(self.angle * PI / 180.0f);
        } else if(state[SDL_SCANCODE_D]){
            self.angle += 3;
            self.velocity_x = 0;
            self.velocity_y = 0;
        } else if(state[SDL_SCANCODE_A]){
            self.angle += -3;
            self.velocity_x = 0;
            self.velocity_y = 0;
        } else {
            self.velocity_x = 0;
            self.velocity_y = 0;
        }
    }

    void bulletInput(){
        const Uint8* state = SDL_GetKeyboardState(null);
        if(state[SDL_SCANCODE_SPACE]){
            self.velocity_x = 3 * sin(self.angle * PI / 180.0f);
            self.velocity_y = 3 * cos(self.angle * PI / 180.0f);
        }
    }

    void enemyInput(){
        // No input needed
    }

    void meteorInput(){
        // No input needed
    }

    void playerUpdate(){
        // Have the sprite move

        if (self.velocity_x > 3){
            self.velocity_x = 3;
        }
        if (self.velocity_x < -3){
            self.velocity_x = -3;
        }
        if (self.velocity_y > 3){
            self.velocity_y = 3;
        }
        if (self.velocity_y < -3){
            self.velocity_y = -3;
        }
    }

    void bulletUpdate(){
        if (self.velocity_x != 0) {
            if (self.mRectangle.y < 0){
                self.velocity_x = 0;
                self.velocity_y = 0;
            } else if (self.mRectangle.y > 800){
                self.velocity_x = 0;
                self.velocity_y = 0;
            } else if (self.mRectangle.x < 0){
                self.velocity_x = 0;
                self.velocity_y = 0;
            } else if (self.mRectangle.x > 1000){
                self.velocity_x = 0;
                self.velocity_y = 0;
            }
                
            self.mRectangle.x += cast(int) round(self.velocity_x);
            self.mRectangle.y -= cast(int) round(self.velocity_y);
        }
    }

    void enemyUpdate(){
        if (self.collided == 1){
            self.mRectangle.y = 2000;
            return;
        }
        if (self.mRectangle.x < 0 || self.mRectangle.x > 1000 || self.mRectangle.y < 0 || self.mRectangle.y > 800) {
            int randomNumber = uniform(1, 5);
            if (randomNumber == 1){
                self.mRectangle.x = 0;
                self.mRectangle.y = uniform(0, 800);
                self.angle = uniform(40, 140);
                self.velocity_x = 2 * sin(self.angle * PI / 180.0f);
                self.velocity_y = 2 * cos(self.angle * PI / 180.0f);
            } else if (randomNumber == 2){
                self.mRectangle.x = 1000;
                self.mRectangle.y = uniform(0, 800);
                self.angle = uniform(220, 320);
                self.velocity_x = 2 * sin(self.angle * PI / 180.0f);
                self.velocity_y = 2 * cos(self.angle * PI / 180.0f);
            } else if (randomNumber == 3){
                self.mRectangle.y = 0;
                self.mRectangle.x = uniform(0, 1000);
                self.angle = uniform(130, 230);
                self.velocity_x = 2 * sin(self.angle * PI / 180.0f);
                self.velocity_y = 2 * cos(self.angle * PI / 180.0f);
            } else if (randomNumber == 4){
                self.mRectangle.y = 800;
                self.mRectangle.x = uniform(0, 1000);
                self.angle = uniform(-140, 140);
                self.velocity_x = 2 * sin(self.angle * PI / 180.0f);
                self.velocity_y = 2 * cos(self.angle * PI / 180.0f);
            }  
        }
        self.mRectangle.x += cast(int) round(self.velocity_x);
        self.mRectangle.y -= cast(int) round(self.velocity_y);
    }

    void meteorUpdate(){
        //no update needed
    }

}
