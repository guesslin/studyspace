package main

import (
	"fmt"
	"time"
)

func main() {
	c1 := make(chan string)
	c2 := make(chan string)
	go func() {
		t := 0
		for {
			time.Sleep(time.Second * 1)
			t++
			fmt.Println("time is", t)
		}
	}()

	go func() {
		for {
			c1 <- "from func01"
			time.Sleep(time.Second * 2)
		}
	}()
	go func() {
		for {
			c2 <- "from func02"
			time.Sleep(time.Second * 3)
		}
	}()
	go func() {
		for {
			select {
			case msg1 := <-c1:
				fmt.Println(msg1)
			case msg2 := <-c2:
				fmt.Println(msg2)
			}
		}
	}()
	var input string
	fmt.Scanln(&input)
}
