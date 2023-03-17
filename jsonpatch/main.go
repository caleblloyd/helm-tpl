package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"helm.sh/helm/v3/pkg/chart"
	"helm.sh/helm/v3/pkg/chartutil"
	"helm.sh/helm/v3/pkg/engine"
	"log"
	"os"
	"path"
)

type jsonPatchParams struct {
	Doc   interface{} `json:"doc"`
	Patch interface{} `json:"patch"`
}

var (
	helmChart              *chart.Chart
	helmEngine             *engine.Engine
	template, jsonPatchTpl []byte
)

func init() {
	var err error
	template, err = os.ReadFile("template.yaml")
	if err != nil {
		log.Fatalln(err)
	}

	jsonPatchTpl, err = os.ReadFile(path.Join("..", "_jsonpatch.tpl"))
	if err != nil {
		log.Fatalln(err)
	}

	helmChart = &chart.Chart{
		Metadata: &chart.Metadata{
			Name:    "test",
			Version: "1.2.3",
		},
		Templates: []*chart.File{
			{
				Name: "template.yaml",
				Data: template,
			},
			{
				Name: "_jsonpatch.tpl",
				Data: jsonPatchTpl,
			},
		},
	}

	helmEngine = &engine.Engine{}
}

func main() {
	args := os.Args[1:]
	if len(args) != 2 {
		log.Fatalf("usage: %s doc-file patch-file\n", os.Args[0])
	}

	doc, err := os.ReadFile(args[0])
	if err != nil {
		log.Fatalln(err)
	}

	patch, err := os.ReadFile(args[1])
	if err != nil {
		log.Fatalln(err)
	}

	var docI, patchI interface{}
	err = json.Unmarshal(doc, &docI)
	if err != nil {
		log.Fatalln(err)
	}

	err = json.Unmarshal(patch, &patchI)
	if err != nil {
		log.Fatalln(err)
	}

	res, err := jsonPatch(docI, patchI)
	if err != nil {
		log.Fatalln(err)
	}

	fmt.Println(res)
}

func jsonPatch(doc, patch interface{}) (string, error) {
	jp := &jsonPatchParams{
		Doc:   doc,
		Patch: patch,
	}
	buf := &bytes.Buffer{}
	encoder := json.NewEncoder(buf)
	encoder.SetEscapeHTML(false)
	err := encoder.Encode(jp)
	if err != nil {
		return "", err
	}

	values, err := chartutil.CoalesceValues(helmChart, chartutil.Values{
		"Values": chartutil.Values{
			"jsonpatch": buf.String(),
		},
	})

	if err != nil {
		return "", err
	}

	res, err := helmEngine.Render(helmChart, values)
	if err != nil {
		return "", err
	}

	return res["test/template.yaml"], nil
}
