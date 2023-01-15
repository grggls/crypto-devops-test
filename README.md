# Crypto Devops Test

## 1. Dockerize:
Write a Dockerfile to run Cosmos Gaia v7.1.0 (https://github.com/cosmos/gaia) in a
container. It should download the source code, build it and run without any modifiers (i.e. docker run
somerepo/gaia:v7.1.0 should run the daemon) as well as print its output to the console. The build
should be security conscious (and ideally pass a container image security test such as Anchor). [20 pts]

> Pull this repo and build the container. Tag it `gaiad`, if you please:
```
$ git clone https://github.com/grggls/crypto-devops-test
$ cd crypto-devops-test
$ docker build -t gaiad .
```

> Jump into the anchore directory and bring up that service. You'll need to wait 10+ for all the feeds to finish downoading:
```
$ cd anchore
$ docker-compose up -d
$ docker-compose ps
NAME                      COMMAND                  SERVICE             STATUS              PORTS
anchore-analyzer-1        "/docker-entrypoint.…"   analyzer            running (healthy)   8228/tcp
anchore-api-1             "/docker-entrypoint.…"   api                 running (healthy)   0.0.0.0:8228->8228/tcp
anchore-catalog-1         "/docker-entrypoint.…"   catalog             running (healthy)   8228/tcp
anchore-db-1              "docker-entrypoint.s…"   db                  running (healthy)   5432/tcp
anchore-policy-engine-1   "/docker-entrypoint.…"   policy-engine       running (healthy)   8228/tcp
anchore-queue-1           "/docker-entrypoint.…"   queue               running (healthy)   8228/tcp

$ docker-compose exec api anchore-cli system feeds list
Feed                   Group                  LastSync                    RecordCount
vulnerabilities        alpine:3.10            2023-01-14T05:50:54Z        2331
vulnerabilities        alpine:3.11            2023-01-14T05:50:54Z        2665
vulnerabilities        alpine:3.12            2023-01-14T05:50:54Z        3205
vulnerabilities        alpine:3.13            2023-01-14T05:50:54Z        3684
vulnerabilities        alpine:3.14            2023-01-14T05:50:54Z        4173
vulnerabilities        alpine:3.15            2023-01-14T05:50:54Z        4591
vulnerabilities        alpine:3.16            2023-01-14T05:50:54Z        4942
...
...
```

> In the meantime, push your `gaiad` image to a registry:
```
$ docker tag gaiad grggls/gaiad:latest
$ docker push grggls/gaiad:latest
The push refers to repository [docker.io/grggls/gaiad]
caf120581354: Pushed
5a2d59dfed5a: Pushed
8849ba573d59: Pushed
...
...
latest: digest: sha256:593e91096f70543c9d5f3c164277f9516a78f016ac607c6519814ecc743bbf20 size: 2425
```

> Add your `gaiad` image to Anchore:
```
$ cd ..
$ docker-compose exec api anchore-cli image add grggls/gaiad:latest
Image Digest: sha256:593e91096f70543c9d5f3c164277f9516a78f016ac607c6519814ecc743bbf20
Parent Digest: sha256:593e91096f70543c9d5f3c164277f9516a78f016ac607c6519814ecc743bbf20
Analysis Status: not_analyzed
Image Type: docker
Analyzed At: None
Image ID: 004253f149da5c9a8380440bc83a3bbbbe63d195bec10b181106680b2d8d691a
Dockerfile Mode: None
Distro: None
Distro Version: None
Size: None
Architecture: None
Layer Count: None

Full Tag: docker.io/grggls/gaiad:latest
Tag Detected At: 2023-01-15T12:03:27Z

$ docker-compose exec api anchore-cli image vuln grggls/gaiad:latest all
Vulnerability ID        Package                         Severity        Fix              CVE Refs              Vulnerability URL                                                   Type        Feed Group         Package Path
CVE-2020-35467          docs-1.0.0                      Critical        None             CVE-2020-35467        https://nvd.nist.gov/vuln/detail/CVE-2020-35467                     npm         nvd                /go/pkg/mod/github.com/cosmos/cosmos-sdk@v0.45.9/docs/package.json
CVE-2020-35467          docs-1.0.0                      Critical        None             CVE-2020-35467        https://nvd.nist.gov/vuln/detail/CVE-2020-35467                     npm         nvd                /go/pkg/mod/github.com/cosmos/ibc-go/v3@v3.0.0/docs/package.json
CVE-2020-35467          docs-1.0.0                      Critical        None             CVE-2020-35467        https://nvd.nist.gov/vuln/detail/CVE-2020-35467                     npm         nvd                /go/pkg/mod/github.com/tendermint/tendermint@v0.34.21/docs/package.json
CVE-2022-28391          busybox-1.35.0-r29              High            1.35.0-r7        CVE-2022-28391        http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-28391        APKG        alpine:3.17        pkgdb
CVE-2022-28391          busybox-binsh-1.35.0-r29        High            1.35.0-r7        CVE-2022-28391        http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-28391        APKG        alpine:3.17        pkgdb
CVE-2022-28391          ssl_client-1.35.0-r29           High            1.35.0-r7        CVE-2022-28391        http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-28391        APKG        alpine:3.17        pkgdb
```

Upgraded the `golang:alpine` image in use as `gaiad-builder` in the buildchain. Confirmed that the solution still works and `gaiad` is running nominally. Ran it through anchore again and got a clean bill of health:
```
$ docker-compose exec api anchore-cli evaluate check grggls/gaiad:latest
Image Digest: sha256:128b029a000d29351020c9ef54f3d59fce377bd6d42db1e69d3751d8b8589c8c
Full Tag: docker.io/grggls/gaiad:latest
Status: pass
Last Eval: 2023-01-15T12:30:20Z
Policy ID: 2c53a13c-1765-11e8-82ef-23527761d060
```

2. k8s FTW: Write a Kubernetes StatefulSet to run the above, using persistent volume claims and resource limits. [15 pts]

> Build a kind cluster with a local filesystem mount inside, then apply the k8s config for a volume and StatefulSet.
```
$ kind create cluster --config kind.yaml
Creating cluster "gaia" ...
 ✓ Ensuring node image (kindest/node:v1.25.3) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-gaia"
You can now use your cluster with:

kubectl cluster-info --context kind-gaia
 
$ kubectl apply -f ./statefulset.yaml
namespace/gaiad created
service/gaiad created
persistentvolume/pv-gaia unchanged
persistentvolumeclaim/pvc-gaia created
statefulset.apps/gaiad created

$ kubectl get pods -n gaiad
NAME      READY   STATUS    RESTARTS   AGE
gaiad-0   1/1     Running   0          15m
gaiad-1   1/1     Running   0          15m

$ kubectl get pvc -n gaiad
NAME               STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-gaia           Pending                                                                        standard       36s
pvc-gaia-gaiad-0   Bound     pvc-835d9388-81b9-4993-9f97-f953977f5d76   1Gi        RWO            standard       36s
pvc-gaia-gaiad-1   Bound     pvc-dd5135d8-9239-447f-a9cc-2e73b0fb0c76   1Gi        RWO            standard       28s

$ kubectl describe statefulset/gaiad -n gaiad
Name:               gaiad
Namespace:          gaiad
CreationTimestamp:  Mon, 16 Jan 2023 10:15:37 +1100
Selector:           app=gaiad
Labels:             <none>
Annotations:        <none>
Replicas:           2 desired | 2 total
Update Strategy:    RollingUpdate
  Partition:        0
Pods Status:        2 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=gaiad
  Containers:
   gaiad:
    Image:        grggls/gaiad:latest
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Volume Claims:
  Name:          pvc-gaia
  StorageClass:
  Labels:        <none>
  Annotations:   <none>
  Capacity:      1Gi
  Access Modes:  [ReadWriteOnce]
Events:
  Type    Reason            Age   From                    Message
  ----    ------            ----  ----                    -------
  Normal  SuccessfulCreate  11m   statefulset-controller  create Claim pvc-gaia-gaiad-0 Pod gaiad-0 in StatefulSet gaiad success
  Normal  SuccessfulCreate  11m   statefulset-controller  create Pod gaiad-0 in StatefulSet gaiad successful
  Normal  SuccessfulCreate  11m   statefulset-controller  create Claim pvc-gaia-gaiad-1 Pod gaiad-1 in StatefulSet gaiad success
  Normal  SuccessfulCreate  11m   statefulset-controller  create Pod gaiad-1 in StatefulSet gaiad successful
```

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
