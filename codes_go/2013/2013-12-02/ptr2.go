package main

import "fmt"

func zero(iptr *int) {
    *iptr = 0
}

func main() {
    num := new(int)
    zero(num)
    fmt.Println(*num)
}
