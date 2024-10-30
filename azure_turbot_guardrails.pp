benchmark "azure_turbot_guardrails" {
  title       = "Azure - Turbot Guardrails"
  description = "Benchmark containing controls to reconcile Azure resources between Azure and Turbot Guardrails, ensuring consistency and alignment across resource types."

  children = [
    control.azure_turbot_guardrails_azure_subscription,
    control.azure_turbot_guardrails_azure_storage_account,
    control.azure_turbot_guardrails_azure_sql_server,
    control.azure_turbot_guardrails_azure_sql_database,
    control.azure_turbot_guardrails_azure_keyvault_vault
  ]

  tags = {
    type    = "Benchmark"
    service = "Guardrails"
  }
}

control "azure_turbot_guardrails_azure_subscription" {
  title       = "Subscription"
  description = "This control checks for discrepancies between GCP projects in your GCP console and those registered in Turbot Guardrails. It ensures that all projects are synchronized between GCP and Turbot Guardrails, helping maintain consistency and compliance across your cloud environment."
  sql         = <<-EOQ
    WITH guardrails_subscriptions AS (
        SELECT
            data ->> 'displayName' AS name,
            metadata -> 'azure' ->> 'subscriptionId' AS subscription_id
        FROM
            guardrails_resource
        WHERE
            resource_type_uri = 'tmod:@turbot/azure#/resource/types/subscription'
    ),
    azure_subscriptions AS (
        SELECT
            display_name AS name,
            subscription_id
        FROM
            azure_subscription
    )
    SELECT
        COALESCE(az.name, gr.name) AS resource,
        CASE
            WHEN az.subscription_id IS NOT NULL AND gr.subscription_id IS NOT NULL THEN 'ok'
            ELSE 'alarm'
        END AS status,
        CASE
            WHEN az.subscription_id IS NOT NULL AND gr.subscription_id IS NOT NULL THEN CONCAT('Subscription ', az.name, ' is in sync.')
            WHEN az.subscription_id IS NOT NULL THEN CONCAT('Subscription ', az.name, ' exists only in Azure and is missing in Guardrails.')
            WHEN gr.subscription_id IS NOT NULL THEN CONCAT('Subscription ', gr.name, ' exists only in Guardrails and is missing in Azure.')
        END AS reason,
        COALESCE(az.subscription_id, gr.subscription_id) AS subscription_id
    FROM
        azure_subscriptions az
    FULL OUTER JOIN
        guardrails_subscriptions gr
        ON az.subscription_id = gr.subscription_id
    ORDER BY
        resource;
  EOQ
}

control "azure_turbot_guardrails_azure_storage_account" {
  title       = "Storage > Account"
  description = "This control checks for discrepancies between Azure Storage accounts in your Azure portal and those registered in Turbot Guardrails. It ensures that all storage accounts are synchronized between Azure and Turbot Guardrails, helping maintain consistency and compliance across your cloud environment."

  sql = <<-EOQ
    WITH guardrails_tables AS (
        SELECT
            data ->> 'name' AS name,
            metadata -> 'azure' ->> 'resourceGroupName' AS resource_group,
            metadata -> 'azure' ->> 'subscriptionId' AS subscription_id
        FROM guardrails_resource
        WHERE resource_type_uri = 'tmod:@turbot/azure-storage#/resource/types/storageAccount'
    ),
    azure_tables AS (
        SELECT
            name,
            resource_group,
            subscription_id
        FROM
            azure_storage_account
    )
    SELECT
        COALESCE(grt.name, azt.name) AS resource,
        CASE
            WHEN grt.name IS NULL THEN 'alarm'
            WHEN azt.name IS NULL THEN 'alarm'
            ELSE 'ok'
        END AS status,
        CASE
            WHEN grt.name IS NULL THEN CONCAT('Storage Account ', azt.name, ' exists only in Azure and is missing in Guardrails.')
            WHEN azt.name IS NULL THEN CONCAT('Storage Account ', grt.name, ' exists only in Guardrails and is missing in Azure.')
            ELSE CONCAT('Storage Account ', grt.name, ' is in sync.')
        END AS reason,
        COALESCE(grt.resource_group, azt.resource_group) AS resource_group,
        COALESCE(grt.subscription_id, azt.subscription_id) AS subscription_id
    FROM
        guardrails_tables grt
    FULL OUTER JOIN
        azure_tables azt
        ON grt.subscription_id = azt.subscription_id
        AND grt.name = azt.name
    ORDER BY resource, subscription_id;
  EOQ
}

control "azure_turbot_guardrails_azure_sql_server" {
  title       = "SQL Server > Server"
  description = "This control checks for discrepancies between Azure SQL Servers in your Azure portal and those registered in Turbot Guardrails. It ensures that all SQL Servers are synchronized between Azure and Turbot Guardrails, helping maintain consistency and compliance across your cloud environment."

  sql = <<-EOQ
    WITH guardrails_sql_servers AS (
        SELECT
            data ->> 'name' AS name,
            metadata -> 'azure' ->> 'resourceGroupName' AS resource_group,
            metadata -> 'azure' ->> 'subscriptionId' AS subscription_id
        FROM guardrails_resource
        WHERE resource_type_uri = 'tmod:@turbot/azure-sql#/resource/types/server'
    ),
    azure_sql_servers AS (
        SELECT
            name,
            resource_group,
            subscription_id
        FROM
            azure_sql_server
    )
    SELECT
        COALESCE(grt.name, azt.name) AS resource,
        CASE
            WHEN grt.name IS NULL THEN 'alarm'
            WHEN azt.name IS NULL THEN 'alarm'
            ELSE 'ok'
        END AS status,
        CASE
            WHEN grt.name IS NULL THEN CONCAT('SQL Server ', azt.name, ' exists only in Azure and is missing in Guardrails.')
            WHEN azt.name IS NULL THEN CONCAT('SQL Server ', grt.name, ' exists only in Guardrails and is missing in Azure.')
            ELSE CONCAT('SQL Server ', grt.name, ' is in sync.')
        END AS reason,
        COALESCE(grt.resource_group, azt.resource_group) AS resource_group,
        COALESCE(grt.subscription_id, azt.subscription_id) AS subscription_id
    FROM
        guardrails_sql_servers grt
    FULL OUTER JOIN
        azure_sql_servers azt
        ON grt.subscription_id = azt.subscription_id
        AND grt.name = azt.name
    ORDER BY resource, subscription_id;
  EOQ
}

control "azure_turbot_guardrails_azure_sql_database" {
  title       = "SQL Database > Database"
  description = "This control checks for discrepancies between Azure SQL Databases in your Azure portal and those registered in Turbot Guardrails. It ensures that all SQL Databases are synchronized between Azure and Turbot Guardrails, helping maintain consistency and compliance across your cloud environment."

  sql = <<-EOQ
    WITH guardrails_sql_databases AS (
        SELECT
            data ->> 'name' AS name,
            metadata ->> 'serverName' AS server_name,
            metadata -> 'azure' ->> 'resourceGroupName' AS resource_group,
            metadata -> 'azure' ->> 'subscriptionId' AS subscription_id
        FROM
            guardrails_resource
        WHERE
            resource_type_uri = 'tmod:@turbot/azure-sql#/resource/types/database'
    ),
    azure_sql_databases AS (
        SELECT
            name,
            server_name,
            resource_group,
            subscription_id
        FROM
            azure_sql_database
    )
    SELECT
        COALESCE(grt.name, azt.name) AS resource,
        CASE
            WHEN grt.name IS NULL THEN 'alarm'
            WHEN azt.name IS NULL THEN 'alarm'
            ELSE 'ok'
        END AS status,
        CASE
            WHEN grt.name IS NULL THEN CONCAT('SQL Database ', azt.name, ' exists only in Azure and is missing in Guardrails.')
            WHEN azt.name IS NULL THEN CONCAT('SQL Database ', grt.name, ' exists only in Guardrails and is missing in Azure.')
            ELSE CONCAT('SQL Database ', grt.name, ' is in sync.')
        END AS reason,
        COALESCE(grt.server_name, azt.server_name) AS server_name,
        COALESCE(grt.resource_group, azt.resource_group) AS resource_group,
        COALESCE(grt.subscription_id, azt.subscription_id) AS subscription_id
    FROM
        guardrails_sql_databases grt
    FULL OUTER JOIN
        azure_sql_databases azt
        ON grt.subscription_id = azt.subscription_id
        AND grt.name = azt.name
        AND grt.server_name = azt.server_name
    ORDER BY resource, subscription_id;
  EOQ
}

control "azure_turbot_guardrails_azure_keyvault_vault" {
  title       = "Key Vault > Vault"
  description = "This control checks for discrepancies between Azure Key Vaults in your Azure portal and those registered in Turbot Guardrails. It ensures that all Key Vaults are synchronized between Azure and Turbot Guardrails, helping maintain consistency and compliance across your cloud environment."

  sql = <<-EOQ
    WITH guardrails_key_vaults AS (
        SELECT
            data ->> 'name' AS name,
            metadata -> 'azure' ->> 'resourceGroupName' AS resource_group,
            metadata -> 'azure' ->> 'subscriptionId' AS subscription_id
        FROM
            guardrails_resource
        WHERE
            resource_type_uri = 'tmod:@turbot/azure-keyvault#/resource/types/vault'
    ),
    azure_key_vaults AS (
        SELECT
            name,
            resource_group,
            subscription_id
        FROM
            azure_key_vault
    )
    SELECT
        COALESCE(grt.name, azt.name) AS resource,
        CASE
            WHEN grt.name IS NULL THEN 'alarm'
            WHEN azt.name IS NULL THEN 'alarm'
            ELSE 'ok'
        END AS status,
        CASE
            WHEN grt.name IS NULL THEN CONCAT('Key Vault ', azt.name, ' exists only in Azure and is missing in Guardrails.')
            WHEN azt.name IS NULL THEN CONCAT('Key Vault ', grt.name, ' exists only in Guardrails and is missing in Azure.')
            ELSE CONCAT('Key Vault ', grt.name, ' is in sync.')
        END AS reason,
        COALESCE(grt.resource_group, azt.resource_group) AS resource_group,
        COALESCE(grt.subscription_id, azt.subscription_id) AS subscription_id
    FROM
        guardrails_key_vaults grt
    FULL OUTER JOIN
        azure_key_vaults azt
        ON grt.subscription_id = azt.subscription_id
        AND grt.name = azt.name
    ORDER BY resource, subscription_id;
  EOQ
}
