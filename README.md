# Mario: A Lightweight CI/CD Pipeline for Bioinformatics Tools

A personal DevOps project exploring the automation of building, testing, and deploying a bioinformatics program using **GitHub Actions**, **Docker**, and **AWS EC2**.

## 🔍 Why I Built This Project

At a previous project, I helped optimize a C++ bioinformatics program in a small dev team. Alongside performance tuning and refactoring, the team was also:
- Sharing new commits
- Building Docker containers manually
- Running smoke tests across various runtime configs
- Validating biological outputs

I realized later the testing process could have benefited from some automation. That reflection inspired this project, and I tried to answer the question:
> _What would a simple, robust CI/CD setup look like for a small team developing and testing bioinformatics software?_

**Mario** is my exploration into building a CI/CD pipeline. It’s not designed to be production-ready or general-purpose; it’s an exploratory build to help me internalize DevOps workflows and evaluate how they'd fit into real-world bioinformatics development pipelines.

## 🎯 Project Goals

![pipeline-flow](/images/pipeline-flow.png)

- Automate building and testing of a bioinformatics tool (BWA-MEM2)
- Orchestrate workflow stages using **GitHub Actions**
- Containerize outputs using **Docker**
- Simulate deployment to a staging environment using **AWS EC2**
- Explore real-world DevOps problems like non-determinism, artifact passing, and remote container deployment

## ⚙️ Architecture Overview

![pipeline-architecture](/images/pipeline-architecture.png)

The pipeline consists of 5 stages:
1. **Build**: Compile BWA-MEM2 from source
2. **Test**: Run smoke tests using sample FASTQ input
3. **Validate**: Compare outputs for determinism (hashing sorted `.sam` files)
4. **Containerize**: Package binaries and test data into a Docker image
5. **Deploy**: Push image to a remote EC2 instance and pull for further testing

Artifacts are passed cleanly between jobs for modularity, debugging, and reproducibility.


## 🛠️ Implementation Highlights

### ✅ Submodule-Based Monorepo Design
The BWA-MEM2 source is added as a submodule under `external/`, enabling:
- Independent source control from the pipeline
- Easy extension to multiple tools in the future

### ✅ GitHub Actions CI
Workflow defined in `.github/workflows/main.yml` with the following features:
- Compile from source using `make`
- Smoke test on sample data
- Use of artifacts to transfer test data and binaries between jobs
- Validation step ensures consistency of `.sam` outputs via hash comparison

### ✅ Docker Integration
- Docker image built upon successful test and validation
- Includes compiled binaries and required test scripts and datasets

### ✅ AWS Deployment
- EC2 instance acts as a mock staging environment
- GitHub Actions `ssh` into EC2 and pull the latest Docker image
- Image available for interactive or detached execution

> Originally intended for Oracle Cloud’s Always Free Tier, but switched to AWS due to provisioning issues.

## 🧠 Technical Challenges

### Artifact Management in GitHub Actions
Early attempts failed because I didn't include all the necessary internal binaries as the main executable was just a wrapper. I learned to use GitHub’s artifact upload/download system correctly, improving both modularity and debuggability.

### Output Validation & Determinism
Simple hash checks failed due to:
- Header metadata
- Threading-induced output order variation

**Solution:** Use `samtools` to sort and strip headers before generating a hash. This simplified validation but also showed how domain- and tool-specific knowledge is crucial for testing.

## 🚀 Demo Pipeline

### Triggered via:
- Manual run
- Commit to bwa-mem2 source code
- Pull request

#### 🔧 Build
![demo-build-image.png](/images/demo-build-image.png)

#### 🧪 Test + Validate
![demo-validate-output.png](/images/demo-validate-output.png)

#### 📦 Dockerize + Deploy
![demo-build-docker-image.png](/images/demo-build-docker-image.png)  
![demo-ec2-pulled-image.png](/images/demo-ec2-pulled-image.png)


## 📚 Future Enhancements
There remain many exciting possibilities for expanding this project. Some that came to mind during its development include: 

1) Develop more robust testing: integrate samtools stats and compare alignment accuracy metrics
2) Add automated profiling and performance benchmarking: record time and memory usage metrics and generate full reports
3) Unit tests: if optimising a specific function, add unit tests
4) Test multiple environments: use matrix builds
5) Self-hosted runner: link to a self-hosted runner with more compute
6) Scale: more complex containerisation management using Kubernetes or AWS ECS
7) Abstract into a template: enable this framework to be reusable for various projects
8) Expand deployment targets: deploy to more than one instance (ie test and prod instance)
