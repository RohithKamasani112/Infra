{{/*
Expand the name of the chart.
*/}}
{{- define "prometheus-grafana.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "prometheus-grafana.fullname" -}}
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
{{- define "prometheus-grafana.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "prometheus-grafana.labels" -}}
helm.sh/chart: {{ include "prometheus-grafana.chart" . }}
{{ include "prometheus-grafana.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "prometheus-grafana.selectorLabels" -}}
app.kubernetes.io/name: {{ include "prometheus-grafana.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "prometheus-grafana.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "prometheus-grafana.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Prometheus server name
*/}}
{{- define "prometheus-grafana.prometheus.fullname" -}}
{{- printf "%s-prometheus" (include "prometheus-grafana.fullname" .) }}
{{- end }}

{{/*
Grafana name
*/}}
{{- define "prometheus-grafana.grafana.fullname" -}}
{{- printf "%s-grafana" (include "prometheus-grafana.fullname" .) }}
{{- end }}

{{/*
AlertManager name
*/}}
{{- define "prometheus-grafana.alertmanager.fullname" -}}
{{- printf "%s-alertmanager" (include "prometheus-grafana.fullname" .) }}
{{- end }}

{{/*
Common monitoring labels
*/}}
{{- define "prometheus-grafana.monitoring.labels" -}}
monitoring: "enabled"
cluster: {{ .Values.cluster.name | quote }}
environment: {{ .Values.cluster.environment | quote }}
{{- end }}

{{/*
Prometheus selector labels
*/}}
{{- define "prometheus-grafana.prometheus.selectorLabels" -}}
app.kubernetes.io/name: prometheus
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: server
{{- end }}

{{/*
Grafana selector labels
*/}}
{{- define "prometheus-grafana.grafana.selectorLabels" -}}
app.kubernetes.io/name: grafana
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: grafana
{{- end }}

{{/*
AlertManager selector labels
*/}}
{{- define "prometheus-grafana.alertmanager.selectorLabels" -}}
app.kubernetes.io/name: alertmanager
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: alertmanager
{{- end }}
