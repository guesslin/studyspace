package main

import (
	"fmt"
	"io/ioutil"
)

func main() {
	bs, err := ioutil.ReadFile("Test.txt")
	if err != nil {
		return
	}
	str := string(bs)
	fmt.Println(str)
}
