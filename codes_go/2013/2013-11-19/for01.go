package main

import "fmt"


func main() {
    i := 0
    for i <= 10 {
        fmt.Println(i)
        i += 1
    }
    for c := 0; c <= 10; c++ {
        fmt.Println("Loop2:", c)
    }
}
