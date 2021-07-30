Architecture
===

Fixed-structure heterogeneous entities with no possibility of adding or removing
components on runtime.

# Entities
Entities are structures that share a common header (preamble), as following:

    Entity
      |
      +-- type_id: int
      +-- flags: int
      +-- x: int
      +-- y: int
      +-- userdata: ptr

An example of a derived entity:

    Player : Entity
      |   ; Common fields
      +-- type_id: int
      +-- flags: int
      +-- x: int
      +-- y: int
      +-- userdata: ptr to any
      |   ; Player fields
      +-- movement: MovementComponent
      +-- health: HealthComponent
      +-- ship: SpriteComponent
      +-- flame: SpriteComponent


# Components
Components are arbitrary structures, the only thing in common they share is a
pointer to the parent entity:

    Component:
      |
      +-- entity: ptr to Entity


An example component:

    HealthComponent : Component
      |   ; Component fields
      +-- entity: ptr to Entity
      |   ; HealthComponent fields
      +-- hp: int


# Entity ops
Entity logic is defined by a set of associated functions (ops), which map to the
value of `type_id` field.

    EntityOps:
      |
      +-- init()  ; called on entity creation
      +-- fini()  ; called upon entity destruction
      +-- tick()  ; called each frame


# Actions
Actions are objects that incapsulate an on-going process and are used to express
various activities performed by entities and on entities, such as attacks, path
following, magic casting and so on.

They may finish instantly, take some time (ticks), or even last forever.

    Action:
      |
      +-- userdata: ptr  ; arbitrary data, passed to `do()`
      +-- done: bool     ; set to `true` when the action is finished
      +-- do()           ; called on each tick, until returns `true`

Actions are typically issued by entities during their tick and queued to some
global array.

After having ticked all entities, the game iterates over this array and calls
the `do()` function of each non-finished action, and if it returns `true`, marks
it as finished and collects it. Actions which return `false` are kept and will
be called the next tick.


# World
Entities live in a "world", that is, an array of currently existing entities
which are processed at every tick.

There are a set of functions that allow to manipulate the world, such as add or
remove entities, query them based on some filter criteria (distance, mask, etc.)
and so on.

### `world_add_entity(entity: ptr)`
Add an entity to the world. Calls `EntityOps.init()` and makes the entity active, i.e. it will be ticked.

### `world_remove_entity(entity: ptr)`
Remove an entity from the world. Calls the `EntityOps.fini()` and marks the entity as destroyed and ready to be collected.

### `world_tick()`
Tick all currently active entities in the world by calling their `EntityOps.tick()` function.
