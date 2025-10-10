#!/bin/bash

#삭제 대상 로그 파일 경로
LOG_DIRS="/usr/local/kafka/logs"

#로그 Prefix
FILE_PREFIX="server.log"
FILE_PREFIX2="controller.log"

#삭제일(30day)
CUTOFF_DATE=$(date -d "-30 days" +%Y-%m-%d)

#로그 파일 저장
LOGFILE="/usr/local/kafka/logs/server-named-log-cleanup.log"


echo "[$(date)] Named log cleanup started" >> "$LOGFILE"

cd $LOG_DIRS

#server.log deleting
for file in ${FILE_PREFIX}.*; do
    DATE_PART=$(echo "$file" | grep -oP '\d{4}-\d{2}-\d{2}')
    if [[ -n "$DATE_PART" ]]; then
        if [[ "$DATE_PART" < "$CUTOFF_DATE" ]]; then
		#echo $file
		echo "Deleting $file (Date: $DATE_PART < Cutoff: $CUTOFF_DATE)" >> "$LOGFILE"
            rm -f "$file"
        fi
    fi
done

#controller.log deleting
for file in ${FILE_PREFIX2}.*; do
    DATE_PART=$(echo "$file" | grep -oP '\d{4}-\d{2}-\d{2}')
    if [[ -n "$DATE_PART" ]]; then
        if [[ "$DATE_PART" < "$CUTOFF_DATE" ]]; then
		#echo $file
		echo "Deleting $file (Date: $DATE_PART < Cutoff: $CUTOFF_DATE)" >> "$LOGFILE"
            rm -f "$file"
        fi
    fi
done

echo "[$(date)] Named log cleanup completed" >> "$LOGFILE"
