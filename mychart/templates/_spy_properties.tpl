{{- define "wildfly-config.spy-properties" -}}
{{- range .Values.wildfly_datasources }}
	{{- if .p6spy }}
realdatasource={{ .jndi }}
		{{- if eq .driver "oracle" }}
realdatasourceclass=oracle.jdbc.xa.client.OracleXADataSource
		{{- end }}
		realdatasourceproperties=port;{{ regexReplaceAll ".*@[^:]+:(\\d+)[/:].*" .url "${1}" }},serverName;{{ regexReplaceAll ".*@([^:]+):\\d+.*" .url "${1}" }},databaseName;{{ regexReplaceAll ".*@[^:]+:\\d+[/:](.*)" .url "${1}" }},{{ .user }};{{ .password }}
	{{- end }}
{{- end }}
appender=com.p6spy.engine.spy.appender.Slf4JLogger
logMessageFormat=com.p6spy.engine.spy.appender.CustomLineFormat
customLogMessageFormat=#now=%(currentTime)| took %(executionTime) ms | %(category)| connection %(connectionId)| query=%(sql)
modulelist=io.opentracing.contrib.p6spy.TracingP6SpyFactory
tracingPeerService={{ .Values.name }}
traceWithActiveSpanOnly=true
traceWithStatementValues=true
# LKP-19119, нигде нет, в k8s все равно будет недоступен
logfile=/dev/null
{{- end -}}
