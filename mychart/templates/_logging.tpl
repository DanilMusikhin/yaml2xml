{{- define "wildfly-config.logging" }}
{{- range .Values.wildfly_logging }}
<logger category="{{ .class }}">
       <level name="{{ .level }}" {{ if .use_parent_handlers }}use-parent-handlers="{{ .use_parent_handlers }}"{{ end }}/>
       {{- if .handler }}
       <handlers>
           <handler name="{{ .handler }}"/>
       </handlers>
       {{- end }}
</logger>
{{- end }}
{{- end }}
