#!/bin/bash
set -e
export $(grep -v '^#' .env | xargs)
if [ -f stack_outputs.env ]; then
  export $(grep -v '^#' stack_outputs.env | xargs)
else
  echo "stack_outputs.env not found - ALB/target-group/SG IDs will be empty; those steps will be skipped."
fi

# ---------------------------------------------------------------
# NEW: tear down the ALB/ASG/multi-AZ layer first
# ---------------------------------------------------------------

echo "== Deleting Auto Scaling Groups (this also terminates their instances) =="
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name "$UPLOADER_ASG_NAME" --force-delete --region "$AWS_REGION" 2>/dev/null || true
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name "$VIEWER_ASG_NAME" --force-delete --region "$AWS_REGION" 2>/dev/null || true

echo "Waiting for both Auto Scaling Groups to be gone..."
for ASG_NAME in "$UPLOADER_ASG_NAME" "$VIEWER_ASG_NAME"; do
  for i in $(seq 1 20); do
    EXISTING=$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "$ASG_NAME" --region "$AWS_REGION" \
      --query "AutoScalingGroups[0].AutoScalingGroupName" --output text 2>/dev/null || true)
    if [ "$EXISTING" = "None" ] || [ -z "$EXISTING" ]; then
      echo "$ASG_NAME deleted."
      break
    fi
    sleep 15
  done
done

echo "== Deleting the load balancer =="
if [ -n "$ALB_ARN" ]; then
  aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region "$AWS_REGION" 2>/dev/null || true
  aws elbv2 wait load-balancers-deleted --load-balancer-arns "$ALB_ARN" --region "$AWS_REGION" 2>/dev/null || true
fi

echo "== Deleting target groups =="
[ -n "$UPLOADER_TG_ARN" ] && aws elbv2 delete-target-group --target-group-arn "$UPLOADER_TG_ARN" --region "$AWS_REGION" 2>/dev/null || true
[ -n "$VIEWER_TG_ARN" ] && aws elbv2 delete-target-group --target-group-arn "$VIEWER_TG_ARN" --region "$AWS_REGION" 2>/dev/null || true

echo "== Restoring the app security group to its previous-lab state =="
if [ -n "$APP_SECURITY_GROUP_ID" ] && [ -n "$ALB_SECURITY_GROUP_ID" ]; then
  aws ec2 revoke-security-group-ingress --group-id "$APP_SECURITY_GROUP_ID" \
    --protocol tcp --port 3000 --source-group "$ALB_SECURITY_GROUP_ID" --region "$AWS_REGION" >/dev/null 2>&1 || true
  aws ec2 authorize-security-group-ingress --group-id "$APP_SECURITY_GROUP_ID" \
    --protocol tcp --port 3000 --cidr 0.0.0.0/0 --region "$AWS_REGION" >/dev/null 2>&1 || true
fi

echo "== Deleting the ALB security group =="
if [ -n "$ALB_SECURITY_GROUP_ID" ]; then
  aws ec2 delete-security-group --group-id "$ALB_SECURITY_GROUP_ID" --region "$AWS_REGION" 2>/dev/null || true
fi

# ---------------------------------------------------------------
# Safety net: stray standalone instances (e.g. from the old run-instances
# version of the create script) that no ASG owns
# ---------------------------------------------------------------

echo "== Looking for stray standalone instances =="
STRAY_IDS=$(aws ec2 describe-instances --region "$AWS_REGION" \
  --filters "Name=tag:Name,Values=uploader-app,viewer-app" \
            "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId" --output text 2>/dev/null || true)
if [ -n "$STRAY_IDS" ]; then
  echo "Terminating: $STRAY_IDS"
  aws ec2 terminate-instances --instance-ids $STRAY_IDS --region "$AWS_REGION" >/dev/null || true
  aws ec2 wait instance-terminated --instance-ids $STRAY_IDS --region "$AWS_REGION" || true
  echo "Stray instances terminated."
else
  echo "No stray instances found."
fi
rm -f uploader_instance_id.txt viewer_instance_id.txt

# ---------------------------------------------------------------
# Unchanged from the previous lab: launch templates, IAM, S3
# ---------------------------------------------------------------

echo "== Deleting launch templates =="
aws ec2 delete-launch-template --launch-template-name "$UPLOADER_LT_NAME" --region "$AWS_REGION" 2>/dev/null || true
aws ec2 delete-launch-template --launch-template-name "$VIEWER_LT_NAME" --region "$AWS_REGION" 2>/dev/null || true

echo "== Removing IAM instance profiles and roles =="
aws iam remove-role-from-instance-profile --instance-profile-name "$UPLOADER_PROFILE_NAME" \
  --role-name "$UPLOADER_ROLE_NAME" 2>/dev/null || true
aws iam delete-instance-profile --instance-profile-name "$UPLOADER_PROFILE_NAME" 2>/dev/null || true
aws iam delete-role-policy --role-name "$UPLOADER_ROLE_NAME" \
  --policy-name "${UPLOADER_ROLE_NAME}-policy" 2>/dev/null || true
aws iam delete-role --role-name "$UPLOADER_ROLE_NAME" 2>/dev/null || true

aws iam remove-role-from-instance-profile --instance-profile-name "$VIEWER_PROFILE_NAME" \
  --role-name "$VIEWER_ROLE_NAME" 2>/dev/null || true
aws iam delete-instance-profile --instance-profile-name "$VIEWER_PROFILE_NAME" 2>/dev/null || true
aws iam delete-role-policy --role-name "$VIEWER_ROLE_NAME" \
  --policy-name "${VIEWER_ROLE_NAME}-policy" 2>/dev/null || true
aws iam delete-role --role-name "$VIEWER_ROLE_NAME" 2>/dev/null || true

echo "== Emptying and deleting S3 bucket =="
aws s3 rm "s3://$BUCKET_NAME" --recursive --region "$AWS_REGION" 2>/dev/null || true
aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null || true

# Cleaned up last, so a re-run after a partial failure still has the IDs it needs
rm -f stack_outputs.env uploader-lt-data.json viewer-lt-data.json \
  user-data-uploader.sh user-data-viewer.sh \
  uploader-policy.json viewer-policy.json trust-policy.json

echo "Cleanup complete."
