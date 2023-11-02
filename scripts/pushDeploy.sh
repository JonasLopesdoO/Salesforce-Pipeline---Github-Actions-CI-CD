
sfdx --version
echo "-------------------DESTINATION BRANCH IS: [$GITHUB_REF_NAME]---------------------"

if [ $GITHUB_REF_NAME  == "dev" ]
then 
    deploymentEnv="DEV"
    consumerKey=$SFDC_DEV_CONSUMER_KEY
    username=$SFDC_DEV_USERNAME
    loginUrl=$SFDC_DEV_INSTANCE_URL
elif [ $GITHUB_REF_NAME  == "uat" ] 
then
    deploymentEnv="UAT"
    consumerKey=$SFDC_UAT_CONSUMER_KEY
    username=$SFDC_UAT_USERNAME
    loginUrl=$SFDC_UAT_INSTANCE_URL
elif [ $GITHUB_REF_NAME  == "main" ]
then
    deploymentEnv="PROD"
    consumerKey=$SFDC_PROD_CONSUMER_KEY
    username=$SFDC_PROD_USERNAME
    loginUrl=$SFDC_PROD_INSTANCE_URL
else
    echo "branch isn't mapped yet"
    exit 0
fi

echo "-------------------DEPLOYMENT ON ENVIRONMENT: [$deploymentEnv]---------------------"

# Pull Request
git fetch origin $GITHUB_REF_NAME --depth=1
metalistSF=$( git diff --name-only HEAD $GIT_EVENT_BEFORE -- force-app/main/default | tr '\n' ',' | sed 's/.$//' )

if [ ! -z "$metalistSF" ]
then
    ./scripts/additionalInstallations.sh
    sfdx force:auth:jwt:grant --client-id $consumerKey --username $username --jwt-key-file keys/salesforce.key --set-default-dev-hub --alias sfdx-ci --instance-url $loginUrl
    mkdir changed-sources
    sfdx sgd:source:delta -s force-app --to HEAD --from $GIT_EVENT_BEFORE --output ./changed-sources --generate-delta
    
    if [ ! -d "changed-sources/force-app" ]; then
        echo "No deploy needed, only deletions"
        exit 0
    fi

    # ===Make sure there is no PMD error with a high priority===
    pmd/pmd-bin-6.42.0/bin/run.sh pmd --minimum-priority $PMD_MINIMUM_PRIORITY --dir './changed-sources' --rulesets pmd/pmd_rule_ref.xml --format textcolor -language apex
    
    # $? is the return of the pmd violations, if 0 no violations, if different than 0, there are violations
    retVal=$?
    if [ $retVal -ne 0 ]; then
        exit 1
    fi

    ./scripts/getTestClassesName.sh
    ./scripts/deploy.sh
else 
    echo "No SF changes found"
fi