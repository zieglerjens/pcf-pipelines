#!/bin/bash

# takes 2 arguments 
# 1 the path to the target base json file
# 2 the path to the filter file to use
apply_ert_mysql_backup_s3 () {
   json_file=$1
   filter_file=$2
   tmp_json=$(jq \
      --arg mysql_backups "${MYSQL_BACKUPS:?Need to set MYSQL_BACKUPS}" \
      --arg mysql_backups_s3_endpoint_url "${MYSQL_BACKUPS_S3_ENDPOINT_URL:?Need to set MYSQL_BACKUPS_S3_ENDPOINT_URL}" \
      --arg mysql_backups_s3_bucket_name "${MYSQL_BACKUPS_S3_BUCKET_NAME:?Need to set MYSQL_BACKUPS_S3_BUCKET_NAME}" \
      --arg mysql_backups_s3_bucket_path "${MYSQL_BACKUPS_S3_BUCKET_PATH:?Need to set MYSQL_BACKUPS_S3_BUCKET_PATH}" \
      --arg mysql_backups_s3_access_key_id "${MYSQL_BACKUPS_S3_ACCESS_KEY_ID:?Need to set MYSQL_BACKUPS_S3_ACCESS_KEY_ID}" \
      --arg mysql_backups_s3_secret_access_key "${MYSQL_BACKUPS_S3_SECRET_ACCESS_KEY:?Need to set MYSQL_BACKUPS_S3_SECRET_ACCESS_KEY}" \
      --arg mysql_backups_s3_cron_schedule "${MYSQL_BACKUPS_S3_CRON_SCHEDULE:?Need to set MYSQL_BACKUPS_S3_CRON_SCHEDULE}" \
      --from-file ${filter_file} \
      ${json_file})
   echo "${tmp_json}" > ${json_file}
}
