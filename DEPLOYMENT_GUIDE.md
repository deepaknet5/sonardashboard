# Deployment Guide for Sonar Dashboard to AWS

This guide covers the steps to provisions the PostgreSQL database on AWS RDS using Terraform, and how to containerize and deploy the Python scripts to AWS.

## Prerequisites
- **AWS CLI** configured with appropriate permissions.
- **Terraform** installed.
- **Docker** installed.
- **PostgreSQL Client** (psql) or a GUI tool (pgAdmin, DBeaver) to initialize the database.

---

## Part 1: Create Database on AWS RDS

We use Terraform to provision a PostgreSQL instance on AWS RDS.

1. **Navigate to the terraform directory:**
   ```bash
   cd terraform
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan and Apply:**
   Run the following command to create the database. Replace `YOUR_SECURE_PASSWORD` with a strong password.
   ```bash
   terraform apply \
     -var="db_password=YOUR_PASSWORD" \
     -var="aws_profile=my-mvp-profile" \
     -var="vpc_id=vpc-0324553d0c67f61a0" \
     -var="github_repo_url=https://github.com/deepaknet5/sonardashboard.git"
   ```
   - Type `yes` when prompted to confirm.

4. **Get Database Output:**
   After the deployment finishes, Terraform will output the RDS endpoint.
   
5. **Initialize Database Schema:**
   Connect to the new RDS instance and run the `all_tables_ddl.sql` script to create the required tables.
   
   Using `psql`:
   ```bash
   # Go back to root directory where sql file is located
   cd ..
   
   # Connect and run the SQL file
   # Replace the host with the rds_endpoint from previous step
   psql -h <RDS_ENDPOINT> -U postgres -d sonardashboard -f all_tables_ddl.sql
   ```
   (Enter the password you set in step 3 when prompted).

---

## Part 2: CI/CD Pipeline (CodeBuild & ECR)

We have set up an AWS CodeBuild project to automatically build the Docker image and push it to ECR.

1. **Deploy resources:** The Terraform command in Part 1 also creates the ECR Repo and CodeBuild project.
2. **Authorize GitHub:** In AWS Console -> CodeBuild, ensure the source is connected to your GitHub account (`deepaknet5`).
3. **Trigger Build:** Every push to `main` triggers a build. You can also start it manually from AWS Console.
   
---

## Part 3: Deploy to ECS (Handoff Instructions)

**For the Deployment Engineer:**

To deploy this application on AWS ECS (Fargate), create a **Task Definition** with the following container configuration:

### 1. Image
- **Image URI:** `723651357729.dkr.ecr.us-east-1.amazonaws.com/sonar-dashboard:latest`

### 2. Environment Variables
You MUST configure these environment variables in the ECS Task Definition for the application to work.

| Variable | Value / Description |
| :--- | :--- |
| `DB_HOST` | `terraform-20260203123912850800000001.covrmisfuk0j.us-east-1.rds.amazonaws.com` |
| `DB_PORT` | `5432` |
| `DB_NAME` | `sonardashboard` |
| `DB_USER` | `postgres` |
| `DB_PASS` | `postgres` (or the password set during Terraform apply) |
| `SONAR_TOKEN` | `<YOUR_SONAR_CLOUD_TOKEN>` |
| `SONAR_ORGANIZATION` | `<YOUR_SONAR_ORG_KEY>` (e.g., `default_org`) |
| `GITHUB_TOKEN` | `<YOUR_GITHUB_PAT_TOKEN>` |
| `SONAR_HOST_URL` | `https://sonarcloud.io` (Optional, defaults to this) |

### 3. Execution Command
The container has a default command, but you can override it if you want to run a specific script:
- **Default (Sonar Analysis):** `["python", "sonar.py"]`
- **GitHub Analysis:** `["python", "refactored_github_parallel_script.py"]`

### 4. Scheduling (Optional)
Create an **Amazon EventBridge Rule** to trigger this ECS Task on a schedule (e.g., `rate(6 hours)` or `cron(0 12 * * ? *)`) to keep the dashboard data up to date.
