{{- define "wildfly-config.naming" }}
<bindings>
{{- range .Values.wildfly_naming }}
       <object-factory name="{{ .jndi }}" module="{{ .wildfly_naming_module | default $.Values.wildfly_naming_module | default "ru.lanit.config" }}" class="{{ .wildfly_naming_class | default $.Values.wildfly_naming_class | default "ru.lanit.jboss.config.spi.ConfigObjectFactory" }}">
           <environment>
           {{- range .properties }}
               <property name="{{ .name }}" value="{{ .value }}"/>
           {{- end }}
           </environment>
       </object-factory>
{{- end }}
{{- range .Values.wildfly_lookup_naming }}
<lookup name="{{ .name }}" lookup="{{ .lookup }}"/>
{{- end }}
{{- range .Values.wildfly_simple_naming }}
<simple name="{{ .name }}" value="{{ .value }}"{{ if .type }} type="{{ .type }}"{{ end }}/>
{{- end }}
</bindings>
{{- end }}
