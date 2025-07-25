module core.factories;

import Engine.component;
import physics;
import scripts;
import Engine.gameobject;
import bindbc.sdl;

GameObject CreateMovingSolid(string name, SDL_Point source, SDL_Point dest, SDL_Renderer* r) {
    GameObject plat = MakeSprite(name);

    TransformComponent transform = cast(TransformComponent) plat.GetComponent(
        ComponentType.TRANSFORM);
    TextureComponent texture = cast(TextureComponent) plat.GetComponent(
        ComponentType.TEXTURE);
    SpriteComponent sprite = cast(SpriteComponent) plat.GetComponent(ComponentType.SPRITE);
    ColliderComponent collider = cast(ColliderComponent) plat.GetComponent(
        ComponentType.COLLIDER);

    transform.x = source.x;
    transform.y = source.y;

    texture.LoadTexture("./assets/images/platform.bmp", r);
    sprite.LoadMetaData("./assets/images/platform.json");

    sprite.mRendererRef = r;

    collider.rect.w = 8;
    collider.rect.h = 8;
    collider.offset.x = 0;
    collider.offset.y = 0;

    auto platScript = new MovingPlatform(plat, 60, source, dest);
    plat.AddComponent!(ComponentType.SCRIPT)(platScript);

    return plat;
}
