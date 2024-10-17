benchmark "gcp_servicenow" {
  title       = "GCP - ServiceNow"
  description = "Benchmark containing controls to reconcile GCP resources between GCP and Service Now, ensuring consistency and alignment across resource types."

  children = [
    control.gcp_servicenow_gcp_project,
    control.gcp_servicenow_gcp_storage_bucket
  ]

  tags = {
    type    = "Benchmark"
    service = "ServiceNow"
  }
}

control "gcp_servicenow_gcp_project" {
  title       = "Project"
  description = "This control checks for discrepancies between GCP projects in your GCP console and those registered in ServiceNow. It ensures that all projects are synchronized between GCP and ServiceNow, helping maintain consistency and compliance across your cloud environment."
  sql         = <<-EOQ
    WITH servicenow_projects AS (
        SELECT
            name AS project_name,
            name AS project_id
        FROM
            servicenow_cmdb_ci
        WHERE
            sys_class_name LIKE '%turbot_guardrails_gcp_project%'
    ),
    gcp_projects AS (
        SELECT
            name AS project_name,
            project_id
        FROM
            gcp_project
    )
    SELECT
        COALESCE(gp.project_name, sn.project_name) AS resource,
        CASE
            WHEN gp.project_id IS NOT NULL AND sn.project_id IS NOT NULL THEN 'ok'
            ELSE 'alarm'
        END AS status,
        CASE
            WHEN gp.project_id IS NOT NULL AND sn.project_id IS NOT NULL THEN CONCAT('Project ', gp.project_name, ' is in sync.')
            WHEN gp.project_id IS NOT NULL THEN CONCAT('Project ', gp.project_name, ' exists only in GCP and is missing in ServiceNow.')
            WHEN sn.project_id IS NOT NULL THEN CONCAT('Project ', sn.project_name, ' exists only in ServiceNow and is missing in GCP.')
        END AS reason,
        COALESCE(gp.project_id, sn.project_id) AS project_id
    FROM
        gcp_projects gp
    FULL OUTER JOIN
        servicenow_projects sn
        ON gp.project_id = sn.project_id
    ORDER BY
        resource
  EOQ
}

control "gcp_servicenow_gcp_storage_bucket" {
  title       = "Storage > Bucket"
  description = "This control checks for discrepancies between GCP Storage buckets in your GCP console and those registered in ServiceNow. It ensures that all storage buckets are synchronized between GCP and ServiceNow, helping maintain consistency and compliance across your cloud environment."

  sql = <<-EOQ
    WITH servicenow_buckets AS (
        SELECT
            name AS bucket_name,
            LOWER(TRIM(name)) AS bucket_id
        FROM
            servicenow_cmdb_ci
        WHERE
            sys_class_name LIKE '%turbot_guardrails_gcp_storage_bucket%'
    ),
    gcp_buckets AS (
        SELECT
            name AS bucket_name,
            LOWER(TRIM(name)) AS bucket_id,
            LOWER(location) as region_name,
            project AS project_id 
        FROM
            gcp_storage_bucket
    )
    SELECT
        COALESCE(gb.bucket_name, sn.bucket_name) AS resource,
        CASE
            WHEN gb.bucket_id IS NOT NULL AND sn.bucket_id IS NOT NULL THEN 'ok'
            ELSE 'alarm'
        END AS status,
        CASE
            WHEN gb.bucket_id IS NOT NULL AND sn.bucket_id IS NOT NULL THEN CONCAT('Bucket ', gb.bucket_name, ' is in sync.')
            WHEN gb.bucket_id IS NOT NULL THEN CONCAT('Bucket ', gb.bucket_name, ' exists only in GCP and is missing in ServiceNow.')
            WHEN sn.bucket_id IS NOT NULL THEN CONCAT('Bucket ', sn.bucket_name, ' exists only in ServiceNow and is missing in GCP.')
        END AS reason,
        COALESCE(gb.region_name) AS region_name,
        COALESCE(gb.project_id) AS project_id
    FROM
        gcp_buckets gb
    FULL OUTER JOIN
        servicenow_buckets sn
        ON gb.bucket_id = sn.bucket_id
    ORDER BY
        resource
  EOQ
}
