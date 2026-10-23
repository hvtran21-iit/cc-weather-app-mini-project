# This is the mini project assignment for ITMS 444-01 Cloud Computing Class.

## In this lab, I learned to:

- Create a web app that uses third party APIs (National Weather Service, Gemini) to inform dress code based on weather in a given area.
- Enforce Least Privilege through role permissions, and Minimized Attack Surface by using AWS' Security Group Reference Feature.
  - Verified role permissions through IAM Simulator.
- Test ALB and ASG against outages to gauge recovery time and failure responses.
- Troubleshooted IAM user permission problems.

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
