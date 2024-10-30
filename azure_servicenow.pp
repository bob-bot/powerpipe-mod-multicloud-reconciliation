benchmark "azure_servicenow" {
  title       = "Azure - ServiceNow"
  description = "Benchmark containing controls to reconcile Azure resources between Azure and Service Now, ensuring consistency and alignment across resource types."

  children = [
    control.azure_servicenow_azure_subscription,
    control.azure_servicenow_azure_storage_storageaccount
  ]

  tags = {
    type    = "Benchmark"
    service = "ServiceNow"
  }
}

control "azure_servicenow_azure_subscription" {
  title       = "Subscription"
  description = "This control checks for discrepancies between Azure subscriptions in your Azure portal and those registered in ServiceNow. It ensures that all subscriptions are synchronized between Azure and ServiceNow, helping maintain consistency and compliance across your cloud environment."
  sql         = <<-EOQ
    WITH servicenow_subscriptions AS (
        SELECT
            name AS subscription_name
        FROM
            servicenow_cmdb_ci
        WHERE
            sys_class_name LIKE '%_guardrails_azure_subscription%'
    ),
    azure_subscriptions AS (
        SELECT
            display_name AS subscription_name
        FROM
            azure_subscription
    )
    SELECT
        COALESCE(az.subscription_name, sn.subscription_name) AS resource,
        CASE
            WHEN az.subscription_name IS NOT NULL AND sn.subscription_name IS NOT NULL THEN 'ok'
            ELSE 'alarm'
        END AS status,
        CASE
            WHEN az.subscription_name IS NOT NULL AND sn.subscription_name IS NOT NULL THEN CONCAT('Subscription ', az.subscription_name, ' is in sync.')
            WHEN az.subscription_name IS NOT NULL THEN CONCAT('Subscription ', az.subscription_name, ' exists only in Azure and is missing in ServiceNow.')
            WHEN sn.subscription_name IS NOT NULL THEN CONCAT('Subscription ', sn.subscription_name, ' exists only in ServiceNow and is missing in Azure.')
        END AS reason,
        COALESCE(az.subscription_name, sn.subscription_name) AS subscription_name
    FROM
        azure_subscriptions az
    FULL OUTER JOIN
        servicenow_subscriptions sn
        ON az.subscription_name = sn.subscription_name
    ORDER BY
        resource
  EOQ
}

control "azure_servicenow_azure_storage_storageaccount" {
  title       = "Storage > Storage Account"
  description = "This control checks for discrepancies between Azure Storage Accounts in your Azure portal and those registered in ServiceNow. It ensures that all storage accounts are synchronized between Azure and ServiceNow, helping maintain consistency and compliance across your cloud environment."

  sql = <<-EOQ
    WITH servicenow_storage_accounts AS (
        SELECT
            name AS storage_account_name,
            LOWER(TRIM(name)) AS storage_account_id
        FROM
            servicenow_cmdb_ci
        WHERE
            sys_class_name LIKE '%_guardrails_azure_storage_storageaccount%'
    ),
    azure_storage_accounts AS (
        SELECT
            name AS storage_account_name,
            LOWER(TRIM(name)) AS storage_account_id,
            LOWER(region) as region_name,
            subscription_id
        FROM
            azure_storage_account
    )
    SELECT
        COALESCE(az.storage_account_name, sn.storage_account_name) AS resource,
        CASE
            WHEN az.storage_account_id IS NOT NULL AND sn.storage_account_id IS NOT NULL THEN 'ok'
            ELSE 'alarm'
        END AS status,
        CASE
            WHEN az.storage_account_id IS NOT NULL AND sn.storage_account_id IS NOT NULL THEN CONCAT('Storage Account ', az.storage_account_name, ' is in sync.')
            WHEN az.storage_account_id IS NOT NULL THEN CONCAT('Storage Account ', az.storage_account_name, ' exists only in Azure and is missing in ServiceNow.')
            WHEN sn.storage_account_id IS NOT NULL THEN CONCAT('Storage Account ', sn.storage_account_name, ' exists only in ServiceNow and is missing in Azure.')
        END AS reason,
        COALESCE(az.region_name) AS region_name,
        COALESCE(az.subscription_id) AS subscription_id
    FROM
        azure_storage_accounts az
    FULL OUTER JOIN
        servicenow_storage_accounts sn
        ON az.storage_account_id = sn.storage_account_id
    ORDER BY
        resource
  EOQ
}
