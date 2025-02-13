"""
python3 gcs_csv_to_bq.py \
  --job_name test-$USER \
  --project alx-ds-sandbox \
  --region us-east1 \
  --runner DataflowRunner \
  --staging_location gs://alx-ds-ecommerce/stn/stg/ \
  --temp_location gs://alx-ds-ecommerce/stn/tmp/ \
  --save_main_session true \
  -S gs://alx-ds-ecommerce/raw/data/olist_order_reviews_dataset_test.csv \
  -P alx-ds-sandbox \
  -D stn_ecommerce \
  -T olist_order_reviews_dataset \
  -L gs://alx-ds-ecommerce/stn/log/
"""

import json
import argparse
from datetime import datetime
import apache_beam as beam
from apache_beam import pvalue
from google.cloud import bigquery
from decimal import Decimal
from dateutil.parser import parse
from typing import List

from apache_beam.dataframe.io import read_csv
from apache_beam.dataframe.convert import to_pcollection

from apache_beam.options.pipeline_options import PipelineOptions


class RenameSchemaFn(beam.DoFn):
    def process(self, element, field_rename):
        dict_element = element._asdict()

        for old_name, new_name in field_rename.items():
            if old_name in dict_element:
                dict_element[new_name] = dict_element.pop(old_name)

        yield dict_element

class MapBigQuerySchemaFn(beam.DoFn):
    TIMESTAMP_FMT = '%Y-%m-%d %H:%M:%S.%f UTC'
    DATETIME_FMT = '%Y-%m-%d %H:%M:%S'
    DATE_FMT = '%Y-%m-%d'
    TIME_FMT = '%H:%M:%S'

    def __init__(self, dict_schema, dayfirst_fields, yerafirst_fields):
        self.dict_schema = dict_schema
        self.dayfirst_fields = dayfirst_fields
        self.yearfirst_fields = yerafirst_fields

        self.DTYPE_MAP = {
            'STRING': lambda field: self.__cast_from_data_type(field, str),
            'INTEGER': lambda field: self.__cast_from_data_type(field, int),
            'FLOAT': lambda field: self.__cast_from_data_type(field, float),
            'BOOLEAN': lambda field: self.__cast_from_data_type(field, bool),
            'NUMERIC': lambda field: self.__cast_from_data_type(field, Decimal),
            'TIMESTAMP': lambda field, **kwargs: self.__parse_datetime_to_string_format(field, self.TIMESTAMP_FMT, **kwargs),
            'DATE': lambda field, **kwargs: self.__parse_datetime_to_string_format(field, self.DATETIME_FMT, **kwargs),
            'TIME': lambda field: self.__parse_datetime_to_string_format(field, self.TIME_FMT),
            'DATETIME': lambda field, **kwargs: self.__parse_datetime_to_string_format(field, self.DATETIME_FMT, **kwargs),
        }
    
    def __cast_from_data_type(self, field, data_type):
        new_field = data_type(field)
        return new_field
    
    def __parse_datetime_to_string_format(self, field, output_format, dayfirst=False, yearfirst=False):
        parsed_ts = parse(field, dayfirst=dayfirst, yearfirst=yearfirst)
        new_field = parsed_ts.strftime(output_format)
        return new_field

    def __validate_element(self, element):
        flag_valid_element = True
        dtype_map_kwargs = {}

        for field_name in element:
            if field_name not in self.dict_schema:
                continue

            if element[field_name] is None:
                if self.dict_schema[field_name].is_nullable is False:
                    yield 'log', (f"[ERROR][VALIDATION] {datetime.now()} [CONSTRAINT_ERROR] Field '{field_name}' must not be NULL - {element}")
                    flag_valid_element = False
                continue

            field_dtype = self.dict_schema[field_name].field_type
            if field_dtype not in self.DTYPE_MAP:
                yield 'log', (f"[WARNING][VALIDATION] {datetime.now()} [NOT_IMPLEMENTED] Skipping '{field_name}' validation. Data type {field_dtype} is not implemented - {element}")
                continue

            if field_name in self.dayfirst_fields:
                dtype_map_kwargs.setdefault('dayfirst', True)

            if field_name in self.yearfirst_fields:
                dtype_map_kwargs.setdefault('yearfirst', True)
            
            try:
                old_value = element[field_name]
                new_value = self.DTYPE_MAP[field_dtype](old_value, **dtype_map_kwargs)
                element[field_name] = new_value
            except Exception:
                yield 'log', (f"[ERROR][VALIDATION] {datetime.now()} [TYPE_ERROR] Failed to cast '{field_name}' value {repr(old_value)} to {field_dtype} - {element}")
                flag_valid_element = False
            
        if flag_valid_element is True:
            yield 'main', element

    def process(self, element):
        val_result = self.__validate_element(element.copy())

        for output_tag, new_element in val_result:
            yield pvalue.TaggedOutput(output_tag, new_element)

def main(argv: List[str] = None) -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument('-S', '--src-file', dest='src_file', type=str, required=True, help='Cloud Storage loaction of the .csv file in format gs://path/to/file.csv')
    parser.add_argument('-P', '--dst-project', dest='dst_project', required=True, type=str, help='Name of the Google Cloud project where the output dataset and table exist')
    parser.add_argument('-D', '--dst-dataset', dest='dst_dataset', required=True, type=str, help="Name of the output Big Query dataset")
    parser.add_argument('-T', '--dst-table', dest='dst_table', type=str, required=True, help='Name of the output Big Query table')
    parser.add_argument('-L', '--dst-log', dest='dst_log', type=str, required=True, help='Cloud Storage location for the output logs in format gs://path/to/output/logs/')
    parser.add_argument('-f', '--field-rename', dest='field_rename', type=json.loads, default={}, help="""JSON format string to rename the .csv file columns. E.g '{"oldname1":"newname1","oldname2":"newname2"}'""")
    parser.add_argument('-d', '--dayfirst-fields', dest='dayfirst_fields', type=str, nargs='*', default=[], help='Date format fields to be interpreted with their first digits as the day, separated by spaces. E.g. field1 field2 field3')
    parser.add_argument('-y', '--yearfirst-fields', dest='yearfirst_fields', type=str, nargs='*', default=[], help='Date format fields to be interpreted with their first digits as the year, separated by spaces. E.g. field1 field2 field3')
    parser.add_argument('-w', '--write-disposition', dest='write_disposition', type=str, choices=['WRITE_APPEND', 'WRITE_TRUNCATE', 'WRITE_EMPTY'], default='WRITE_APPEND', help='Write disposition to use for the output table')

    known_args, pipeline_args = parser.parse_known_args(argv)

    client = bigquery.Client()
    dst_table_ref = client.get_table(f'{known_args.dst_project}.{known_args.dst_dataset}.{known_args.dst_table}')
    dict_schema = {field_ref.name: field_ref for field_ref in dst_table_ref.schema}

    default_job_id = f'{known_args.dst_project}_{known_args.dst_dataset}_{known_args.dst_table}_{datetime.now().strftime('%Y%m%d-%H%M%S%.f')}'

    pipeline_options = PipelineOptions(pipeline_args)

    with beam.Pipeline(options=pipeline_options) as p:
        parsed_csv = p | 'Read input file' >> read_csv(known_args.src_file)

        raw_pcoll = to_pcollection(parsed_csv)

        dict_pcoll = raw_pcoll | beam.ParDo(
            RenameSchemaFn(),
            known_args.field_rename
        )

        mapped_pcoll = dict_pcoll | beam.ParDo(
            MapBigQuerySchemaFn(
                dict_schema,
                known_args.dayfirst_fields,
                known_args.yearfirst_fields
            )
        ).with_outputs()

        output_pcoll = mapped_pcoll.main
        log_pcoll = mapped_pcoll.log

        output_pcoll | beam.io.WriteToBigQuery(
            table=f'{known_args.dst_project}:{known_args.dst_dataset}.{known_args.dst_table}',
            schema={'fields': [{'name': field_ref.name, 'type': field_ref.field_type, 'mode': field_ref.mode} for field_ref in dst_table_ref.schema]},
            write_disposition=known_args.write_disposition,
            create_disposition=beam.io.BigQueryDisposition.CREATE_NEVER,
        )

        log_pcoll | beam.io.textio.WriteToText(f'{known_args.dst_log}{beam.io.gcp.gce_metadata_util.fetch_dataflow_job_id() or default_job_id}', file_name_suffix=".log")

if __name__ == '__main__':
  main()
