# kubectl — Full Command Reference

Source: https://kubernetes.io/docs/reference/kubectl/_print/

## All Commands

| Command | Syntax | Description |
|---------|--------|-------------|
| `alpha` | `kubectl alpha SUBCOMMAND` | Alpha feature commands |
| `annotate` | `kubectl annotate TYPE NAME KEY=VAL [--overwrite]` | Add/update annotations |
| `api-resources` | `kubectl api-resources [flags]` | List available API resources |
| `api-versions` | `kubectl api-versions` | List available API versions |
| `apply` | `kubectl apply -f FILE` | Apply config from file/stdin |
| `attach` | `kubectl attach POD [-c CONTAINER] [-it]` | Attach to running container |
| `auth` | `kubectl auth SUBCOMMAND` | Inspect authorization |
| `autoscale` | `kubectl autoscale TYPE NAME --max=N` | Auto-scale a resource |
| `certificate` | `kubectl certificate SUBCOMMAND` | Modify certificate resources |
| `cluster-info` | `kubectl cluster-info` | Show control plane endpoints |
| `completion` | `kubectl completion SHELL` | Output shell completion code |
| `config` | `kubectl config SUBCOMMAND` | Modify kubeconfig |
| `cordon` | `kubectl cordon NODE` | Mark node unschedulable |
| `cp` | `kubectl cp SRC DEST` | Copy files to/from containers |
| `create` | `kubectl create -f FILE` | Create resources |
| `debug` | `kubectl debug POD [-it] --image=IMG` | Debugging sessions |
| `delete` | `kubectl delete TYPE [NAME\|-l label\|--all]` | Delete resources |
| `describe` | `kubectl describe TYPE [NAME]` | Detailed resource info + events |
| `diff` | `kubectl diff -f FILE` | Diff live vs would-be applied |
| `drain` | `kubectl drain NODE` | Evict pods from node |
| `edit` | `kubectl edit TYPE NAME` | Edit live resource in editor |
| `events` | `kubectl events` | List cluster events |
| `exec` | `kubectl exec POD [-c CTR] -- CMD` | Execute in container |
| `explain` | `kubectl explain TYPE[.field]` | Field documentation |
| `expose` | `kubectl expose TYPE NAME --port=N` | Expose as service |
| `get` | `kubectl get TYPE [NAME] [-o fmt]` | List/show resources |
| `kustomize` | `kubectl kustomize DIR` | Build kustomize output |
| `label` | `kubectl label TYPE NAME KEY=VAL` | Add/update labels |
| `logs` | `kubectl logs POD [-c CTR] [-f]` | Container logs |
| `patch` | `kubectl patch TYPE NAME --patch JSON` | Partially update resource |
| `plugin` | `kubectl plugin [list]` | Plugin utilities |
| `port-forward` | `kubectl port-forward POD LOCAL:REMOTE` | Port forwarding |
| `proxy` | `kubectl proxy [--port=N]` | Proxy to API server |
| `replace` | `kubectl replace -f FILE` | Replace resource from file |
| `rollout` | `kubectl rollout SUBCOMMAND` | Manage rollouts |
| `run` | `kubectl run NAME --image=IMG` | Run a pod/image |
| `scale` | `kubectl scale TYPE NAME --replicas=N` | Scale resource |
| `set` | `kubectl set SUBCOMMAND` | Configure app resources |
| `taint` | `kubectl taint NODE KEY=VAL:EFFECT` | Update node taints |
| `top` | `kubectl top (pod\|node)` | Resource usage (CPU/mem) |
| `uncordon` | `kubectl uncordon NODE` | Mark node schedulable |
| `version` | `kubectl version` | Print client+server versions |
| `wait` | `kubectl wait --for=condition=Ready pod/<name>` | Wait for condition |

## `kubectl config` Subcommands

| Subcommand | Description |
|------------|-------------|
| `current-context` | Show active context |
| `get-contexts` | List all contexts |
| `use-context NAME` | Switch to context |
| `set-context --current --namespace=NS` | Set default namespace |
| `set-cluster NAME --server=URL` | Add/update cluster |
| `set-credentials NAME --token=TOKEN` | Set credentials |
| `delete-context NAME` | Remove a context |
| `view` | Show merged kubeconfig |
| `view --minify` | Show only active context config |

## `kubectl rollout` Subcommands

| Subcommand | Description |
|------------|-------------|
| `status TYPE/NAME` | Watch rollout until complete |
| `history TYPE/NAME` | Show revision history |
| `undo TYPE/NAME` | Rollback to previous revision |
| `undo TYPE/NAME --to-revision=N` | Rollback to specific revision |
| `restart TYPE/NAME` | Rolling restart |
| `pause TYPE/NAME` | Pause a deployment |
| `resume TYPE/NAME` | Resume a paused deployment |

## `kubectl create` Subcommands

| Subcommand | Example |
|------------|---------|
| `deployment` | `kubectl create deployment nginx --image=nginx` |
| `service clusterip` | `kubectl create service clusterip svc --tcp=80:8080` |
| `secret generic` | `kubectl create secret generic s --from-literal=k=v` |
| `secret docker-registry` | `kubectl create secret docker-registry r --docker-server=...` |
| `configmap` | `kubectl create configmap cm --from-file=config.properties` |
| `namespace` | `kubectl create namespace my-ns` |
| `serviceaccount` | `kubectl create serviceaccount sa-name` |
| `role` | `kubectl create role r --verb=get,list --resource=pods` |
| `rolebinding` | `kubectl create rolebinding rb --role=r --user=u` |
| `clusterrole` | `kubectl create clusterrole cr --verb=get --resource=pods` |
| `clusterrolebinding` | `kubectl create clusterrolebinding crb --clusterrole=cr --user=u` |
| `job` | `kubectl create job j --image=busybox -- echo hello` |
| `cronjob` | `kubectl create cronjob cj --image=busybox --schedule="*/1 * * * *" -- echo hi` |
| `ingress` | `kubectl create ingress i --rule="host/path=svc:port"` |
| `token` | `kubectl create token <serviceaccount-name>` |

## `kubectl auth` Subcommands

| Subcommand | Description |
|------------|-------------|
| `can-i create pods` | Check if current user can perform action |
| `can-i '*' '*' --all-namespaces` | Check all permissions |
| `can-i list pods --as=user` | Check as another user |
| `whoami` | Show current user identity |
| `reconcile -f rbac.yaml` | Reconcile RBAC policies |

## `kubectl set` Subcommands

| Subcommand | Example |
|------------|---------|
| `image` | `kubectl set image deploy/app container=image:v2` |
| `env` | `kubectl set env deploy/app KEY=value` |
| `resources` | `kubectl set resources deploy/app --limits=cpu=200m` |
| `serviceaccount` | `kubectl set serviceaccount deploy/app mysa` |

## Common Resource Type Abbreviations

| Full name | Short name |
|-----------|------------|
| `pods` | `po` |
| `deployments` | `deploy` |
| `services` | `svc` |
| `replicasets` | `rs` |
| `statefulsets` | `sts` |
| `daemonsets` | `ds` |
| `namespaces` | `ns` |
| `nodes` | `no` |
| `configmaps` | `cm` |
| `persistentvolumeclaims` | `pvc` |
| `persistentvolumes` | `pv` |
| `horizontalpodautoscalers` | `hpa` |
| `ingresses` | `ing` |
| `serviceaccounts` | `sa` |
| `cronjobs` | `cj` |

## Output Format Summary

| Flag | Use case |
|------|----------|
| `-o yaml` | Full spec — copy to edit a manifest |
| `-o json` | Pipe to `jq` for complex queries |
| `-o name` | Scripting (just `pod/name`) |
| `-o wide` | Quick overview with node/IP |
| `-o jsonpath='...'` | Extract specific fields |
| `-o custom-columns=...'` | Custom table columns |
| `--sort-by=.metadata.name` | Sort list output |
| `-w` / `--watch` | Watch for changes live |

## Verbosity Flags

| Flag | Level |
|------|-------|
| `--v=0` | Always visible to cluster operator |
| `--v=2` | Recommended default |
| `--v=4` | Debug |
| `--v=6` | Show requested resources |
| `--v=7` | Show HTTP request headers |
| `--v=8` | Show HTTP request body |
