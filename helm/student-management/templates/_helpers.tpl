{{- define "student-management.name" -}}
student-management
{{- end }}

{{- define "student-management.labels" -}}
app.kubernetes.io/name: {{ include "student-management.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{- define "student-management.selectorLabels" -}}
app.kubernetes.io/name: {{ include "student-management.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
