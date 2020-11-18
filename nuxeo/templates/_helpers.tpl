{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "nuxeo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "nuxeo.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- printf .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "nuxeo.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "nuxeo.validateValues.clustering" .) -}}
{{- $messages := append $messages (include "nuxeo.validateValues.binaryStorage" .) -}}
{{- $messages := append $messages (include "nuxeo.validateValues.database" .) -}}
{{- $messages := append $messages (include "nuxeo.validateValues.kafkaRedis" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\n\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a cloud provider is enabled for binary storage.
*/}}
{{- define "nuxeo.cloudProvider.enabled" -}}
{{- if or .Values.nuxeo.googleCloudStorage.enabled .Values.nuxeo.amazonS3.enabled -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a database is enabled.
*/}}
{{- define "nuxeo.database.enabled" -}}
{{- if or .Values.nuxeo.mongodb.enabled .Values.nuxeo.postgresql.enabled -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a Kafka or Redis is enabled.
*/}}
{{- define "nuxeo.kafkaRedis.enabled" -}}
{{- if or .Values.nuxeo.kafka.enabled .Values.nuxeo.redis.enabled -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Validate clustering configuration: if more than 1 replica, must enable:
  - A cloud provider for binary storage.
  - A database.
  - Kafka or Redis.
*/}}
{{- define "nuxeo.validateValues.clustering" -}}
{{- if and (gt (int .Values.nuxei.replicaCount) 1) (not (and (include "nuxeo.cloudProvider.enabled" .) (and (include "nuxeo.database.enabled" .) (include "nuxeo.kafkaRedis.enabled" .)))) -}}
{{-   printf "\n" -}}
nuxeo clustering configuration:

  When deploying a Nuxeo cluster, ie. replicaCount > 1, the following must be enabled:
    {{- if not (include "nuxeo.cloudProvider.enabled" .) -}}
    {{-   printf "\n    " -}}
    - A cloud provider for binary storage. Please set either nuxeo.googleCloudStorage.enabled=true or nuxeo.amazonS3.enabled=true.
    {{- end -}}
    {{- if not (include "nuxeo.database.enabled" .) -}}
    {{-   printf "\n    " -}}
    - A database for metadata storage. Please set either nuxeo.mongodb.enabled=true or nuxeo.postgresql.enabled=true.
    {{- end -}}
    {{- if not (include "nuxeo.kafkaRedis.enabled" .) -}}
    {{-   printf "\n    " -}}
    - Kafka or Redis for the WorkManager, PubSub Service and Nuxeo Streams. Please set either nuxeo.kafka.enabled=true or nuxeo.redis.enabled=true.
    {{- end -}}
{{- end -}}
{{- end -}}

{{/* Validate binary storage configuration: can enable either Google Cloud Storage or Amazon S3 but not both. */}}
{{- define "nuxeo.validateValues.binaryStorage" -}}
{{- if and .Values.nuxeo.googleCloudStorage.enabled .Values.nuxeo.amazonS3.enabled -}}
{{-   printf "\n" -}}
nuxeo binary storage configuration:

  Google Cloud Storage and Amazon S3 cloud providers cannot be enabled at the same time.
  Please set either nuxeo.googleCloudStorage.enabled=true or nuxeo.amazonS3.enabled=true.
{{- end -}}
{{- end -}}

{{/* Validate database configuration: can enable either MongoDB or PostgreSQL but not both. */}}
{{- define "nuxeo.validateValues.database" -}}
{{- if and .Values.nuxeo.mongodb.enabled .Values.nuxeo.postgresql.enabled -}}
 {{-   printf "\n" -}}
 nuxeo database configuration:

  MongoDB and PostgreSQL databases cannot be enabled at the same time.
  Please set either nuxeo.mongodb.enabled=true or nuxeo.postgresql.enabled=true.
{{- end -}}
{{- end -}}

{{/* Validate Kafka/Redis mutual exclusion: can enable either kafka or Redis but not both . */}}
{{- define "nuxeo.validateValues.kafkaRedis" -}}
{{- if and .Values.nuxeo.kafka.enabled .Values.nuxeo.redis.enabled -}}
 {{-   printf "\n" -}}
 kafka and redis mutual exclusion:

  Kafka and Redis cannot be enabled at the same time.
  Please set either nuxeo.kafka.enabled=true or nuxeo.redis.enabled=true.
{{- end -}}
{{- end -}}