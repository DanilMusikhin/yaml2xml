{{- define "wildfly-config.system-properties" }}
<system-properties>
    <property name="consul.host.default.override" value="192.168.1.72"/>
    <property name="consul.port.default.override" value="8500"/>
{{- range .Values.wildfly_system_properties }}
    {{- if eq .name "jboss.as.management.blocking.timeout" }}
    {{ else }}
    <property name="{{ .name }}" value="{{ .value }}"/>
    {{- end }}
{{- end }}
    <property name="ppaStubHelper" value="${jboss.home.dir}/ppa.properties"/>
    <property name="ejbCacheEnabled" value="false"/>
</system-properties>
{{- end }}
