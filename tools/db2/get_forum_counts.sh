#!/bin/bash

if [[ -n "${1}" ]]; then
    forumName="${1}"
fi

t="forum.df_node"

# Connect to FORUM
db2 connect to forum >/dev/null

if [[ -n "${forumName}" ]]; then
    # Get the specified forum UUID
    forumUuids=($(db2 -x "select ${t}.nodeuuid from ${t} where ${t}.nodeuuid = ${t}.forumuuid and ${t}.name = '${forumName}'"))
else
    # Get an array of all forum UUIDs
    forumUuids=($(db2 -x "select ${t}.nodeuuid from ${t} where ${t}.nodeuuid = ${t}.forumuuid and ${t}.delstate = 0 and ${t}.state = 0"))
fi

# Exit if no forums were found
if (( "${#forumUuids[@]}" == 0 )); then
    if [[ -n "${forumName}" ]]; then
        printf "No forum exists named ${forumName}\n"
    else
        printf "No forums found\n"
    fi
    exit 0
fi

# For each forum UUID, get the topic UUIDs
for forumUuid in "${forumUuids[@]}"; do

    # Get the count of all topics in the forum
    topicCount=$(($(db2 -x \
        "select count(*) from ${t} where ${t}.forumUuid = '${forumUuid}' and ${t}.nodeuuid = ${t}.topicid and ${t}.delstate = 0 and ${t}.state = 0"))) 

    # Get the count of all messages in the forum
    messageCount=$(($(db2 -x "select count(*) from ${t} where ${t}.forumuuid = '${forumUuid}' and ${t}.delstate = 0 and ${t}.state = 0")))
    # Subtract the forum itself
    messageCount=$((${messageCount}-1))

    forumName=$(db2 -x "select substr(${t}.name,1,64) from ${t} where ${t}.nodeuuid = '${forumUuid}'")
    forumName="$(echo -e "${forumName}" | sed -e 's/[[:space:]]*$//')"

    printf "Forum: [${forumName}] Topics: [${topicCount}] Messages: [${messageCount}]\n"

done
