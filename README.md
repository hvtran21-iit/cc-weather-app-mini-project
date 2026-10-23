# This is the mini project assignment for ITMS 444-01 Cloud Computing Class.

## In this lab, I learned to:

- Create a web app that uses third party APIs (National Weather Service, Gemini) to inform dress code based on weather in a given area.
- Enforce Least Privilege through role permissions, and Minimize Attack Surface by using AWS' Security Group Reference Feature.
  - Verify role permissions through IAM Simulator.
- Test ALB and ASG against outages to gauge recovery time and failure responses.
- Troubleshoot IAM user permission problems.

### Troubleshooting -- Issues I encountered during implementation

Note: API key does not start with Aiza anymore; rather, it starts with AQ.

1. **Lab instructions does not mention which Gemini model to choose.**

I chose gemini-3.5-flash-lite for cost effectiveness. Set it with export GEMINI_MODEL="gemini-3.5-flash-lite".

2. **IAM Lab user keeps getting implicitly denied from SSM and RDS.**

Add AWS managed permissions to save on customer inline policy limit (max of 2048 bytes): add DynamoDB, EC2FullAccess, RDSFullAccess, SSMFullAccess, AutoScalingFullAccess, IAMFullAccess.

3. **Python3 app_smoke_test.py fails.**

Solution: move the python file into /lab06/testing/ and run from inside the /testing/ directory, since ../stack_outputs.env is within the /lab06/ directory and not within the root (/) directory.

4. **Permission denied when attempting to access weather journal.**

Workaround, add .pem keypair to the repository for lab purposes, but ensure that .gitignore has *.pem included so the keypair is not visible in the repo. Remove the keypair.pem file from the repo before committing as a safeguard.

5. **The itmo-444-544-uploader-role persists after ./delete_weather_stack.sh and ./delete_database.sh execution.**

I had to ask AI to help me resolve this issue. Use the commands below at your own risk, and double check before execution.

```
aws iam delete-role-policy --role-name itmo-444-544-uploader-role --policy-name uploader-put-only
aws iam remove-role-from-instance-profile --instance-profile-name itmo-444-544-uploader-profile --role-name itmo-444-544-uploader-role 2>/dev/null || true
aws iam delete-instance-profile --instance-profile-name itmo-444-544-uploader-profile 2>/dev/null || true
aws iam delete-role --role-name itmo-444-544-uploader-role
```
