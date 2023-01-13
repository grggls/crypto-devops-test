# Crypto Devops Test

1. Dockerize: Write a Dockerfile to run Cosmos Gaia v7.1.0 (https://github.com/cosmos/gaia) in a
container. It should download the source code, build it and run without any modifiers (i.e. docker run
somerepo/gaia:v7.1.0 should run the daemon) as well as print its output to the console. The build
should be security conscious (and ideally pass a container image security test such as Anchor). [20 pts]

2. k8s FTW: Write a Kubernetes StatefulSet to run the above, using persistent volume claims and
resource limits. [15 pts]

3. All the observabilities: Alter the Gaia config file to enable prometheus metrics. Create a prometheus
config or ServiceMonitor k8s resource to scrape the endpoint. [15 pts]

4. Script kiddies: Source or come up with a text manipulation problem and solve it with at least two of awk,
sed, tr and / or grep. Check the question below first though, maybe. [10pts]

5. Script grown-ups: Solve the problem in question 4 using any programming language you like. [15pts]

6. Terraform lovers unite: write a Terraform module that creates the following resources in IAM;
- A role, with no permissions, which can be assumed by users within the same account,
- A policy, allowing users / entities to assume the above role,
- A group, with the above policy attached,
- A user, belonging to the above group.

All four entities should have the same name, or be similarly named in some meaningful way given the
context e.g. prod-ci-role, prod-ci-policy, prod-ci-group, prod-ci-user; or just prod-ci. Make the suffixes
toggleable, if you like. [25pts]
