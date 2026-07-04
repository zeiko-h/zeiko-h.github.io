---
title: "Following eblog"
date: 2026-06-17
---

A [blog](https://eblog.fly.dev/index.html) I enjoyed reading has a series titled
"starting systems programming: practical systems programming for the contemporary developer"

That's a bit of a mouthful but it sounded interesting to me and I thought doing it would be fun.
The series uses Go to write several systems-programmy programs, but I am not (at the moment) 
very interested in Go. Instead, because I am one of those people, let's do it in zig 0.16.

Before we start, I won't paste the contents of every activity here because that would be pretty hard to read.
I will write my thoughts about each program, and any reflections I had along the way, supported by a minimal code example.

## findoffset

Quite a simple program.
The most interesting part here was how to match the search string, but I used the same method as in the blog post.
I did some reading sometime this week and saw how ripgrep is faster than grep because it doesn't compare every byte,
I think it would be fun to do some basic optimisation in a similar vein here, like skipping N bytes when nothing matches the pattern.

Because I am writing this after the fact, I think I could have had some nicer argument handling and I should have used a writer.

## echo

I noticed when I came back to this program I looped over my arguments in a poor way.
I swapped to a while loop, considering there is a teeny bit of logic around what arg you are printing,
but you can do the same with slices and a for loop, which is what is done in the blog.

Personally I prefer the while loop, because you avoid having the second payload capture:

```zig
var i: u32 = 1;
while(i < args.len) : (i += 1) {
    if (i > 1) try w.print(" ", .{});
    try w.print("{s}", .{args[i]});
}
try w.print("\n", .{});

for (args[1..], 1..) |arg, j| {
    if(j > 1) try w.print(" ", .{});
    try w.print("{s}", .{arg});
}
try w.print("\n", .{});
```

Ultimately though, my first super-lame attempt still worked.
A large part of the point of these exercises is to realise that some of the most useful tools are really simple to implement.
Everything is just bytes is sort of the motto of the eblog systems programming series. 


## cat

Apparently I forgot to write cat, so it's a good thing I checked!.
TODO

## binpatch

Again an easy one, I went back and used a writer.
Nothing super interesting here except zig's sort of cool slices:
``` zig 
try w.print("{s}", .{file[0..offset]});
try w.print("{s}", .{replacement});
try w.print("{s}", .{file[(offset + replacement.len)..]});
try w.flush();
```
Looking at my program, vs the example go program, my one is a lot shorter.
I think the example does some more interesting stuff with `io.Copy` and error handling,
whereas mine just prints. Probably the `print("{s}", .{bytes})"` indicates a memory copy or something would be better for me.

## torso

This was the first sort of big read-y program.
Again the example program was a lot longer than what I ended up with.
I think the example checks bounds and errors a bit more than my program did.
They also used file specific functions, but I just used `readFileAlloc` and used zig's slices to get to the offset.
I am not totally sure if that's an uber efficient method for reading in files, but it works and should be easy to change in the future 
if the file reading or writing is a bottleneck.

In this program I handled arguments like so:
``` zig
var i: usize = 1;
while (i < args.len) : (i += 1) {
    if (std.mem.eql(u8, args[i], "-from")) {
        filepath = args[i + 1];
        i += 1; // skip the next arg
    } else if (std.mem.eql(u8, args[i], "-before")) {
        bytesbefore = try std.fmt.parseInt(u32, args[i + 1], 10);
        i += 1; 
    } else if (std.mem.eql(u8, args[i], "-after")) {
        bytesafter = try std.fmt.parseInt(u32, args[i + 1], 10);
        i += 1;
    } else if (std.mem.eql(u8, args[i], "-offset")) {
        offset = try std.fmt.parseInt(u32, args[i+1], 10);
        i += 1;
    } else if (std.mem.eql(u8, args[i], "-newline")) {
        newline = true;
    } else { // it must be a positional arg
        std.debug.print("Found unexpected arg: {s}\n", .{args[i]});
        std.debug.print(usage_str, .{});
        return;
    }
}
```
The main thing I don't like with this strategy is checking the nullness of certain variables,
but I suppose somewhere you have to check which/if all the needed args have been provided.

Mainly this annoys me with default values, for example it's nice to allow a user to specify which file
to write to, or write straight to stdout, and what I have been doing is something like:
``` zig
var out_file: ?std.Io.File = null;
if (std.mem.eql(u8, args[i], "-file")) {
        filepath = args[i + 1];
        i += 1; // skip the next arg
        if (file == null) {
            file = try std.Io.Dir.cwd().openFile(init.io, args[i+1], .{});
        } else {
            std.log.err("Couldnt open file: {s}\n", .{args[i+1]});
            return 1;
        }
}
// set default here
if (file == null) {
    file = std.Io.File.stdout();
}
```
In hindsight its probably better to store the filepath, and depending on if thats set or not handle opening the file elsewhere:
``` zig
var filepath: ?[]const u8 = null;
if (std.mem.eql(u8, args[i], "-file")) {
        filepath = args[i + 1];
        i += 1; // skip the next arg
}
const out_file = if(filepath == null) std.Io.File.stdout() 
                 else try std.Io.Dir.cwd().openFile(init.io, filepath.?, .{});
```

Now that I have written that out I think it makes more sense to separate the user provided filepath from resource initialisation / defaults.
Part of the benefit of writing out this process is making reflections like these, I am glad I caught this.

## hexdump

Writing hexdump was fun.
I enjoyed coming up with a nice(ish) argument handling style using a while loop, learned about some zig std library functions mostly to do with printing, and got to compare it against an existing tool (hexdump.
I think if I spent a bit more time on it I would be able to make the code a bit simpler, make the printing logic a bit clearer, maybe handle some errors instead of `try`ing everything, but I am pretty satisfied.

I realised after I first got the program working that I had been using bad way to write bytes out.
Essentially, I was using a convenience function `writeStreamingAll` to write my program output.
The `writeStreamingAll` function is stated in the docs to be equivalent to creating a writer, writing some bytes, and then flushing.
Ignoring the large fact I was using this function poorly, it was a bad choice anyway because:

- Probably writing a lot of stuff (entire file contents)
- Logic around bytes to be printed
- Had to separately create a formatted string 

This is probably a good function to use if you just want to dump some bytes out.
Also, I probably could have done all my logic to a buffer, keeping track of the buffer offset and using `std.fmt.bufPrint` or something.
But as far as I understand thats sort of what the `Writer` abstraction is for.


There's a quick example below, you can see without any loops how it's tedious to keep track of the buffer offset manually:

``` zig
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const out = std.Io.File.stdout();
    const fmt_str = "Some hex: {X:0>2}\n";

    // Writing directly to the file
    try out.writeStreamingAll(init.io, "Hello, world!\n");

    // How I was using writeStreamingAll:
    const sbuf = try arena.alloc(u8, 4096);
    const fmt_str_len = 13;
    _ = try std.fmt.bufPrint(sbuf, fmt_str, .{0xFF});
    try out.writeStreamingAll(init.io, sbuf[0..fmt_str_len]);

    // Using a writer instead
    const wbuf = try arena.alloc(u8, 4096);
    var writer = out.writer(init.io, wbuf);
    const interface = &writer.interface;
    try interface.print(fmt_str, .{0xFF});
    try interface.flush();
}
```


It was really fun starting backwards (by accident) essentially printing and flushing every character, to using the actual std library api.
Unexpectedly this little project made me respect the writer abstraction a bit more.


Another thing I realised I was probably doing wrong was calling `std.process.exit` in some parts of my code.
I noticed I was using it to replicate returning an error code, and it would probably be a bit tidier to just return a `u8` from main,
and return either `0` or `1` in the code.
Maybe with a more serious program using `std.process.exit` makes sense, but for `shexdump` I thought this made things a bit nicer to read.

A quick aside on the zig writer abstraction:

There are many well written articles about zig's writer abstraction, but here are my thoughts.
It was interesting to me to use a writer you have to do something like: `&xyz.writer(&buf).interface`.
I had a super quick skim and it's sort of how zig can do an abstracted interface.
You can create your own data structure and offer a `Writer` interface into it by connecting your writing functions to the interface.
I thought it was interesting to see that the `std.Io.Writer` struct had a `vtable` member.
I suppose this is a bit of a zigism that I have not fully gotten used to yet.

## unhexdump

I also haven't gotten around to unhexdump yet
I think it will be pretty quick though, just have to figure out a reverse format string, and jam them into a writer.
TODO
