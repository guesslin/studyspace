package main

import (
	"fmt"
	"math"
)

type Rectangle struct {
	x1, y1, x2, y2 float64
}

func (r *Rectangle) area() float64 {
	l := distance(r.x1, r.y1, r.x1, r.y2)
	w := distance(r.x1, r.y1, r.x2, r.y1)
	return l * w
}

type Circle struct {
	x, y, r float64
}

func (c *Circle) area() float64 {
	return math.Pi * c.r * c.r
}

type Poly struct {
	ndoes []float64
}

func (p *Poly) area() float64 {
	var area float64
	for _, s := range p.ndoes {
		area += s
	}
	return area
}

type Shape interface {
	area() float64
}

func distance(x1, y1, x2, y2 float64) float64 {
	a := x2 - x1
	b := y2 - y1
	return math.Sqrt(a*a + b*b)
}

func totalArea(shapes ...Shape) float64 {
	var area float64
	for _, s := range shapes {
		area += s.area()
	}
	return area
}

type MultiShape struct {
	shapes []Shape
}

func (m *MultiShape) area() float64 {
	var area float64
	for _, s := range m.shapes {
		area += s.area()
	}
	return area
}

func main() {
	r := Rectangle{0, 0, 10, 10} // Rectangle
	c := Circle{0, 0, 5}         // Circle
	p := Poly{[]float64{1, 2, 3, 4, 5}}
	m := MultiShape{[]Shape{&r, &c, &p}}
	p2 := Poly{[]float64{4, 5, 6, 7, 8, 9}}
	fmt.Println(r.area())
	fmt.Println(c.area())
	fmt.Println(totalArea(&c, &r, &p))
	fmt.Println(m.area(), m.shapes)
	tmp := append(m.shapes, &p2)
	m2 := MultiShape{tmp}
	fmt.Println(m.area(), tmp)
	fmt.Println(m2.area(), tmp)
}
