benchmark "gcp_turbot_guardrails" {
  title       = "GCP - Turbot Guardrails"
  description = "Benchmark containing controls to reconcile GCP resources between GCP and Turbot Guardrails, ensuring consistency and alignment across resource types."

  children = [
    control.gcp_turbot_guardrails_gcp_project,
    control.gcp_turbot_guardrails_gcp_bigquery_dataset,
    control.gcp_turbot_guardrails_gcp_bigquery_table,
    control.gcp_turbot_guardrails_gcp_cloudfunctions_function,
    control.gcp_turbot_guardrails_gcp_storage_bucket
  ]

  tags = {
    type    = "Benchmark"
    service = "Guardrails"
  }
}

control "gcp_turbot_guardrails_gcp_project" {
  title       = "Project"
  description = "This control checks for discrepancies between GCP projects in your GCP console and those registered in Turbot Guardrails. It ensures that all projects are synchronized between GCP and Turbot Guardrails, helping maintain consistency and compliance across your cloud environment."
  sql         = <<-EOQ
    WITH guardrails_projects AS 
    (SELECT
        data ->> 'name' AS name,
        metadata -> 'gcp' ->> 'projectId' AS project_id 
    FROM
        guardrails_resource 
    WHERE
        resource_type_uri = 'tmod:@turbot/gcp#/resource/types/project' 
    ),
    gcp_projects AS 
    (SELECT
        name,
        project_id 
    FROM
        gcp_project 
    )
    SELECT
    COALESCE(gp.name, gr.name) AS resource,
    CASE
        WHEN gp.project_id IS NOT NULL AND gr.project_id IS NOT NULL THEN 'ok' 
        ELSE 'alarm' 
    END
    AS status, 
    CASE
        WHEN gp.project_id IS NOT NULL AND gr.project_id IS NOT NULL THEN CONCAT('Project ', gp.name, ' is in sync.') 
        WHEN gp.project_id IS NOT NULL THEN CONCAT('Project ', gp.name, ' exists only in GCP and is missing in Guardrails.') 
        WHEN gr.project_id IS NOT NULL THEN CONCAT('Project ', gr.name, ' exists only in Guardrails and is missing in GCP.') 
    END
    AS reason, 
    COALESCE(gp.project_id, gr.project_id) AS project_id 
    FROM
    gcp_projects gp 
    FULL OUTER JOIN
        guardrails_projects gr 
        ON gp.project_id = gr.project_id 
    ORDER BY
    resource;
  EOQ
}

control "gcp_turbot_guardrails_gcp_bigquery_dataset" {
  title       = "BigQuery > Dataset"
  description = "This control checks for discrepancies between GCP BigQuery datasets in your GCP console and those registered in Turbot Guardrails. It ensures that all datasets are synchronized between GCP and Turbot Guardrails, helping maintain consistency and compliance across your cloud environment."

  sql = <<-EOQ
    WITH guardrails_tables AS (
        SELECT
            data -> 'datasetReference' ->> 'datasetId' AS dataset_id,
            data ->> 'location' AS location,
            metadata -> 'gcp' ->> 'projectId' AS project_id
        FROM guardrails_resource
        WHERE resource_type_uri = 'tmod:@turbot/gcp-bigquery#/resource/types/dataset'
    ),
    gcp_tables AS (
        SELECT
            dataset_id,
            location,
            project AS project_id 
        FROM gcp_bigquery_dataset
    )
    SELECT
        COALESCE(grt.dataset_id, gct.dataset_id) AS resource,
        CASE
            WHEN grt.dataset_id IS NULL THEN 'alarm'
            WHEN gct.dataset_id IS NULL THEN 'alarm'
            ELSE 'ok'
        END AS status,
        CASE            
            WHEN grt.dataset_id IS NULL THEN CONCAT('Dataset ', gct.dataset_id, ' exists only in GCP and is missing in Guardrails.')
            WHEN gct.dataset_id IS NULL THEN CONCAT('Dataset ', grt.dataset_id, ' exists only in Guardrails and is missing in GCP.')
            ELSE CONCAT('Dataset ', grt.dataset_id, ' is in sync.')
        END as reason,
        COALESCE(grt.location, gct.location) AS location,
        COALESCE(grt.project_id, gct.project_id) AS project_id
    FROM guardrails_tables grt
    FULL OUTER JOIN gcp_tables gct
        ON grt.project_id = gct.project_id
        AND grt.dataset_id = gct.dataset_id
    ORDER BY resource,project_id;
  EOQ
}

control "gcp_turbot_guardrails_gcp_bigquery_table" {
  title       = "BigQuery > Table"
  description = "This control checks for discrepancies between GCP BigQuery tables in your GCP console and those registered in Turbot Guardrails. It ensures that all tables are synchronized between GCP and Turbot Guardrails, helping maintain consistency and compliance across your cloud environment."

  sql = <<-EOQ
    WITH guardrails_tables AS (
        SELECT
            data -> 'tableReference' ->> 'tableId' AS table_id,
            data -> 'tableReference' ->> 'datasetId' AS dataset_id,
            data ->> 'location' AS location,
            metadata -> 'gcp' ->> 'projectId' AS project_id
        FROM guardrails_resource
        WHERE resource_type_uri = 'tmod:@turbot/gcp-bigquery#/resource/types/table'
    ),
    gcp_tables AS (
        SELECT
            table_id,
            dataset_id,
            location,
            project AS project_id 
        FROM gcp_bigquery_table
    )
    SELECT
        COALESCE(grt.table_id, gct.table_id) AS resource,
        CASE
            WHEN grt.table_id IS NULL THEN 'alarm'
            WHEN gct.table_id IS NULL THEN 'alarm'
            ELSE 'ok'
        END AS status,
        CASE            
            WHEN grt.table_id IS NULL THEN CONCAT('Table ', gct.table_id, ' exists only in GCP and is missing in Guardrails.')
            WHEN gct.table_id IS NULL THEN CONCAT('Table ', grt.table_id, ' exists only in Guardrails and is missing in GCP.')
            ELSE CONCAT('Table ', grt.table_id, ' is in sync.')
        END as reason,
        COALESCE(grt.dataset_id, gct.dataset_id) AS dataset_id,
        COALESCE(grt.location, gct.location) AS location,
        COALESCE(grt.project_id, gct.project_id) AS project_id
    FROM guardrails_tables grt
    FULL OUTER JOIN gcp_tables gct
        ON grt.project_id = gct.project_id
        AND grt.dataset_id = gct.dataset_id
        AND grt.table_id = gct.table_id
    ORDER BY resource,project_id;
  EOQ
}

control "gcp_turbot_guardrails_gcp_cloudfunctions_function" {
  title       = "CloudFunctions > Function"
  description = "This control checks for discrepancies between GCP Cloud Functions in your GCP console and those registered in Turbot Guardrails. It ensures that all Cloud Functions are synchronized between GCP and Turbot Guardrails, helping maintain consistency and compliance across your cloud environment."

  sql = <<-EOQ
    WITH guardrails_tables AS (
        SELECT
            REVERSE(SPLIT_PART(REVERSE(data ->> 'name'), '/', 1)) AS name,
            metadata -> 'gcp' ->> 'regionName' AS region_name,
            metadata -> 'gcp' ->> 'projectId' AS project_id
        FROM guardrails_resource
        WHERE resource_type_uri = 'tmod:@turbot/gcp-functions#/resource/types/function'
    ),
    gcp_tables AS (
        SELECT
            name,
            LOWER(location) as region_name,
            project AS project_id 
        FROM gcp_cloudfunctions_function
    )
    SELECT
        COALESCE(grt.name, gct.name) AS resource,
        CASE
            WHEN grt.name IS NULL THEN 'alarm'
            WHEN gct.name IS NULL THEN 'alarm'
            ELSE 'ok'
        END AS status,
        CASE            
            WHEN grt.name IS NULL THEN CONCAT('Function ', gct.name, ' exists only in GCP and is missing in Guardrails.')
            WHEN gct.name IS NULL THEN CONCAT('Function ', grt.name, ' exists only in Guardrails and is missing in GCP.')
            ELSE CONCAT('Function ', grt.name, ' is in sync.')
        END as reason,
        COALESCE(grt.region_name, gct.region_name) AS region_name,
        COALESCE(grt.project_id, gct.project_id) AS project_id
    FROM guardrails_tables grt
    FULL OUTER JOIN gcp_tables gct
        ON grt.project_id = gct.project_id
        AND grt.name = gct.name
    ORDER BY resource,project_id;
  EOQ
}

control "gcp_turbot_guardrails_gcp_storage_bucket" {
  title       = "Storage > Bucket"
  description = "This control checks for discrepancies between GCP Storage buckets in your GCP console and those registered in Turbot Guardrails. It ensures that all storage buckets are synchronized between GCP and Turbot Guardrails, helping maintain consistency and compliance across your cloud environment."

  sql = <<-EOQ
    WITH guardrails_tables AS (
        SELECT
            data ->> 'name' AS name,
            metadata -> 'gcp' ->> 'regionName' AS region_name,
            metadata -> 'gcp' ->> 'projectId' AS project_id
        FROM guardrails_resource
        WHERE resource_type_uri = 'tmod:@turbot/gcp-storage#/resource/types/bucket'
    ),
    gcp_tables AS (
        SELECT
            name,
            LOWER(location) as region_name,
            project AS project_id 
        FROM gcp_storage_bucket
    )
    SELECT
        COALESCE(grt.name, gct.name) AS resource,
        CASE
            WHEN grt.name IS NULL THEN 'alarm'
            WHEN gct.name IS NULL THEN 'alarm'
            ELSE 'ok'
        END AS status,
        CASE            
            WHEN grt.name IS NULL THEN CONCAT('Bucket ', gct.name, ' exists only in GCP and is missing in Guardrails.')
            WHEN gct.name IS NULL THEN CONCAT('Bucket ', grt.name, ' exists only in Guardrails and is missing in GCP.')
            ELSE CONCAT('Bucket ', grt.name, ' is in sync.')
        END as reason,
        COALESCE(grt.region_name, gct.region_name) AS region_name,
        COALESCE(grt.project_id, gct.project_id) AS project_id
    FROM guardrails_tables grt
    FULL OUTER JOIN gcp_tables gct
        ON grt.project_id = gct.project_id
        AND grt.name = gct.name
    ORDER BY resource,project_id;
  EOQ
}
