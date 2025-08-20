## _Zetr_
/zɛtər/ — **ZET-er**

<p align="center">
  <img align="center" width="300" height="912" alt="image" src="https://github.com/user-attachments/assets/2a22279c-6428-4593-a53a-6d802eed6bac" />
</p>

### Why?
> *“Because playing Tetris in a GUI is for cowards.”*  
> — Me

### Features
- runs on you're granny's toaster
- shows you the next tetronimo (the one about to invoke dOOm)
- plays sounds*
- Pure 100% terminal-based gaming — no mice allowed, no mercy given
- written in zig because c was to popular and rust kept shouting at me in red text whenever i tried to compile anything

*if you imagine them hard enough

### Install
Run the quick install script and it'll install _zetr_ in a matter of seconds.
```bash
curl -ffSL https://raw.githubusercontent.com/ajTronic/zetr/main/install.sh | sh 
```
If for some reason you don't want to use the install script, build it from source (still only works on Linux terminals) 
```bash
git clone https://github.com/ajTronic/zetr.git
cd zetr
zig build
cp zig-out/bin/zetr /usr/local/bin/zetr
zetr
```

### Uninstall
Why would ever do such a thing? I don't know.
```bash
sudo rm /usr/local/bin/zetr
```

### Usage
```sh
zetr
```

### Controls
| Key      | Action  |
| -------- | ------- |
| h  | move tetronimo left    |
| l | move tetronimo right     |
| j    | move tetronimo down    |
| k    | rotate tetronimo clockwise    |
| o    | rotate tetronimo anticlockwise    |
| space    | hard drop    |

### Limitations
- output is corrupted if terminal is too small
- only works on linux (preferably arch btw)
- only tested on arch btw

### I don't know why this is here
- arch btw
- i like arch btw
