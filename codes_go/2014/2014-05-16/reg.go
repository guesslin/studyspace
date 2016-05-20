package main

import (
	"fmt"
	"io/ioutil"
	"regexp"
)

func main() {
	var filename string
	fmt.Scanln(&filename)
	content, _ := ioutil.ReadFile(filename)
	reg, _ := regexp.Compile(`[ \n]`)
	for _, line := range content {
		fmt.Printf("%s", reg.ReplaceAllString(string(line), "1exec\n"))
	}
}
