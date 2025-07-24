{{- define "wildfly-config.standalone-conf" }}
SERVER_OPTS="-c ../../../../../../etc/wildfly/standalone.xml"
JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=UTF-8 -Djava.security.egd=file:/dev/./urandom -Dorg.jboss.ejb.client.discovery.timeout=30  -Djboss.tx.node.id=$(echo $HOSTNAME | md5sum | cut -b -16) -XX:ActiveProcessorCount=$(nproc) {{ if not (regexMatch ".*-XX:\\+Use" (.Values.wildfly_jvm_options | default "")) }}{{ (index .Values.app_conf (print .Chart.Name)).gc_options | default "-XX:+UseParallelGC -XX:GCTimeRatio=9" }}{{ end }} -Dorg.jboss.logmanager.nocolor=true"
{{- if .Values.wildfly_proxy_target_host }}
JAVA_OPTS="$JAVA_OPTS -Dproxy.target.host={{ .Values.wildfly_proxy_target_host }}"
{{- end }}
{{- if .Values.wildfly_zorka_enabled }}
JAVA_OPTS="$JAVA_OPTS -javaagent:{{ .Values.wildfly_zorka_dir }}/zorka.jar={{ .Values.wildfly_zorka_dir }} -Djboss.modules.system.pkgs=org.jboss.byteman,com.jitlogic.zorka.core.spy"
{{- end }}
{{- if .Values.wildfly_yjp_enabled }}
  {{- if hasKey (index .Values.app_conf .Chart.Name) "wildfly_yjp_options" }}
JAVA_OPTS="$JAVA_OPTS -agentpath:{{ .Values.wildfly_yjp_dir }}/bin/linux-x86-64/libyjpagent.so=sessionname=wildfly_{{ .Chart.Name }},{{ (index .Values.app_conf .Chart.Name).wildfly_yjp_options }}"
  {{- else }}
JAVA_OPTS="$JAVA_OPTS -agentpath:{{ .Values.wildfly_yjp_dir }}/bin/linux-x86-64/libyjpagent.so=sessionname=wildfly_{{ .Chart.Name }},{{ .Values.wildfly_yjp_options }}"
  {{- end }}
{{- end }}
{{- if .Values.wildfly_consul_host_override }}
JAVA_OPTS="$JAVA_OPTS -Dconsul.host.default.override={{ .Values.wildfly_consul_host_override }}"
{{- end }}
{{- if .Values.wildfly_consul_kv_prefix }}
JAVA_OPTS="$JAVA_OPTS -Dconsul.kv.prefix={{ .Values.wildfly_consul_kv_prefix }}"
{{- end }}
{{- if .Values.wildfly_enable_http_client_configuration }}
JAVA_OPTS="$JAVA_OPTS -Dwildfly.config.url=/etc/wildfly/wildfly-config.xml"
{{- end }}
{{- if .Values.wildfly_jvm_options }}
JAVA_OPTS="$JAVA_OPTS {{ .Values.wildfly_jvm_options }}"
{{- end }}


{{- if hasKey .Values.app_conf .Chart.Name }}
  {{- if hasKey (index .Values.app_conf .Chart.Name) "xms" }}
JAVA_OPTS="$JAVA_OPTS -Xms{{(index .Values.app_conf (print .Chart.Name)).xms}}"
  {{- end }}
  {{- if hasKey (index .Values.app_conf .Chart.Name) "xmx" }}
JAVA_OPTS="$JAVA_OPTS -Xmx{{(index .Values.app_conf (print .Chart.Name)).xmx}}"
  {{- else }}
JAVA_OPTS="$JAVA_OPTS -Xmx{{(index .Values.app_conf (print .Chart.Name)).resources.limits.memory | trimSuffix "i" }}"
  {{- end }}
  {{- if hasKey (index .Values.app_conf .Chart.Name) "MetaspaceSize" }}
JAVA_OPTS="$JAVA_OPTS -XX:MetaspaceSize={{(index .Values.app_conf (print .Chart.Name)).MetaspaceSize}}"
  {{- end }}
  {{- if hasKey (index .Values.app_conf .Chart.Name) "MaxMetaspaceSize" }}
JAVA_OPTS="$JAVA_OPTS -XX:MaxMetaspaceSize={{(index .Values.app_conf (print .Chart.Name)).MaxMetaspaceSize}}"
  {{- end }}
{{- end }}

{{- end }}
