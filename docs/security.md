# Security Decisions (DevSecOps)

## Container Security

### Distroless Base Image
- **Image**: `gcr.io/distroless/java21-debian12:nonroot`
- **Why**: No shell, no package manager, no OS utilities → dramatically reduced attack surface
- **UID**: 65532 (`nonroot`) — never runs as root
- **CVE surface**: ~0 OS CVEs (vs. ~200+ on ubuntu-based images)

### JVM Security Flags
```
-Djava.security.egd=file:/dev/./urandom   # Fast SecureRandom (non-blocking)
-Dfile.encoding=UTF-8                      # Explicit encoding
-XX:+HeapDumpOnOutOfMemoryError           # OOM capture for forensics
```

## Kubernetes Security

### Pod Security Standards (restricted)
Applied at namespace level:
```yaml
pod-security.kubernetes.io/enforce: restricted
pod-security.kubernetes.io/audit: restricted
```

All pods satisfy:
- `runAsNonRoot: true`
- `runAsUser: 65532`
- `allowPrivilegeEscalation: false`
- `capabilities.drop: [ALL]`
- `seccompProfile: RuntimeDefault`

### NetworkPolicy
```
App pods  → MySQL:3306    ✅ allowed
App pods  → DNS:53        ✅ allowed
App pods  → Internet      ❌ blocked
MySQL     → App           ❌ blocked (one-way only)
MySQL     → Internet      ❌ blocked
```

### Secrets Management
| What | How |
|---|---|
| MySQL credentials | Jenkins Credentials → K8s Secret (via helm --set) |
| App credentials | Jenkins Credentials → K8s Secret (via helm --set) |
| Docker Hub | Jenkins Credentials (usernamePassword) |
| SonarQube token | Jenkins Credentials (secretText) |
| Kubeconfig | Jenkins Credentials (secretFile) |
| .env file (dev only) | Never committed (.gitignore) |

**Rule**: Zero secrets in code, YAML files, or Docker images.

## CI/CD Security

### Trivy Scan Policy
```
CRITICAL vulnerabilities → Pipeline FAILS (exit-code 1)
HIGH vulnerabilities     → Warning only (exit-code 0) + report archived
```

### Docker Image Build
- `--pull` flag: always uses latest base image
- OCI labels track exact git commit and build date
- Image never pushed if Trivy finds CRITICAL CVEs

### Dependency Management
- Dependabot: weekly Maven updates
- JaCoCo: minimum 70% coverage enforced in build
- SonarQube Quality Gate: blocks merge on new bugs/vulnerabilities

## Network Security

### Application Configuration
- TLS between app and MySQL (useSSL=true in prod)
- No Swagger UI in K8s/prod profile
- CORS restricted to allowed origins
- Basic auth on Actuator and API endpoints

## Recommendations for Production (beyond Minikube)

1. **Mutual TLS (mTLS)**: Use Istio or Linkerd service mesh
2. **Secret rotation**: Use HashiCorp Vault or AWS Secrets Manager
3. **Image signing**: Use Cosign to sign Docker images
4. **RBAC**: Create dedicated ServiceAccount with minimal permissions
5. **Audit logging**: Enable K8s API server audit logs
6. **Registry scanning**: Enable Docker Hub or GHCR vulnerability scanning
7. **Sealed Secrets**: Use Bitnami Sealed Secrets for GitOps-safe secrets
