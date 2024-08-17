package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:sys/posix"
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
    output: [1024]byte
    for posix.fgets(raw_data(output[:]), len(output), fp) != nil {
    //        posix.printf("RAW: %s", string(output[:]))
//            s := strings.trim_right_null(string(output[:]))
    //        s:=fmt.aprint(output)
    //        fmt.println("RAW: %s", s)
    //        if len(s) > 90 {
    //            strings.write_string(&sb, s[:90])
    //        } else {
    //            strings.write_string(&sb, s)
    //        }
    //        strings.write_string(&sb, s)
        strings.write_bytes(&sb, output[:])
    }

    status := posix.pclose(fp)
    if status == -1 {
        fmt.println("Error reported by pclose()")
        os.exit(1)
    }

    return strings.to_string(sb)
}

ex :: proc() {
    os.exit(1)
}

search_for : []string
lower : string

check :: proc(search_for: []string) {
    ps := exec_and_get_stdout("/bin/ps -axo %cpu,%mem,command")
    lines := strings.split(ps, "\n")
    filtered := slice.filter(lines, proc (line: string) -> bool {
        lower = strings.to_lower(line)
        return slice.all_of_proc(search_for, proc (search: string) -> bool {
            return strings.contains(lower, search)
        })
    })
    length := 90
    for line in filtered {
        if len(line) > length {
            fmt.println(line[:length])
        } else {
            fmt.println(line)
        }
    }
}

main :: proc() {
    os.args = []string{ "foo", "arc.app"}
    //    os.args = []string{ "foo", "glfw", "firefox" }
    if len(os.args) < 2 {
        fmt.println("Pass the search arguments")
        os.exit(1)
    }
    search_for = os.args[1:]

    // clear screen
    //    fmt.printf("\033[2J")
    //    for {
    //        fmt.printf("\033[H")
    check(search_for)
//        fmt.printf("\033[H");
//        time.sleep(500 * time.Millisecond)
//    }
}