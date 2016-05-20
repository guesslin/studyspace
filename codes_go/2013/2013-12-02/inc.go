package main

import "fmt"

func main() {
    x := 0
    inc := func() int {
        x++
        return x
    }
    fmt.Println(inc())
    fmt.Println(inc())
}
