{{- define "wildfly-config.system-properties" }}
<system-properties>
        <property name="org.wildfly.sigterm.suspend.timeout" value="{{ .Values.wildfly_sigterm_suspend_timeout | default 60 }}"/>
        <property name="org.jboss.ejb.client.discovery.additional-node-timeout" value="{{ .Values.wildfly_disovery_additional_node_timeout | default 0 }}"/>
        <property name="jboss.as.management.blocking.timeout" value="1800"/>
{{- range .Values.wildfly_system_properties }}
        {{- if eq .name "jboss.as.management.blocking.timeout" }}
        {{ else }}
        <property name="{{ .name }}" value="{{ .value }}"/>
        {{- end }}
{{- end }}
</system-properties>
{{- end }}
