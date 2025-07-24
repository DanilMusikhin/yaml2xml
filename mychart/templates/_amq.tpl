{{- define "wildfly-config.amq" }}
{{- $wildfly_amq_adapters := list }}
{{- if .Values.wildfly_amq_url }}
    {{/* To allow legacy style configurations with just one 
    adapter, we will silently convert it to multi-adapters configuration 
    with dark Go template magic */}}
    {{- $aa := dict }}
    {{- $_ := set $aa "app" "activemq-rar.rar" }}
    {{- $_ := set $aa "url" .Values.wildfly_amq_url }}
    {{- $_ := set $aa "connfactories" .Values.wildfly_amq_connection_factories }}
    {{- $_ := set $aa "queues" .Values.wildfly_amq_queues }}
    {{- $_ := set $aa "topics" .Values.wildfly_amq_topics }}
    {{- $wildfly_amq_adapters = list $aa }}
{{- else }}
    {{- $wildfly_amq_adapters = .Values.wildfly_amq_adapters }} 
{{- end }}
{{- range $wildfly_amq_adapters }}
<resource-adapter id="{{ .app }}" statistics-enabled="true">  
     <archive>activemq-rar-{{ $.Values.wildfly_amq_rar_version | default "5.15.6" }}.rar</archive>
     <transaction-support>XATransaction</transaction-support>
     <config-property name="UseInboundSession">
         false
     </config-property>
     <config-property name="ServerUrl">  
         {{ .url }}
     </config-property>  
     <connection-definitions>  
	 {{- range .connfactories }}
         <connection-definition class-name="org.apache.activemq.ra.ActiveMQManagedConnectionFactory" jndi-name="{{ .jndi }}" enabled="true" pool-name="{{ .name }}" tracking="false">  
             <config-property name="useSessionArgs">{{ $.Values.wildfly_amq_use_session_args | default "true" }}</config-property>
             {{- if .prefetch_size }}
             <config-property name="queuePrefetch">{{ .prefetch_size }}</config-property>
             {{- end }}
             <xa-pool>  
                 <min-pool-size>{{ .pool.min | default 1 }}</min-pool-size>  
                 <max-pool-size>{{ .pool.max | default 20 }}</max-pool-size>  
                 <prefill>false</prefill>  
                 <is-same-rm-override>false</is-same-rm-override>  
             </xa-pool>  
         </connection-definition>  
     {{- end }}
     </connection-definitions>  
     <admin-objects>  
		 {{- range .queues }}          
         <admin-object class-name="org.apache.activemq.command.ActiveMQQueue" jndi-name="{{ .jndi }}" use-java-context="true" pool-name="{{ .physical_name }}">  
             <config-property name="PhysicalName">  
                 {{- .physical_name }} 
             </config-property>  
         </admin-object>  
		 {{- end }}
		 {{- range .topics }}
         <admin-object class-name="org.apache.activemq.command.ActiveMQTopic" jndi-name="{{ .jndi }}" use-java-context="true" pool-name="{{ .physical_name }}">  
             <config-property name="PhysicalName">  
                 {{- .physical_name }}
             </config-property>  
         </admin-object>  
		 {{- end }}
     </admin-objects>  
</resource-adapter>  
{{- end }}

{{- end }}
