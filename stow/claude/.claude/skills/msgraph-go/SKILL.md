---
name: msgraph-go
description: "Microsoft Graph from Go: Teams (send messages, list channels, read conversations), SharePoint (sites, documents, drive items), M365 users. Covers azidentity credentials, msgraph-sdk-go client setup, OData pagination, error handling, and Bubble Tea async patterns for TUI apps."
argument-hint: "Describe the Microsoft resource to integrate (e.g., 'send Teams message', 'read SharePoint documents', 'list users')"
---

# Microsoft Graph & Azure SDK for Go

## When to Use

- Integrating Teams channels, chats, or messages into a Go app
- Reading or writing SharePoint sites, lists, or drive items
- Querying Microsoft 365 users, groups, or organization resources
- Setting up Azure Identity (app credentials, managed identity, device code)
- Adding a Microsoft integration layer to a Bubble Tea TUI project
- Paginating large Microsoft Graph collections

## Package Reference

| Package | Import path | Purpose |
|---------|------------|---------|
| msgraph-sdk-go | `github.com/microsoftgraph/msgraph-sdk-go` | Graph client and models |
| kiota-auth-azure-go | `github.com/microsoft/kiota-authentication-azure-go` | Auth bridge |
| azidentity | `github.com/Azure/azure-sdk-for-go/sdk/azidentity` | Credential providers |
| msgraph-sdk-go-core | `github.com/microsoftgraph/msgraph-sdk-go-core` | PageIterator |

## Installation

```bash
go get github.com/microsoftgraph/msgraph-sdk-go
go get github.com/microsoft/kiota-authentication-azure-go
go get github.com/Azure/azure-sdk-for-go/sdk/azidentity
go get github.com/microsoftgraph/msgraph-sdk-go-core
```

## Procedure

### 1. App Registration (Azure Portal)

1. Go to **Azure Portal → Microsoft Entra ID → App registrations → New registration**
2. Set redirect URI to `http://localhost` (for device code / interactive flows) or none (for client credentials)
3. Under **Certificates & secrets**, create a client secret
4. Under **API permissions**, add Microsoft Graph application/delegated permissions:
   - Teams: `ChannelMessage.Read.All`, `ChannelMessage.Send`, `Team.ReadBasic.All`
   - SharePoint: `Sites.Read.All`, `Sites.ReadWrite.All`, `Files.ReadWrite.All`
   - Users: `User.Read`, `User.ReadBasic.All`
5. Grant admin consent for application permissions

Record: **Tenant ID**, **Client ID**, **Client Secret**

### 2. Authentication Setup

See [authentication reference](./references/auth.md) for all credential types.

**Client Credentials (app-level, no user):**
```go
import (
    azidentity "github.com/Azure/azure-sdk-for-go/sdk/azidentity"
    auth "github.com/microsoft/kiota-authentication-azure-go"
    msgraphsdk "github.com/microsoftgraph/msgraph-sdk-go"
)

cred, err := azidentity.NewClientSecretCredential(tenantID, clientID, clientSecret, nil)
if err != nil {
    return fmt.Errorf("creating credential: %w", err)
}
authProvider, err := auth.NewAzureIdentityAuthenticationProviderWithScopes(
    cred, []string{"https://graph.microsoft.com/.default"},
)
adapter, err := msgraphsdk.NewGraphRequestAdapter(authProvider)
client := msgraphsdk.NewGraphServiceClient(adapter)
```

**Device Code (interactive user sign-in):**
```go
cred, err := azidentity.NewDeviceCodeCredential(&azidentity.DeviceCodeCredentialOptions{
    TenantID: tenantID,
    ClientID: clientID,
    UserPrompt: func(ctx context.Context, msg azidentity.DeviceCodeMessage) error {
        fmt.Println(msg.Message) // Print the device code URL to the user
        return nil
    },
})
```

### 3. Graph Client Construction

Always build the client once and reuse it. Inject it via constructor (no globals).

```go
type MSGraphClient struct {
    client *msgraphsdk.GraphServiceClient
}

func NewMSGraphClient(tenantID, clientID, clientSecret string) (*MSGraphClient, error) {
    cred, err := azidentity.NewClientSecretCredential(tenantID, clientID, clientSecret, nil)
    if err != nil {
        return nil, fmt.Errorf("azidentity: %w", err)
    }
    authProvider, err := auth.NewAzureIdentityAuthenticationProviderWithScopes(
        cred, []string{"https://graph.microsoft.com/.default"},
    )
    if err != nil {
        return nil, fmt.Errorf("auth provider: %w", err)
    }
    adapter, err := msgraphsdk.NewGraphRequestAdapter(authProvider)
    if err != nil {
        return nil, fmt.Errorf("adapter: %w", err)
    }
    return &MSGraphClient{client: msgraphsdk.NewGraphServiceClient(adapter)}, nil
}
```

### 4. Teams Integration

See [Teams reference](./references/teams.md) for full patterns.

**List teams the app can see:**
```go
result, err := client.Teams().Get(ctx, nil)
```

**Send a channel message:**
```go
import graphmodels "github.com/microsoftgraph/msgraph-sdk-go/models"

body := graphmodels.NewChatMessage()
content := graphmodels.NewItemBody()
text := "Hello from jirlab!"
content.SetContent(&text)
body.SetBody(content)

_, err := client.Teams().ByTeamId(teamID).Channels().ByChannelId(channelID).Messages().Post(ctx, body, nil)
```

### 5. SharePoint Integration

See [SharePoint reference](./references/sharepoint.md) for full patterns.

**List all sites:**
```go
result, err := client.Sites().GetAllSites().Get(ctx, nil)
```

**Get a drive item (file):**
```go
result, err := client.Sites().BySiteId(siteID).Drives().Get(ctx, nil)
```

### 6. Pagination with PageIterator

Always paginate large collections — never assume a single page.

```go
import (
    msgraphcore "github.com/microsoftgraph/msgraph-sdk-go-core"
    "github.com/microsoftgraph/msgraph-sdk-go/models"
)

result, err := client.Users().Get(ctx, nil)
if err != nil {
    return handleODataError(err)
}

pageIterator, err := msgraphcore.NewPageIterator[models.Userable](
    result,
    client.GetAdapter(),
    models.CreateUserCollectionResponseFromDiscriminatorValue,
)
err = pageIterator.Iterate(ctx, func(user models.Userable) bool {
    // process each user; return false to stop early
    return true
})
```

### 7. Error Handling

Always unwrap `ODataError` for structured Microsoft Graph errors.

```go
import "github.com/microsoftgraph/msgraph-sdk-go/models/odataerrors"

func handleODataError(err error) error {
    var odataErr *odataerrors.ODataError
    if errors.As(err, &odataErr) {
        if terr := odataErr.GetErrorEscaped(); terr != nil {
            return fmt.Errorf("graph api [%s]: %s", *terr.GetCode(), *terr.GetMessage())
        }
    }
    return err
}
```

### 8. Bubble Tea Integration Pattern

Follow the project's async pattern: wrap Graph calls in `tea.Cmd` returning `tea.Msg`.

```go
// Define message types
type MSGraphTeamsMsg struct {
    Teams []string
    Err   error
}

// Define command
func fetchTeamsCmd(c *MSGraphClient) tea.Cmd {
    return func() tea.Msg {
        ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
        defer cancel()

        result, err := c.client.Teams().Get(ctx, nil)
        if err != nil {
            return MSGraphTeamsMsg{Err: handleODataError(err)}
        }
        var names []string
        for _, t := range result.GetValue() {
            if t.GetDisplayName() != nil {
                names = append(names, *t.GetDisplayName())
            }
        }
        return MSGraphTeamsMsg{Teams: names}
    }
}

// In Update(), handle the message:
case MSGraphTeamsMsg:
    if msg.Err != nil {
        // handle error
        return m, nil
    }
    m.teams = msg.Teams
```

### 9. Integration Layer Placement

Per the project's architecture:
- Put the `MSGraphClient` struct and constructor in `internal/integration/`
- Define the interface in `internal/integration/` alongside other integration interfaces
- Never call the Graph SDK directly from `internal/tui/`; call through the interface
- Use `context.Context` on all methods

```go
// internal/integration/msgraph.go
type MSGraphIntegration interface {
    ListTeams(ctx context.Context) ([]string, error)
    SendTeamsMessage(ctx context.Context, teamID, channelID, text string) error
    ListSharePointSites(ctx context.Context) ([]string, error)
}
```

### 10. Configuration

Add these to Viper config / environment variables:
```
AZURE_TENANT_ID        - Azure AD tenant ID
AZURE_CLIENT_ID        - App registration client ID
AZURE_CLIENT_SECRET    - App registration client secret (use secret manager in prod)
MSGRAPH_TEAM_ID        - Default team ID for Teams operations
MSGRAPH_CHANNEL_ID     - Default channel ID for Teams operations
MSGRAPH_SITE_ID        - Default SharePoint site ID
```

Load in `internal/config/config.go` using existing Viper patterns.

## Quality Gates

- [ ] App registration has only the minimum required permissions (least privilege)
- [ ] Client secret is not hardcoded; loaded from env/config
- [ ] `context.Context` passed to all Graph calls with a deadline/timeout
- [ ] ODataError is properly unwrapped and logged
- [ ] Graph client constructed once and injected; not created per-call
- [ ] Integration interface defined so TUI layer depends on abstraction
- [ ] Pagination used for all collection endpoints
- [ ] Unit tests use a mock of the integration interface

## References

- [Authentication patterns](./references/auth.md)
- [Teams integration](./references/teams.md)
- [SharePoint integration](./references/sharepoint.md)
- [msgraph-sdk-go GitHub](https://github.com/microsoftgraph/msgraph-sdk-go)
- [Azure SDK for Go GitHub](https://github.com/Azure/azure-sdk-for-go/tree/main)
- [Microsoft Graph API reference](https://docs.microsoft.com/graph/api/overview)
- [azidentity package docs](https://pkg.go.dev/github.com/Azure/azure-sdk-for-go/sdk/azidentity)
