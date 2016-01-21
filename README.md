# CC Termu
**A ComputerCraft Emulator for the Terminal**


### Requirements
- [LuaJIT](http://luajit.org/) with Lua 5.2 compatibility or [Lua 5.2 or 5.3](http://www.lua.org/) (only works for CC 1.74 and above)
- [Penlight](http://stevedonovan.github.io/Penlight/api/index.html)
- [luv](https://github.com/luvit/luv)
- [terminfo](http://www.pjb.com.au/comp/lua/terminfo.html)

### Compatibility
This version has been cursorily tested with:

- 1.77
- 1.74
- 1.73
- 1.64
- 1.6
- 1.5
- 1.41

### Installation
Install the dependencies (I used luaenv and luarocks to do so)
Put ComputerCraft's lua files in `cc` (I cloned [alekso56/ComputercraftLua](https://github.com/alekso56/ComputercraftLua), you could also download the tarball or extract them (from the ComputerCraft jar) yourself).
Your directory structure should now look something like below
```
.
├── cc
│   ├── bios.lua
│   ├── README.md
│   ├── rom
│   └── treasure
├── cli.lua
├── emu.lua
├── LICENSE.txt
└── README.md
```

### Usage
`lua cli.lua <directory> <args>`- Start a computer in *directory* (*args* is passed to `bios.lua`)
If you want to use left control you can instead press `Ctrl-Shift-tilde` (this might be broken on other terminal emulators, tested on st and xterm).
