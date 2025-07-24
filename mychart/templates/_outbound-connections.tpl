{{- define "wildfly-config.outbound-connections" }}
<outbound-connections>
    {{- range .Values.wildfly_outbound_connections }}
        {{- if .uri }}
    <outbound-connection name="{{ .name }}" uri="{{ .uri }}"/>
        {{- else }}
    <remote-outbound-connection name="{{ .name }}" outbound-socket-binding-ref="{{ .socket_binding }}" protocol="http-remoting" security-realm="{{ .security_realm }}" username="{{ .user }}">
        <properties>
            <property name="SASL_POLICY_NOANONYMOUS" value="false"/>
            <property name="SSL_ENABLED" value="false"/>
            {{- if .heartbeat_interval }}
            <property name="org.jboss.remoting3.RemotingOptions.HEARTBEAT_INTERVAL" value="{{ .heartbeat_interval }}"/>
            {{- end }}
        </properties>
    </remote-outbound-connection>
        {{- end }}
    {{- end }}
</outbound-connections>
{{- end }}
