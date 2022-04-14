export WORKFLOW_TEMPLATE_PATH="${1}/workflow_engine/workflow-template.yml"

workflow=$(cat $WORKFLOW_TEMPLATE_PATH | \
sed "s~{{SLACK_CHANNEL_ID}}~${2}~g; \
s~{{SLACK_TOKEN}}~${3}~g; \
s~{{POLARIS_URL}}~${4}~g; \
s~{{POLARIS_TOKEN}}~${5}~g")

# apply the yml with the substituted value
echo "$workflow" > ${1}/workflow_engine/workflow.yml
