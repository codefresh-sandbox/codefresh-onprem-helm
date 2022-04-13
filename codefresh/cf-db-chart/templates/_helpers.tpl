{{/*
Defines rabbit pvc storage class name
*/}}
{{- define "rabbit.storageClass" -}}
{{- $storageClass := coalesce .Values.rabbit.storageClass .Values.global.storageClass | default "" -}}
{{- printf "%s" $storageClass -}}
{{- end -}}

{{/*
Defines rabbit pvc storage size
*/}}
{{- define "rabbit.storageSize" -}}
{{- $storageSize := coalesce .Values.rabbit.storageSize | default "32Gi" -}}
{{- printf "%s" $storageSize -}}
{{- end -}}