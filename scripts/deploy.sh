echo "-------------------changed-sources/package/package.xml file---------------------"
less -FX changed-sources/package/package.xml
echo $'\n'
echo "\n-------------------changed-sources/package/package.xml file---------------------"
echo "-------------------DESTINATION BRANCH IS: [$GITHUB_REF_NAME]---------------------"
echo $'\n'

metalistSfdx=$(git diff --name-only HEAD $GIT_EVENT_BEFORE  -- force-app/main/default | tr '\n' ',' | sed 's/.$//' )

if [ ! -z "$(<TEST_CLASSES_MERGED)" ]
then
    echo "THIS WILL DEPLOY WITH SPECIFIED TEST CLASSES"
    echo "-------------------TEST CLASSES: [$(<TEST_CLASSES_MERGED)]---------------------"
    sfdx force:source:deploy -x changed-sources/package/package.xml --target-org sfdx-ci -l RunSpecifiedTests -r "$(<TEST_CLASSES_MERGED)" --verbose
elif [ -z "$(<TEST_CLASSES_MERGED)" ] && [ ! -z "$metalistSfdx" ] && [ "$GITHUB_REF_NAME" != "main" ]
then
    echo "THIS WILL DEPLOY WITHOUT ANY TEST (SANDBOX)"
    sfdx force:source:deploy -x changed-sources/package/package.xml --target-org sfdx-ci --verbose
elif [ -z "$(<TEST_CLASSES_MERGED)" ] && [ ! -z "$metalistSfdx" ] && [ "$GITHUB_REF_NAME" == "main" ]
then
    echo "THIS WILL DEPLOY RUNNING LOCAL TESTS (PRODUCTION)"
    # In prod we need to run some test class
    sfdx force:source:deploy -x changed-sources/package/package.xml --target-org sfdx-ci -l RunLocalTests --verbose
else
	echo "No SF changes found"
fi