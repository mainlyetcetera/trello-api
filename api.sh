#!/bin/bash
# change this according to where bash is in the chosen container eventually

# this script lets me see my projects, their importance, urgency, and to prioritize one
# then i can see the "next steps" of each project, particularly the prioritized one
# this will expand quite a bit to let me work with the tasks, but for now, this is a good mvp

# mvp is seeing next task for a project

# functions

# take name of list to pass to cat and output as json
# $1: name to cat and build json
# $2: pretty name
# don't forget that i'll need something like this to grab next tasks - this is just grabbing id's
# so is really just appropriate for the projects
# tasks need next task, too...
# yeah, only thing is to also add build in next tasks, then this _should_ be fine for both project id's and tasks... i think...

build_task_list () {
    echo "[INFO]: grabbin' cards from $2"

    echo 'https://api.trello.com/1/lists/{yourList}/cards?fields=name,labels&key={yourKey}&token={yourToken}' | sed "s/{yourKey}/$(cat key.txt)/g" | sed "s/{yourToken}/$(cat token.txt)/g" | sed "s/{yourList}/$(cat $1.txt)/g" | xargs -I {} curl -s {} | jq '[.[] | { id, name, labels: [.labels[] | select(.name | startswith("id") or startswith("next task")) | { id, name }] }]' > $1.json
}

# take full name of file and "pretty" name
# $1: file name, _including extension!_
# $2: pretty name
# outputs msgs and exits if file not found

check_for_file () {
    echo "[INFO]: checkin' for $2's list"
    f=$(find . -maxdepth 1 -name $1)
    ff=$(echo -n $f | wc -w)

    if [[ $ff -eq 0 ]] 
    then
        echo "[ERROR]: did not find $2's list"
        exit 1
    else
        echo "[INFO]: found $2's list at $f"
    fi
}

# $1: target file name
# $2: pretty name for stdout
# $3: starts with

build_id_file () {
    # thinking this control-flows to finding for a board, which requires me as a member, and a list, which is held by the board
    # this holds both build fn's, and calls as appropriate
    # to start, start with list, and build in board when i circle back to that
    echo "[INFO]: building id file for $2"

    echo 'https://api.trello.com/1/boards/{id}/lists?fields=name&key={apiKey}&token={apiToken}' | sed "s/{apiKey}/$(cat key.txt)/g" | sed "s/{apiToken}/$(cat token.txt)/g" | sed "s/{id}/$(cat board.txt)/g" | xargs -I {} curl -s --header 'Accept: application/json' {} | jq ".[] | select(.name | startswith(\"$3\")) | .id" | sed 's/"//g' > $1
}

check_for_file 'key.txt' 'api key'
check_for_file 'token.txt' 'api token'
check_for_file 'board.txt' 'board'
check_for_file 'project_ids.txt' "project id's"

build_task_list 'project_ids' "project id's" 

check_for_file 'project_ids.json' "project id's"

build_id_file 'waitin_on.txt' "waitin' on" 'Waitin'
check_for_file 'waitin_on.txt' "waitin' on"
build_task_list 'waitin_on' "waitin' on"
check_for_file 'waitin_on.json' "waitin' on"

build_id_file 'sprint_hold.txt' 'sprint hold' 'Sprint Hold'
check_for_file 'sprint_hold.txt' 'sprint hold'
build_task_list 'sprint_hold' 'sprint hold'
check_for_file 'sprint_hold.json' 'sprint hold'

build_task_list 'shit_to_get_done' 'shit to get done'
check_for_file 'shit_to_get_done.json' 'shit to get done'

build_task_list 'to_do_asap' 'to do asap'
check_for_file 'to_do_asap.json' 'to do asap'

build_task_list 'workin_on' "workin' on"
check_for_file 'workin_on.json' "workin' on"

echo "[INFO]: combinin' output and searchin' for next tasks"

jq -s "{ project_ids: . }" project_ids.json > labeled_ids.json
jq -s "{ tasks: . }" shit_to_get_done.json to_do_asap.json workin_on.json waitin_on.json sprint_hold.json > tasks.json
jq -s . labeled_ids.json tasks.json > total.json

echo "[INFO]: showin' projects and next tasks!"

p=$(jq -s '[.[][] | select(.labels[].name | startswith("id"))]' project_ids.json)
pl=$(echo $p | jq 'length')

t=$(jq -s '[.[].tasks[] | .[] | select(.labels[].name == "next task")]' tasks.json)
tl=$(echo $t | jq 'length')

if [[ -f 'anime_cat_girl.txt' ]]; then
    echo "[INFO]: cleanin' up anime cat girl!"
    rm anime_cat_girl.txt
fi

touch anime_cat_girl.txt

for (( i = 0; i < pl; i++ )); 
do
    pid=$(echo $p | jq ".[$i].id")
    plid=$(echo $p | jq ".[$i].labels[] | select(.name | startswith(\"id\")).id")
    pname=$(echo $p | jq ".[$i].name" | sed 's/"//g' | sed 's/\\//g')
    for (( j = 0; j < tl; j++ )); 
    do
        tlid=$(echo $t | jq ".[$j].labels[] | select(.name | startswith(\"id\")).id")

        if [[ $tlid == $plid ]]; then
            tid=$(echo $t | jq ".[$j].id")
            tname=$(echo $t | jq ".[$j].name" | sed 's/"//g' | sed 's/\\//g')
            echo "* $pname's next task is: $tname" >> anime_cat_girl.txt
        fi
    done
done

echo
echo '[RESULTS]:'
echo
cat anime_cat_girl.txt
