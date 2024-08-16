package main

import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

foreign import subprocess "subprocess.h/libsubprocess.a"

subprocess_s :: struct {
    stdin_file: ^libc.FILE,
    stdout_file: ^libc.FILE,
    stderr_file: ^libc.FILE,
    // assume that pid_t is an int
    child: c.uint,
    return_status: c.int,
    alive: c.size_t,
}

foreign subprocess {
    subprocess_create :: proc (command_line: [^]cstring, options: c.int, out_process: ^subprocess_s) -> c.int ---
    subprocess_stdout :: proc (process: ^subprocess_s) -> ^libc.FILE ---
    subprocess_join :: proc (process: ^subprocess_s, out_return: ^c.int) -> c.int ---
    subprocess_destroy :: proc (process: ^subprocess_s) -> c.int ---
}

// Inputs:
// - args: is a list of strings with at least one element which is the process to execute. It needs to be the full path
exec_and_get_stdout :: proc(args: ..string) -> string {
    process := subprocess_s{ }
    inp : [dynamic]cstring
    for arg in args {
        append(&inp, strings.clone_to_cstring(arg))
    }
    append(&inp, nil)
    okay := subprocess_create(raw_data(inp), 0, &process)
    if 0 != okay {
        fmt.println(fmt.aprint("Can not create process:", args))
        os.exit(1)
    }
    defer subprocess_destroy(&process)

    okay = subprocess_join(&process, nil)
    if 0 != okay {
        fmt.println("Failed to wait on process completion")
        os.exit(1)
    }

    s : [dynamic]u8
    stdout := subprocess_stdout(&process)
    for {
        char : i32 = libc.fgetc(stdout)
        if char == libc.EOF {
            break
        }
        append(&s, u8(char))
    }

    okay = subprocess_destroy(&process)
    if 0 != okay {
        fmt.println("Failed to destroy process")
        os.exit(1)
    }

    return transmute(string)s[:]
}

check :: proc(search_for: string) {
    pgrep := exec_and_get_stdout("/usr/bin/pgrep", search_for)
    ps_command : [dynamic]string = {
    // do not use command which gets stuck
        "/bin/ps", "-o", "%cpu,%mem,comm"
    }
    stdout := strings.trim_right_space(pgrep)
    if stdout == "" {
        return
    }
    lines := strings.split(stdout, "\n")
    if len(lines) == 0 {
        return
    }
    for line in lines {
        append(&ps_command, line)
    }
    ps := exec_and_get_stdout(..ps_command[:])
    if ps != "" {
        fmt.println(ps)
    }
}

main :: proc() {
    if len(os.args) < 2 {
        fmt.println("Pass search for as single argument")
        os.exit(1)
    }
    search_for := os.args[1]

    // clear screen
    fmt.printf("\033[2J")
    for {
        fmt.printf("\033[H")
        check(search_for)
        fmt.printf("\033[H");
        time.sleep(500 * time.Millisecond)
    }
}