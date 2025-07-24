{{- define "wildfly-config.datasources" }}
<datasources>
{{- if eq (.Values.wildfly_concurrency_datasource | default "java:jboss/datasources/ExampleDS") "java:jboss/datasources/ExampleDS" }}
    <datasource jndi-name="java:jboss/datasources/ExampleDS" pool-name="ExampleDS" enabled="true" use-java-context="true">
        <connection-url>jdbc:h2:mem:test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE</connection-url>
        <driver>h2</driver>
        <security>
            <user-name>sa</user-name>
            <password>sa</password>
        </security>
    </datasource>
{{- end }}
{{- $wildfly_datasources := list }}{{/* Convertion part. For p6spy/opentracing. Doesn't render anything */}}
{{- range .Values.wildfly_datasources }}
    {{- $xa := .xa | default false }}
    {{- $rm := .rm | default false }}
    {{- $url := .url }}
    {{- $driver := .driver }}

    {{- if .opentracing }}
        {{- if not (contains "p6spy" $url) }}
            {{- $driver = "opentracing" }}
            {{- $url = .url | replace "jdbc:" "jdbc:tracing:" }}
            {{- $url = .url | replace "jdbc:tracing:p6spy" "jdbc:p6spy:tracing" }}
        {{- end }}
    {{- end }}

    {{- if .p6spy }}
        {{- if .opentracing }}
            {{- $url = $url | replace "jdbc:tracing:" "jdbc:" }}
            {{- $driver = .driver }}
        {{- end }}
    {{- end }}

    {{- $convertedds := deepCopy . }}
    {{- $_ := set $convertedds "xa" $xa }}
    {{- $_ := set $convertedds "rm" $rm }}
    {{- $_ := set $convertedds "url" $url }}
    {{- $_ := set $convertedds "driver" $driver }}
    {{- $wildfly_datasources = append $wildfly_datasources $convertedds }}

    {{- if .p6spy }}
        {{- $p6spyds := deepCopy . }}
        {{- $_ := set $p6spyds "driver" "p6spy" }}
        {{- $_ := set $p6spyds "url"  ($p6spyds.url | replace "jdbc:" "jdbc:p6spy:") }}
        {{- $_ := set $p6spyds "p6spy" false }}
        {{- $_ := set $p6spyds "jndi" (list $p6spyds.jndi  "SPY" | join "_") }}
        {{- $_ := set $p6spyds.pool "name" (list $p6spyds.pool.name "SPY" | join "_") }}
        {{- $wildfly_datasources = append $wildfly_datasources $p6spyds }}
    {{- end }}

{{- end }}
{{- range $wildfly_datasources }}{{/* Rendering part */}}
    {{- if .xa }}
    <xa-datasource jndi-name="{{ .jndi }}" pool-name="{{ .pool.name }}" enabled="true" use-java-context="true" statistics-enabled="true"{{ if eq .driver "p6spy" }} spy="true"{{ end }}>
        <xa-datasource-property name="URL">{{ .url }}</xa-datasource-property>
        <recovery no-recovery="{{ .no_recovery | default false }}"/>
    {{- else }}
    <datasource jta="true" jndi-name="{{ .jndi }}" pool-name="{{ .pool.name }}" enabled="true" use-java-context="true" statistics-enabled="true"{{ if eq .driver "p6spy" }} spy="true"{{ end }}>
        <connection-url>{{ .url }}</connection-url>
    {{- end }}
    {{- if hasKey . "transaction_isolation" }}
        <transaction-isolation>{{ .transaction_isolation }}</transaction-isolation>
    {{- end }}
        <driver>{{ .driver }}</driver>
    {{- if .xa }}
        <xa-pool>
    {{- else }}
        <pool>
    {{- end }}
            <max-pool-size>{{ .pool.max | default 5 }}</max-pool-size>
            <prefill>true</prefill>
    {{- if hasKey . "decrementer_watermark" }}
            <decrementer class-name="org.jboss.jca.core.connectionmanager.pool.capacity.WatermarkDecrementer">
                <config-property name="watermark">{{ .decrementer_watermark }}</config-property>
            </decrementer>
    {{- end }}
    {{- if hasKey . "is_same_rm_override" }}
            <is-same-rm-override>{{ .is_same_rm_override }}</is-same-rm-override>
    {{- end }}
    {{- if .xa }}
        {{- if hasKey . "no_tx_separate_pools" }}
            <no-tx-separate-pools>{{ .no_tx_separate_pools }}</no-tx-separate-pools>
        {{- end }}
        </xa-pool>
    {{- else }}
        </pool>
    {{- end }}
        <security>
            <user-name>{{ .user }}</user-name>
            <password>{{ .password }}</password>
        </security>
    {{- if or (or (eq .driver "oracle") (eq .driver "postgresql")) (eq .driver "postgresqlro") }} 
        <validation>
        {{- if hasKey . "background_validation_time" }}
            <validate-on-match>false</validate-on-match>
            <background-validation>true</background-validation>
            <background-validation-millis>{{ .background_validation_time }}</background-validation-millis>
        {{- else }}
            {{- if .validate_on_match }}
            <validate-on-match>true</validate-on-match>
            <background-validation>false</background-validation>
            {{- end }}
        {{- end }}
        {{- if hasKey . "valid_connection_checker" }}
            <valid-connection-checker class-name="{{ .valid_connection_checker }}"/>
        {{- else }}
            {{- if eq .driver "oracle" }}
            <check-valid-connection-sql>SELECT 1 FROM DUAL</check-valid-connection-sql>
            {{- else }}
            <check-valid-connection-sql>SELECT 1</check-valid-connection-sql>
            {{- end }}
        {{- end }}
        {{- if hasKey . "stale_connection_checker" }}
            <stale-connection-checker class-name="{{ .stale_connection_checker }}"/>
        {{- end }}
        {{- if hasKey . "exception_sorter" }}
            <stale-connection-checker class-name="{{ .exception_sorter }}"/>
        {{- end }}
        </validation>
        {{- if hasKey . "idle_timeout_minutes" }}
        <timeout>
            <idle-timeout-minutes>{{ .idle_timeout_minutes }}</idle-timeout-minutes>
        </timeout>
        {{- else }}
        <timeout>
            <idle-timeout-minutes>1</idle-timeout-minutes>
        </timeout>
        {{- end }}
    {{-  end }}
    {{- if eq .driver "mysql" }}
        <timeout>
            <idle-timeout-minutes>3</idle-timeout-minutes>
        </timeout>
        {{- if hasKey . "validate_mysql" }}
        {{- if eq (.validate_mysql | toString ) "true" }}
            <validation>
                <check-valid-connection-sql>select 1</check-valid-connection-sql>
                <validate-on-match>false</validate-on-match>
                <background-validation>true</background-validation>
                <background-validation-millis>{{ .background_validation_time }}</background-validation-millis>
            </validation>
        {{- end }}
        {{- end }}
        {{- if hasKey . "validate_mysql_on_match" }}
        {{- if eq (.validate_mysql_on_match | toString ) "true" }}
            <validation>
                <check-valid-connection-sql>select 1</check-valid-connection-sql>
                <validate-on-match>true</validate-on-match>
            </validation>
        {{- end }}
        {{- end }}
    {{- end }}
    {{- if .xa }}
    </xa-datasource>
    {{- else }}
    </datasource>
    {{- end }}
{{- end }}
    <drivers>
        <driver name="postgresql" module="org.postgresql.jdbc">
            <xa-datasource-class>org.postgresql.xa.PGXADataSource</xa-datasource-class>
        </driver>
        <driver name="oracle" module="com.oracle">
            <xa-datasource-class>oracle.jdbc.xa.client.OracleXADataSource</xa-datasource-class>
        </driver>
        <driver name="h2" module="com.h2database.h2">
            <xa-datasource-class>org.h2.jdbcx.JdbcDataSource</xa-datasource-class>
        </driver>
        <driver name="mysql" module="com.mysql">
            <driver-class>com.mysql.jdbc.Driver</driver-class>
            <xa-datasource-class>com.mysql.jdbc.jdbc2.optional.MysqlXADataSource</xa-datasource-class>
        </driver>
        {{- if .Values.wildfly_postgresqlro }}
        <driver name="postgresqlro" module="ru.lanit.jdbc.postgresqlro:main"/>
        {{- end }}
        {{- if .Values.wildfly_opentracing }}
        <driver name="opentracing" module="io.opentracing.contrib.opentracing-jdbc">
            <driver-class>io.opentracing.contrib.jdbc.TracingDriver</driver-class>
        </driver>
        {{- end }}
        {{- if .Values.wildfly_p6spy }}
        <driver name="p6spy" module="com.p6spy">
             <driver-class>com.p6spy.engine.spy.P6SpyDriver</driver-class>
             <xa-datasource-class>com.p6spy.engine.spy.P6DataSource</xa-datasource-class>
        </driver>
        {{- end }}
    </drivers>
</datasources>
{{- end }}
