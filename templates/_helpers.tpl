{{/* vim: set filetype=mustache: */}}

{{/*
Fullname of configMap/secret that contains environment variables
*/}}
{{- define "archetype.env.fullname" -}}
{{- $root := index . 0 -}}
{{- $postfix := index . 1 -}}
{{- printf "%s-%s-%s" (include "archetype.fullname" $root) "env" $postfix -}}
{{- end -}}

{{/*
Fullname of configMap/secret that contains files
*/}}
{{- define "archetype.files.fullname" -}}
{{- $root := index . 0 -}}
{{- $postfix := index . 1 -}}
{{- printf "%s-%s-%s" (include "archetype.fullname" $root) "files" $postfix -}}
{{- end -}}

{{- define "archetype.configmap.name" -}}
{{- default (printf "%s-config" .Values.app  | trunc 54 | trimSuffix "-") | lower -}}
{{- end -}}

{{- define "archetype.service.name" -}}
{{- default (printf "%s-svc" .Values.app | trunc 54 | trimSuffix "-") | lower -}}
{{- end -}}

{{- define "archetype.archetype.spark.configmap.name" -}}
{{- default (printf "%s-configmap" .Values.app | lower | trunc 54 | trimSuffix "-") .Values.fullnameOverride -}}
{{- end -}}

{{/*
Environment template block for deployable resources
*/}}
{{- define "archetype.common.env" -}}
{{- $root := . -}}
{{- if or ($root.Values.configMap $root.Values.secrets) }}
envFrom:
{{- range $name, $config := $root.Values.configMap -}}
{{- if $config.enabled }}
{{- if not ( empty $config.env ) }}
- configMapRef:
    name: {{ include "archetype.env.fullname" (list $root $name) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- range $name, $secret := $root.Values.secrets -}}
{{- if $secret.enabled }}
{{- if not ( empty $secret.env ) }}
- secretRef:
    name: {{ include "archetype.env.fullname" (list $root $name) }}-env
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Namespace template block
*/}}
{{- define "archetype.namespace.name" -}}
{{- $root := . -}}
{{- $ns := $root.Values.namespace -}}
{{- if $ns.enabled }}
namespace: {{ if hasKey $ns "name" }}{{ $ns.name }}{{ else }}{{ include "archetype.appname" $root }}{{ end }}
{{- end }}
{{- end }}

{{/*
Volumes template block for deployable resources
*/}}
{{- define "archetype.files.volumes" -}}
{{- $root := . -}}
{{- $config := $root.Values.configMap -}}
{{- if $config.enabled }}
{{- if not ( empty $config.files ) }}
- name: config-files
  configMap:
    name: {{ include "archetype.shortname" $root }}
{{- end }}
{{- end }}

{{- range $name, $secret := $root.Values.secrets -}}
{{- if $secret.enabled }}
{{- if not ( empty $secret.files ) }}
- name: secret-{{ $name }}-files
  secret:
    secretName: {{ include "archetype.files.fullname" (list $root $name) }}
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
VolumeMounts template block for deployable resources
*/}}
{{- define "archetype.files.volumeMounts" -}}
{{- if .Values.configMap.enabled }}
{{- if not ( empty .Values.configMap.files ) }}
- mountPath: {{ default "/data" | .Values.configMap.mountPath }}
  name: config-{{ include "archetype.appname" }}-files
{{- end }}
{{- end -}}
{{- range $name, $secret := .Values.secrets -}}
{{- if $secret.enabled }}
{{- if not ( empty $secret.files ) }}
- mountPath: {{ default (printf "/%s" $name) $secret.mountPath }}
  name: secret-{{ $name }}-files
  readOnly: true
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "archetype.ingress.service" -}}
- path: "/"
  backend:
    serviceName: {{ include "archetype.servicename" . }}
    servicePort: {{ .Values.ports.external }}
{{- end -}}

{{- define "archetype.istio.virtualservice" -}}
- match:
  - uri:
      prefix: /
  route:
  - destination:
      host: {{ include "archetype.appname" . }}
      port:
        number: {{ .Values.ports.external }}
{{- end -}}

{{- define "archetype.container.ports" -}}
- name: www
  containerPort: {{ .Values.ports.internal }}
- name: metrics
  containerPort: {{ .Values.ports.prometheus }}
{{- end -}}

{{- define "archetype.appname" -}}
{{ .Values.app | default (include "common.name" . ) }}
{{- end -}}

{{- define "archetype.servicename" -}}
{{ include "archetype.appname" . }}-svc
{{- end -}}

{{- define "archetype.service.selectors" -}}
app: {{ include "archetype.appname" . | quote }}
release: {{ .Release.Name | quote }}
{{- end -}}

{{- define "archetype.service.ports" -}}
- name: http
  protocol: TCP
  port: {{ .Values.ports.external }}
  targetPort: {{ .Values.ports.internal }}
- name: https
  protocol: TCP
  port: {{ .Values.ports.tls_external }}
  targetPort: {{ .Values.ports.tls_internal }}
{{- end -}}

{{- define "archetype.spark.jmxmonitoring" -}}
exposeDriverMetrics: true
exposeExecutorMetrics: true
port: {{ .Values.ports.jmx }}
prometheus:
  jmxExporterJar: "/prometheus/jmx_prometheus_javaagent-0.11.0.jar"
{{- end -}}

{{- define "archetype.spark.configmap" -}}
volumeMounts:
- name: config-vol
  mountPath: /opt/spark
{{- end -}}

{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- /*
archetype.zonemap returns a short name for the zone.
*/ -}}
{{- define "archetype.zonemap" -}}
{{- $zoneMap := index . 0 -}}
{{- $zone := index . 1 -}}
{{- if hasKey $zoneMap $zone }}
{{- index $zoneMap $zone -}}
{{- else }}
{{- printf "%s" "internal" -}}
{{- end }}
{{- end -}}

{{- /*
archetype.ingressclassmap returns a short name for the zone.
*/ -}}
{{- define "archetype.ingressclassmap" -}}
{{- $classMap := index . 0 -}}
{{- $zone := index . 1 -}}
{{- if hasKey $classMap $zone }}
{{- index $classMap $zone -}}
{{- end }}
{{- end -}}

{{- /*
archetype.ingress.certissuer prints a derived ingress certmanager annotation based on zone
*/ -}}
{{- define "archetype.ingress.certissuer" -}}
{{- $issuerMap := index . 0 -}}
{{- $zone := index . 1 -}}
{{- if hasKey $issuerMap $zone }}
{{- with (index $issuerMap $zone)}}
{{- toYaml . }}
{{- end }}
{{- end }}
{{- end -}}

{{- /*
archetype.clusterdns prints a derived dns name based on zone
*/ -}}
{{- define "archetype.clusterdns" -}}
{{- $zone := include "archetype.zonemap" (list .Values.zoneMap .Values.zone) -}}
{{- printf "%s.%s" $zone .Values.dnsRoot | trimPrefix "." -}}
{{- end -}}

{{- /*
archetype.ingress.class prints a derived ingress class based on zone
*/ -}}
{{- define "archetype.ingress.class" -}}
{{- $class := include "archetype.ingressclassmap" (list .Values.ingressClassMap .Values.zone) -}}
{{- if $class -}}
kubernetes.io/ingress.class: {{ $class | quote }}
{{- end -}}
{{- end -}}

{{- define "archetype.fullname" -}}
{{- $base := default (printf "%s-%s" .Release.Name .Chart.Name) .Values.fullnameOverride -}}
{{- $gpre := default "" .Values.global.fullnamePrefix -}}
{{- $pre := default "" .Values.fullnamePrefix -}}
{{- $suf := default "" .Values.fullnameSuffix -}}
{{- $gsuf := default "" .Values.global.fullnameSuffix -}}
{{- $name := print $gpre $pre $base $suf $gsuf -}}
{{- $name | lower | trunc 54 | trimSuffix "-" -}}
{{- end -}}

{{- /*
archetype.fullname.unique adds a random suffix to the unique name.
This takes the same parameters as archetype.fullname
*/ -}}
{{- define "archetype.fullname.unique" -}}
{{ template "archetype.fullname" . }}-{{ randAlphaNum 7 | lower }}
{{- end }}

{{- define "archetype.shortname" -}}
{{- $base := default (printf "%s" .Release.Name) .Values.fullnameOverride -}}
{{- $name := print $base -}}
{{- $name | lower | trunc 54 | trimSuffix "-" -}}
{{- end -}}

{{- /*
standard labels for project deployments
*/ -}}
{{- define "archetype.labels" -}}
app: {{ include "archetype.appname" . | quote }}
chart: {{ template "common.chartref" . }}
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
zone: {{ .Values.zone | quote }}
namespace: {{ .Release.Namespace | quote }}
{{- if .Values.argocd }}
app.kubernetes.io/part-of: argocd
{{- end }}
{{- end -}}

{{- /*
Create an image pull secret string
*/ -}}
{{- define "archetype.imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.dockercfg.image.pullSecret.registry (printf "%s:%s" .Values.dockercfg.image.pullSecret.username .Values.dockercfg.image.pullSecret.password | b64enc) | b64enc }}
{{- end }}