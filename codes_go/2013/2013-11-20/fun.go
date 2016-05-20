package main

import "fmt"

func add(args ...int) int {
	total := 0
	for index, i := range args {
		fmt.Println(index)
		total += i
	}
	return total
}

func main() {
	fmt.Println(add(32, 41, 1, 5, 2))
}
