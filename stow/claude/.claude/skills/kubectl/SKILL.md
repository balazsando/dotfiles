---
name: kubectl
description: "Kubernetes and kubectl work: pods, deployments, namespaces, logs, port-forwarding, exec, rollouts and rollbacks, patching, manifests, kubeconfig contexts, JSONPath and label selectors. Also for checking a cluster's state in a work environment (test, preprod, prod), the kubeconfig-switching shell aliases, and the Helm config repositories in the machine-local environment map."
argument-hint: 'What kubectl operation, resource, or environment do you need? (e.g. "get pods", "describe deployment", "check k8s situation in test", "connector preprod health")'
---

# kubectl — Command Line Tool for Kubernetes

Reference: https://kubernetes.io/docs/reference/kubectl/  
Quick Reference: https://kubernetes.io/docs/reference/kubectl/quick-reference/

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

