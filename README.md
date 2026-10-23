# This is the mini project assignment for ITMS 444-01 Cloud Computing Class.

## In this lab, I learned to:

- Create a web app that uses third party APIs (National Weather Service, Gemini) to inform dress code based on weather in a given area
- Enforce Least Privilege through role permissions, and Minimized Attack Surface by using AWS' Security Group Reference Feature
  - Verified role permissions through IAM Simulator
- Test ALB and ASG against outages to gauge recovery time and failure responses
- Troubleshooted IAM user permission problems

### Troubleshooting -- Issues I encountered during implementation

Note: API key does not start with Aiza anymore; rather, it starts with AQ.

1. ** Lab instructions does not mention which Gemini model to choose. **
  a. I chose gemini-3.5-flash-lite for cost effectiveness. Set it with export GEMINI_MODEL="gemini-3.5-flash-lite".
2. ** IAM Lab user keeps getting implicitly denied from SSM and RDS. **
  a. Add AWS managed permissions to save on customer inline policy limit (max of 2048 bytes): add DynamoDB, EC2FullAccess, RDSFullAccess, SSMFullAccess, AutoScalingFullAccess, IAMFullAccess.
