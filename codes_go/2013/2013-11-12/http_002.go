package main

import (
	"fmt"
	"html"
	"log"
	"net/http"
)

func myHttpHandler() {
	fmt.Println("Hello?")
}

func main() {
	http.Handle("/foo", myHttpHandler)

	http.HandleFunc("/bar", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
