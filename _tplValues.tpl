{{- /*
tplValues
input: map with 2 keys:
- doc: interface{}
- ctx: context to pass to tpl function
output: JSON encoded map with 1 key:
- doc: interface{} with any keys called tpl or tplSpread values templated and replaced

maps matching the following syntax will be templated
{
  tpl: string
}

maps matching the follow syntax will be templated, then spread into the parent map/slice
{
  tplSpread: string
}
*/}}
{{- define "tplValues" -}}
  {{- $patch := get (include "tplValuesItr" (dict "ctx" .ctx "parentKind" "" "parentPath" "" "path" "/" "value" .doc) | fromJson) "patch" -}}
  {{- include "jsonpatch" (dict "doc" .doc "patch" $patch) -}}
{{- end -}}

{{- /*
tplValuesItr
input: map with 4 keys:
- path: string JSONPath to current element
- parentKind: string kind of parent element
- parentPath: string JSONPath to parent element
- value: interface{}
- ctx: context to pass to tpl function
output: JSON encoded map with 1 key:
- patch: list of patches to apply in order to template
*/}}
{{- define "tplValuesItr" -}}
  {{- $params := . -}}
  {{- $kind := kindOf $params.value -}}
  {{- $patch := list -}}
  {{- $joinPath := $params.path -}}
  {{- if eq $params.path "/" -}}
    {{- $joinPath = "" -}}
  {{- end -}}
  {{- $joinParentPath := $params.parentPath -}}
  {{- if eq $params.parentPath "/" -}}
    {{- $joinParentPath = "" -}}
  {{- end -}}

  {{- if eq $kind "slice" -}}
    {{- $iAdj := 0 -}}
    {{- range $i, $v := $params.value -}}
      {{- $iPath := printf "%s/%d" $joinPath (add $i $iAdj) -}}
      {{- $itrPatch := get (include "tplValuesItr" (dict "ctx" $params.ctx "parentKind" $kind "parentPath" $params.path "path" $iPath "value" $v) | fromJson) "patch" -}}
      {{- $itrLen := len $itrPatch -}}
      {{- if gt $itrLen 0 -}}
        {{- $patch = concat $patch $itrPatch -}}
        {{- if gt $itrLen 2 -}}
          {{- $iAdj = add $iAdj (sub $itrLen 2) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}

  {{- else if eq $kind "map" -}}
    {{- if and (eq (len $params.value) 1) (or (hasKey $params.value "tpl") (hasKey $params.value "tplSpread")) -}}
      {{- $tpl := get $params.value "tpl" -}}
      {{- $spread := false -}}
      {{- if hasKey $params.value "tplSpread" -}}
        {{- if eq $params.path "/" -}}
          {{- fail "cannot tplSpread on root object" -}}
        {{- end -}}
        {{- $tpl = get $params.value "tplSpread" -}}
        {{- $spread = true -}}
      {{- end -}}

      {{- $res := tpl $tpl $params.ctx -}}
      {{- $res = get (fromYaml (tpl "tpl: {{ nindent 2 .res }}" (merge (dict "res" $res) $params.ctx))) "tpl" -}}

      {{- if eq $spread false -}}
        {{- $patch = append $patch (dict "op" "replace" "path" $params.path "value" $res) -}}
      {{- else -}}
        {{- $resKind := kindOf $res -}}
        {{- if ne $resKind $params.parentKind -}}
           {{- fail (cat "can only tplSpread slice onto a slice or map onto a map; attempted to spread" $resKind "on" $params.parentKind "at path" $params.path) -}}
        {{- end -}}
          {{- $patch = append $patch (dict "op" "remove" "path" $params.path) -}}
        {{- if eq $resKind "slice" -}}
          {{- range $v := reverse $res -}}
            {{- $patch = append $patch (dict "op" "add" "path" $params.path "value" $v) -}}
          {{- end -}}
        {{- else -}}
          {{- range $k, $v := $res -}}
            {{- $kPath := replace "~" "~0" $k -}}
            {{- $kPath = replace "/" "~1" $kPath -}}
            {{- $kPath = printf "%s/%s" $joinParentPath $kPath -}}
            {{- $patch = append $patch (dict "op" "add" "path" $kPath "value" $v) -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- else -}}
       {{- range $k, $v := $params.value -}}
          {{- $kPath := replace "~" "~0" $k -}}
          {{- $kPath = replace "/" "~1" $kPath -}}
          {{- $kPath = printf "%s/%s" $joinPath $kPath -}}
          {{- $itrPatch := get (include "tplValuesItr" (dict "ctx" $params.ctx "parentKind" $kind "parentPath" $params.path "path" $kPath "value" $v) | fromJson) "patch" -}}
          {{- if gt (len $itrPatch) 0 -}}
            {{- $patch = concat $patch $itrPatch -}}
          {{- end -}}
       {{- end -}}
    {{- end -}}
  {{- end -}}
  
  {{- toJson (dict "patch" $patch) -}}
{{- end -}}
