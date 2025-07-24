{{- define "wildfly-config.mail" }}
{{- range .Values.wildfly_mail_sessions }}
<mail-session name="{{ .name }}" debug="false" jndi-name="{{ .jndi }}" from="{{ .from }}">
    <smtp-server outbound-socket-binding-ref="{{ .name }}-mail" ssl="false" {{ if .username }}username="{{ .username }}"{{ end }} {{ if .password }}password="{{ .password }}"{{ end }}/>
</mail-session>
{{- end }}
{{- end }}
