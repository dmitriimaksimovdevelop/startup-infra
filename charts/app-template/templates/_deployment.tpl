{{- define "app-template.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app-template.fullname" . }}
  labels: {{- include "app-template.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicas | default 2 }}
  selector:
    matchLabels: {{- include "app-template.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels: {{- include "app-template.selectorLabels" . | nindent 8 }}
      {{- with .Values.podAnnotations }}
      annotations: {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets: {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: app
          image: {{ include "app-template.image" (dict "root" . "key" (.Values.imageKey | default "app")) }}
          {{- with .Values.command }}
          command: {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.args }}
          args: {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.ports }}
          ports:
            {{- range . }}
            - name: {{ .name | default "http" }}
              containerPort: {{ .containerPort }}
              protocol: {{ .protocol | default "TCP" }}
            {{- end }}
          {{- end }}
          {{- with .Values.env }}
          env: {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.envFrom }}
          envFrom: {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.resources }}
          resources: {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if .Values.probes }}
          {{- with .Values.probes.liveness }}
          livenessProbe: {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.probes.readiness }}
          readinessProbe: {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.probes.startup }}
          startupProbe: {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- end }}
          {{- with .Values.volumeMounts }}
          volumeMounts: {{- toYaml . | nindent 12 }}
          {{- end }}
      {{- with .Values.volumes }}
      volumes: {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector: {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations: {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity: {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
