package main

import "fmt"

func main() {
    var x [5]float64
    for i := 0; i <= 4; i++ {
        fmt.Println("Please input", 5 - i,"Numbers")
        fmt.Scanf("%f", &x[i])
    }
    var total float64 = 0.0
    for i := 0; i <= 4; i++ {
        total += x[i]
    }
    fmt.Println("Average of 5 numbers is", total / 5)
}
