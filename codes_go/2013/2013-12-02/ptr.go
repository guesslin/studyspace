package main

import "fmt"

func foo(iptr *int) {
    *iptr = 0
}

func main() {
    num := 10
    foo(&num)
    fmt.Println(num)
}
