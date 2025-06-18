![header](/images/header.png)
![pipeline-flow](/images/pipeline-flow.png)


# Overview and Motivation
On a previous project, I was optimising a bioinformatics program. The dev team was small (a senior dev and me), and the extended testing team was also limited. 

While we spent a decent chunk of our time attempting to optimise various portions of the program, we were also sharing latest commits, building and running docker images, running smoke tests on various datasets, simulating different runtime configurations and program options, all while making sure the results were detecting significant/relevant biological signals.

I was picking up a new language through this process, and was unable to consider how to improve the building and testing process. A few months later, the project ended, and I learned a lot, but I wanted to explore if this process could have been improved. So I tinkered with DevOps and found myself creating this pipeline. 

The point of this simple pipeline (named Mario) is to optimise the development and testing process *in the way I experienced it at the time.* It's not one size fits all, and isn't for replicating. It is a personal exploration of creating a system that could have helped me in the past and hopefully enable me to create such systems in the future when needed. 

I believe if I had an understanding of how to execute this, it would have sped up the development and helped streamline and ensure consistency in the testing process.

In short, this project contains a CI/CD pipeline implemented using Github Actions, Docker, and a Amazon Web Services EC2 instance. When commits are pushed or when the workflow is manually run, several jobs are executed. 
1) The program is automatically compiled
2) A smoke test is run, and the output is validated
3) If the smoke test is passed, the binaries, along with test scripts and data, are containerised
4) The Docker image is pushed to a private repo
5) On a private EC2 instance, the latest Docker image is pulled and can be run detached or interactively.

*A more detailed write-up of the learning process will be posted soon on my website  . Stay tuned*

# Architectural Design & Key features and technologies used
![pipeline-architecture](/images/pipeline-architecture.png)

*A note on tools/libraries used: I will go into more detail regarding why I selected certain tools/libraries in a separate writeup. Most likely, it boiled down to popularity, accessibility, online support, or price.*

I attempted to design the architecture of this pipeline in a way that it could be expanded and more tests and functionaltiy could be added. At this level, it covers the bare bones, but can easily be built upon if I want to learn new skills around the DevOps process. 

To begin with, the project adopts a monorepo setup, and code base(s) are added as a submodule under the directory `external`. This enables 1) changes to be made to the codebase independent from the pipeline and 2) more programs to be included if the suite were to be extended. I selected BWA-MEM2 as the program to be added, as it is rather simple to run and a key bioinformatics program. I chose this particular version as it requires fewer resources and runs faster than the original. 

## Continuous integration

For continuous integration, I utilise Github Actions. The workflow is defined in `.github/workflows/main.yml` with the following stages: Build, Smoke Test, Validate Output, Containerize, and Deploy. 

When set up, it nicely automates compiling BWA-MEM2 directly from its C/C++ source and also handles the external dependency it has. 

Within the CI pipeline, a smoke test utilising small-scale FASTQ data was also implemented to ensure functionality and reproducibility. Output validation is performed by comparing hashes of processed output files to verify that identical results are achieved (in practice, a more likely comparison is to actually look at the alignment results and compare them, but for a basic smoke test to ensure identical deterministic results, this will suffice).

I intentionally made use of Github Actions' artifact management system, so that I could pass compiled binaries and test results between different jobs. This allowed a nice clean separation of jobs and made it easier to debug if I needed to troubleshoot a certain step. In the situation where I need to have lots of jobs running, it would probably optimise the runner's distribution a little, but that is not yet a concern at this stage. 

## Continuous deployment
To deploy a commit that passes the smoke test and validation, Github Action automatically builds a Docker image if the smoke test is passed, and the image is pushed as a private repo to Docker Hub. 

To wrap up the pipeline, Github Actions will `ssh` into an AWS EC2 instance and automatically pulls the latest image so that it is available in a cloud environment that could be shared for further testing.

## Cloud Choices
Initially, I set out to use Oracle Cloud Infrastructure's Always Free Tier which provides a rather generous amount of compute and storage. However, I constantly ran into a "no shapes are available" error, which prevented me from acquiring a VM. Thus, I had to resort to Amazon Web Services' free EC2, which is much more limited in compute, but has enough for me to install and acquire my Docker image. 

# Technical Implementation Highlights & Challenges Overcome
I go into more detail about the entire set-up process in a separate write-up, but two takeaways include:

**Github Actions Artifact Management**

![pipeline-architecture](/images/artifacts.png)

My initial lack of understanding of Github Actions means I took a minute to grasp the purpose of having artifacts. It took an extra step or two to upload and download artifacts, and I contemplated not even utilising them. At one point, I failed to upload all the variants of the BWA-MEM2 binary and was unable to run the program at all. I later realised that the main executable served as a wrapper for the other internal components, and I needed to upload and download them all each time (frankly, a deeper understanding of the program would have allowed me to avoid this). In the end, the distinction between each job made running the entire workflow much more comprehensible, and I preferred being able to see at which job my workflow may have failed. 

**Smoke Test Validation & Determinism**
Verifying the correctness of BWA-MEM2's output, specifically the `.sam` file, presented some nuance: simple hash comparisons were unreliable due to non-deterministic elements like metadata timestamps or multithreading-induced output order variations. Even though the results may have been the same, the order in which they were completed or the metadata may have differed which means the hashes would have been different. I implemented a quick fix by sorting the alignments and stripping headers from the `.sam` files before generating hashes. This does highlight to me that if more extensive testing were to be developed, it would need to be specific to the type of analysis being conducted and require deeper expertise in that area. 

# End flow
This is not built to be replicable, but just to demonstrate the outcome, I have included the results. 

When triggered (manually, commits to the source code, or pull requests), the CI & CD pipeline kicks off. 

![demo-pipeline-start.png](/images/demo-pipeline-start.png)

The image is first built (this step typically takes the longest). 

![demo-build-image.png](/images/demo-build-image.png)

The smoke test is run, and the output saved as an artifact. Using samtools, the output is sorted and its headers are removed, before generating a hash to determine if the output produced is the same.

![demo-validate-output.png](/images/demo-validate-output.png)

The Docker image is built and tested on Github Actions, before being pushed as a private repo. Github Actions than proceeds to `ssh` into an AWS EC2 instance, and pulls the image. 

![demo-build-docker-image.png](/images/demo-build-docker-image.png)

Finally, I can `ssh` into the server from my laptop, and the Docker image is already pulled, and I can run my container there.

![demo-ec2-pulled-image.png](/images/demo-ec2-pulled-image.png)

That's about it! Unfortunately, the free tier EC2 instance is very limited and is unable to run even my small test set. Given a larger instance, it should be able to run the alignment program, but this was an exercise in deployment and I'd say it was successful.

# Room For Future Enhancements 

This could still be expanded in so many ways. Ideas that came to mind include:

1) Develop more robust testing: integrate samtools stats and compare alignment accuracy metrics
2) Add automated profiling and performance benchmarking: record time and memory usage metrics and generate full reports
3) Unit tests: if optimising a specific function, add unit tests
4) Test multiple environments: use matrix builds
5) Self-hosted runner: link to a self-hosted runner with more compute
6) Scale: more complex containerisation management using Kubernetes or AWS ECS
7) Abstract into a template: enable this framework to be reusable for various projects
8) Expand deployment targets: deploy to more than one instance (ie a test and a prod instance)