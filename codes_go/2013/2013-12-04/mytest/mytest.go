package mytest

func Average(nums []float64) float64 {
	var sum float64
	count := 0.0
	for _, n := range nums {
		sum += n
		count++
	}
	return sum / count
}
