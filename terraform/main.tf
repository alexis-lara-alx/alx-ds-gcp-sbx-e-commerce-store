resource "google_storage_bucket" "ecommerce" {
	name = "alx-ds-ecommerce"
	location = "US"
	force_destroy = true
	public_access_prevention = "enforced"

	# TODO - Add lifecycle policies

	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "raw"
	}
}

resource "google_bigquery_dataset" "stn_ecommerce" {
	dataset_id = "stn_ecommerce"
	description = "Standardized E-Commerce data"
	location = "US"
	is_case_insensitive = true

	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_customers" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_customers_dataset"
	description = "This dataset has information about the customer and its location. Use it to identify unique customers in the orders dataset and to find the orders delivery location"
	deletion_protection=false

	schema = <<EOF
		[
			{
				"name": "customer_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Key to the orders dataset. Each order has a unique order_customer_id"
			},
			{
				"name": "customer_unique_id",
				"type": "STRING",
				"mode": "REQUIRED",
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
			},
			{
				"name": "_created_date",
				"type": "TIMESTAMP",
				"mode": "NULLABLE",
				"description": "Record creation date",
				"defaultValueExpression": "CURRENT_TIMESTAMP()"
			}
		]
		EOF

	table_constraints {
		primary_key {
			columns = ["customer_id"]
		}

		foreign_keys {
			name = "FK__customers__geolocation"

			referenced_table {
				project_id = google_bigquery_dataset.stn_ecommerce.project
				dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
				table_id = google_bigquery_table.stn_ecommerce_geolocation.table_id
			}

			column_references {
				referencing_column = "customer_zip_code_prefix"
				referenced_column = "geolocation_zip_code_prefix"
			}
		}
	}

	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_geolocation" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_geolocation_dataset"
	description = "This dataset has information Brazilian zip codes and its lat/lng coordinates. Use it to plot maps and find distances between sellers and customers"
	deletion_protection=false

	schema = <<EOF
		[
			{
				"name": "geolocation_zip_code_prefix",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "First 5 digits of zip code"
			},
			{
				"name": "geolocation_lat",
				"type": "BIGNUMERIC",
				"mode": "REQUIRED",
				"description": "Latitude",
				"precision": "17",
				"scale": "15"
			},
			{
				"name": "geolocation_lng",
				"type": "BIGNUMERIC",
				"mode": "REQUIRED",
				"description": "Longitude",
				"precision": "17",
				"scale": "15"
			},
			{
				"name": "geolocation_city",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "City name"
			},
			{
				"name": "geolocation_state",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "State"
			},
			{
				"name": "_created_date",
				"type": "TIMESTAMP",
				"mode": "NULLABLE",
				"description": "Record creation date",
				"defaultValueExpression": "CURRENT_TIMESTAMP()"
			}
		]
		EOF

	table_constraints {
		primary_key {
			columns = ["geolocation_zip_code_prefix"]
		}
	}

	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_order_items" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_order_items_dataset"
	description = "This dataset includes data about the items purchased within each order"
	deletion_protection=false

	schema = <<EOF
		[
			{
				"name": "order_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Order unique identifier"
			},
			{
				"name": "order_item_id",
				"type": "INTEGER",
				"mode": "REQUIRED",
				"description": "Sequential number identifying number of items included in the same order"
			},
			{
				"name": "product_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Product unique identifier"
			},
			{
				"name": "seller_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Seller unique identifier"
			},
			{
				"name": "shipping_limit_date",
				"type": "DATETIME",
				"mode": "REQUIRED",
				"description": "Shows the seller shipping limit date for handling the order over to the logistic partner"
			},
			{
				"name": "price",
				"type": "NUMERIC",
				"mode": "REQUIRED",
				"description": "Item price",
				"precision": "9",
				"scale": "2"
			},
			{
				"name": "freight_value",
				"type": "NUMERIC",
				"mode": "REQUIRED",
				"description": "Item freight value item (if an order has more than one item the freight value is splitted between items)",
				"precision": "9",
				"scale": "2"
			},
			{
				"name": "_created_date",
				"type": "TIMESTAMP",
				"mode": "NULLABLE",
				"description": "Record creation date",
				"defaultValueExpression": "CURRENT_TIMESTAMP()"
			}
		]
		EOF

	table_constraints {
		primary_key {
			columns = ["order_id", "order_item_id"]
		}

		foreign_keys {
			name = "FK__order_items__orders"

			referenced_table {
				project_id = google_bigquery_dataset.stn_ecommerce.project
				dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
				table_id = google_bigquery_table.stn_ecommerce_orders.table_id
			}

			column_references {
				referencing_column = "order_id"
				referenced_column = "order_id"
			}
		}

		foreign_keys {
			name = "FK__order_items__products"

			referenced_table {
				project_id = google_bigquery_dataset.stn_ecommerce.project
				dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
				table_id = google_bigquery_table.stn_ecommerce_products.table_id
			}

			column_references {
				referencing_column = "product_id"
				referenced_column = "product_id"
			}
		}
		
		foreign_keys {
			name = "FK__order_items__sellers"

			referenced_table {
				project_id = google_bigquery_dataset.stn_ecommerce.project
				dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
				table_id = google_bigquery_table.stn_ecommerce_sellers.table_id
			}

			column_references {
				referencing_column = "seller_id"
				referenced_column = "seller_id"
			}
		}
	}

	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_order_payments" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_order_payments_dataset"
	description = "This dataset includes data about the orders payment options"
	deletion_protection=false

	schema = <<EOF
		[
			{
				"name": "order_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Unique identifier of an order"
			},
			{
				"name": "payment_sequential",
				"type": "INTEGER",
				"mode": "REQUIRED",
				"description": "A customer may pay an order with more than one payment method. If he does so, a sequence will be created to"
			},
			{
				"name": "payment_type",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Method of payment chosen by the customer"
			},
			{
				"name": "payment_installments",
				"type": "INTEGER",
				"mode": "REQUIRED",
				"description": "Number of installments chosen by the customer"
			},
			{
				"name": "payment_value",
				"type": "NUMERIC",
				"mode": "REQUIRED",
				"description": "Transaction value",
				"precision": "9",
				"scale": "2"
			},
			{
				"name": "_created_date",
				"type": "TIMESTAMP",
				"mode": "NULLABLE",
				"description": "Record creation date",
				"defaultValueExpression": "CURRENT_TIMESTAMP()"
			}
		]
		EOF

	table_constraints {
		primary_key {
			columns = ["order_id", "payment_sequential"]
		}

		foreign_keys {
			name = "FK__order_payment__orders"

			referenced_table {
				project_id = google_bigquery_dataset.stn_ecommerce.project
				dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
				table_id = google_bigquery_table.stn_ecommerce_orders.table_id
			}

			column_references {
				referencing_column = "order_id"
				referenced_column = "order_id"
			}
		}
	}
	
	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_order_reviews" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_order_reviews_dataset"
	description = "This dataset includes data about the reviews made by the customers"
	deletion_protection=false

	schema = <<EOF
		[
			{
				"name": "review_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Unique review identifier"
			},
			{
				"name": "order_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Unique order identifier"
			},
			{
				"name": "review_score",
				"type": "INTEGER",
				"mode": "REQUIRED",
				"description": "Note ranging from 1 to 5 given by the customer on a satisfaction survey"
			},
			{
				"name": "review_comment_title",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Comment title from the review left by the customer, in Portuguese"
			},
			{
				"name": "review_comment_message",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Comment message from the review left by the customer, in Portuguese"
			}
			,
			{
				"name": "review_creation_date",
				"type": "DATETIME",
				"mode": "REQUIRED",
				"description": "Shows the date in which the satisfaction survey was sent to the customer"
			},
			{
				"name": "review_answer_DATETIME",
				"type": "DATETIME",
				"mode": "REQUIRED",
				"description": "Shows satisfaction survey answer DATETIME"
			},
			{
				"name": "_created_date",
				"type": "TIMESTAMP",
				"mode": "NULLABLE",
				"description": "Record creation date",
				"defaultValueExpression": "CURRENT_TIMESTAMP()"
			}
		]
		EOF

	table_constraints {
		primary_key {
			columns = ["review_id"]
		}

		foreign_keys {
			name = "FK__order_reviews__orders"

			referenced_table {
				project_id = google_bigquery_dataset.stn_ecommerce.project
				dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
				table_id = google_bigquery_table.stn_ecommerce_orders.table_id
			}

			column_references {
				referencing_column = "order_id"
				referenced_column = "order_id"
			}
		}
	}
	
	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_orders" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_orders_dataset"
	description = "This is the core dataset. From each order you might find all other information"
	deletion_protection=false

	schema = <<EOF
		[
			{
				"name": "order_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Unique identifier of the order"
			},
			{
				"name": "customer_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Key to the customer dataset. Each order has a unique customer_id"
			},
			{
				"name": "order_status",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Reference to the order status (delivered, shipped, etc)"
			},
			{
				"name": "order_purchase_DATETIME",
				"type": "DATETIME",
				"mode": "REQUIRED",
				"description": "Shows the purchase DATETIME"
			},
			{
				"name": "order_approved_at",
				"type": "DATETIME",
				"mode": "NULLABLE",
				"description": "Shows the payment approval DATETIME"
			}
			,
			{
				"name": "order_delivered_carrier_date",
				"type": "DATETIME",
				"mode": "NULLABLE",
				"description": "Shows the order posting DATETIME. When it was handled to the logistic partner"
			},
			{
				"name": "order_delivered_customer_date",
				"type": "DATETIME",
				"mode": "NULLABLE",
				"description": "Shows the actual order delivery date to the customer"
			},
			{
				"name": "order_estimated_delivery_date",
				"type": "DATETIME",
				"mode": "REQUIRED",
				"description": "Shows the estimated delivery date that was informed to customer at the purchase moment"
			},
			{
				"name": "_created_date",
				"type": "TIMESTAMP",
				"mode": "NULLABLE",
				"description": "Record creation date",
				"defaultValueExpression": "CURRENT_TIMESTAMP()"
			}
		]
		EOF

	table_constraints {
		primary_key {
			columns = ["order_id"]
		}

		foreign_keys {
			name = "FK__orders__customers"

			referenced_table {
				project_id = google_bigquery_dataset.stn_ecommerce.project
				dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
				table_id = google_bigquery_table.stn_ecommerce_customers.table_id
			}

			column_references {
				referencing_column = "customer_id"
				referenced_column = "customer_id"
			}
		}
	}
	
	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_products" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_products_dataset"
	description = "This dataset includes data about the products sold by Olist"
	deletion_protection=false

	schema = <<EOF
		[
			{
				"name": "product_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Unique product identifier"
			},
			{
				"name": "product_category_name",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Root category of product, in Portuguese"
			},
			{
				"name": "product_name_lenght",
				"type": "INTEGER",
				"mode": "NULLABLE",
				"description": "Number of characters extracted from the product name"
			},
			{
				"name": "product_description_lenght",
				"type": "INTEGER",
				"mode": "NULLABLE",
				"description": "Number of characters extracted from the product description"
			},
			{
				"name": "product_photos_qty",
				"type": "INTEGER",
				"mode": "NULLABLE",
				"description": "Number of product published photos"
			}
			,
			{
				"name": "product_weight_g",
				"type": "INTEGER",
				"mode": "NULLABLE",
				"description": "Product weight measured in grams"
			},
			{
				"name": "product_length_cm",
				"type": "INTEGER",
				"mode": "NULLABLE",
				"description": "Product length measured in centimeters"
			},
			{
				"name": "product_height_cm",
				"type": "INTEGER",
				"mode": "NULLABLE",
				"description": "Product height measured in centimeters"
			},
			{
				"name": "product_width_cm",
				"type": "INTEGER",
				"mode": "NULLABLE",
				"description": "product width measured in centimeters"
			},
			{
				"name": "_created_date",
				"type": "TIMESTAMP",
				"mode": "NULLABLE",
				"description": "Record creation date",
				"defaultValueExpression": "CURRENT_TIMESTAMP()"
			}
		]
		EOF

	table_constraints {
		primary_key {
			columns = ["product_id"]
		}
	}
	
	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_sellers" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_sellers_dataset"
	description = "This dataset includes data about the sellers that fulfilled orders made at Olist. Use it to find the seller location and to identify which seller fulfilled each product"
	deletion_protection=false

	schema = <<EOF
		[
			{
				"name": "seller_id",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Seller unique identifier"
			},
			{
				"name": "seller_zip_code_prefix",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "First 5 digits of seller zip code"
			},
			{
				"name": "seller_city",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Seller city name"
			},
			{
				"name": "seller_state",
				"type": "STRING",
				"mode": "REQUIRED",
				"description": "Seller state"
			},
			{
				"name": "_created_date",
				"type": "TIMESTAMP",
				"mode": "NULLABLE",
				"description": "Record creation date",
				"defaultValueExpression": "CURRENT_TIMESTAMP()"
			}
		]
		EOF

	table_constraints {
		primary_key {
			columns = ["seller_id"]
		}

		foreign_keys {
			name = "FK__sellers__geolocation"

			referenced_table {
				project_id = google_bigquery_dataset.stn_ecommerce.project
				dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
				table_id = google_bigquery_table.stn_ecommerce_geolocation.table_id
			}

			column_references {
				referencing_column = "seller_zip_code_prefix"
				referenced_column = "geolocation_zip_code_prefix"
			}
		}
	}

	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}
