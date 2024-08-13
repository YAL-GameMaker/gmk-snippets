# Snippet API (working title)
**Quick links:** [documentation](https://yal-gamemaker.github.io/gmk-snippets/)\
**Supported versions:** GameMaker 8.1<sup>\[1]</sup>

A collection of Cool Tricks for dynamically loading scripts in GameMaker 8.1¹.

Based on my own findings and techniques of yesteryear.

Features:
- Can load and call "scripts" (snippets)  
  Snippets can call each other,
  support arguments, and generally act like scripts.
- Can load objects from a GMEdit-like single-file format
- A little syntactic sugar for snippet code
- A few helper functions

\[1] Technically any version that has `argument[]`/`argument_count` and `execute_string`/`object_event_add`,
which is most likely versions between GM8.1 (incl.) and GM:HTML5 (incl.).

## Technical
The extension consists of a DLL and a bunch of GML scripts.

The DLL does code preprocessing and other operations that were deemed too slow to do in GM8.1.

The scripts use `object_event_add` + `event_perform_object` to store and call the final code without parsing penalties that would occur with `execute_string`.

## Syntactic sugar

<table><tr>
<th>Syntax</th>
<th>Result</th>
<th>Notes</th>
</tr>

<tr><td> <!-- row -->

```gml
var i = 0
globalvar g = 1
```

</td><td>

```gml
var i; i = 0
globalvar g; g = 1
```

</td><td>

Single-variable declarations only!

</td></tr>

<tr><td> <!-- row -->

```gml
enum E {
    A,
    B,
    C = 5,
    D
}
trace(E.D);
```

</td><td>

```gml
global.__E__A = 0;
global.__E__B = 1;
global.__E__C = 5;
global.__E__D = 6;
trace(global.__E__D);
```

</td><td>

Init is done on spot - avoid function calls in enum field "values".

</td></tr>

<tr><td> <!-- row -->

```gml
missing(1, 2);
```

</td><td>

```gml
snippet_call("missing", 1, 2);
```

</td><td>

Allows snippets to call each other without forward declaration.

</td></tr>

</table>

## Intended use cases

| ![shrug](./misc/shrug.png) |
|:-:|
| ~~What use cases?~~ |

You could use it for dynamic content loading if you are making a game in GM8.1.

Myself I wanted something that could run snippets of GM8.1 code without opening GM8.1,
which is convenient timing given that GM8.1
[doesn't open at the time of writing](https://forum.gamemaker.io/index.php?threads/gamemaker-8-1-unable-to-validate-license.113289/#post-675237).

## snippet-tester
This is an example project that has snippets setup and does
```gml
snippet_init();
snippet_load_listfile("startup.gmk-snips");
```
on game start.

If you compile a [GMEdit](https://github.com/YellowAfterlife/GMEdit/) version from git, you can open `.gmk-snips` files in it for a slightly-better code editing experience.

## Extras

- A [plugin](https://github.com/YAL-GameMaker/gmk-snippets) for GMEdit
  that lets you run the snippet-set by pressing F5 when a `.gmk-snips` is open.

## TODOs

- Wildcard support in listfiles?\
  (`folder/*.gml`)
- `script_execute` hook (that does either script_execute or snippet_call depending on whether index is number/string)

## Meta

**Author:** [YellowAfterlife](https://github.com/YellowAfterlife)  
**License:** MIT?