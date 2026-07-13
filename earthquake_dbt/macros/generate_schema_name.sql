{% macro generate_schema_name(custom_schema_name, node) -%}
    {#
      Override dbt's default schema naming.
      By default dbt prefixes custom schema names with the target schema (e.g. analytics_staging).
      This macro uses the custom schema name directly so each layer gets a clean schema:
        staging/    → staging
        intermediate/ → intermediate
        marts/      → marts
      Models without a custom schema fall back to the profile's default schema (analytics).
    #}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
