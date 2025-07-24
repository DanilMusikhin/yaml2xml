{{- define "wildfly-config.application-roles-properties" }}
{{ range .Values.wildfly_users }}
{{ .login }}={{ .roles }}
{{ end }}
{{- end }}
