---
name: kubectl
description: 'kubectl CLI skill. Use when writing or reviewing kubectl commands, shell scripts using kubectl, Kubernetes resource management, debugging pods and deployments, managing kubeconfig contexts, working with namespaces, scaling deployments, viewing logs, port-forwarding, executing commands in containers, rolling updates, rollbacks, patching resources, applying manifests, or any kubectl operation. Also use when asked to check the Kubernetes or cluster situation in a work environment (test, preprod, prod), or when working with the kubeconfig-switching shell aliases or the Helm configuration repositories named in the machine-local environment map. Covers syntax, output formats, JSONPath, label selectors, common workflows, and quick-reference examples.'
argument-hint: 'What kubectl operation, resource, or environment do you need? (e.g. "get pods", "describe deployment", "check k8s situation in test", "connector preprod health")'
---

# kubectl — Command Line Tool for Kubernetes

Reference: https://kubernetes.io/docs/reference/kubectl/  
Quick Reference: https://kubernetes.io/docs/reference/kubectl/quick-reference/

## Syntax

```
kubectl [command] [TYPE] [NAME] [flags]
```

- `command`: operation (`get`, `apply`, `delete`, `describe`, `exec`, …)
- `TYPE`: resource type — singular, plural, or abbreviated (e.g. `pod`, `pods`, `po`)
- `NAME`: case-sensitive resource name (omit to target all resources of the type)
- `flags`: `-n namespace`, `-o yaml`, `-l label`, `--all-namespaces` / `-A`, etc.

Global flag: `--kubeconfig <path>` or `$KUBECONFIG` env var to target a specific config.

## Context & Namespace

```bash
kubectl config get-contexts                         # list all contexts
kubectl config current-context                      # show active context
kubectl config use-context <name>                   # switch context

kubectl config set-context --current --namespace=<ns>  # set default namespace
kubectl -n <namespace> get pods                     # one-off namespace override
kubectl get pods -A                                 # all namespaces shorthand
```

## Viewing Resources

```bash
kubectl get pods                                    # list pods (current namespace)
kubectl get pods -o wide                            # include node name, IP
kubectl get pod <name> -o yaml                      # full YAML spec
kubectl get pod <name> -o json                      # full JSON spec
kubectl describe pod <name>                         # verbose details + events
kubectl get events --sort-by='.lastTimestamp'       # sorted cluster events
kubectl get pods --field-selector=spec.nodeName=n1  # field selector filter
kubectl get pods -l app=nginx                       # label selector filter
kubectl get pods --show-labels                      # show all labels
kubectl get all -n <ns>                             # all resources in namespace
```

## Applying & Creating Resources

```bash
kubectl apply -f manifest.yaml                      # declarative create/update
kubectl apply -f ./dir/                             # apply all files in directory
kubectl apply -f https://example.com/manifest.yaml  # from URL
kubectl create deployment nginx --image=nginx       # imperative create
kubectl create namespace my-ns
kubectl create secret generic my-secret --from-literal=key=value
kubectl create configmap my-cm --from-file=config.properties
kubectl diff -f manifest.yaml                       # preview changes before apply
```

## Editing & Patching

```bash
kubectl edit deployment/<name>                      # open in $EDITOR
KUBE_EDITOR="nano" kubectl edit svc/<name>          # specific editor

# Strategic merge patch
kubectl patch pod <name> -p '{"spec":{"containers":[{"name":"app","image":"v2"}]}}'

# JSON patch (positional)
kubectl patch deployment <name> --type=json \
  -p='[{"op":"replace","path":"/spec/replicas","value":3}]'

kubectl set image deployment/<name> <container>=<image>:<tag>  # rolling update image
kubectl set env deployment/<name> ENV_VAR=value
kubectl set resources deployment/<name> --limits=cpu=200m,memory=256Mi
```

## Scaling & Rollouts

```bash
kubectl scale deployment/<name> --replicas=3
kubectl autoscale deployment/<name> --min=2 --max=10 --cpu=80

kubectl rollout status deployment/<name>            # watch rollout progress
kubectl rollout history deployment/<name>           # view revisions
kubectl rollout undo deployment/<name>              # rollback to previous
kubectl rollout undo deployment/<name> --to-revision=2
kubectl rollout restart deployment/<name>           # rolling restart (no downtime)
kubectl rollout pause deployment/<name>
kubectl rollout resume deployment/<name>
```

## Deleting Resources

```bash
kubectl delete pod <name>
kubectl delete pod <name> --now                     # no grace period
kubectl delete -f manifest.yaml
kubectl delete pods -l app=myapp                    # by label
kubectl delete pods --all -n <ns>
kubectl -n <ns> delete pod,svc --all
```

## Logs

```bash
kubectl logs <pod>                                  # stdout of pod
kubectl logs <pod> -c <container>                   # multi-container pod
kubectl logs -f <pod>                               # follow / tail -f
kubectl logs <pod> --previous                       # previous (crashed) container
kubectl logs -l app=myapp --all-containers          # all pods matching label
kubectl logs <pod> --since=1h
kubectl logs <pod> --tail=50
```

## Exec & Debug

```bash
kubectl exec <pod> -- <command>                     # run command in pod
kubectl exec -it <pod> -- /bin/sh                   # interactive shell
kubectl exec <pod> -c <container> -- ls /           # specific container

kubectl debug <pod> -it --image=busybox             # ephemeral debug container
kubectl debug node/<node> -it --image=busybox       # debug on node

kubectl port-forward pod/<name> 8080:80             # local:pod port forward
kubectl port-forward svc/<name> 8080:80             # via service
kubectl port-forward deploy/<name> 8080:80

kubectl cp <pod>:/path/to/file ./local-file         # copy from pod
kubectl cp ./local-file <pod>:/path/to/file         # copy to pod
```

## Resource Usage

```bash
kubectl top node                                    # CPU/memory per node
kubectl top pod                                     # CPU/memory per pod
kubectl top pod --sort-by=cpu
kubectl top pod --containers                        # per container
```

## Node Management

```bash
kubectl cordon <node>                               # mark unschedulable
kubectl drain <node> --ignore-daemonsets            # evict pods (maintenance)
kubectl uncordon <node>                             # mark schedulable again
kubectl taint nodes <node> key=value:NoSchedule
```

## Output Formats

| Flag | Output |
|------|--------|
| `-o wide` | extra columns (node, IP) |
| `-o yaml` | full YAML |
| `-o json` | full JSON |
| `-o name` | resource names only |
| `-o jsonpath='{.spec.nodeName}'` | JSONPath expression |
| `-o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image` | custom columns |
| `--sort-by=.metadata.name` | sort by field |

## JSONPath Quick Reference

```bash
kubectl get pod <name> -o jsonpath='{.status.podIP}'
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'
# Filter: only items matching a condition
kubectl get pods -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'
```

## Label Selectors

```bash
-l app=nginx                          # equality
-l app!=nginx                         # inequality
-l 'env in (prod, staging)'          # set-based
-l 'tier notin (frontend)'           # set-based exclusion
-l app=nginx,tier=frontend           # AND of multiple
--field-selector status.phase=Running
```

## Dry Run & Validation

```bash
kubectl apply -f manifest.yaml --dry-run=client    # client-side preview
kubectl apply -f manifest.yaml --dry-run=server    # server-side validation
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml  # generate manifest
kubectl explain pods.spec.containers               # field documentation
kubectl explain deployment --recursive             # full schema
```

## Common `--dry-run` + `apply` Pattern

1. Draft YAML or generate with `--dry-run=client -o yaml`
2. Validate with `kubectl diff -f manifest.yaml`
3. Apply with `kubectl apply -f manifest.yaml`
4. Watch rollout: `kubectl rollout status deployment/<name>`

## Work Environments

The environment specifics — alias/kubeconfig/namespace matrix, deployment repository map, and the
triage workflow for "check the k8s situation in \<env\>" — are machine-local and not versioned in
this repository.

**Read `~/.claude/local/work-environments.md` if it exists** before answering anything about a
particular cluster, namespace, or deployment repository. If it does not exist, say the
environment map is not configured on this machine rather than guessing at names or paths.

Kubeconfigs are switched by shell aliases (`k` + environment + optional stack suffix) defined in
`~/.config/zsh/secrets`. Those exist **only in an interactive shell** — a tool call does not
source that file, so an alias fails with "command not found". Set the kubeconfig explicitly,
using a filename from the environment map:

```bash
KUBECONFIG="$HOME/.kube/<config-file>" kubectl get pods    # not: <alias> && kubectl get pods
```

Each kubeconfig carries its own default namespace, so `-n` is only needed to look outside it.

**Never** mutate a production cluster without explicit per-command confirmation, and state which
environment the command would hit before asking. Changes belong in the deployment repository's
`values-<env>.yaml` and its pipeline, not in a direct `kubectl apply`.

## Full Command Reference

See [./references/commands.md](./references/commands.md) for the complete command listing.
