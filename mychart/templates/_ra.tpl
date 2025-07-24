{{- define "wildfly-config.ra" }}
{{- range .Values.wildfly_resource_adapters }}
<resource-adapter id="{{ .id }}" statistics-enabled="true">
    <archive>
        {{ .archive }}
    </archive>
    <transaction-support>{{ .transaction_support }}</transaction-support>
    <connection-definitions>
        {{- range .connection_definitions }}
        <connection-definition class-name="{{ .class }}" jndi-name="{{ .jndi }}" enabled="true" tracking="{{ .tracking }}" pool-name="{{ .pool }}">
            <pool>
                <min-pool-size>{{ .min_pool_size }}</min-pool-size>
                <max-pool-size>{{ .max_pool_size }}</max-pool-size>
            </pool>
            {{- range .config_properties }}
            <config-property name="{{ .name }}">{{ .value }}</config-property>
            {{- end }}
            <timeout>
            {{- if .blocking_timeout_millis }}
                <blocking-timeout-millis>{{ .blocking_timeout_millis }}</blocking-timeout-millis>
            {{- end }}
            {{- if .idle_timeout_minutes }}
                <idle-timeout-minutes>{{ .idle_timeout_minutes }}</idle-timeout-minutes>
            {{- end }}
            </timeout>
        </connection-definition>
        {{- end }}
    </connection-definitions>
</resource-adapter>
{{- end }}
{{- end }}
