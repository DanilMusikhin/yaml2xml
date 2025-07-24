{{- define "wildfly-config.zorka-properties" }}
scripts = {{ .Values.wildfly_zorka_scripts | default "zabbix.bsh, jvm.bsh, wildfly-custom.bsh, jdbc/oracle.bsh, jdbc/mysql.bsh, jdbc/pgsql.bsh, javax/jms.bsh, ldap.bsh, http.bsh, ejb.bsh, sql.bsh, ft.bsh" }}

zorka.hostname = unknown

zorka.spy.compute.frames = yes
tracer = no
zorka.req.timeout = 120000


sql.error = yes
sql.error.file.path = /dev/stdout
sql.error.format = [${TIME}] [DB:${DB}] [SQL:${SQL}] [ERR:${ERR}]

sql.slow = yes
{{ if hasKey .Values.app_conf .Chart.Name }}
sql.slow.time = {{ index .Values.app_conf (print .Chart.Name) "sql_slow_time" | default "60000" }}
{{ else }}
sql.slow.time = 30000
{{ end }}
sql.slow.file.path = /dev/stdout
sql.slow.format = [${TIME}] [DB:${DB}] [SQL:${SQL}]
{{- end }}
