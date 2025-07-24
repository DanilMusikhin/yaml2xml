{{- define "wildfly-config.wildfly-config-xml" }}
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <http-client xmlns="urn:wildfly-http-client:1.0">
        <defaults>
            <enable-http2 value="false"/>
            <idle-timeout value="1"/>
            <max-connections value="100"/>
            <eagerly-acquire-session value="true"/>
            <buffer-pool buffer-size="2000" max-size="10" direct="true" thread-local-size="1" />
        </defaults>
        <configs>
    {{- range .Values.wildfly_outbound_connections }}
        {{- if .uri }}
            <config uri="{{ .uri }}">
                <enable-http2 value="false"/>
                <idle-timeout value="1000"/>
                <max-connections value="100"/>
                <eagerly-acquire-session value="false"/>
            </config>
        {{- end }}
    {{- end }}
        </configs>
    </http-client>

    <worker xmlns="urn:xnio:3.5">
        <worker-name value="XNIO-WORK"/>
        <pool-size max-threads="200"/>
        <io-threads value="100"/>
        <task-keepalive value="10000"/>
        <daemon-threads value="true"/>
    </worker>
</configuration>
{{- end }}
