package main

import (
	"fmt"
	"time"
)

func main() {
	c := make(chan int, 3)
	go func() {
		t := 0
		for {
			c <- t
			time.Sleep(time.Second * 1)
			fmt.Println(t)
			t++
		}
	}()
	go func() {
		for {
			num := <-c
			fmt.Println("printer", num)
		}
	}()
	var input string
	fmt.Scanln(&input)

}
