# CC Termu
**A ComputerCraft Emulator for the Terminal**

### Requirements
- luajit with lua 5.2 compatibility (might work with Lua 5.1)
- Penlight
- lcurses
- lposix

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
├── README.md
└── test
```

### Usage
`lua cli.lua <directory>`- Start a computer in *directory*
