{{- define "wildfly-config.concurrent" }}
<concurrent>
    <context-services>
        <context-service name="default" jndi-name="java:jboss/ee/concurrency/context/default" use-transaction-setup-provider="true"/>
    </context-services>
    <managed-thread-factories>
        <managed-thread-factory name="default" jndi-name="java:jboss/ee/concurrency/factory/default" context-service="default"/>
    </managed-thread-factories>
    <managed-executor-services>
        <managed-executor-service name="default" jndi-name="java:jboss/ee/concurrency/executor/default" context-service="default" hung-task-threshold="180000" keepalive-time="5000" {{ if .Values.wildfly_concurrency_executor_default_core_threads }} core-threads="{{ .Values.wildfly_concurrency_executor_default_core_threads }}" {{ end }} {{ if .Values.wildfly_concurrency_executor_default_max_threads }} max-threads="{{ .Values.wildfly_concurrency_executor_default_max_threads }}" {{ end }} {{ if .Values.wildfly_concurrency_executor_default_queue_length }} queue-length="{{ .Values.wildfly_concurrency_executor_default_queue_length }}" {{ end }} />
            {{- range .Values.wildfly_concurrency_executor }}
                {{- if .queue_length }}
            <managed-executor-service name="{{ .name }}" jndi-name="{{ .jndi }}" hung-task-threshold="{{ .hung_task_threshold | default 180000 }}" core-threads="{{ .core_threads | default 50 }}" max-threads="{{ .max_threads | default 50 }}" queue-length="{{ .queue_length }}" keepalive-time="{{ .keepalive_time | default 3000 }}" context-service="{{ .context_service | default "default" }}" long-running-tasks="{{ .long_running_tasks | default "false" }}"/>
                {{- else }}
            <managed-executor-service name="{{ .name }}" jndi-name="{{ .jndi }}" hung-task-threshold="{{ .hung_task_threshold | default 180000 }}" core-threads="{{ .core_threads | default 50 }}" max-threads="{{ .max_threads | default 50 }}" queue-length="{{ $.Values.wildfly_default_queue_length | default 100000 }}" keepalive-time="{{ .keepalive_time | default 3000 }}" context-service="{{ .context_service | default "default" }}" long-running-tasks="{{ .long_running_tasks | default "false" }}"/>
                {{- end }}
            {{- end }}
    </managed-executor-services>
    <managed-scheduled-executor-services>
        <managed-scheduled-executor-service name="default" jndi-name="java:jboss/ee/concurrency/scheduler/default" context-service="default" hung-task-threshold="180000" keepalive-time="3000"/>
            {{- range .Values.wildfly_scheduled_executor_services }}
                {{- if .core_threads }}
        <managed-scheduled-executor-service name="{{ .name }}" jndi-name="{{ .jndi }}" context-service="{{ .context_service | default "default" }}" core-threads="{{ .core_threads | default 50 }}" hung-task-threshold="{{ .hung_task_threshold | default 180000 }}" keepalive-time="{{ .keepalive_time | default 3000 }}"/>
                {{- else }}
        <managed-scheduled-executor-service name="{{ .name }}" jndi-name="{{ .jndi }}" context-service="{{ .context_service | default "default" }}" core-threads="{{ $.Values.wildfly_scheduled_executor_core_threads | default 50 }}" hung-task-threshold="{{ .hung_task_threshold | default 180000 }}" keepalive-time="{{ .keepalive_time | default 3000 }}"/>
                {{- end }}
            {{- end }}
    </managed-scheduled-executor-services>
</concurrent>
{{- end }}
