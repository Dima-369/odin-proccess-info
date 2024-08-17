package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/posix"
import "core:time"
// Inputs:
// - args: is a list of strings with at least one element which is the process to execute. It needs to be the full path

exec_and_get_stdout :: proc(cmd: string) -> string {
    fmt.printf("Running %s\n", cmd)
    fp := posix.popen(strings.clone_to_cstring(cmd), "r")
    if fp == nil {
        fmt.println("Failed to start process")
        os.exit(1)
    }

    sb := strings.builder_make()
    output: [8192]byte
    for posix.fgets(raw_data(output[:]), len(output), fp) != nil {
        s := strings.trim_right_null(string(output[:]))
        strings.write_string(&sb, s)
    }

    status := posix.pclose(fp)
    if status == -1 {
        fmt.println("Error reported by pclose()")
        os.exit(1)
    }

    return strings.to_string(sb)
}

check :: proc(search_for: []string) {
    args := [dynamic]string{ "/usr/bin/pgrep" }
    for search in search_for {
        append(&args, search)
    }
    pgrep := exec_and_get_stdout(strings.join(args[:], " "))

    ps_command_sb := strings.builder_make()
    strings.write_string(&ps_command_sb, "/bin/ps -o %cpu,%mem,command ")
    stdout := strings.trim_right_space(pgrep)
    if stdout == "" {
        return
    }
    lines := strings.split(stdout, "\n")
    if len(lines) == 0 {
        return
    }
    strings.write_string(&ps_command_sb, strings.join(lines, ","))
    ps := exec_and_get_stdout(strings.to_string(ps_command_sb))
    length := 90
    for line in strings.split(ps, "\n") {
        if len(line) > length {
            fmt.println(line[:length])
        } else {
            fmt.println(line)
        }
    }
}

main :: proc() {
    if len(os.args) < 2 {
        fmt.println("Pass the search arguments")
        os.exit(1)
    }
    search_for := os.args[1:]

    // clear screen
    fmt.printf("\033[2J")
    for {
        fmt.printf("\033[H")
        check(search_for)
        fmt.printf("\033[H");
        time.sleep(500 * time.Millisecond)
    }
}