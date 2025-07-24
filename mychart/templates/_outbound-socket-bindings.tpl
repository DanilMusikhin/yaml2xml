{{- define "wildfly-config.outbound-socket-bindings" }}
{{- range .Values.wildfly_mail_sessions }}
<outbound-socket-binding name="{{ .name }}-mail">
    <remote-destination host="{{ .server }}" port="{{ .port }}"/>
</outbound-socket-binding>
{{- end }}
{{- range .Values.wildfly_socket_bindings }}
<outbound-socket-binding name="{{ .name }}">
    {{- range .destinations }}
    <remote-destination host="{{ .host }}" port="{{ .port }}"/>
    {{- end }}
</outbound-socket-binding>
{{- end }}
{{- end }}
