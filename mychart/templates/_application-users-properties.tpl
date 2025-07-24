{{- define "wildfly-config.application-users-properties" }}
{{ range .Values.wildfly_users }}
{{ .login }}={{ .passwordhash }}
{{ end }}
{{- end }}
