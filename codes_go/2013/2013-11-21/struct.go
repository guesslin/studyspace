package main

import "fmt"

type num01 struct {
    x1 int
}

type num02 struct {
    n1 float64
}

func (n *num01) print() int {
    return n.x1 + 10
}

func (m *num02) print() float64 {
    return m.n1 * 10
}

func main() {
    a := num01{12}
    b := num02{1.11}
    fmt.Println(a.print(), b.print())
}
