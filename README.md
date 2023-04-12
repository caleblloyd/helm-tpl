# helm-tpl

Various helm templates to provide useful functions in helm charts.

- jsonpatch
- toPrettyRawJson
- tplYaml

## jsonpatch

[JSON Patch](https://jsonpatch.com/) in a [Helm Named Template](https://helm.sh/docs/chart_template_guide/named_templates/)

### Usage

Copy `_jsonpatch.tpl` to your helm chart `templates/` directory

Call the `jsonpatch` named template:
- input: a map with 2 keys:
  - `doc`: `interface{}` valid JSON document
  - `patch`: `[]interface{}` valid [JSON Patch](https://jsonpatch.com/) document
- output: JSON encoded map with 1 key:
  - `doc`: interface{} patched json result

### Example

**values.yaml:**

```yaml
pod:
  apiVersion: v1
  kind: Pod
  metadata:
    name: nginx
  spec:
    containers:
    - name: nginx
      image: nginx:latest
      ports:
      - containerPort: 80

patchPod:
- op: replace
  path: /spec/containers/0/image
  value: nginx:alpine
- op: add
  path: /spec/containers/0/ports/-
  value:
    containerPort: 8080
```

**templates/pod.yaml:**

```yaml
{{ get (include "jsonpatch" (dict "doc" .Values.pod "patch" .Values.patchPod) | fromJson) "doc" | toYaml }}
```

**helm template output:**

```yaml
---
# Source: jsonpatch-example/templates/pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - image: nginx:alpine
    name: nginx
    ports:
    - containerPort: 80
    - containerPort: 8080
```

Try it by running `./jsonpatch/example/template.sh`

## toPrettyRawJson

Copy `_toPrettyRawJson.tpl` to your helm chart `templates/` directory

Pretty prints using `toPrettyJson` and unescapes HTML entities for `&`, `<`, and `>`

Try it by running `./toPrettyRawJson/example/template.sh`

## tplYaml

Copy `_jsonpatch.tpl` and `_tplYaml.tpl` to your helm chart `templates/` directory

Call the `tplYaml` named template:
- input: a map with 2 keys:
  - `doc`: `interface{}` valid JSON document
  - `ctx`: `interface{}` context to pass to template function
- output: JSON encoded map with 1 key:
  - `doc`: interface{} patched json result

### Example

**values.yaml:**

```yaml
name: nginx
ports:
  http: 80
  https: 443

pod:
  apiVersion: v1
  kind: Pod
  metadata:
    name:
      $tplYaml: >-
        {{ .Values.name | quote }}
  spec:
    containers:
    - name:
        $tplYaml: >-
          {{ .Values.name | quote }}
      image: nginx:latest
      ports:
      - $tplYamlSpread: |-
          {{- range $k, $v := .Values.ports }}
          - name: {{ $k | quote }}
            containerPort: {{ $v }}
          {{- end }}
```

**templates/pod.yaml:**

```yaml
{{ get (include "tplYaml" (dict "doc" .Values.pod "ctx" .) | fromJson) "doc" | toYaml }}
```

**helm template output:**

```yaml
---
# Source: tplYaml-example/templates/pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - image: nginx:latest
    name: nginx
    ports:
    - containerPort: 80
      name: http
    - containerPort: 443
      name: https
```

Try it by running `./tplYaml/example/template.sh`
