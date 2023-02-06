package main

import (
	"encoding/json"
	"fmt"
	tassert "github.com/stretchr/testify/assert"
	"os"
	"testing"
)

type test struct {
	Comment  string      `json:"comment"`
	Doc      interface{} `json:"doc"`
	Patch    interface{} `json:"patch"`
	Expected interface{} `json:"expected"`
	Error    string      `json:"error"`
	Disabled bool        `json:"disabled"`
}

type tests []*test

func TestSpec(t *testing.T) {
	testFile(t, "spec_tests.json")
}

func TestTests(t *testing.T) {
	testFile(t, "tests.json")
}

func testFile(t *testing.T, file string) {
	testBytes, err := os.ReadFile(file)
	if err != nil {
		t.Fatal(err)
	}

	ts := tests{}
	err = json.Unmarshal(testBytes, &ts)
	if err != nil {
		t.Fatal(err)
	}

	for _, tt := range ts {
		if tt.Disabled {
			continue
		}

		t.Run(tt.Comment, func(t *testing.T) {
			assert := tassert.New(t)

			res, err := jsonPatch(tt.Doc, tt.Patch)
			if tt.Error != "" {
				if err == nil {
					assert.Fail("no error but expected " + tt.Error)
				}
				return
			}

			if !assert.NoError(err) {
				return
			}

			var intf interface{}
			err = json.Unmarshal([]byte(res), &intf)
			if !assert.NoError(err) {
				fmt.Println(res)
				return
			}

			assert.Equal(tt.Expected, intf)
		})
	}
}
