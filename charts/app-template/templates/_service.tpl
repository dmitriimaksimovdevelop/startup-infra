{{- define "app-template.service" -}}
{{- if ne (toString (.Values.service).enabled) "false" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "app-template.fullname" . }}
  labels: {{- include "app-template.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  selector: {{- include "app-template.selectorLabels" . | nindent 4 }}
  ports:
    - name: http
      port: {{ .Values.service.port | default 80 }}
      targetPort: {{ .Values.service.targetPort | default .Values.service.port | default 80 }}
      protocol: TCP
{{- end }}
{{- end }}
