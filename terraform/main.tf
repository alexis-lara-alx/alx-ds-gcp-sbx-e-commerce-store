resource "google_bigquery_dataset" "stn_ecommerce" {
	dataset_id = "stn_ecommerce"
	description = "stn E-Commerce data"
	location = "US"
	is_case_insensitive = true

	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_customer" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_customers_dataset"
	description = "This dataset has information about the customer and its location. Use it to identify unique customers in the orders dataset and to find the orders delivery location"

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

	schema = <<EOF
		[
			{
				"name": "geolocation_zip_code_prefix",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "First 5 digits of zip code"
			},
			{
				"name": "geolocation_lat",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Latitude"
			},
			{
				"name": "geolocation_lng",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Longitude"
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
			}
		]
		EOF

	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_order_items" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_geolocation_order_items_dataset"
	description = "This dataset includes data about the items purchased within each order"

	schema = <<EOF
		[
			{
				"name": "order_id",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Order unique identifier"
			},
			{
				"name": "order_item_id",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Sequential number identifying number of items included in the same order"
			},
			{
				"name": "product_id",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Product unique identifier"
			},
			{
				"name": "seller_id",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Seller unique identifier"
			},
			{
				"name": "shipping_limit_date",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Shows the seller shipping limit date for handling the order over to the logistic partner"
			},
			{
				"name": "price",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Item price"
			},
			{
				"name": "freight_value",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Item freight value item (if an order has more than one item the freight value is splitted between items)"
			}
		]
		EOF

	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}

resource "google_bigquery_table" "stn_ecommerce_payments" {
	dataset_id = google_bigquery_dataset.stn_ecommerce.dataset_id
	table_id = "olist_geolocation_payments_dataset"
	description = "This dataset includes data about the orders payment options"

	schema = <<EOF
		[
			{
				"name": "order_id",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Unique identifier of an order"
			},
			{
				"name": "payment_sequential",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "A customer may pay an order with more than one payment method. If he does so, a sequence will be created to"
			},
			{
				"name": "payment_type",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Method of payment chosen by the customer"
			},
			{
				"name": "payment_installments",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Number of installments chosen by the customer"
			},
			{
				"name": "payment_value",
				"type": "STRING",
				"mode": "NULLABLE",
				"description": "Transaction value"
			}
		]
		EOF

	labels = {
		project = "ecommerce-store"
		env = "sandbox"
		customer = "alx-ds"
		lake_zone = "stn"
	}
}