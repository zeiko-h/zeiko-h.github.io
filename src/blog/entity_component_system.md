---
title: "Writing an Entity Component System from scratch in Zig"
date: "2026-06-17"
---

Hello, this post will talk about an entity component system.

## What is an ECS?
An entity component system is a way to design a program, commonly used in game development.
This design focuses on separation of an 'entity' and its associated data 'components'.
Generally, the entity is a unique id, and for every component type there is an array of that type.
This allows you to iterate over components rather than objects, which as discussed in the famous data oriented design talk,
is good for cpu stuff and makes your program more performant.


Catherine West's [RustConf ECS talk](https://www.youtube.com/watch?v=aKLntZcp27M) is a great primer on ECS.


Here is an example of doing a game in an OOP like fashion:
``` zig
const std = @import("std");

const Pos = struct {
    x: i32,
    y: i32,
};

const Player = struct {
    pos: Pos = .{ .x = 10, .y = 10 },
    hp: i32 = 10,
    renderable: Renderable = Renderable{},
    pub fn handle_input(self: *Player) void {
        _ = self;
    }
};

const Monster = struct {
    pos: Pos = .{ .x = 0, .y = 0 },
    hp: i32 = 5,
    sound: []const u8 = "ROAR!!!\n",
    ai: Ai = Ai{},
    renderable: Renderable = Renderable{},
};

const Ai = struct {
    // pretend to do ai
    pub fn do_ai(self: *const Ai) void {
        _ = self;
        std.debug.print("Doing ai\n", .{});
    }
};

const Renderable = struct {
    // pretend to render
    pub fn render(self: *const Renderable) void {
        _ = self;
        std.debug.print("Rendering...\n", .{});
    }

};

pub fn main() !void {
    var player: Player = .{};
    const monster_list = [_]Monster{ Monster{}, Monster{} };

    player.handle_input();
    for (monster_list) |monster| {
        monster.ai.do_ai();
    }

    for (monster_list) |monster| {
        monster.renderable.render();
        player.renderable.render();
    }
}
```

If you can imagine continuing to build a game,
adding more systems and members to each 'class', 
eventually you might wind up with some really large classes with many fields,
or some sort of inheritance which can make it difficult to share code.
Overall I think the deficiencies of OOP in game development have been stated plenty,
the advice I hear today is to favour composition over inheritance.


Lets see what that would look like, following this style:
``` zig
const std = @import("std");

const PositionComponent = struct {
    x: i32 = 0,
    y: i32 = 0,
};

const HpComponent = struct {
    health: i32 = 10,
};

const RenderableComponent = struct {
    glyph: u8 = '@',
};

const AiComponent = struct {
    something: u8 = ' ',
};

const Entity = struct {
    position: PositionComponent = .{},
    hp: HpComponent = .{},
    renderable: RenderableComponent = .{},
    ai: AiComponent = .{},
};

pub fn do_ai(entity: *Entity) void{
    _ = entity;
    std.debug.print("ai...\n", .{});
}

pub fn render(entity: *Entity) void{
    _ = entity;
    std.debug.print("rendering...\n", .{});
}

pub fn handle_input(entity: *Entity) void{
    entity.position.x = entity.position.x + 1;
    std.debug.print("input...\n", .{});
}

pub fn main() !void {
    var player: Entity = .{};

    var entity_list= [_]Entity{.{}} ** 5;
    entity_list[0] = Entity{};

    handle_input(&player);
    for (&entity_list) |*entity| {
        do_ai(entity);
    }

    for (&entity_list) |*entity| {
        render(entity);
    }
}
```
I feel like this style is better, it separates the data (components) from the systems (functions to act on data).


Again though, you can imagine having more and more components and systems,
and having a very large class which holds a bunch of optional components.
I guess this is fine, people make games like this (even in the OOP style - yuck),
I have heard of these paradigms as [Arrays of Structs and Structs of Arrays]().
Our example is clearly an array of structs, and I don't think there is a compelling reason to leave it that way.


Let's see what a struct of arrays (of components) would look like:




The above example has several problems

- Code duplication (inheritance vs composition)
- Consistent cache misses (data oriented design)

These problems can be mitigated, and I have really enjoyed Bob Nystrom's talk, and Game Programming Patterns book
on using the good parts of OOP. 

To give a quick example of how an ECS would be used (for context's sake):
``` cpp
Component position{
    int x;
    int y;
}

Component graphic{
    Texture texture;
}

while(true){
    player->do_action();
    for (const auto graphic : GraphicComponentList) {
        graphic->render();
    }
    for (const auto ai : AiComponentList) {
        ai->do_ai();
    }
}

```

You can do some pretty interesting thing using an ECS, see cient's youtube series on making an ecs from scratch.


To reiterate, the advantages of ECS is the separation of entities and components.
This allows for both more performant programs by iterating over arrays of components rather than objects,
and promotes code reuse because data is separated from the object it belongs to.

## Why write it from scratch (and in Zig)?
I think Zig is a sick language with cool new ideas, and it's different from what I usually use.

There are ECS implementations which exist and are used, but I thought it an interesting programming exercise because:
- it involves a user facing functionality
- it uses simlar data structures (fun!)
- it's easy to improve (in terms of both interface, and efficiency)

## The implementation

Lets jump right into it!

``` zig
pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try stdout_writer.flush(); // Don't forget to flush!
}
```


Like I mentioned before we are going to

From a user functionality standpoint we want to be able to:
- create entities
- create component types
- create component for an entity
- iterate over component lists

So just to sketch out the shape of what we want to make:
- some container for array of a ComponentType
- some container for array of array of ComponentType (we want a list of all our registered component types)
- some way to map entities to their components

## TODO
- Think about this more
- Probably create a cohesive example
