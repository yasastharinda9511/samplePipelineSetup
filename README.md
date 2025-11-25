# Jenkins CI/CD Pipeline Setup Guide

A complete setup guide for Jenkins CI/CD pipeline with Docker and Go application builds.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Step 1: Start Jenkins with Docker Compose](#step-1-start-jenkins-with-docker-compose)
- [Step 2: Initial Jenkins Setup](#step-2-initial-jenkins-setup)
- [Step 3: Install Essential Jenkins Plugins](#step-3-install-essential-jenkins-plugins)
- [Step 4: Build the Go Docker Image](#step-4-build-the-go-docker-image)
- [Step 5: Configure Jenkins Pipeline](#step-5-configure-jenkins-pipeline)
- [Step 6: Configure Docker Hub Credentials](#step-6-configure-docker-hub-credentials)
- [Step 7: Run Your First Pipeline](#step-7-run-your-first-pipeline)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have the following installed on your system:
- Docker (version 20.10 or higher)
- Docker Compose (version 1.29 or higher)
- Git

Verify installations:
```bash
docker --version
docker-compose --version
git --version
```

---

## Step 1: Start Jenkins with Docker Compose

### 1.1 Navigate to the project directory
```bash
cd /path/to/samplePipelineSetup
```

### 1.2 Start Jenkins container
```bash
docker-compose up -d
```

This will:
- Download the Jenkins LTS image with JDK 17
- Install Docker CLI inside the Jenkins container
- Start Jenkins on port 8080
- Expose agent port 50000

### 1.3 Verify Jenkins is running
```bash
docker-compose ps
```

You should see the `jenkins` container with status "Up".

### 1.4 Check Jenkins logs
```bash
docker-compose logs -f jenkins
```

Wait for the message: `Jenkins is fully up and running`

Press `Ctrl+C` to exit logs.

---

## Step 2: Initial Jenkins Setup

### 2.1 Access Jenkins web interface
Open your browser and navigate to:
```
http://localhost:8080
```

### 2.2 Get the initial admin password
Since we disabled the setup wizard in docker-compose, you may need to create an admin user manually or use the default setup.

To get the initial password (if needed):
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

**Note:** Our docker-compose.yaml has `JAVA_OPTS=-Djenkins.install.runSetupWizard=false` which skips the setup wizard. You can remove this line if you want the guided setup.

---

## Step 3: Install Essential Jenkins Plugins

### 3.1 Navigate to Plugin Manager
1. Go to: `Manage Jenkins` → `Manage Plugins`
2. Click on the `Available` tab

### 3.2 Install required plugins

Search and install the following plugins (select all, then click "Install without restart"):

#### Core Pipeline Plugins:
- **Pipeline** - Pipeline as Code support
- **Pipeline: Stage View** - Visual pipeline stage view
- **Pipeline: GitHub Groovy Libraries** - Pipeline shared libraries

#### Docker Plugins:
- **Docker Pipeline** - Docker support in Pipeline
- **Docker** - Docker plugin for Jenkins
- **CloudBees Docker Build and Publish** - Build and publish Docker images

#### Git & SCM Plugins:
- **Git** - Git SCM support
- **GitHub** - GitHub integration
- **GitHub Branch Source** - GitHub branch discovery

#### Build & Quality Plugins:
- **Warnings Next Generation** - Static analysis results
- **JUnit** - JUnit test results
- **Cobertura** - Code coverage reports
- **HTML Publisher** - Publish HTML reports

#### Utility Plugins:
- **Workspace Cleanup** - Clean workspace before build
- **Timestamper** - Add timestamps to console output
- **Build Timeout** - Abort builds that take too long
- **Credentials Binding** - Use credentials in builds

#### Optional but Recommended:
- **Blue Ocean** - Modern UI for Jenkins
- **SonarQube Scanner** - SonarQube integration
- **Slack Notification** - Slack notifications

### 3.3 Restart Jenkins
After installation completes:
```bash
docker-compose restart jenkins
```

Or via UI: `Manage Jenkins` → `Prepare for Shutdown` → Wait for jobs to complete → Restart container

---

## Step 4: Build the Go Docker Image

This step creates the Docker image that will be used by Jenkins to build your Go applications.

### 4.1 Verify the Dockerfile
The `Dockerfile` in this repository includes:
- Go 1.23
- Git
- Docker CLI
- golangci-lint (v1.55.2)
- gosec (v2.18.2)

### 4.2 Build the Docker image
```bash
docker build -t golang-git:1.23 .
```

This may take 5-10 minutes on first build.

### 4.3 Verify the image was built
```bash
docker images | grep golang-git
```

You should see:
```
golang-git    1.23    <image-id>    <timestamp>    <size>
```

### 4.4 Test the image (optional)
```bash
docker run --rm golang-git:1.23 go version
docker run --rm golang-git:1.23 golangci-lint --version
docker run --rm golang-git:1.23 gosec --version
```

---

## Step 5: Configure Jenkins Pipeline

### 5.1 Create a new Pipeline job

1. From Jenkins dashboard, click `New Item`
2. Enter job name: `GoLoadBalancer-Pipeline` (or your preferred name)
3. Select `Pipeline` as the job type
4. Click `OK`

### 5.2 Configure the Pipeline

#### General Settings:
- Check `Discard old builds`
  - Days to keep builds: `30`
  - Max # of builds to keep: `10`

#### Build Triggers (choose one):
- `Poll SCM`: `H/5 * * * *` (check every 5 minutes)
- `GitHub hook trigger for GITScm polling` (if using webhooks)

#### Pipeline Configuration:

**Option A: Pipeline from SCM**
1. Definition: `Pipeline script from SCM`
2. SCM: `Git`
3. Repository URL: `https://github.com/yasastharinda9511/GoLoadBalancer.git`
4. Branch: `*/main`
5. Script Path: `jenkinsfile`

**Option B: Direct Pipeline Script**
1. Definition: `Pipeline script`
2. Copy the contents from `jenkinsfile` in this repository
3. Paste into the Pipeline script text area

### 5.3 Save the configuration

---

## Step 6: Configure Docker Hub Credentials

The pipeline requires Docker Hub credentials to push images.

### 6.1 Add Docker Hub credentials

1. Go to: `Manage Jenkins` → `Manage Credentials`
2. Click on `(global)` domain
3. Click `Add Credentials`
4. Fill in:
   - **Kind**: `Username with password`
   - **Username**: Your Docker Hub username
   - **Password**: Your Docker Hub password or access token
   - **ID**: `docker-hub-credentials` (must match Jenkinsfile)
   - **Description**: `Docker Hub Credentials`
5. Click `Create`

### 6.2 Generate Docker Hub access token (recommended)

Instead of using your password, use an access token:
1. Log in to https://hub.docker.com
2. Go to: Account Settings → Security → Access Tokens
3. Click `New Access Token`
4. Name: `Jenkins CI/CD`
5. Permissions: `Read, Write, Delete`
6. Copy the token and use it as the password in Jenkins

---

## Step 7: Run Your First Pipeline

### 7.1 Trigger the pipeline

1. Go to your pipeline job: `GoLoadBalancer-Pipeline`
2. Click `Build Now`

### 7.2 Monitor the build

- Click on the build number (e.g., `#1`) in Build History
- Click `Console Output` to see logs
- Or use Blue Ocean for a visual view

### 7.3 Pipeline stages

The pipeline will execute the following stages:
1. **Checkout** - Clone the repository
2. **Setup Go Environment** - Configure Go workspace
3. **Dependencies** - Download and verify Go modules
4. **Code Quality Check** (parallel):
   - Lint with golangci-lint
   - Format check
   - Go vet
5. **Security Scan** - Run gosec
6. **Unit Tests** - Run tests with coverage
7. **Build Binary** - Compile Go application
8. **Build Docker Image** - Create Docker image
9. **Docker Security Scan** - Scan with Trivy
10. **Push Docker Image** - Push to Docker Hub
11. **Archive Artifacts** - Save build artifacts

### 7.4 Verify success

After successful build:
- Check console output for green checkmarks
- Verify artifacts in the build page
- Check Docker Hub for the pushed image

---

## Troubleshooting

### Jenkins container won't start
```bash
# Check logs
docker-compose logs jenkins

# Check if port 8080 is already in use
sudo lsof -i :8080

# Remove and recreate
docker-compose down -v
docker-compose up -d
```

### Docker socket permission denied
```bash
# Give Jenkins container access to Docker socket
docker exec -u root jenkins chmod 666 /var/run/docker.sock
```

### Pipeline fails with "golang-git:1.23 not found"
```bash
# Make sure you built the image
docker build -t golang-git:1.23 .

# Verify it exists
docker images | grep golang-git
```

### Pipeline fails at Docker build stage
```bash
# Ensure Jenkins can access Docker
docker exec jenkins docker ps

# If fails, restart Jenkins
docker-compose restart jenkins
```

### Plugin installation fails
```bash
# Update plugin site
# Go to: Manage Jenkins → Manage Plugins → Advanced
# Click "Check now" at the bottom

# Or restart Jenkins
docker-compose restart jenkins
```

### Can't access Jenkins at localhost:8080
```bash
# Check if container is running
docker-compose ps

# Check if port is mapped correctly
docker port jenkins

# Try 127.0.0.1:8080 instead of localhost:8080
```

### Build fails with "permission denied"
```bash
# Execute as root in Jenkins container
docker exec -u root jenkins bash -c "chown -R jenkins:jenkins /var/jenkins_home"
```

---

## Additional Configuration

### Enable Blue Ocean UI
After installing Blue Ocean plugin:
1. Go to Jenkins dashboard
2. Click `Open Blue Ocean` in the left sidebar
3. Enjoy the modern pipeline visualization

### Configure Email Notifications
1. Go to: `Manage Jenkins` → `Configure System`
2. Scroll to `Extended E-mail Notification`
3. Configure SMTP settings
4. Test email configuration

### Set up GitHub Webhooks
1. Go to your GitHub repository → Settings → Webhooks
2. Click `Add webhook`
3. Payload URL: `http://your-jenkins-url:8080/github-webhook/`
4. Content type: `application/json`
5. Select events: `Just the push event`
6. Click `Add webhook`

---

## File Structure

```
samplePipelineSetup/
├── docker-compose.yaml    # Jenkins container configuration
├── Dockerfile            # Go builder image with tools
├── jenkinsfile          # Pipeline definition
└── README.md           # This file
```

---

## Next Steps

1. Customize the `jenkinsfile` for your specific project
2. Update the Git repository URL
3. Add your own deployment stages
4. Configure notification channels (Slack, email)
5. Set up SonarQube for code quality metrics
6. Configure multi-branch pipeline for PR builds

---

## Support

For issues or questions:
- Check Jenkins logs: `docker-compose logs jenkins`
- Review console output in Jenkins UI
- Check Docker container logs: `docker logs jenkins`

---

## License

This setup guide is provided as-is for educational and development purposes.
