{{/*
Expand the name of the chart.
*/}}
{{- define "probo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "probo.fullname" -}}
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
{{- define "probo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "probo.labels" -}}
helm.sh/chart: {{ include "probo.chart" . }}
{{ include "probo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "probo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "probo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "probo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "probo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL hostname
*/}}
{{- define "probo.postgresql.host" -}}
{{- .Values.postgresql.host | required "postgresql.host is required" }}
{{- end }}

{{/*
PostgreSQL port
*/}}
{{- define "probo.postgresql.port" -}}
{{- .Values.postgresql.port | default 5432 }}
{{- end }}

{{/*
PostgreSQL database name
*/}}
{{- define "probo.postgresql.database" -}}
{{- .Values.postgresql.database | default "probod" }}
{{- end }}

{{/*
PostgreSQL username
*/}}
{{- define "probo.postgresql.username" -}}
{{- .Values.postgresql.username | default "probod" }}
{{- end }}

{{/*
S3 endpoint
*/}}
{{- define "probo.s3.endpoint" -}}
{{- .Values.s3.endpoint }}
{{- end }}

{{/*
Chrome DevTools Protocol address
*/}}
{{- define "probo.chrome.addr" -}}
{{- if .Values.chrome.enabled }}
{{- printf "%s-chrome:9222" (include "probo.fullname" .) }}
{{- else }}
{{- .Values.chrome.external.addr | required "chrome.external.addr is required when chrome.enabled=false" }}
{{- end }}
{{- end }}
