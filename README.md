# DFF
**D**a **F**ast **F**(p)icker: a non-fzf picker which still feels faster.

## Usage
+ To use, just: `./dff` (or `python3 dff`).
+ To use list-mode, just pipe data: `ls -l | ./dff`.
+ To use output, just: `$EDITOR -- $(./dff)`.
+ To ignore directories in output, just: `./dff | xargs -I_ sh -c "test -f _&&$EDITOR -- _"`.

It is recommended to put the `dff` file in a `$PATH` for quick access.

### Mappings
+ Backspace: delete from input, or if input empty:
    + In dir-mode, jump to parent directory
        + May jump multiple directories if `skip_one` is enabled (which it is by default)
    + In list-mode, if `exit_on_first_back`, exit, else do nothing
+ Escape: quit and, in dir-mode, also print active directory

### Design
Dff can be in two modes (dir or list), but the basics are the same:

There's an index, and a list of string(typically files):
1. If there's only one string in the list, return it
    + Or if in dir-mode and thing is dir, recurs into it
2. If all the characters are the same at index of every string, increment index and go to step 1
3. Wait for user character input
4. Remove every string from the list which doesn't have character on index
    + Out of bound indexing falls back to ending-characters (can be changed with `-e`)
5. Go to step 1

### Options
+ `ending`: two characters, used when indexing out of bounds: the first character is used when index is one off , and the other if more than one off
    + Two characters is needed to handle all possible name collision
    + Default: `?&`
    + Shell-flag: `-e`/`--ending`
+ `skip_one`: If there's only one entry in input, then auto select it
    + Especially noticeable in dir-mode, where it can skip multiple parent/child directories if they only have one child
    + Default: `true`
    + Shell-not-flag: `-S`/`--no-skip-one`
+ `dir_first_skip_one`: When first opening dff in dir-mode, overwrite `skip_one`
    + Useful so that you can start dff in a single-entry directory and then jump up to a good directory, without the program instantly exiting
    + Can't overwrite `skip_one` to true, only to false
    + Default: `false` (e.g. it disables `skip_one`)
    + Shell-flag: `-f`/`--dir-first-skip-one`
+ `dir_print_current_directory`: In dir-mode, print active directory on top row
    + Default: `true`
    + Shell-not-flag: `-P`/`--no-dir-print-current-directory`

<!--
<details open=true><summary><b>Step-by-step</b></summary>

Let's say we have a directory with the files:
```
lib.h
lib.c
main.c
main
```
(Quick command to set up: `printf "lib.h\nlib.c\nmain.c\nmain" | ./dff`)

Running dff in this directory, you'll see two l and two m highlighted.

Let's press `l`.

</details>
-->

#### Q&A
*Why is the name DFF?*\
Well, in the random project directory, it was project D(4), version F(5) (yes, I needed to rewrite it five times before being happy with the algorithm), but DF is already a tool, so just repeat the last letter, and thus we get DFF.

*Donation link where?*\
[Here](https://buymeacoffee.com/altermo)... Or well, it's actually [here](https://buymeacoffee.com/altermo)... No wait, it's [here](https://buymeacoffee.com/altermo).
