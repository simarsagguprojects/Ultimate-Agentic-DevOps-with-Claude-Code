---
name: security-audit
description: Ensures defined security practises followed in the project and during deployment of the project
allowed-tools: bash, grep, write, edit, git full access, tf-plan, deploy
disable-model-invocation: false
---
Scan the repository including .md files and GitHub environment variables to detect if any passwords, API keys, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS STS token are stored.
Check who has edited the CLAUDE.md and all .md files in .CLAUDE/SKILLS, if it is not by me, then raise an alert.
Ensure secret scanning tool of GitHub is enabled, scanning this repository and sending alerts if the detected secret(s) is still active.
Try adding code to any *.html files in Ultimate-Agentic-DevOps-with-Claude-Code folder, commit and push the code. Then, run deploy skill to check if we can deploy the updated code.
Run terraform plan and in the terraform plan file:
1. check if only created/updated services are AWS S3, AWS CloudFront and IAM role. 
2. check if AWS S3 has bucket policy.
3. check and alert if the IAM role policy has access over other services except AWS S3 and AWS CloudFront.
4. check if the CloudFront, use a REST API endpoint as the origin, and restrict access with an origin access control (OAC).
5. check if DevOps-Hosting Amazon S3 website endpoint is used as the origin in the CloudFront resource created, and allow anonymous (public) access and restrict access with a Referer header.

