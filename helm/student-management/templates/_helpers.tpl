{{/*
Expand the name of the chart.
*/}}
{{- define "student-management.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this
(by the DNS naming spec).
*/}}
{{- define "student-management.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "student-management.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to all resources.
*/}}
{{- define "student-management.labels" -}}
helm.sh/chart: {{ include "student-management.chart" . }}
{{ include "student-management.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used by Deployments and Services.
*/}}
{{- define "student-management.selectorLabels" -}}
app.kubernetes.io/name: {{ include "student-management.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MySQL-specific labels.
*/}}
{{- define "student-management.mysqlLabels" -}}
helm.sh/chart: {{ include "student-management.chart" . }}
app.kubernetes.io/name: mysql
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
MySQL selector labels.
*/}}
{{- define "student-management.mysqlSelectorLabels" -}}
app.kubernetes.io/name: mysql
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Secret name for MySQL credentials.
*/}}
{{- define "student-management.mysqlSecretName" -}}
{{- printf "%s-mysql-secret" (include "student-management.fullname" .) }}
{{- end }}

{{/*
Secret name for application credentials.
*/}}
{{- define "student-management.appSecretName" -}}
{{- printf "%s-app-secret" (include "student-management.fullname" .) }}
{{- end }}

{{/*
ConfigMap name.
*/}}
{{- define "student-management.configMapName" -}}
{{- printf "%s-config" (include "student-management.fullname" .) }}
{{- end }}
