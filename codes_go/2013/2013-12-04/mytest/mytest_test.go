package mytest

import "testing"

func TestAverage(t *testing.T) {
	var v float64
	v = Average([]float64{1, 2})
	if v != 1.5 {
		t.Error("Expected 1.5, got", v)
	}
	v = Average([]float64{49, 122, 522, 644, 234})
	if v != 314.2 {
		t.Error("Expected 314.2, got", v)
	}

}
