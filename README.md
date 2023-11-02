# Salesforce Bitbucket Pipelines CI/CD

# **How does it work?**

The deployment automation is done by the pipelines of the Github Actions and this is configured on the file `pr-branch.yml` and `push-branch.yml`, in this file you can add any bash commands that you want, for our deployment we can resume the steps like below:

- Permissions and additional installations
    - Python and libs (necessary to identify some file names)
    - SFDX plugin delta (identify the changes of salesforce metadata E.g. Apex classes, Custom fields, Triggers, etc.)
    - PMD (Static code analyzer)
- SFDX Authentication by JWT
    - You will have to create a conntected app and a single signed certificate to attach to this certificate
    - You can set this with a big timestamp so the token will not be revoked anytime soon and the pipelin will not fail due to refreshed token problem.
- SFDX plugin delta
    - Identify changed files that can be deployed and build the `package.xml`
    - If validation
        - `-to $GITHUB_SHA --from origin/$GITHUB_BASE_REF`(compare all the commits to the destination branch)
        - $GITHUB_SHA: The commit SHA that triggered the workflow. The value of this commit SHA depends on the event that triggered the workflow. For more information see github doc.
    - If deployment
        - `-to HEAD --from $GIT_EVENT_BEFORE`  (compare each commit with the previous)
        - $GIT_EVENT_BEFORE = {{github.event.before}}: The last git sha pushed to origin on branch reference.
- PMD on the Apex classes that changed
- Identify test classes
    - Check each apex class changed and try to find the respective test class with the suffix **“_Test”**
- Validation (SFDX)
    - Changes in classes?
        - If yes
            - Run deployment validation with specified tests
        - If no
            - Run deployment validation without any tests
    - Nothing changed in the folder `force-app`
- Deploy (SFDX)
    - Changes in classes?
        - If yes
            - Run real deployment with specified tests
        - If no
            - Run real deployment without any tests
    - Nothing changed in the folder `force-app`
        - It will not deploy any SFDC metadata

If you want to skip the pipeline automation, add a **[skip ci]** inside the commit message

# **Proposed deployment flow**
- bugfixes or features must be created from feature/dev
- hotfixes must be created from main

# Acknowledgments
I want to kudos for [@willianmatheus98](https://www.github.com/willianmatheus98)  which helped me a lot on defined this process.


![deployment flow](/assets/FLOW%20DEPLOYMENT%20SALESFORCE.png)
![deployment flow](/assets/Salesforce%20branch%20deployment.png)
