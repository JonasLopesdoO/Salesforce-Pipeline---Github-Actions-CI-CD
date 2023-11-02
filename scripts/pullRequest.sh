sfdx --version
echo "-------------------DESTINATION BRANCH IS: [$GITHUB_BASE_REF]---------------------"

if [ $GITHUB_BASE_REF  == "dev" ]
then 
    validationEnv="DEV"
    consumerKey=$SFDC_DEV_CONSUMER_KEY
    username=$SFDC_DEV_USERNAME
    loginUrl=$SFDC_DEV_INSTANCE_URL
elif [ $GITHUB_BASE_REF  == "uat" ] 
then
    validationEnv="UAT"
    consumerKey=$SFDC_UAT_CONSUMER_KEY
    username=$SFDC_UAT_USERNAME
    loginUrl=$SFDC_UAT_INSTANCE_URL
elif [ $GITHUB_BASE_REF  == "main" ]
then
    validationEnv="PROD"
    consumerKey=$SFDC_PROD_CONSUMER_KEY
    username=$SFDC_PROD_USERNAME
    loginUrl=$SFDC_PROD_INSTANCE_URL
else
    echo "branch isn't mapped yet"
    exit 0
fi

echo "-------------------VALIDATION ON ENVIRONMENT: [$validationEnv]---------------------"

# Pull Request
git fetch origin $GITHUB_BASE_REF --depth=1
metalistSF=$( git diff --name-only origin/$GITHUB_BASE_REF $GITHUB_SHA -- force-app/main/default | tr '\n' ',' | sed 's/.$//' )

if [ ! -z "$metalistSF" ]
then
    ./scripts/additionalInstallations.sh
    # This is the key of the created single sign certificate for the connected app, you can use the same certificate between
    # the apps in different sandboxes. Even though I didn't have a time to figure it out a more safe way to store that, you
    # should store it in a safe place, not in the folder accessible through the repo.
    sfdx force:auth:jwt:grant --client-id $consumerKey --username $username --jwt-key-file keys/salesforce.key --set-default-dev-hub --alias sfdx-ci --instance-url $loginUrl
    mkdir changed-sources
    sfdx sgd:source:delta -s force-app --to $GITHUB_SHA --from "origin/$GITHUB_BASE_REF" --output ./changed-sources --generate-delta
    
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

    echo "-----------------------------------------------------------------------------"

    ./scripts/getTestClassesName.sh
    ./scripts/validateDeploy.sh
else 
    echo "No SF changes found"
fi