{{- define "wildfly-config.main" -}}
<?xml version='1.0' encoding='UTF-8'?>
    <server xmlns="urn:jboss:domain:15.0">
        <extensions>
            <extension module="org.jboss.as.clustering.infinispan"/>
            <extension module="org.jboss.as.connector"/>
            <extension module="org.jboss.as.deployment-scanner"/>
            <extension module="org.jboss.as.ee"/>
            <extension module="org.jboss.as.ejb3"/>
            <extension module="org.jboss.as.jaxrs"/>
            <extension module="org.jboss.as.jdr"/>
            <extension module="org.jboss.as.jmx"/>
            <extension module="org.jboss.as.jpa"/>
            <extension module="org.jboss.as.jsf"/>
            <extension module="org.jboss.as.jsr77"/>
            <extension module="org.jboss.as.logging"/>
            <extension module="org.jboss.as.mail"/>
            <extension module="org.jboss.as.naming"/>
            <extension module="org.jboss.as.pojo"/>
            <extension module="org.jboss.as.remoting"/>
            <extension module="org.jboss.as.sar"/>
            <extension module="org.jboss.as.security"/>
            <extension module="org.jboss.as.transactions"/>
            <extension module="org.jboss.as.webservices"/>
            <extension module="org.jboss.as.weld"/>
            <extension module="org.wildfly.extension.batch.jberet"/>
            <extension module="org.wildfly.extension.bean-validation"/>
            <extension module="org.wildfly.extension.clustering.web"/>
            <extension module="org.wildfly.extension.core-management"/>
            <extension module="org.wildfly.extension.discovery"/>
            <extension module="org.wildfly.extension.ee-security"/>
            <extension module="org.wildfly.extension.elytron"/>
            <extension module="org.wildfly.extension.health"/>
            <extension module="org.wildfly.extension.io"/>
            <extension module="org.wildfly.extension.messaging-activemq"/>
            <extension module="org.wildfly.extension.metrics"/>
            <extension module="org.wildfly.extension.microprofile.config-smallrye"/>
            <extension module="org.wildfly.extension.microprofile.jwt-smallrye"/>
            <extension module="org.wildfly.extension.microprofile.health-smallrye"/>
            <extension module="org.wildfly.extension.microprofile.metrics-smallrye"/>
            {{- if or .Values.wildfly_microprofile_opentracing_smallrye (not (hasKey .Values "wildfly_microprofile_opentracing_smallrye")) }}
            <extension module="org.wildfly.extension.microprofile.opentracing-smallrye"/>
            {{- end }}
            <extension module="org.wildfly.extension.request-controller"/>
            <extension module="org.wildfly.extension.security.manager"/>
            <extension module="org.wildfly.extension.undertow"/>
            {{- if .Values.wildfly_atomic_transactions }}
            <extension module="org.jboss.as.xts"/>
            {{- end }}
            {{- if .Values.wildfly_ha }}
            <extension module="org.jboss.as.clustering.jgroups"/>
            <extension module="org.jboss.as.modcluster"/>
            <extension module="org.wildfly.extension.clustering.singleton"/>
            {{- end }}

    <!--        <extension module="org.wildfly.iiop-openjdk"/> -->
        </extensions>
        {{- include "wildfly-config.system-properties" . | indent 8 }}
        <management>
            <security-realms>
                <security-realm name="ManagementRealm">
                    <authentication>
                        <local default-user="$local" skip-group-loading="true"/>
                        <properties path="mgmt-users.properties" relative-to="jboss.server.config.dir"/>
                    </authentication>
                    <authorization map-groups-to-roles="false">
                        <properties path="mgmt-groups.properties" relative-to="jboss.server.config.dir"/>
                    </authorization>
                </security-realm>
                <security-realm name="ApplicationRealm">
                    <server-identities>
                        <ssl>
                            <keystore path="application.keystore" relative-to="jboss.server.config.dir" keystore-password="password" alias="server" key-password="password" generate-self-signed-certificate-host="localhost"/>
                        </ssl>
                    </server-identities>
                    <authentication>
                        <local default-user="$local" allowed-users="*" skip-group-loading="true"/>
                        <properties path="/etc/wildfly/application-users.properties"/>
                    </authentication>
                    <authorization>
                        <properties path="/etc/wildfly/application-roles.properties"/>
                    </authorization>
                </security-realm>
                {{- include "wildfly-config.security-realms" . | indent 16 }}
            </security-realms>
            <audit-log>
                <formatters>
                    <json-formatter name="json-formatter"/>
                </formatters>
                <handlers>
                    <size-rotating-file-handler name="file" formatter="json-formatter" path="audit-log.log" relative-to="jboss.server.data.dir"/>
                </handlers>
                <logger log-boot="false" log-read-only="false" enabled="{{ .Values.wildfly_audit_status | default "false" }}">
                    <handlers>
                        <handler name="file"/>
                    </handlers>
                </logger>
            </audit-log>
            <management-interfaces>
                <http-interface security-realm="ManagementRealm">
                    <http-upgrade enabled="true"/>
                    <socket-binding http="management-http"/>
                </http-interface>
            </management-interfaces>
            {{- if .Values.wildfly_rbac }}
            <access-control provider="rbac">
                <role-mapping>
                    {{- range list "SuperUser" "Administrator" "Monitor" "Operator" "Maintainer" "Deployer" "Auditor" }}
                    {{- $role := . }}
                    <role name="{{ $role }}">
                        <include>
                            {{ if eq $role "SuperUser" }}<user name="$local"/>{{ end }}
                            <user name="admin" />
                            {{- range $.Values.wildfly_roles.role }}
                            <user name="{{ . }}" />
                            {{- end }}
                        </include>
                    </role>
                    {{- end }}
                </role-mapping>
            </access-control>
            {{- else }}
            <access-control provider="simple">
                <role-mapping>
                    <role name="SuperUser">
                        <include>
                            <user name="$local"/>
                        </include>
                    </role>
                </role-mapping>
            </access-control>
            {{- end }}
        </management>
        <profile>
            <subsystem xmlns="urn:jboss:domain:logging:8.0">
                <console-handler name="CONSOLE" >
                    <formatter>
    <!--                 <pattern-formatter pattern="%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%E%n"/> -->
                         {{- if eq (.Values.wildfly_system_logging | default "") "lkp" }}
                         <named-formatter name="LKP-FORMATTER" />
                         {{- else if .Values.wildfly_async_logging_enabled }}
                         <named-formatter name="SIMPLE-FORMATTER" />
                         {{- else  }}
                         <named-formatter name="EIS-FORMATTER" />
                         {{- end }}
                    </formatter>
                </console-handler>
                {{- if .Values.wildfly_async_logging_enabled }}
                <custom-handler name="ASYNC_CUSTOM_HANDLER" class="ru.lanit.eis.logging.AsyncHandler" module="ru.lanit.eis.logging">
                    <level name="DEBUG"/>
                    <formatter>
                        {{- if eq (.Values.wildfly_system_logging | default "") "lkp" }}
                        <named-formatter name="LKP-FORMATTER" />
                        {{- else }}
                        <named-formatter name="EIS-FORMATTER"/>
                        {{- end }}
                    </formatter>
                    <properties>
                        <property name="constructorProperties" value="queueLength"/>
                        <property name="queueLength" value="512"/>
                        <property name="handler" value="CONSOLE"/>
                        <property name="overflowAction" value="BLOCK"/>
                    </properties>
                </custom-handler>
                {{ end }}

                {{- include "wildfly-config.logging" . | indent 16 }}
                <logger category="com.arjuna">
                    <level name="WARN"/>
                </logger>
                <logger category="org.jboss.as.config">
                    <level name="DEBUG"/>
                </logger>
                <logger category="sun.rmi">
                    <level name="WARN"/>
                </logger>
                {{- $ru_lanit_logging_user_set := false }}
                {{- range .Values.wildfly_logging }}
                    {{- if eq .class "ru.lanit" }}
                        {{- $ru_lanit_logging_user_set = true }}
                    {{- end }}
                {{- end }}
                {{- if not $ru_lanit_logging_user_set }}
                <logger category="ru.lanit">
                    <level name="INFO"/>
                </logger>
                {{- end }}
                <logger category="ru.lanit.monitoring.util.config">
                    <level name="ERROR"/>
                </logger>
                <logger category="ru.lanit.monitoring.config">
                    <level name="ERROR"/>
                </logger>
                <root-logger>
                    <level name="{{ .Values.wildfly_root_logger_level | default "ERROR" }}"/>
                    <handlers>
                        {{- if .Values.wildfly_async_logging_enabled }}
                        <handler name="ASYNC_CUSTOM_HANDLER"/>
                        {{- else }}
                        <handler name="CONSOLE"/>
                        {{- end }}
                    </handlers>
                </root-logger>
                <formatter name="PATTERN">
                    <pattern-formatter pattern="%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n"/>
                </formatter>
                <formatter name="COLOR-PATTERN">
                    <pattern-formatter pattern="%K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n"/>
                </formatter>
                {{- if .Values.wildfly_async_logging_enabled }}
                <formatter name="SIMPLE-FORMATTER">
                    <pattern-formatter pattern="%s"/>
                </formatter>
                {{- end }}
                {{- if eq (.Values.wildfly_system_logging | default "") "lkp" }}
                <formatter name="LKP-FORMATTER">
                    <custom-formatter module="ru.lanit.lkp.logging" class="ru.lant.lkp.logging.CustomPatternFormatter">
                {{- else }}
                <formatter name="EIS-FORMATTER">
                    <custom-formatter module="ru.lanit.eis.logging" class="ru.lanit.eis.logging.CustomPatternFormatter">
                {{- end }}
                        <properties>
                            <property name="pattern" value="%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p (%t) [%c{1}] [#m] #r#d %s%e%n"/>
                        </properties>
                    </custom-formatter>
                </formatter>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:batch-jberet:2.0">
                <default-job-repository name="in-memory"/>
                <default-thread-pool name="batch"/>
                <job-repository name="in-memory">
                    <in-memory/>
                </job-repository>
                <thread-pool name="batch">
                    <max-threads count="{{ .Values.wildfly_batch_jberet_max_threads | default 10 }}"/>
                    <keepalive-time time="30" unit="seconds"/>
                </thread-pool>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:bean-validation:1.0"/>
            <subsystem xmlns="urn:jboss:domain:core-management:1.0"/>
            <subsystem xmlns="urn:jboss:domain:datasources:6.0">
            {{- include "wildfly-config.datasources" . | indent 12 }}
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:deployment-scanner:2.0">
            {{- $wildfly_blocking_timeout := 1200 }}
            {{- range .Values.wildfly_system_properties }}
            {{- if eq .name "jboss.as.management.blocking.timeout" }}
            {{- $wildfly_blocking_timeout := .value }}
            {{- end }}
            {{- end }}
                <deployment-scanner path="deployments" relative-to="jboss.server.base.dir" scan-interval="5000" runtime-failure-causes-rollback="${jboss.deployment.scanner.rollback.on.failure:false}" deployment-timeout="{{ $wildfly_blocking_timeout }}"/>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:discovery:1.0"/>
            <subsystem xmlns="urn:jboss:domain:distributable-web:2.0" default-session-management="default" default-single-sign-on-management="default">
                <infinispan-session-management name="default" cache-container="web" granularity="SESSION">
                    <local-affinity/>
                </infinispan-session-management>
                <infinispan-single-sign-on-management name="default" cache-container="web" cache="sso"/>
                <local-routing/>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:ee:5.0">
                {{- if .Values.wildfly_annotation_property_replacement }}
                <annotation-property-replacement>true</annotation-property-replacement>
                {{- end }}
                <global-modules>
                    {{- if eq (.Values.wildfly_system_logging | default "") "lkp" }}
                    <module name="ru.lanit.lkp.logging" slot="main" services="true"/>
                    {{- else }}
                    <module name="ru.lanit.eis.logging" slot="main" services="true"/>
                    {{- end }}
                    {{- if .Values.wildfly_system_logging_lkp_and_eis }}
                    <module name="ru.lanit.lkp.logging" slot="main" services="true"/>
                    {{- end }}
                    {{- range .Values.wildfly_sharedlibs }}
                    {{- if .global }}
                    <module name="{{ .name }}" slot="main"/>
                    {{- end }}
                    {{- end }}
                </global-modules>
                <spec-descriptor-property-replacement>false</spec-descriptor-property-replacement>
                {{- include "wildfly-config.concurrent" . | indent 16 }}
                <default-bindings context-service="java:jboss/ee/concurrency/context/default" datasource="{{ .Values.wildfly_concurrency_datasource | default "java:jboss/datasources/ExampleDS" }}" managed-executor-service="java:jboss/ee/concurrency/executor/default" managed-scheduled-executor-service="java:jboss/ee/concurrency/scheduler/default" managed-thread-factory="java:jboss/ee/concurrency/factory/default"/>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:ee-security:1.0"/>
            <subsystem xmlns="urn:jboss:domain:ejb3:8.0">
                <session-bean>
                    <stateless>
                        <bean-instance-pool-ref pool-name="slsb-strict-max-pool"/>
                    </stateless>
                    <stateful default-access-timeout="{{ .Values.wildfly_stateful_default_access_timeout | default "5000" }}" cache-ref="{{ if .Values.wildfly_ha }}distributable{{ else }}simple{{ end }}" passivation-disabled-cache-ref="simple"/>
                    <singleton default-access-timeout="{{ .Values.wildfly_singleton_default_access_timeout | default "5000" }}"/>

                </session-bean>
                <mdb>
                    <resource-adapter-ref resource-adapter-name="activemq-rar"/>
                    <bean-instance-pool-ref pool-name="mdb-strict-max-pool"/>
                </mdb>
                <pools>
                    <bean-instance-pools>
                        <strict-max-pool name="mdb-strict-max-pool" derive-size="from-cpu-count" instance-acquisition-timeout="5" instance-acquisition-timeout-unit="MINUTES"/>
                        <strict-max-pool name="slsb-strict-max-pool" max-pool-size="{{ .Values.slsb_strict_max_pool | default "200" }}" instance-acquisition-timeout="5" instance-acquisition-timeout-unit="MINUTES"/>
                        {{- range .Values.wildfly_strict_max_pools }}
                        <strict-max-pool name="{{ .name }}" max-pool-size="{{ .size }}" instance-acquisition-timeout="{{ .timeout_seconds }}" instance-acquisition-timeout-unit="SECONDS"/>
                        {{- end }}
                    </bean-instance-pools>
                </pools>
                <caches>
                    <cache name="simple"/>
                    <cache name="distributable" passivation-store-ref="infinispan" aliases="passivating clustered"/>
                </caches>
                <passivation-stores>
                    <passivation-store name="infinispan" cache-container="ejb" max-size="10000"/>
                </passivation-stores>
                <async thread-pool-name="default"/>
                <timer-service thread-pool-name="default" default-data-store="default-file-store">
                    <data-stores>
                        <file-data-store name="default-file-store" path="timer-service-data" relative-to="jboss.server.data.dir"/>
                    {{- range .Values.wildfly_timer_service_database_ds }}
                    <database-data-store name="{{ .name }}" datasource-jndi-name="{{ .jndi }}" partition="{{ .partition }}"/>
                    {{- end }}
                    </data-stores>
                </timer-service>
                <remote cluster="ejb" connectors="http-remoting-connector" thread-pool-name="default">
                    <channel-creation-options>
                        <option name="READ_TIMEOUT" value="${prop.remoting-connector.read.timeout:20}" type="xnio"/>
                        <option name="MAX_OUTBOUND_MESSAGES" value="1234" type="remoting"/>
                    </channel-creation-options>
                </remote>
                <thread-pools>
                    <thread-pool name="default">
                        <max-threads count="10"/>
                        <keepalive-time time="100" unit="milliseconds"/>
                    </thread-pool>
                </thread-pools>
    <!--            <iiop enable-by-default="false" use-qualified-name="false"/> -->
                <default-security-domain value="other"/>
                <default-missing-method-permissions-deny-access value="{{ .Values.wildfly_missing_methods_deny_access | default true }}"/>
                <statistics enabled="true"/>
                <log-system-exceptions value="true"/>
                {{- if .Values.wildfly_ejb3_client_interceptors }}
                <client-interceptors>
                    {{- range .Values.wildfly_ejb3_client_interceptors }}
                    <interceptor module="{{ .module }}" class="{{ .class }}"/>
                    {{- end }}
                </client-interceptors>
                {{- end }}
            </subsystem>
            <subsystem xmlns="urn:wildfly:elytron:12.0" final-providers="combined-providers" disallowed-providers="OracleUcrypto">
                <providers>
                    <aggregate-providers name="combined-providers">
                        <providers name="elytron"/>
                        <providers name="openssl"/>
                    </aggregate-providers>
                    <provider-loader name="elytron" module="org.wildfly.security.elytron"/>
                    <provider-loader name="openssl" module="org.wildfly.openssl"/>
                </providers>
                <audit-logging>
                    <file-audit-log name="local-audit" path="audit.log" relative-to="jboss.server.log.dir" format="JSON"/>
                </audit-logging>
                <security-domains>
                    <security-domain name="ApplicationDomain" default-realm="ApplicationRealm" permission-mapper="default-permission-mapper">
                        <realm name="ApplicationRealm" role-decoder="groups-to-roles"/>
                        <realm name="local"/>
                    </security-domain>
                    <security-domain name="ManagementDomain" default-realm="ManagementRealm" permission-mapper="default-permission-mapper">
                        <realm name="ManagementRealm" role-decoder="groups-to-roles"/>
                        <realm name="local" role-mapper="super-user-mapper"/>
                    </security-domain>
                </security-domains>
                <security-realms>
                    <identity-realm name="local" identity="$local"/>
                    <properties-realm name="ApplicationRealm">
                        <users-properties path="/etc/wildfly/application-users.properties" digest-realm-name="ApplicationRealm"/>
                        <groups-properties path="/etc/wildfly/application-roles.properties"/>
                    </properties-realm>
                    <properties-realm name="ManagementRealm">
                        <users-properties path="mgmt-users.properties" relative-to="jboss.server.config.dir" digest-realm-name="ManagementRealm"/>
                        <groups-properties path="mgmt-groups.properties" relative-to="jboss.server.config.dir"/>
                    </properties-realm>
                </security-realms>
                <mappers>
                    <simple-permission-mapper name="default-permission-mapper" mapping-mode="first">
                        <permission-mapping>
                            <principal name="anonymous"/>
                            <permission-set name="default-permissions"/>
                        </permission-mapping>
                        <permission-mapping match-all="true">
                            <permission-set name="login-permission"/>
                            <permission-set name="default-permissions"/>
                        </permission-mapping>
                    </simple-permission-mapper>
                    <constant-realm-mapper name="local" realm-name="local"/>
                    <simple-role-decoder name="groups-to-roles" attribute="groups"/>
                    <constant-role-mapper name="super-user-mapper">
                        <role name="SuperUser"/>
                    </constant-role-mapper>
                </mappers>
                <permission-sets>
                    <permission-set name="login-permission">
                        <permission class-name="org.wildfly.security.auth.permission.LoginPermission"/>
                    </permission-set>
                    <permission-set name="default-permissions">
                        <permission class-name="org.wildfly.extension.batch.jberet.deployment.BatchPermission" module="org.wildfly.extension.batch.jberet" target-name="*"/>
                        <permission class-name="org.wildfly.transaction.client.RemoteTransactionPermission" module="org.wildfly.transaction.client"/>
                        <permission class-name="org.jboss.ejb.client.RemoteEJBPermission" module="org.jboss.ejb-client"/>
                    </permission-set>
                </permission-sets>
                <http>
                    <http-authentication-factory name="management-http-authentication" security-domain="ManagementDomain" http-server-mechanism-factory="global">
                        <mechanism-configuration>
                            <mechanism mechanism-name="DIGEST">
                                <mechanism-realm realm-name="ManagementRealm"/>
                            </mechanism>
                        </mechanism-configuration>
                    </http-authentication-factory>
                    <provider-http-server-mechanism-factory name="global"/>
                </http>
                <sasl>
                    <sasl-authentication-factory name="application-sasl-authentication" sasl-server-factory="configured" security-domain="ApplicationDomain">
                        <mechanism-configuration>
                            <mechanism mechanism-name="JBOSS-LOCAL-USER" realm-mapper="local"/>
                            <mechanism mechanism-name="DIGEST-MD5">
                                <mechanism-realm realm-name="ApplicationRealm"/>
                            </mechanism>
                        </mechanism-configuration>
                    </sasl-authentication-factory>
                    <sasl-authentication-factory name="management-sasl-authentication" sasl-server-factory="configured" security-domain="ManagementDomain">
                        <mechanism-configuration>
                            <mechanism mechanism-name="JBOSS-LOCAL-USER" realm-mapper="local"/>
                            <mechanism mechanism-name="DIGEST-MD5">
                                <mechanism-realm realm-name="ManagementRealm"/>
                            </mechanism>
                        </mechanism-configuration>
                    </sasl-authentication-factory>
                    <configurable-sasl-server-factory name="configured" sasl-server-factory="elytron">
                        <properties>
                            <property name="wildfly.sasl.local-user.default-user" value="$local"/>
                        </properties>
                    </configurable-sasl-server-factory>
                    <mechanism-provider-filtering-sasl-server-factory name="elytron" sasl-server-factory="global">
                        <filters>
                            <filter provider-name="WildFlyElytron"/>
                        </filters>
                    </mechanism-provider-filtering-sasl-server-factory>
                    <provider-sasl-server-factory name="global"/>
                </sasl>
            </subsystem>
    <!--        <subsystem xmlns="urn:jboss:domain:iiop-openjdk:2.1">
                <orb socket-binding="iiop"/>
                <initializers security="identity" transactions="spec"/>
                <security server-requires-ssl="false" client-requires-ssl="false"/>
            </subsystem> -->
            <subsystem xmlns="urn:jboss:domain:infinispan:11.0">
            {{- if .Values.wildfly_ha }}
                <cache-container name="server" aliases="singleton cluster" default-cache="default" module="org.wildfly.clustering.server">
                    <transport lock-timeout="60000"/>
                    <replicated-cache name="default">
                        <transaction mode="BATCH"/>
                    </replicated-cache>
                </cache-container>
                <cache-container name="web" default-cache="dist" module="org.wildfly.clustering.web.infinispan">
                    <transport lock-timeout="60000"/>
                    <distributed-cache name="dist">
                        <locking isolation="READ_COMMITTED"/>
                        <transaction mode="BATCH"/>
                        <file-store/>
                    </distributed-cache>
                </cache-container>
                <cache-container name="ejb" aliases="sfsb" default-cache="dist" module="org.wildfly.clustering.ejb.infinispan">
                    <transport lock-timeout="60000"/>
                    <distributed-cache name="dist">
                        <locking isolation="READ_COMMITTED"/>
                        <transaction mode="BATCH"/>
                        <file-store/>
                    </distributed-cache>
                </cache-container>
                <cache-container name="hibernate" module="org.infinispan.hibernate-cache">
                    <transport lock-timeout="60000"/>
                    <local-cache name="local-query">
                        <heap-memory size="10000"/>
                        <expiration max-idle="100000"/>
                    </local-cache>
                    <invalidation-cache name="entity">
                        <transaction mode="NON_XA"/>
                        <heap-memory size="10000"/>
                        <expiration max-idle="100000"/>
                    </invalidation-cache>
                    <replicated-cache name="timestamps"/>
                </cache-container>
            {{- else }}
                <cache-container name="server" default-cache="default" module="org.wildfly.clustering.server">
                    <local-cache name="default">
                        <transaction mode="BATCH"/>
                    </local-cache>
                </cache-container>
                <cache-container name="web" default-cache="passivation" module="org.wildfly.clustering.web.infinispan">
                    <local-cache name="passivation">
                        <locking isolation="REPEATABLE_READ"/>
                        <transaction mode="BATCH"/>
                        <file-store passivation="true" purge="false"/>
                    </local-cache>
                    <local-cache name="sso"/>
                </cache-container>
                <cache-container name="ejb" aliases="sfsb" default-cache="passivation" module="org.wildfly.clustering.ejb.infinispan">
                    <local-cache name="passivation">
                        <locking isolation="REPEATABLE_READ"/>
                        <transaction mode="BATCH"/>
                        <file-store passivation="true" purge="false"/>
                    </local-cache>
                </cache-container>
                <cache-container name="server" default-cache="default" module="org.wildfly.clustering.server">
                    <local-cache name="default"/>
                </cache-container>
                <cache-container name="hibernate" module="org.infinispan.hibernate-cache">
                    <local-cache name="entity">
                        <transaction mode="NON_XA"/>
                        <heap-memory size="10000"/>
                        <expiration max-idle="100000"/>
                    </local-cache>
                    <local-cache name="local-query">
                        <heap-memory size="10000"/>
                        <expiration max-idle="100000"/>
                    </local-cache>
                    <local-cache name="timestamps"/>
                </cache-container>
            {{- end }}
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:io:3.0">
                <worker name="default" {{ if .Values.wildfly_io_threads }}io-threads="{{ .Values.wildfly_io_threads }}"{{ end }} {{ if .Values.wildfly_task_core_threads }}task-core-threads="{{ .Values.wildfly_task_core_threads }}"{{ end }} {{ if .Values.wildfly_task_max_threads }}task-max-threads="{{ .Values.wildfly_task_max_threads }}"{{ end }} {{ if .Values.wildfly_task_keepalive }}task-keepalive="{{ .Values.wildfly_task_keepalive }}"{{ end }}/>
                {{- range .Values.wildfly_additional_workers }}
                <worker name="{{ .name }}" {{ if .io_threads }}io-threads="{{ .io_threads }}"{{ end }} {{ if .task_core_threads }}task-core-threads="{{ .task_core_threads }}"{{ end }} {{ if .task_max_threads }}task-max-threads="{{ .task_max_threads }}"{{ end }} {{ if .task_keepalive }}task-keepalive="{{ .task_keepalive }}"{{ end }}/>
                {{- end }}
                <buffer-pool name="default"/>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:jaxrs:2.0"/>
            <subsystem xmlns="urn:jboss:domain:jca:5.0">
                <archive-validation enabled="true" fail-on-error="true" fail-on-warn="false"/>
                <bean-validation enabled="true"/>
                <default-workmanager>
                    <short-running-threads>
                        <core-threads count="50"/>
                        <queue-length count="50"/>
                        <max-threads count="50"/>
                        <keepalive-time time="10" unit="seconds"/>
                    </short-running-threads>
                    <long-running-threads>
                        <core-threads count="50"/>
                        <queue-length count="50"/>
                        <max-threads count="50"/>
                        <keepalive-time time="10" unit="seconds"/>
                    </long-running-threads>
                </default-workmanager>
                <cached-connection-manager/>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:jdr:1.0"/>
            {{- if .Values.wildfly_ha }}
            <subsystem xmlns="urn:jboss:domain:jgroups:6.0">
                <channels default="ee">
                    <channel name="ee" stack="udp" cluster="ejb"/>
                </channels>
                <stacks>
                    <stack name="udp">
                        <transport type="UDP" socket-binding="jgroups-udp"/>
                        <protocol type="PING"/>
                        <protocol type="MERGE3"/>
                        <protocol type="FD_SOCK"/>
                        <protocol type="FD_ALL"/>
                        <protocol type="VERIFY_SUSPECT"/>
                        <protocol type="pbcast.NAKACK2"/>
                        <protocol type="UNICAST3"/>
                        <protocol type="pbcast.STABLE"/>
                        <protocol type="pbcast.GMS"/>
                        <protocol type="UFC"/>
                        <protocol type="MFC"/>
                        <protocol type="FRAG3"/>
                    </stack>
                    <stack name="tcp">
                        <transport type="TCP" socket-binding="jgroups-tcp"/>
                        <socket-protocol type="MPING" socket-binding="jgroups-mping"/>
                        <protocol type="MERGE3"/>
                        <protocol type="FD_SOCK"/>
                        <protocol type="FD_ALL"/>
                        <protocol type="VERIFY_SUSPECT"/>
                        <protocol type="pbcast.NAKACK2"/>
                        <protocol type="UNICAST3"/>
                        <protocol type="pbcast.STABLE"/>
                        <protocol type="pbcast.GMS"/>
                        <protocol type="MFC"/>
                        <protocol type="FRAG3"/>
                    </stack>
                </stacks>
            </subsystem>
            {{- end }}
            <subsystem xmlns="urn:jboss:domain:jmx:1.3">
                <expose-resolved-model/>
                <expose-expression-model/>
                <remoting-connector/>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:jpa:1.1">
                <jpa default-datasource="" default-extended-persistence-inheritance="DEEP"/>
            </subsystem>
            {{- if or .Values.wildfly_jsf_enabled (not (hasKey .Values "wildfly_jsf_enabled")) }}
            <subsystem xmlns="urn:jboss:domain:jsf:1.1"{{ if .Values.wildfly_jsf_attr_mojarra_1_2_15 }} default-jsf-impl-slot="mojarra-1.2_15"{{ end }}/>
            {{- end }}
            <subsystem xmlns="urn:jboss:domain:jsr77:1.0"/>
            <subsystem xmlns="urn:jboss:domain:mail:4.0">
            {{- include "wildfly-config.mail" . | indent 12 }}
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:messaging-activemq:12.0">
                <server name="default">
                    <security-setting name="#">
                        <role name="guest" send="true" consume="true" create-non-durable-queue="true" delete-non-durable-queue="true"/>
                    </security-setting>
                    <address-setting name="#" dead-letter-address="jms.queue.DLQ" expiry-address="jms.queue.ExpiryQueue" max-size-bytes="10485760" page-size-bytes="2097152" message-counter-history-day-limit="10"/>
                    <http-connector name="http-connector" socket-binding="http" endpoint="http-acceptor"/>
                    <http-connector name="http-connector-throughput" socket-binding="http" endpoint="http-acceptor-throughput">
                        <param name="batch-delay" value="50"/>
                    </http-connector>
                    <in-vm-connector name="in-vm" server-id="0">
                        <param name="buffer-pooling" value="false"/>
                    </in-vm-connector>
                    <http-acceptor name="http-acceptor" http-listener="default"/>
                    <http-acceptor name="http-acceptor-throughput" http-listener="default">
                        <param name="batch-delay" value="50"/>
                        <param name="direct-deliver" value="false"/>
                    </http-acceptor>
                    <in-vm-acceptor name="in-vm" server-id="0">
                        <param name="buffer-pooling" value="false"/>
                    </in-vm-acceptor>
                    <!-- No integrated AMQ resources
                    <jms-queue name="ExpiryQueue" entries="java:/jms/queue/ExpiryQueue"/>
                    <jms-queue name="DLQ" entries="java:/jms/queue/DLQ"/>
                    <connection-factory name="InVmConnectionFactory" entries="java:/ConnectionFactory" connectors="in-vm"/>
                    <connection-factory name="RemoteConnectionFactory" entries="java:jboss/exported/jms/RemoteConnectionFactory" connectors="http-connector"/>
                    <pooled-connection-factory name="activemq-ra" entries="java:/JmsXA java:jboss/DefaultJMSConnectionFactory" connectors="in-vm" transaction="xa"/>
                    -->
                </server>
            </subsystem>
            <subsystem xmlns="urn:wildfly:microprofile-config-smallrye:1.0"/>
            <subsystem xmlns="urn:wildfly:metrics:1.0" security-enabled="false" exposed-subsystems="*" prefix="${wildfly.metrics.prefix:wildfly}"/>
            <subsystem xmlns="urn:wildfly:health:1.0" security-enabled="false"/>
            {{- if or .Values.wildfly_microprofile_health_smallrye }}
            <subsystem xmlns="urn:wildfly:microprofile-health-smallrye:2.0" security-enabled="false"/>
            {{- end }}
            {{- if or .Values.wildfly_microprofile_opentracing_smallrye (not (hasKey .Values "wildfly_microprofile_opentracing_smallrye")) }}
            <subsystem xmlns="urn:wildfly:microprofile-opentracing-smallrye:3.0">
               {{- if .Values.wildfly_microprofile_opentracing_jaeger }}
                <jaeger-tracer name="jaeger">
                    <sampler-configuration sampler-type="{{ .Values.wildfly_microprofile_opentracing_jaeger.type | default "const" }}" sampler-param="{{ .Values.wildfly_microprofile_opentracing_jaeger.param | default "1.0" }}"/>
                </jaeger-tracer>
               {{- end }}
            </subsystem>
            {{- end }}
            {{- if or .Values.wildfly_microprofile_metrics (not (hasKey .Values "wildfly_microprofile_metrics")) }}
            <subsystem xmlns="urn:wildfly:microprofile-metrics-smallrye:2.0" security-enabled="false" exposed-subsystems="*" prefix="${wildfly.metrics.prefix:wildfly}"/>
            {{- end }}
            {{- if .Values.wildfly_ha }}
            <subsystem xmlns="urn:jboss:domain:modcluster:4.0">
                 <proxy name="default" advertise-socket="modcluster" listener="ajp">
                     <dynamic-load-provider>
                         <load-metric type="cpu"/>
                     </dynamic-load-provider>
                 </proxy>
            </subsystem>
            {{- end }}
            <subsystem xmlns="urn:jboss:domain:naming:2.0">
                {{- include "wildfly-config.naming" . | indent 16 }}
                <remote-naming/>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:pojo:1.0"/>
            <subsystem xmlns="urn:jboss:domain:remoting:4.0">
                <http-connector name="http-remoting-connector" connector-ref="default"/>
                {{- include "wildfly-config.outbound-connections" . | indent 16 }}
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:request-controller:1.0"/>
            <subsystem xmlns="urn:jboss:domain:resource-adapters:6.0">
                <resource-adapters>
                    {{- include "wildfly-config.amq" . | indent 20 }}
                    {{- include "wildfly-config.ra" . | indent 20 }}
                </resource-adapters>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:sar:1.0"/>
            <subsystem xmlns="urn:jboss:domain:security:2.0">
                <security-domains>
                    <security-domain name="other" cache-type="default">
                        <authentication>
                            <login-module code="Remoting" flag="optional">
                                <module-option name="password-stacking" value="useFirstPass"/>
                            </login-module>
                            <login-module code="RealmDirect" flag="required">
                                <module-option name="password-stacking" value="useFirstPass"/>
                            </login-module>
                        </authentication>
                    </security-domain>
                    <security-domain name="jboss-web-policy" cache-type="default">
                        <authorization>
                            <policy-module code="Delegating" flag="required"/>
                        </authorization>
                    </security-domain>
                    <security-domain name="jboss-ejb-policy" cache-type="default">
                        <authorization>
                            <policy-module code="Delegating" flag="required"/>
                        </authorization>
                    </security-domain>
                    <security-domain name="jaspitest" cache-type="default">
                        <authentication-jaspi>
                            <login-module-stack name="dummy">
                                <login-module code="Dummy" flag="optional"/>
                            </login-module-stack>
                            <auth-module code="Dummy"/>
                        </authentication-jaspi>
                    </security-domain>
                    <!-- {% include "security-domain-app.xml.j2" ignore missing %} -->
                </security-domains>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:security-manager:1.0">
                <deployment-permissions>
                    <maximum-set>
                        <permission class="java.security.AllPermission"/>
                    </maximum-set>
                </deployment-permissions>
            </subsystem>
            {{- if .Values.wildfly_ha }}
            <subsystem xmlns="urn:jboss:domain:singleton:1.0">
                <singleton-policies default="default">
                    <singleton-policy name="default" cache-container="server">
                        <simple-election-policy/>
                    </singleton-policy>
                </singleton-policies>
            </subsystem>
            {{- end }}
            <subsystem xmlns="urn:jboss:domain:transactions:5.0">
                <core-environment node-identifier="${jboss.tx.node.id:1}">
                    <process-id>
                        <uuid/>
                    </process-id>
                </core-environment>
                <recovery-environment socket-binding="txn-recovery-environment" status-socket-binding="txn-status-manager"/>
                <coordinator-environment statistics-enabled="true" default-timeout="{{ .Values.wildfly_tm_default_timeout | default 1200 }}"/>
                <object-store path="tx-object-store" relative-to="jboss.server.data.dir"/>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:undertow:11.0" statistics-enabled="{{ .Values.wildfly_undertow_statistics_enabled | default true }}" default-server="default-server" default-virtual-host="default-host" default-servlet-container="default" default-security-domain="other">
                <buffer-cache name="default"/>
                <server name="default-server">
                    <ajp-listener name="ajp" socket-binding="ajp" enabled="false"/>
                        <http-listener name="default" max-parameters="{{ .Values.wildfly_max_parameters | default 10000 }}" socket-binding="http" max-header-size="{{ .Values.wildfly_max_header_size | default 1048576 }}" max-post-size="{{ .Values.wildfly_max_post_size | default 104857600 }}" redirect-socket="https" enable-http2="true" allow-unescaped-characters-in-url="true"{{ if .Values.wildfly_set_encoding }} url-charset="{{ .Values.wildfly_set_encoding }}"{{ end }}{{ if .Values.wildfly_read_timeout }} read-timeout="{{ .Values.wildfly_read_timeout }}"{{ end }}{{ if .Values.wildfly_write_timeout }} write-timeout="{{ .Values.wildfly_write_timeout }}"{{ end }}/>
                        <https-listener name="https" socket-binding="https" max-header-size="{{ .Values.wildfly_https_max_header_size | default 1048576 }}" max-post-size="{{ .Values.wildfly_https_max_post_size  | default 104857600 }}" security-realm="ApplicationRealm" enable-http2="true" {{ if .Values.wildfly_set_encoding }} url-charset="{{ .Values.wildfly_set_encoding }}"{{ end }}{{ if .Values.wildfly_read_timeout }} read-timeout="{{ .Values.wildfly_read_timeout }}"{{ end }}{{ if .Values.wildfly_write_timeout }} write-timeout="{{ .Values.wildfly_write_timeout }}"{{ end }}/>
                    <host name="default-host" alias="localhost">
                        <location name="/" handler="welcome-content"/>
                        <filter-ref name="server-header"/>
                        <filter-ref name="x-powered-by-header"/>
                        <http-invoker />
                    </host>
                </server>
                <servlet-container name="default" {{ if .Values.wildfly_stacktrace_on_error }} stack-trace-on-error="{{ .Values.wildfly_stacktrace_on_error }}" {{ end }} default-session-timeout="{{ .Values.wildfly_session_timeout | default 31 }}"{{ if .Values.wildfly_set_encoding }} default-encoding="{{ .Values.wildfly_set_encoding }}"{{ end }}>
                    <jsp-config/>
                    <websockets/>
                </servlet-container>
                <handlers>
                    <file name="welcome-content" path="${jboss.home.dir}/welcome-content"/>
                </handlers>
                <filters>
                    <response-header name="server-header" header-name="Server" header-value="WildFly/11"/>
                    <response-header name="x-powered-by-header" header-name="X-Powered-By" header-value="Undertow/1"/>
                </filters>
            </subsystem>
            <subsystem xmlns="urn:jboss:domain:webservices:2.0">
                <wsdl-host>${jboss.bind.address:0.0.0.0}</wsdl-host>
                <endpoint-config name="Standard-Endpoint-Config"/>
                <endpoint-config name="Recording-Endpoint-Config">
                    <pre-handler-chain name="recording-handlers" protocol-bindings="##SOAP11_HTTP ##SOAP11_HTTP_MTOM ##SOAP12_HTTP ##SOAP12_HTTP_MTOM">
                        <handler name="RecordingHandler" class="org.jboss.ws.common.invocation.RecordingServerHandler"/>
                    </pre-handler-chain>
                </endpoint-config>
                <endpoint-config name="LKP-Endpoint-Config">
                    <pre-handler-chain name="custom-endpoint-handlers">
                    <handler name="ServerRequestContextSOAPHandler" class="{{ .Values.wildfly_server_request_custom_handler | default "ru.lanit.lkp.ws.context.ServerRequestContextSOAPHandler" }}"/>
                    </pre-handler-chain>
                </endpoint-config>
                <client-config name="LKP-Client-Config">
                    {{- if .Values.wildfly_atomic_transactions }}
                    <post-handler-chain name="custom-client-handlers">
                    <handler name="ClientRequestContextSOAPHandler" class="{{ .Values.wildfly_client_request_custom_handler | default "ru.lanit.lkp.ws.context.ClientRequestContextSOAPHandler" }}"/>
                    </post-handler-chain>
                    {{- else }}
                    <pre-handler-chain name="custom-client-handlers">
                    <handler name="ClientRequestContextSOAPHandler" class="{{ .Values.wildfly_client_request_custom_handler | default "ru.lanit.lkp.ws.context.ClientRequestContextSOAPHandler" }}"/>
                    </pre-handler-chain>
                    {{- end }}
                    </client-config>
                <client-config name="Standard-Client-Config"/>
            </subsystem>
            {{- if .Values.wildfly_weld_require_bean_descriptor }}
            <subsystem xmlns="urn:jboss:domain:weld:4.0" require-bean-descriptor="true"/>
            {{- else }}
            <subsystem xmlns="urn:jboss:domain:weld:4.0"/>
            {{- end }}
            {{- if .Values.wildfly_atomic_transactions }}
            <subsystem xmlns="urn:jboss:domain:xts:2.0">
                <host name="default-host"/>
                <xts-environment url="http://${jboss.bind.address:0.0.0.0}:8080/ws-c11/ActivationService"/>
                <default-context-propagation enabled="true"/>
            </subsystem>
            {{- end }}
        </profile>
        <interfaces>
            <interface name="management">
                <inet-address value="${jboss.bind.address.management:0.0.0.0}"/>
            </interface>
            <interface name="public">
                <inet-address value="${jboss.bind.address:0.0.0.0}"/>
            </interface>
        </interfaces>
        <socket-binding-group name="standard-sockets" default-interface="public" port-offset="${jboss.socket.binding.port-offset:0}">
            <socket-binding name="management-http" interface="management" port="${jboss.management.http.port:9990}"/>
            <socket-binding name="management-https" interface="management" port="${jboss.management.https.port:9993}"/>
            <socket-binding name="ajp" port="${jboss.ajp.port:8009}"/>
            <socket-binding name="http" port="${jboss.http.port:{{ .Values.wildfly_http_port | default 8080 }}}"/>
            <socket-binding name="https" port="${jboss.https.port:8443}"/>
            <socket-binding name="txn-recovery-environment" port="4712"/>
            <socket-binding name="txn-status-manager" port="4713"/>
            {{- if .Values.wildfly_ha }}
            <socket-binding name="jgroups-mping" interface="public" multicast-address="${jboss.default.multicast.address:230.0.0.{{ .Values.wildfly_cluster_id | default 1 }}}" multicast-port="45700"/>
            <socket-binding name="jgroups-tcp" interface="public" port="7600"/>
            <socket-binding name="jgroups-udp" interface="public" port="55200" multicast-address="${jboss.default.multicast.address:230.0.0.{{ .Values.wildfly_cluster_id | default 1 }}}" multicast-port="45688"/>
            <socket-binding name="modcluster" multicast-address="${jboss.modcluster.multicast.address:224.0.1.{{ .Values.wildfly_cluster_id | default 1 }}}" multicast-port="23364"/>
            <socket-binding name="messaging-group" multicast-address="${jboss.messaging.group.address:231.7.7.{{ .Values.wildfly_cluster_id | default 1}}}" multicast-port="${jboss.messaging.group.port:9876}"/>
            {{- end }}
    <!--        <socket-binding name="iiop" interface="unsecure" port="3528"/>
            <socket-binding name="iiop-ssl" interface="unsecure" port="3529"/> -->
            {{- include "wildfly-config.outbound-socket-bindings" . | indent 12 }}
        </socket-binding-group>
    </server>

{{- end }}
