package main

import "fmt"

func f_to_c(f float32) float32 {
	return (f - 32) * 5 / 9
}

func f_to_m(f float32) float32 {
	return f * 0.3048
}

func main() {
	fmt.Print("Please input Fahrenheit: ")
	var Fahre float32
	fmt.Scanf("%f", &Fahre)
	fmt.Println("Celsius is ", f_to_c(Fahre))
	fmt.Print("Please input Feet: ")
	var Feet float32
	fmt.Scanf("%f", &Feet)
	fmt.Println("Celsius is ", f_to_c(Feet))
}
