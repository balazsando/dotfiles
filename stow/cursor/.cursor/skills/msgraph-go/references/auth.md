# Azure Identity Authentication Reference

All credential types from `github.com/Azure/azure-sdk-for-go/sdk/azidentity`.

## Credential Decision Tree

```
Is this a server/daemon (no user)?
  └── Yes → ClientSecretCredential  (service principal + secret)
            or CertificateCredential (service principal + cert)
            or ManagedIdentityCredential (Azure-hosted, no secret needed)
  └── No  → Is this a CLI/TUI tool?
              └── Yes → DeviceCodeCredential  (prints a URL, user authenticates)
                        or InteractiveBrowserCredential (opens browser)
              └── No  → UsernamePasswordCredential  (not recommended)
```

## ClientSecretCredential (Service Principal)

Best for background daemons, CI, and server-side apps. Requires admin consent for application permissions.

```go
import azidentity "github.com/Azure/azure-sdk-for-go/sdk/azidentity"

cred, err := azidentity.NewClientSecretCredential(
    os.Getenv("AZURE_TENANT_ID"),
    os.Getenv("AZURE_CLIENT_ID"),
    os.Getenv("AZURE_CLIENT_SECRET"),
    nil, // *azidentity.ClientSecretCredentialOptions
)
```

Required permissions: application permissions (not delegated) in Azure Portal.

## DeviceCodeCredential (Interactive TUI / CLI)

Prints a URL + code; user authenticates in browser. Ideal for TUI apps like jirlab.
Must enable **Allow public client flows** on the app registration.

```go
cred, err := azidentity.NewDeviceCodeCredential(&azidentity.DeviceCodeCredentialOptions{
    TenantID: os.Getenv("AZURE_TENANT_ID"),
    ClientID: os.Getenv("AZURE_CLIENT_ID"),
    UserPrompt: func(ctx context.Context, msg azidentity.DeviceCodeMessage) error {
        fmt.Fprintln(os.Stderr, msg.Message) // or bubble tea message
        return nil
    },
})
```

Token is cached automatically in memory for the session. Use `TokenCachePersistenceOptions` to persist across restarts.

## ManagedIdentityCredential (Azure-hosted)

Zero secrets needed. Only works when running on an Azure resource (VM, Container Apps, AKS pod with workload identity, etc.).

```go
cred, err := azidentity.NewManagedIdentityCredential(nil)
// or with explicit client ID for user-assigned identity:
cred, err := azidentity.NewManagedIdentityCredential(&azidentity.ManagedIdentityCredentialOptions{
    ID: azidentity.ClientID("your-managed-identity-client-id"),
})
```

## DefaultAzureCredential (Chained, Development-friendly)

Tries a chain: environment variables → workload identity → managed identity → Azure CLI → Azure Developer CLI → Visual Studio → browser. Good for local dev when running `az login`.

```go
cred, err := azidentity.NewDefaultAzureCredential(nil)
```

For production, prefer an explicit credential type.

## Building the Auth Provider for Graph SDK

```go
import (
    azidentity "github.com/Azure/azure-sdk-for-go/sdk/azidentity"
    auth "github.com/microsoft/kiota-authentication-azure-go"
    msgraphsdk "github.com/microsoftgraph/msgraph-sdk-go"
)

func newGraphClient(cred azcore.TokenCredential, scopes []string) (*msgraphsdk.GraphServiceClient, error) {
    authProvider, err := auth.NewAzureIdentityAuthenticationProviderWithScopes(cred, scopes)
    if err != nil {
        return nil, fmt.Errorf("auth provider: %w", err)
    }
    adapter, err := msgraphsdk.NewGraphRequestAdapter(authProvider)
    if err != nil {
        return nil, fmt.Errorf("request adapter: %w", err)
    }
    return msgraphsdk.NewGraphServiceClient(adapter), nil
}
```

### Scopes

| Use case | Scope |
|----------|-------|
| App-only (service principal) | `https://graph.microsoft.com/.default` |
| Delegated (user) | Individual scopes, e.g. `"User.Read"`, `"ChannelMessage.Send"` |

## Environment Variables (standard Azure SDK names)

```
AZURE_TENANT_ID       - Directory (tenant) ID
AZURE_CLIENT_ID       - Application (client) ID
AZURE_CLIENT_SECRET   - Client secret value
AZURE_CLIENT_CERTIFICATE_PATH - Path to PEM/PFX (for cert auth)
```

`DefaultAzureCredential` reads these automatically.

## Security Notes

- Never commit client secrets to source control
- Prefer managed identity or workload identity for production Azure workloads
- Rotate client secrets regularly (max 2 years in Azure Portal)
- Use `context.WithTimeout` on all credential/token operations
- Client secrets in config should be loaded from environment or secret manager (e.g., Azure Key Vault)
