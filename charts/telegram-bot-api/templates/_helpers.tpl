{{/*
Expand the name of the chart.
*/}}
{{- define "telegram-bot-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "telegram-bot-api.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "telegram-bot-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "telegram-bot-api.labels" -}}
helm.sh/chart: {{ include "telegram-bot-api.chart" . }}
{{ include "telegram-bot-api.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "telegram-bot-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "telegram-bot-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Name of the API credentials Secret.
*/}}
{{- define "telegram-bot-api.apiSecretName" -}}
{{- default (include "telegram-bot-api.fullname" .) .Values.telegram.existingSecret -}}
{{- end -}}

{{/*
Name of the basic-auth Secret.
*/}}
{{- define "telegram-bot-api.basicAuthSecretName" -}}
{{- if .Values.basicAuth.existingSecret -}}
{{- .Values.basicAuth.existingSecret -}}
{{- else if .Values.basicAuth.secretName -}}
{{- .Values.basicAuth.secretName -}}
{{- else -}}
{{- printf "%s-basic-auth" (include "telegram-bot-api.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Name of the Traefik Middleware resource.
*/}}
{{- define "telegram-bot-api.traefikMiddlewareName" -}}
{{- if .Values.traefik.middleware.name -}}
{{- .Values.traefik.middleware.name -}}
{{- else -}}
{{- printf "%s-basic-auth" (include "telegram-bot-api.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Traefik middleware reference used by the ingress annotation.
*/}}
{{- define "telegram-bot-api.traefikMiddlewareReference" -}}
{{- printf "%s-%s@kubernetescrd" .Release.Namespace (include "telegram-bot-api.traefikMiddlewareName" .) -}}
{{- end -}}

{{/*
Container image reference.
*/}}
{{- define "telegram-bot-api.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}
