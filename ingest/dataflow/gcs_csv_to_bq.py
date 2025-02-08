import json
import argparse
from datetime import datetime
import apache_beam as beam
from apache_beam import pvalue
from google.cloud import bigquery
from decimal import Decimal

from apache_beam.dataframe.io import read_csv
from apache_beam.dataframe.convert import to_pcollection

from apache_beam.options.pipeline_options import PipelineOptions


class RenameSchemaFn(beam.DoFn):
    def process(self, element, field_rename_dict):
        dict_element = element._asdict()

        for old_name, new_name in field_rename_dict.items():
            if old_name in dict_element:
                dict_element[new_name] = dict_element.pop(old_name)

        yield dict_element

class MapBigQuerySchemaFn(beam.DoFn):
    DTYPE_MAP = {
        'STRING': str,
        'BYTES': str,
        'INTEGER': int,
        'FLOAT': float,
        'NUMERIC': Decimal,
        'BOOLEAN': bool
    }

    def __init__(self, table_ref):
        self.table_ref = table_ref

    def _validate_element(self, element):
        flag_valid_element = True

        for field_name in element:
            if field_name not in self.table_ref.dict_schema:
                continue

            field_dtype = self.table_ref.dict_schema[field_name].field_type
            if field_dtype not in self.DTYPE_MAP:
                continue

            if element[field_name] is None:
                if self.table_ref.dict_schema[field_name].is_nullable is False:
                    yield 'error', (f'[ERROR][VALIDATION] {datetime.now()} [CONSTRAINT ERROR] Field {field_name} must not be NULL - {element}')
                    flag_valid_element = False
                continue
            
            try:
                old_value = element[field_name]
                new_value = self.DTYPE_MAP[field_dtype](old_value)
                element[field_name] = new_value
            except Exception:
                yield 'error', (f'[ERROR][VALIDATION] {datetime.now()} [TYPE ERROR] Failed to cast value {old_value} to {field_dtype} - {element}')
                flag_valid_element = False
            
        if flag_valid_element is True:
            yield 'main', element

    def process(self, element):
        val_result = self._validate_element(element.copy())

        for output_tag, new_element in val_result:
            yield pvalue.TaggedOutput(output_tag, new_element)

def main(argv=None):
    parser = argparse.ArgumentParser()

    parser.add_argument('--src-file', dest='src_file', type=str, help='Input file to process')
    parser.add_argument('--dst-project', dest='dst_project', type=str, default='alx-ds-sandbox')
    parser.add_argument('--dst-dataset', dest='dst_dataset', type=str, default='stn_ecommerce')
    parser.add_argument('--dst-table', dest='dst_table', type=str, default='olist_order_reviews_dataset')
    parser.add_argument('--field-rename-dict', dest='field_rename_dict', type=json.loads, default='{"review_score": "reviewscore"}')
    parser.add_argument('--map-bq-schema', dest='map_bq_schema', type=bool, default=True)

    known_args, pipeline_args = parser.parse_known_args(argv)

    client = bigquery.Client()
    dst_table_ref = client.get_table(f'{known_args.dst_project}.{known_args.dst_dataset}.{known_args.dst_table}')
    dst_table_ref.dict_schema = {field_ref.name: field_ref for field_ref in dst_table_ref.schema}

    beam_options = PipelineOptions()

    with beam.Pipeline() as p:
        parsed_csv = p | 'Read input file' >> read_csv("/home/alexdelara/repos/business/alx_ds/alx-ds-gcp-sbx-e-commerce-store/data/olist_order_reviews_dataset_test.csv")

        csv_pcoll = to_pcollection(parsed_csv)

        if known_args.field_rename_dict is not None:
            csv_pcoll = csv_pcoll | beam.ParDo(RenameSchemaFn(), known_args.field_rename_dict)

        if known_args.map_bq_schema is True:
            mapped_pcoll = csv_pcoll | beam.ParDo(MapBigQuerySchemaFn(dst_table_ref)).with_outputs()

            mapped_pcoll.error | beam.Map(print)
        #     error_pcoll = mapped_pcoll.error
        #     csv_pcoll = mapped_pcoll.valid

        # csv_pcoll | beam.Map(print)

        # csv_pcoll | beam.io.WriteToBigQuery(
        #     pa,
        #     schema=table_schema,
        #     write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
        #     create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED
        # )

if __name__ == '__main__':
  main()
