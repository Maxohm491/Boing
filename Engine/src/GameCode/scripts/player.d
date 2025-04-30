module GameCode.scripts.player;
import GameCode.component;
import GameCode.gameobject;
import GameCode.scripts.script;

class Player : ScriptComponent
{
    GameObject mOwner;
    TransformComponent mTransformRef;
    ColliderComponent mColliderRef;
    SpriteComponent mSpriteRef;
    InputComponent mInputRef;
    float runSpeed = 7;
    float vel_y = 0;
    bool grounded = true;

    this(GameObject owner)
    {
        mOwner = owner;

        mTransformRef = cast(TransformComponent) owner.GetComponent(ComponentType.TRANSFORM);
        mColliderRef = cast(ColliderComponent) owner.GetComponent(ComponentType.COLLIDER);
        mInputRef = cast(InputComponent) mOwner.GetComponent(ComponentType.INPUT);
        mSpriteRef = cast(SpriteComponent) mOwner.GetComponent(ComponentType.SPRITE);

        mSpriteRef.SetAnimation("idle");
    }

    override void Update()
    {
        mTransformRef.Translate(runSpeed * mInputRef.GetDir(), 0);
    }
}
