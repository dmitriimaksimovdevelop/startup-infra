{{- define "app-template.all" -}}
{{ include "app-template.deployment" . }}
---
{{ include "app-template.service" . }}
{{- if .Values.secrets }}
---
{{ include "app-template.secret" . }}
{{- end }}
{{- end }}
