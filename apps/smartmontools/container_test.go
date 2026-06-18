package main

import (
	"testing"

	"github.com/home-operations/containers/testhelpers"
)

func Test(t *testing.T) {
	image := testhelpers.GetTestImage("ghcr.io/aclerici38/smartmontools:rolling")
	testhelpers.TestCommandSucceeds(t, image, nil, "smartctl", "--version")
}
