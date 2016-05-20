package main

import "fmt"

func main() {
	for pos, char := range "日本\x80語" {
		fmt.Printf("Character %#U starts at byte position %d\n", char, pos)
	}
	a := []int{1, 2, 3, 4, 5, 6, 7, 8, 9}
	for i, j := 0, len(a)-1; i < j; i, j = i+1, j-1 {
		a[i], a[j] = a[j], a[i]
	}
	for pos, char := range a {
		fmt.Println(pos, char)
	}
}
