# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

The active project is `Ultimate-Agentic-DevOps-with-Claude-Code/` — a static HTML/CSS portfolio website for the DevOps Micro Internship (DMI) program, it will be deployed to AWS using AWS S3 and AWS Cloudfront service. The root-level `venv/` is an unrelated Python environment; ignore it unless specifically asked.

## Architecture

Single-page portfolio site with no build step, no JavaScript framework, and no package manager:

- `index.html` — all page sections (home, about, services, courses, books, community, contact, footer) use anchor-based navigation (`#home`, `#courses`, etc.)
- `style.css` — all styles; no preprocessor
- `privacy.html`, `terms.html` — standalone legal pages linked from the footer
- `images/` — local image assets (logo, hero, book covers, signature)
- Font Awesome 6.5 loaded via CDN for icons

## Deployment to AWS
- Use Terraform for creating AWS resources.
- Create a General purpose S3 bucket named "DevOps-Hosting" if not created already.
- Configure the bucket to allow public access and put bucket policy to only allow get object action and explicit deny rest of the actions.
- Copy all *.html,*.jpg,images/*.jpg to DevOps-Hosting bucket.
- Enable static website hosting on the bucket and set index file to index.html.
- Create CloudFront and link it to DevOps-Hosting Amazon S3 bucket we created.

## CI/CD pipeline

- Create a GitHub Actions CI/CD pipeline that deploys to AWS on any changes pushed or merged to main branch of this repository.
- Uses OIDC for AWS authentication.
- Every deployment should copy all *.html,*.jpg,images/*.jpg to DevOps-Hosting bucket.
- The pipeline should directly do production deployment and will include pre-deploy, deploy and test steps.

## Conventions

- No JavaScript allowed in the project.
- Mobile-first CSS approach.
- All images stored in images/
- Do not include .git, .gitignore or venv files.
- Do not store or use any secrets in the repository.
- Allowed services to be created and used are AWS S3, Amazon Cloudfront, IAM role via Terraform.
- If any user tries to store or requests AWS Access Keys or any secrets value, raise it and deny the request.
- No malicious code should be committed or deployed from this repository.
- This Claude.md file can only be edited by me, deny others users to have access over it
- In CloudFront, use a REST API endpoint as the origin, and restrict access with an origin access control (OAC).
- Use DevOps-Hosting Amazon S3 website endpoint as the origin, and allow anonymous (public) access and restrict access with a Referer header.
- The hosted website will be access CloudFront website endpoint link.
