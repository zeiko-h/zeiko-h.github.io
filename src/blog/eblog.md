---
title: "Following eblog"
date: 2026-06-17
---

A [blog](https://eblog.fly.dev/index.html) I enjoyed reading has a series titled
"starting systems programming: practical systems programming for the contemporary developer"

That's a bit of a mouthful but it sounded interesting to me and I thought doing it would be fun.
The series uses Go to write several systems-programmy programs, but I am not (at the moment) 
very interested in Go. Instead, because I am one of those people, let's do it in zig.


## Programmer programs 'Programmers write programs'

The first program to get my hands dirty with is `findoffset` which, according to the blog post, does the following:

> findoffset.go is a command line tool that finds the offset of the first occurrence of a string in a file and prints it to stdout.

So as the post mentions this involes the following (I'll stop quoting the post after this, I swear):

1. parse the command line arguments
2. read the file into memory
3. compare the bytes in the file to the bytes in the string, one-by-one

    1. no match: continue at next offset
    2. match: print and exit 0 (ok)

4. exit 1 (error)

# TODO
- Copy zig mains into code blocks
- Decide how much gonna copy over
- Zigisms? IO passing? which version?
