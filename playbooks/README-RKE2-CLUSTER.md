# Création de Cluster RKE2 via API Rancher

Ce playbook permet de créer un cluster RKE2 via l'API Rancher avec configuration complète des mirrors de registries Docker.

## Fonctionnalités

- ✅ Création de cluster RKE2 via API Rancher (100% automatisé)
- ✅ Configuration de registry mirror (docker-proxy.office.toto.fr)
- ✅ Mirrors pour docker.io et quay.io
- ✅ Support TLS avec ou sans certificats auto-signés
- ✅ Génération automatique des commandes d'enregistrement des nodes
- ✅ Sauvegarde des commandes dans un fichier

## Prérequis

- Rancher 2.6+ déployé et accessible
- Credentials admin pour l'API Rancher
- Réseau permettant l'accès au registry mirror

## Utilisation Rapide

### 1. Création basique avec valeurs par défaut

```bash
ansible-playbook playbooks/create-rke2-cluster.yml
```

**Valeurs par défaut:**
- Cluster name: `rke2-cluster`
- Kubernetes version: `v1.28.15+rke2r1`
- Registry mirror: `docker-proxy.office.toto.fr`
- Rancher URL: `https://192.168.56.10:8443`

### 2. Création avec variables personnalisées

```bash
ansible-playbook playbooks/create-rke2-cluster.yml \
  -e cluster_name=production-rke2 \
  -e kubernetes_version=v1.29.3+rke2r1 \
  -e registry_mirror=registry.company.com
```

### 3. Création avec fichier de variables

```bash
# Copier l'exemple
cp playbooks/rke2-cluster-vars-example.yml playbooks/rke2-cluster-vars.yml

# Éditer le fichier selon vos besoins
vim playbooks/rke2-cluster-vars.yml

# Lancer le playbook
ansible-playbook playbooks/create-rke2-cluster.yml \
  -e @playbooks/rke2-cluster-vars.yml
```

## Configuration du Registry Mirror

Le playbook configure automatiquement les mirrors suivants:

```yaml
registries:
  mirrors:
    docker.io:
      endpoint:
        - "https://docker-proxy.office.toto.fr"
    quay.io:
      endpoint:
        - "https://docker-proxy.office.toto.fr"
  configs:
    "docker-proxy.office.toto.fr":
      tls:
        insecure_skip_verify: false
```

### Ajouter des mirrors supplémentaires

Modifiez la variable `registry_mirrors` :

```bash
ansible-playbook playbooks/create-rke2-cluster.yml \
  -e '{"registry_mirrors": [
    {"source": "docker.io", "mirror": "docker-proxy.office.toto.fr"},
    {"source": "quay.io", "mirror": "docker-proxy.office.toto.fr"},
    {"source": "gcr.io", "mirror": "docker-proxy.office.toto.fr"},
    {"source": "ghcr.io", "mirror": "docker-proxy.office.toto.fr"}
  ]}'
```

### Registry avec certificats auto-signés

```bash
ansible-playbook playbooks/create-rke2-cluster.yml \
  -e registry_insecure_skip_verify=true
```

## Après la Création

### 1. Récupérer les commandes d'enregistrement

Les commandes sont affichées dans l'output du playbook et sauvegardées dans:
```
rke2-cluster-registration.txt
```

### 2. Enregistrer des nodes

Sur chaque serveur que vous voulez ajouter au cluster:

```bash
# Pour production (avec certificats valides)
curl -fL https://192.168.56.10:8443/system-agent-install.sh | \
  sudo sh -s - --server https://192.168.56.10:8443 \
  --label 'cattle.io/os=linux' \
  --token <TOKEN>

# Pour testing (certificats auto-signés)
curl --insecure -fL https://192.168.56.10:8443/system-agent-install.sh | \
  sudo sh -s - --server https://192.168.56.10:8443 \
  --label 'cattle.io/os=linux' \
  --token <TOKEN>
```

### 3. Configurer les rôles des nodes

Dans l'interface Rancher, configurez les rôles pour chaque node:
- **Control Plane**: Nœuds qui exécutent le control plane Kubernetes
- **etcd**: Nœuds qui font partie du cluster etcd
- **Worker**: Nœuds qui exécutent les workloads

**Recommandation pour production:**
- 3 nodes avec roles: Control Plane + etcd
- N nodes avec role: Worker

### 4. Vérifier le cluster

```bash
# Via l'interface Rancher
https://192.168.56.10:8443/dashboard/c/<CLUSTER_ID>/explorer

# Via l'API
curl -k -H "Authorization: Bearer <TOKEN>" \
  https://192.168.56.10:8443/v1/provisioning.cattle.io.clusters/fleet-default/rke2-cluster
```

## Variables Disponibles

| Variable | Défaut | Description |
|----------|--------|-------------|
| `rancher_url` | `https://192.168.56.10:8443` | URL de Rancher |
| `rancher_admin_user` | `admin` | Utilisateur admin Rancher |
| `rancher_admin_password` | `admin123456789` | Mot de passe admin |
| `rancher_verify_ssl` | `false` | Vérifier les certificats SSL |
| `cluster_name` | `rke2-cluster` | Nom du cluster |
| `kubernetes_version` | `v1.28.15+rke2r1` | Version de Kubernetes |
| `registry_mirror` | `docker-proxy.office.toto.fr` | Registry mirror principal |
| `registry_mirrors` | `[docker.io, quay.io]` | Liste des sources à mirror |
| `registry_insecure_skip_verify` | `false` | Ignorer validation TLS |
| `cluster_cidr` | `10.42.0.0/16` | CIDR du réseau cluster |
| `service_cidr` | `10.43.0.0/16` | CIDR du réseau services |
| `cluster_dns` | `10.43.0.10` | IP du DNS cluster |

## Exemples d'Utilisation

### Cluster de Production

```bash
ansible-playbook playbooks/create-rke2-cluster.yml \
  -e cluster_name=prod-cluster \
  -e kubernetes_version=v1.29.3+rke2r1 \
  -e registry_mirror=registry.company.com \
  -e registry_insecure_skip_verify=false
```

### Cluster de Développement

```bash
ansible-playbook playbooks/create-rke2-cluster.yml \
  -e cluster_name=dev-cluster \
  -e kubernetes_version=v1.28.15+rke2r1 \
  -e registry_mirror=docker-proxy.dev.local \
  -e registry_insecure_skip_verify=true
```

### Cluster avec Multiples Registries

Créer un fichier `custom-registries.yml`:
```yaml
cluster_name: "multi-registry-cluster"
registry_mirror: "primary-registry.company.com"
registry_mirrors:
  - source: "docker.io"
    mirror: "docker-mirror.company.com"
  - source: "quay.io"
    mirror: "quay-mirror.company.com"
  - source: "gcr.io"
    mirror: "gcr-mirror.company.com"
  - source: "ghcr.io"
    mirror: "ghcr-mirror.company.com"
```

Puis lancer:
```bash
ansible-playbook playbooks/create-rke2-cluster.yml \
  -e @custom-registries.yml
```

## Vérification de la Configuration Registry

Une fois le cluster actif, vérifier que les mirrors sont bien configurés:

```bash
# Se connecter à un node du cluster
ssh user@node-ip

# Vérifier la configuration RKE2
sudo cat /etc/rancher/rke2/registries.yaml
```

Vous devriez voir:
```yaml
mirrors:
  docker.io:
    endpoint:
      - "https://docker-proxy.office.toto.fr"
  quay.io:
    endpoint:
      - "https://docker-proxy.office.toto.fr"
configs:
  "docker-proxy.office.toto.fr":
    tls:
      insecure_skip_verify: false
```

## Troubleshooting

### Erreur d'authentification

```
Status code was 401 and not [201]: HTTP Error 401: Unauthorized
```

**Solution:** Vérifier les credentials Rancher
```bash
ansible-playbook playbooks/create-rke2-cluster.yml \
  -e rancher_admin_password=VOTRE_MOT_DE_PASSE
```

### Cluster déjà existant

```
Cluster already exists, skipping creation
```

**Solution:** Changer le nom du cluster ou supprimer l'ancien
```bash
# Nouveau nom
ansible-playbook playbooks/create-rke2-cluster.yml \
  -e cluster_name=nouveau-cluster

# Ou supprimer via l'UI Rancher
```

### Registry inaccessible

Si les nodes ne peuvent pas pull les images:

1. Vérifier la connectivité réseau vers le registry
```bash
curl -v https://docker-proxy.office.toto.fr
```

2. Vérifier les certificats TLS
```bash
# Si auto-signé, utiliser:
ansible-playbook playbooks/create-rke2-cluster.yml \
  -e registry_insecure_skip_verify=true
```

3. Vérifier la configuration sur le node
```bash
sudo cat /etc/rancher/rke2/registries.yaml
sudo systemctl status rke2-server  # ou rke2-agent
sudo journalctl -u rke2-server -f  # voir les logs
```

## Versions Kubernetes Disponibles

Pour voir les versions disponibles, consultez l'interface Rancher ou utilisez l'API:

```bash
curl -k -H "Authorization: Bearer <TOKEN>" \
  https://192.168.56.10:8443/v1/management.cattle.io.kontainerdrivers
```

Versions couramment utilisées:
- `v1.29.3+rke2r1` (Latest stable)
- `v1.28.15+rke2r1` (LTS)
- `v1.27.16+rke2r1` (Older LTS)

## Architecture Recommandée

### Cluster de Production
```
3x Control Plane + etcd + Worker (HA)
  → 3 nodes minimum
  → 8 CPU, 16 GB RAM par node
  → Disks SSD pour etcd

Nx Worker uniquement
  → Selon charge de travail
  → 4 CPU, 8 GB RAM minimum
```

### Cluster de Développement
```
1x Control Plane + etcd + Worker
  → 4 CPU, 8 GB RAM

Optionnel: 1-2x Worker
  → 2 CPU, 4 GB RAM
```

## Ressources

- [Documentation RKE2](https://docs.rke2.io/)
- [Rancher API Documentation](https://rancher.com/docs/rancher/v2.x/en/api/)
- [Registry Configuration](https://docs.rke2.io/install/containerd_registry_configuration)
