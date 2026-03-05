{{- define "app-template.secret" -}}
{{- if .Values.secrets }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "app-template.fullname" . }}
  labels: {{- include "app-template.labels" . | nindent 4 }}
type: Opaque
stringData:
  {{- range $key, $value := .Values.secrets }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}
{{- end }}
