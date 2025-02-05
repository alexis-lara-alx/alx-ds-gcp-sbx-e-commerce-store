import io
import json
import copy
import argparse
import apache_beam as beam
from google.cloud import bigquery
from decimal import Decimal

from apache_beam.dataframe.io import read_csv
from apache_beam.dataframe.convert import to_pcollection

from apache_beam.options.pipeline_options import PipelineOptions


class RenameSchemaFn(beam.DoFn):
    def process(self, elem, field_rename_dict):
        dict_elem = elem._asdict()

        for old_name, new_name in field_rename_dict.items():
            if old_name in dict_elem:
                dict_elem[new_name] = dict_elem.pop(old_name)

        yield dict_elem

class MapBigQuerySchemaFn(beam.DoFn):
    def process(self, elem, bq_schema):
        bq_data_type_map = {
            'STRING': str,
            'BYTES': str,
            'INTEGER': int,
            'FLOAT': float,
            'NUMERIC': Decimal,
            'BOOLEAN': bool
        }

        mapped_elem = elem.copy()

        for field_def in bq_schema:
            if field_def.name not in mapped_elem:
                continue
        
            if field_def.field_type not in bq_data_type_map:
                continue

            orig_val = mapped_elem[field_def.name]
            casting_func = bq_data_type_map[field_def.field_type]
            try:
                casted_val = casting_func(orig_val)
                mapped_elem[field_def.name] = casted_val
            except Exception as e:
                print(e)
                raise

            if field_def.field_mode == 'REQUIRED' and orig_val
                






def main(argv=None):
    parser = argparse.ArgumentParser()

    parser.add_argument('--src-file', dest='src_file', type=str, help='Input file to process')
    parser.add_argument('--dst-project', dest='dst_project', type=str, default='alx-ds-sandbox')
    parser.add_argument('--dst-dataset', dest='dst_dataset', type=str, default='stn_ecommerce')
    parser.add_argument('--dst-table', dest='dst_table', type=str, default='olist_order_reviews_dataset')
    parser.add_argument('--field-rename-dict', dest='field_rename_dict', type=json.loads, default='{"review_score": "reviewscore"}')

    known_args, pipeline_args = parser.parse_known_args(argv)

    client = bigquery.Client()
    dst_table_ref = client.get_table(f'{known_args.dst_project}.{known_args.dst_dataset}.{known_args.dst_table}')

    beam_options = PipelineOptions()

    with beam.Pipeline() as p:
        parsed_csv = p | 'Read input file' >> read_csv("/home/alexdelara/repos/business/alx_ds/alx-ds-gcp-sbx-e-commerce-store/data/olist_order_reviews_dataset_test.csv")

        csv_pcoll = to_pcollection(parsed_csv)

        if known_args.rename_fields_dict:
            csv_pcoll = csv_pcoll | beam.ParDo(RenameSchemaFn(), known_args.field_rename_dict)

        # csv_pcoll | beam.io.WriteToBigQuery(
        #     pa,
        #     schema=table_schema,
        #     write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
        #     create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED
        # )

if __name__ == '__main__':
  main()
