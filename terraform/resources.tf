resource "google_bigquery_dataset" "raw_ecommerce" {
  dataset_id                  = "raw_ecommerce"
  description                 = "Raw E-Commerce data"
  location                    = "US"
  is_case_insensitive         = true

  labels = {
    project         = "ecommerce-store"
    env             = "sandbox"
    customer        = "alx-ds"
    lake_zone       = "raw"
  }
}

resource "google_bigquery_table" "raw_ecommerce_customer" {
  dataset_id = google_bigquery_dataset.raw_ecommerce.dataset_id
  table_id   = "olist_customers_dataset"

  labels = {
    project         = "ecommerce-store"
    env             = "sandbox"
    customer        = "alx-ds"
    lake_zone       = "raw"
  }

  schema = <<EOF
    [
        {
            "name": "customer_id",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": "Key to the orders dataset. Each order has a unique customer_id"
        },
        {
            "name": "customer_unique_id",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": "Unique identifier of a customer"
        },
        {
            "name": "customer_zip_code_prefix",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": "First five digits of customer zip code"
        },
        {
            "name": "customer_city",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": "Customer city name"
        },
        {
            "name": "customer_state",
            "type": "STRING",
            "mode": "NULLABLE",
            "description": "Customer state"
        }
    ]
    EOF
}
