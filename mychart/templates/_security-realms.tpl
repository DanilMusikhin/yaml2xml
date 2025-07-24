{{- define "wildfly-config.security-realms" }}
{{- range .Values.wildfly_security_realms }}
<security-realm name="{{ .name }}">
   <server-identities>
       <secret value="{{ .password | b64enc }}"/>
   </server-identities>
</security-realm>
{{- end }}
{{- end }}
