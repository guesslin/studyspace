package main

import "fmt"

func main() {
	slice1 := make([]float64, 5)
	for i := 0; i < 5; i++ {
		slice1[i] = float64(i)
		fmt.Println(slice1[i])
	}
	slice2 := make([]float64, 3)
	copy(slice2, slice1)
	for _, f := range slice2 {
		fmt.Println(f)
	}
}
