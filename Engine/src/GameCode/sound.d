module sound;

import bindbc.sdl.mixer;
import std.stdio;
import std.string;

static class SoundManager {
    static Mix_Chunk* characterDeath;
    static Mix_Chunk* enemy1Death;
    static Mix_Chunk* enemy2Death;
    static Mix_Chunk* shootLaser;

    static void Initialize() {
        characterDeath = Mix_LoadWAV("assets/sounds/character_death.wav");
        enemy1Death    = Mix_LoadWAV("assets/sounds/enemy1_death.wav");
        enemy2Death    = Mix_LoadWAV("assets/sounds/enemy2_death.wav");
        shootLaser     = Mix_LoadWAV("assets/sounds/shoot_laser.wav");

        if (!characterDeath || !enemy1Death || !enemy2Death || !shootLaser) {
            writeln("Failed to load one or more sound files.");
        }
    }

    static void Cleanup() {
        if (characterDeath) Mix_FreeChunk(characterDeath);
        if (enemy1Death)    Mix_FreeChunk(enemy1Death);
        if (enemy2Death)    Mix_FreeChunk(enemy2Death);
        if (shootLaser)     Mix_FreeChunk(shootLaser);

        characterDeath = null;
        enemy1Death = null;
        enemy2Death = null;
        shootLaser = null;
    }

    static void PlayCharacterDeath() {
        if (characterDeath) Mix_PlayChannel(-1, characterDeath, 0);
    }

    static void PlayEnemy1Death() {
        if (enemy1Death) Mix_PlayChannel(-1, enemy1Death, 0);
    }

    static void PlayEnemy2Death() {
        if (enemy2Death) Mix_PlayChannel(-1, enemy2Death, 0);
    }

    static void PlayShootLaser() {
        if (shootLaser) Mix_PlayChannel(-1, shootLaser, 0);
    }
}
