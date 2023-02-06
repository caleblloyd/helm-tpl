# helm-jsonpatch-tpl

[JSON Patch](https://jsonpatch.com/) in a [Helm Named Template](https://helm.sh/docs/chart_template_guide/named_templates/)

## Usage

Copy `_jsonpatch.tpl` to your helm chart `templates/` directory

Call the `jsonpatch` named template:
- input: a map with 2 keys:
  - `doc`: `interface{}` valid JSON document
  - `patch`: `[]interface{}` valid [JSON Patch](https://jsonpatch.com/) document
- output: JSON string with the patched json result

## Example

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
{{ include "jsonpatch" (dict "doc" .Values.pod "patch" .Values.patchPod) | fromJson | toYaml }}
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

Try it by running `./example/template.sh`
