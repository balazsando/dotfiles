# Vim Masterclass — Notes

> Native Vim keys work everywhere. Keys marked **(LV)** are LazyVim defaults for this setup;
> `<leader>` is `Space`. Help for anything: `:h <topic>` (e.g. `:h text-objects`).

---

## 1. The Core Idea: Operator + Count + Motion

Vim commands are a small language: **`[count] operator [count] motion | text-object`**.

| Example | Reads as |
| --- | --- |
| `d3w` | delete 3 words |
| `ci"` | change inside quotes |
| `yap` | yank a paragraph |
| `gUiw` | uppercase inner word |
| `>ip` | indent paragraph |

Doubling an operator acts on the whole line: `dd`, `yy`, `cc`, `>>`, `g~~`, `gUU`, `guu`.

**`.` repeats the last change.** Design edits so `.` can replay them — it is the single biggest
productivity multiplier.

---

## 2. Modes

| Key | Mode |
| --- | --- |
| `Esc` / `Ctrl+[` | Back to Normal |
| `i` `a` `o` … | Insert |
| `v` / `V` / `Ctrl+v` | Visual char / line / block |
| `R` | Replace |
| `:` | Command-line |

---

## 3. Entering Insert Mode

| Key | Inserts |
| --- | --- |
| `i` / `I` | before cursor / at first non-blank of line |
| `a` / `A` | after cursor / at end of line |
| `o` / `O` | on a new line below / above |
| `gi` | where you last left Insert mode |
| `s` / `S` | delete char / line, then insert (**(LV)** `s` is remapped to Flash — see §8) |

**Insert-mode keys:** `Ctrl+w` delete word back · `Ctrl+u` delete to line start ·
`Ctrl+r {reg}` paste a register · `Ctrl+o {cmd}` run one Normal command and return.

---

## 4. Delete, Yank, Put

| Key | Action |
| --- | --- |
| `x` / `X` | delete char under / before cursor |
| `d{motion}` | delete |
| `dd` / `3dd` | delete line / 3 lines |
| `D` | delete to end of line (`d$`) |
| `y{motion}` | yank (copy) |
| `yy` / `3yy` | yank line / 3 lines |
| `Y` | yank to end of line (Neovim; classic Vim yanks the whole line) |
| `p` / `P` | put after / before cursor |
| `xp` | swap two characters |
| `ddp` | swap two lines |

Deletes go to registers too — `d` is "cut", not "erase". Use `"_d` to really erase (§10).

---

## 5. Change and Replace

| Key | Action |
| --- | --- |
| `r{c}` | replace one char |
| `R` | Replace mode (overtype) |
| `c{motion}` | change (delete + Insert) |
| `cc` / `C` | change line / to end of line |
| `~` | toggle case of char |
| `g~{motion}` | toggle case — `g~w` word, `g~$` to EOL, `g~~` line |
| `gU{motion}` / `gUU` | uppercase |
| `gu{motion}` / `guu` | lowercase |
| `J` / `3J` | join lines with a space / join 3 lines |
| `gJ` | join without a space |
| `Ctrl+a` / `Ctrl+x` | increment / decrement number under cursor (`5 Ctrl+a` adds 5) |

---

## 6. Text Objects

Use after an operator or in Visual mode: **`i`** = inner (contents only), **`a`** = around
(includes delimiters / surrounding space).

| Object | Selects |
| --- | --- |
| `w` / `W` | word / WORD (WORD = space-delimited) |
| `s` | sentence |
| `p` | paragraph |
| `t` | HTML/XML tag — `cit` changes tag contents |
| `b` or `(` `)` | parentheses block |
| `B` or `{` `}` | braces block |
| `[` `]` | brackets |
| `<` `>` | angle brackets |
| `"` `'` `` ` `` | quoted string (works from anywhere on the line) |

**Most-used:** `ciw` `diw` `ci"` `da(` `yi{` `cit` `dap`.

**(LV) extras:** `if`/`af` function, `ic`/`ac` class, `ia`/`aa` argument (mini.ai).

**(LV) mini-surround** (enabled in this config):
`gsa{motion}{char}` add · `gsd{char}` delete · `gsr{old}{new}` replace — e.g. `gsaiw"` wraps a
word in quotes, `gsr"'` swaps `"` for `'`.

---

## 7. Navigation

### Characters, words, lines

| Key | Moves to |
| --- | --- |
| `h` `j` `k` `l` | left, down, up, right |
| `w` / `b` / `e` | next word start / previous word start / word end |
| `W` / `B` / `E` | same, by WORD |
| `0` / `^` / `$` | line start / first non-blank / line end |
| `gg` / `G` / `42G` | file start / end / line 42 |
| `{` / `}` | previous / next paragraph |
| `%` | matching bracket |
| `H` / `M` / `L` | top / middle / bottom of screen (**(LV)** `H`/`L` switch buffers instead) |

Prefer relative jumps: with `relativenumber` on, `5j` / `12k` beats holding `j`.

### Scrolling

| Key | Action |
| --- | --- |
| `Ctrl+d` / `Ctrl+u` | half page down / up |
| `Ctrl+f` / `Ctrl+b` | full page down / up |
| `Ctrl+e` / `Ctrl+y` | scroll view one line down / up (cursor stays) |
| `zz` / `zt` / `zb` | put cursor line at center / top / bottom of screen |

### Jump list and change list

| Key | Action |
| --- | --- |
| `Ctrl+o` / `Ctrl+i` | back / forward through jump history (across files) |
| `` `` `` | toggle between the last two jump positions |
| `g;` / `g,` | previous / next change position |
| `` `. `` | last change |

### Marks

| Key | Action |
| --- | --- |
| `ma` | set mark `a` (lowercase = this file, uppercase = global across files) |
| `` `a `` / `'a` | jump to mark exact position / its line |
| `:marks` | list marks |

---

## 8. Search

### Within the line

| Key | Action |
| --- | --- |
| `f{c}` / `F{c}` | jump onto next / previous `{c}` |
| `t{c}` / `T{c}` | jump to just before / after `{c}` |
| `;` / `,` | repeat last `f`/`t` forward / backward |

`dt)` (delete up to `)`) and `ct,` are everyday combos.

### Across the file

| Key | Action |
| --- | --- |
| `/pattern` / `?pattern` | search forward / backward |
| `n` / `N` | next / previous match |
| `*` / `#` | search word under cursor forward / backward |
| `:noh` | clear highlight (**(LV)** `Esc` does this) |
| `\c` in pattern | case-insensitive for this search, e.g. `/foo\c` |

### (LV) Flash

| Key | Action |
| --- | --- |
| `s` | type chars, then the label to jump anywhere on screen |
| `S` | select a Treesitter node |
| `f` `t` `F` `T` | enhanced: matches are labelled, repeat with the same key |

### (LV) Pickers

| Key | Finds |
| --- | --- |
| `<leader><space>` / `<leader>ff` | files |
| `<leader>/` / `<leader>sg` | grep text in project |
| `<leader>sw` | word under cursor in project |
| `<leader>,` / `<leader>fb` | open buffers |
| `<leader>fr` | recent files |
| `<leader>ss` | symbols in file |
| `<leader>sk` | keymaps — use it when you forget a key |

---

## 9. Substitute

Syntax: **`:[range]s/old/new/[flags]`**

| Command | Effect |
| --- | --- |
| `:s/old/new` | first match on current line |
| `:s/old/new/g` | all matches on current line |
| `:%s/old/new/g` | all matches in file |
| `:%s/old/new/gc` | same, confirm each |

### Ranges

| Range | Meaning |
| --- | --- |
| `.` | current line |
| `%` | whole file |
| `$` | last line |
| `.,$` | current line to end of file |
| `10,20` | lines 10–20 |
| `.,+5` | current line and next 5 |
| `'<,'>` | Visual selection (auto-filled when you press `:` in Visual) |
| `/pat1/,/pat2/` | from line matching `pat1` to line matching `pat2` |
| `/pat1/,$` | from `pat1` to end of file |

### Flags

`g` all in line · `c` confirm · `i` ignore case · `I` match case · `n` count only, no change.

### Tricks

- `:%s//new/g` — empty pattern reuses the last search. Search with `/` first, check the
  highlights, then substitute.
- `&` in replacement = whole match: `:%s/\w\+/"&"/g` quotes every word.
- `\(…\)` groups, `\1` back-reference: `:%s/\(\w\+\) \(\w\+\)/\2 \1/` swaps two words.
- Use another delimiter for paths: `:%s#/old/path#/new/path#g`.

### Global command

`:g/pattern/cmd` runs `cmd` on every matching line; `:v/pattern/cmd` on every non-matching one.

| Command | Effect |
| --- | --- |
| `:g/TODO/d` | delete every line with TODO |
| `:v/\S/d` | delete blank lines |
| `:g/pattern/normal @q` | run macro `q` on matching lines |

---

## 10. Registers

Access with `"{reg}` before a command: `"ayy` yank into `a`, `"ap` put from `a`.

| Register | Holds |
| --- | --- |
| `""` | unnamed — the default for every `d`/`c`/`y`/`p` |
| `"0` | last yank (not overwritten by deletes) |
| `"1`–`"9` | last line-wise deletes, newest first |
| `"-` | last small (within-line) delete |
| `"a`–`"z` | named; uppercase **appends** (`"Ayy`) |
| `"_` | black hole — discard |
| `"+` / `"*` | system clipboard |
| `".` | last inserted text |
| `":` | last command line |
| `"/` | last search |

`:reg` lists all. **(LV)** `<leader>s"` opens a register picker.

**Classic fix:** you yank a word, delete something, then `p` pastes the delete. Use `"0p` to put
the yank instead, or delete with `"_d` in the first place.

---

## 11. Macros

| Key | Action |
| --- | --- |
| `q{reg}` | start recording into register (`qa`) |
| `q` | stop recording |
| `@{reg}` | play (`@a`) |
| `@@` | replay last macro |
| `10@a` | play 10 times |
| `qA` | append to macro `a` |

### Writing reliable macros

1. Start from a known position: `0` or `^` first.
2. Move with searches and text objects (`f,` `/foo` `ciw`), not counts of `l`/`j`.
3. End by moving to the next target (`j0`, `n`), so the macro chains.
4. Over a range: `:27,35normal @b` runs macro `b` on lines 27–35. In Visual mode:
   `:'<,'>normal @b`.
5. A macro is just text in a register: `"ap` to paste it, edit, `"ayy` (or `0"ay$`) to save it back.

---

## 12. Visual Mode

| Key | Action |
| --- | --- |
| `v` / `V` / `Ctrl+v` | char / line / block |
| `gv` | reselect last selection |
| `o` | jump to other end of selection |
| `O` | (block) jump to other corner on the same line |
| `>` / `<` | indent / outdent (**(LV)** selection stays, repeat freely) |
| `=` | auto-indent |
| `u` / `U` / `~` | lowercase / uppercase / toggle case |
| `J` | join |
| `:` | command on selection — `'<,'>` filled in |

### Block mode (`Ctrl+v`)

| Key | Action |
| --- | --- |
| `I` | insert before block on every line, then `Esc` |
| `A` | append after block on every line (`$A` appends at each line end) |
| `c` | change block on every line |
| `r{c}` | replace every char in block |

### Alignment

`:'<,'>center` / `:'<,'>left` / `:'<,'>right` (short: `ce`, `le`, `ri`) — takes an optional width.

---

## 13. Buffers

A buffer is an open file in memory; windows are views onto buffers.

| Command / Key | Action |
| --- | --- |
| `:ls` | list buffers |
| `:bn` / `:bp` | next / previous |
| `:b3` | buffer 3 |
| `:b name` | buffer by partial name (Tab completes) |
| `:bfirst` (`:bf`) / `:blast` (`:bl`) | first / last |
| `Ctrl+^` | alternate (most recent) buffer |
| `:badd file` | add to list without opening |
| `:bd` | delete (close) buffer |
| `:bufdo cmd` | run on every buffer — e.g. `:bufdo %s/a/b/ge \| update` |
| `:ball` | open every buffer in a window |

### (LV)

| Key | Action |
| --- | --- |
| `Shift+h` / `Shift+l` or `[b` / `]b` | previous / next buffer |
| `<leader>bb` / ``<leader>` `` | alternate buffer |
| `<leader>bj` | pick buffer by letter |
| `<leader>,` / `<leader>fb` | buffer picker |
| `<leader>bd` | close buffer |
| `<leader>bo` | close all other buffers |
| `<leader>bp` | pin buffer |

---

## 14. Windows

Native prefix is `Ctrl+w`. **(LV)** `<leader>w` is an alias for it, so `<leader>wv` =
`Ctrl+w v`.

| Key | Action |
| --- | --- |
| `Ctrl+w v` / `<leader>\|` | split vertically |
| `Ctrl+w s` / `<leader>-` | split horizontally |
| `Ctrl+h/j/k/l` **(LV)** | move between windows (and tmux panes) |
| `Ctrl+w w` | cycle windows |
| `Ctrl+w r` | rotate windows |
| `Ctrl+w x` | swap with next window |
| `Ctrl+w q` / `<leader>wd` | close window |
| `Ctrl+w o` | close all other windows |
| `Ctrl+w H/J/K/L` | move window to far left / bottom / top / right |
| `Ctrl+w =` | equalise sizes |
| `Ctrl+w _` / `Ctrl+w \|` | maximise height / width |
| `<leader>wm` **(LV)** | toggle zoom |
| `Ctrl+Up/Down/Left/Right` **(LV)** | resize |
| `:windo cmd` | run on every window |

**Tabs** are layouts of windows, not files: `:tabnew`, `gt` / `gT`, `:tabclose`.
**(LV)** `<leader><tab><tab>` new tab, `<leader><tab>]` / `[` next / previous.

---

## 15. File Explorer (LV — Snacks explorer)

Open with `<leader>e` (project root) or `<leader>E` (current working directory).

| Key | Action |
| --- | --- |
| `Enter` / `l` | open file / expand directory |
| `h` | collapse directory |
| `Backspace` | go to parent directory |
| `.` | make directory the root |
| `a` | add file (end name with `/` for a directory) |
| `r` | rename |
| `d` | delete |
| `c` | copy |
| `m` | move |
| `y` / `p` | yank / paste file |
| `o` | open with system app |
| `H` / `I` | toggle hidden / gitignored files |
| `i` or `/` | filter by name |
| `Ctrl+v` / `Ctrl+s` | open in vertical / horizontal split |
| `P` | toggle preview |
| `Z` | collapse all |
| `]g` / `[g` | next / previous git change |
| `?` | show all keys |

Native fallback without plugins: `:Explore` (netrw), or just `:e path/to/file` with Tab completion.

---

## 16. Command Mode Essentials

| Command | Action |
| --- | --- |
| `:w` | write |
| `:q` / `:q!` | quit / quit discarding changes |
| `:wq` / `:x` | write and quit (`:x` writes only if changed) |
| `:wa` / `:qa` / `:wqa` | write / quit / both for all |
| `:e file` / `:e!` | open file / reload discarding changes |
| `:h topic` | help |
| `:r file` / `:r !cmd` | insert file / command output below cursor |
| `:!cmd` | run shell command |
| `:{range}!cmd` | filter lines through a shell command — `:%!jq .` formats JSON, `:'<,'>!sort -u` |
| `:sort` / `:sort u` | sort lines / sort and dedupe |
| `:{range}m{line}` | move lines — `:m0` moves line to top |
| `:{range}t{line}` | copy lines — `:t.` duplicates current line |
| `Ctrl+r Ctrl+w` | insert word under cursor into the command line |
| `@:` | repeat last command line |
| `q:` | command history in an editable window |

Normal mode: `ZZ` = `:x`, `ZQ` = `:q!`.

---

## 17. Undo and History

| Key | Action |
| --- | --- |
| `u` / `Ctrl+r` | undo / redo |
| `U` | undo all changes on last line |
| `:earlier 5m` / `:later 5m` | time travel through undo history |
| `g-` / `g+` | walk the undo tree |

---

## 18. Useful Combos

| Combo | What it does |
| --- | --- |
| `/word` → `cgn` new `Esc` → `.` `.` `.` | change matches one by one; `.` jumps to the next and changes it (no `n` needed). `n` skips one |
| `*` → `cgn` → `.` | same, for the word under cursor |
| `/word` → `cw` → `n` → `.` | course version: change, find next, repeat |
| `:27,35normal @b` | play macro `b` on lines 27–35 |
| `:%normal A;` | append `;` to every line |
| `Ctrl+v` `5j` `I//` `Esc` | comment 6 lines (block insert) |
| `gcc` / `gc{motion}` | toggle comment line / motion (Neovim built-in) |
| `xp` / `ddp` / `ddkP` | swap chars / swap line down / swap line up |
| `yiw` → `viw"0p` | replace a word with the last yank, repeatable on other words |
| `ggVG` / `ggyG` | select / yank whole file |
| `=ap` / `gg=G` | re-indent paragraph / whole file |
| `ciw Ctrl+r 0` | change word to the last yank, `.`-repeatable |
| `:g/^$/d` | delete empty lines |
| `zf{motion}` / `za` / `zR` / `zM` | create fold / toggle / open all / close all |

---

## 19. Habits That Pay Off

1. **Stay in Normal mode.** Insert mode is for typing text only; leave it as soon as you stop.
2. **Think in text objects**, not character movement: `ci(` beats `f(lct)`.
3. **Make changes repeatable** so `.` does the work; prefer `cgn` over manual search-and-change.
4. **Use counts and relative numbers** instead of repeating keys. If you press a key 3+ times,
   there is a better motion.
5. **Search to move.** `/`, `*`, `f`, Flash `s` are faster than scrolling.
6. **Jump back with `Ctrl+o`** after looking something up.
7. **Learn one new command a week** and force yourself to use it until it is reflex.
8. **Forgot a key?** `:h`, or **(LV)** `<leader>sk` to search keymaps, or press `<leader>` and
   wait for which-key.
9. Practise with `:Tutor` occasionally — it covers fundamentals worth rechecking.
