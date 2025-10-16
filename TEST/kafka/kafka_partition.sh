#!/bin/bash

#설정 변수
BOOTSTRAP_SERVERS="10.240.34.200:9092,10.240.34.202:9092,10.240.34.203:9092"
TOPIC_FILTER=".*"
KAFKA_BIN="/usr/local/kafka/bin"
JSON_FIlE="./topics.json"
BROKER_LIST="1,2,3"

touch ./topics.json

#모든 토픽 가져오기
echo "Fetching topics..."

TOPICS=$($KAFKA_BIN/kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVERS --list | grep -E "$TOPIC_FILTER")

if [[ -z "$TOPICS" ]]; then
    echo "No topics found matching filter: $TOPIC_FILTER"
    exit 1
fi

#토픽 목록 임시저장
echo "$TOPICS" > ./topic-list.txt

cat <<EOF > $JSON_FIlE
{
    "topics": [
EOF

total=$(wc -l < topic-list.txt)

while IFS= read -r line; do
    count=$((count + 1))
    if [[ $count -eq $total ]]; then
        echo -e "            {\"topic\": \"$line\"}" >> topics.json

    else
        echo -e "            {\"topic\": \"$line\"}," >> topics.json
    fi
done < topic-list.txt
  
cat <<EOF >> $JSON_FIlE
    ],
    "version":1
}
EOF

#reassignment.json 생성
$KAFKA_BIN/kafka-reassign-partitions.sh --bootstrap-server $BOOTSTRAP_SERVERS --topics-to-move-json-file topics.json --broker-list "$BROKER_LIST" --generate > reassignment.json

#reassignmet.json 수정
sed '/Current partition replica assignment/,/Proposed partition reassignment configuration/d' reassignment.json > reassignment2.json

#재할당 실행
$KAFKA_BIN/kafka-reassign-partitions.sh --bootstrap-server $BOOTSTRAP_SERVERS --reassignment-json-file reassignment2.json --execute
echo "partition reassignment completed"

#leader election 실행 
$KAFKA_BIN/kafka-leader-election.sh --bootstrap-server $BOOTSTRAP_SERVERS --election-type preferred --all-topic-partitions
echo "leader reassignment completed"

#생성된 Json 파일 삭제
rm -f ./reassignment.json
rm -f ./reassignment2.json
rm -f ./topics.json
rm -f ./topic-list.txt

