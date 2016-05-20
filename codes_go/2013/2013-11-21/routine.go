package main

import (
    "fmt"
    "time"
    )

func f() {
    for i := 1; i <= 10; i++ {
        fmt.Println("Loop in", i, "times")
        time.Sleep(time.Second * 1)
    }
}

func main() {
    go f()
    var input string
    fmt.Scanln(&input)
    fmt.Println(input)
}
