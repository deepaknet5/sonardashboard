# Deployment Guide for Sonar Dashboard

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
   terraform apply -var="db_password=YOUR_SECURE_PASSWORD"
   ```
   - Type `yes` when prompted to confirm.

4. **Get Database Output:**
   After the deployment finishes, Terraform will output the RDS endpoint.
   Example output:
   ```
   rds_endpoint = "terraform-2023...rds.amazonaws.com:5432"
   rds_db_name  = "sonardashboard"
   rds_username = "postgres"
   ```

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

## Part 2: Containerize and Deploy to AWS

### 1. Build Docker Image
We have created a `Dockerfile` in the root directory.

```bash
# Build the image
docker build -t sonar-dashboard .
```

### 2. Push to AWS ECR using CodeBuild

We have set up an AWS CodeBuild project to automatically build the Docker image and push it to ECR.

1. **Deploy CodeBuild and ECR Resources:**
   Run Terraform to create the ECR repo and CodeBuild project.
   ```bash
   # In terraform/ directory
   terraform apply \
     -var="db_password=YOUR_PASSWORD" \
     -var="aws_profile=my-mvp-profile" \
     -var="vpc_id=vpc-0324553d0c67f61a0" \
     -var="github_repo_url=https://github.com/shantanu10839179/sonardashboard.git"
   ```

2. **Trigger the Build:**
   You can trigger the build from the AWS Console or using AWS CLI:
   ```bash
   aws codebuild start-build --project-name sonar-dashboard-build --profile my-mvp-profile
   ```

3. **Verify:**
   Check the CodeBuild logs in the AWS Console to ensure the build succeeded and the image was pushed to ECR.

### 3. Run on AWS (ECS Fargate or EC2)

You can run this as a standalone task on AWS ECS.

**Environment Variables Required:**
When running the container, you must pass the following environment variables so the scripts can connect to the DB and APIs:
- `SONAR_TOKEN`: Your SonarCloud token.
- `SONAR_ORGANIZATION`: Your Sonar organization.
- `GITHUB_TOKEN`: Your GitHub PAT.
- `DB_HOST`: The RDS endpoint (from Part 1).
- `DB_NAME`: `sonardashboard`
- `DB_USER`: `postgres`
- `DB_PASS`: The password you set.

**Example: Run local test connecting to RDS:**
```bash
docker run -e SONAR_TOKEN=your_token \
           -e DB_HOST=your_rds_endpoint \
           -e DB_PASS=your_password \
           sonar-dashboard
```

**To run the GitHub specific script instead of Sonar:**
The Dockerfile defaults to `sonar.py`. To run the GitHub script:
```bash
docker run ... sonar-dashboard python refactored_github_parallel_script.py
```
