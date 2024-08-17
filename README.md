# Setup steps in the subprocess.h directory

Needs latest `Odin` version with `posix` package support.

```bash
gcc -c -o subprocess.o subprocess.c
ar rcs libsubprocess.a subprocess.o
```

# Output

```
Running /usr/bin/pgrep glfw
Running /bin/ps -o %cpu,%mem,command 30883
 %CPU %MEM COMMAND
  8.5  0.2 ./glfw_opengl3
  ```