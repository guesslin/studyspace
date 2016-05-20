package main

import "fmt"

func add(args ...int) (total int) {
    total = 0
    for _, j := range args {
        total += j
    }
    return
}

func main() {
    fmt.Println(add(1, 2, 3))
}
