#!/bin/bash

# takes 2 arguments 
# 1 the path to the target base json file
# 2 the path to the filter file to use
apply_ert_mysql_backup_scp () {
   json_file=$1
   filter_file=$2
   tmp_json=$(jq \
      --arg mysql_backups "${MYSQL_BACKUPS:?Need to set MYSQL_BACKUPS}" \
      --arg mysql_backups_scp_server "${MYSQL_BACKUPS_SCP_SERVER:?Need to set MYSQL_BACKUPS_SCP_SERVER}" \
      --arg mysql_backups_scp_port "${MYSQL_BACKUPS_SCP_PORT:?Need to set MYSQL_BACKUPS_SCP_PORT}" \
      --arg mysql_backups_scp_user "${MYSQL_BACKUPS_SCP_USER:?Need to set MYSQL_BACKUPS_SCP_USER}" \
      --arg mysql_backups_scp_key "${MYSQL_BACKUPS_SCP_KEY:?Need to set MYSQL_BACKUPS_SCP_KEY}" \
      --arg mysql_backups_scp_destination "${MYSQL_BACKUPS_SCP_DESTINATION:?Need to set MYSQL_BACKUPS_SCP_DESTINATION}" \
      --arg mysql_backups_scp_cron_schedule "${MYSQL_BACKUPS_SCP_CRON_SCHEDULE:?Need to set MYSQL_BACKUPS_SCP_CRON_SCHEDULE}" \
      --from-file ${filter_file} \
      ${json_file})
   echo "${tmp_json}" > ${json_file}
}
