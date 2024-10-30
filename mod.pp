mod "multicloud_resource_reconciliation" {
  title = "Multi-Cloud Resource Reconciliation"

  description = "This mod provides controls and benchmarks to reconcile cloud resources across AWS, Azure, GCP, and Kubernetes with Turbot Guardrails and ServiceNow. It ensures that resources are synchronized between your cloud environments and governance tools, helping maintain consistency, compliance, and accurate asset management across your multi-cloud infrastructure."


  color = "#4285F4"
  # documentation = file("./docs/index.md")
  # icon       = "/images/mods/gcp/gcp-icon.svg"
  categories = ["public cloud", "azure", "gcp", "guardrails", "compliance"]

  require {
    plugin "azure" {
      min_version = "0.66.0"
    }
    plugin "gcp" {
      min_version = "0.57.0"
    }
    plugin "guardrails" {
      min_version = "0.17.1"
    }
    plugin "servicenow" {
      min_version = "0.3.1"
    }
  }
}
