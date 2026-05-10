package main

import "testing"

func TestMessage(t *testing.T) {
	if got := message(); got != "hello" {
		t.Fatalf("message() = %q, want %q", got, "hello")
	}
}
