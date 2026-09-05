# Microsoft Teams Integration Reference

Using `github.com/microsoftgraph/msgraph-sdk-go` for Teams operations.

## Required App Permissions

| Permission | Type | Use |
|-----------|------|-----|
| `Team.ReadBasic.All` | Application | List all teams |
| `Channel.ReadBasic.All` | Application | List channels in a team |
| `ChannelMessage.Read.All` | Application | Read channel messages |
| `ChannelMessage.Send` | Delegated | Send messages (requires user context) |
| `Chat.Read` | Delegated | Read user chats |
| `Chat.ReadWrite` | Delegated | Send chat messages |

> Note: `ChannelMessage.Send` is delegated-only — it requires DeviceCodeCredential or interactive auth. For app-only message sending, use [incoming webhooks](https://learn.microsoft.com/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook) or the Bot Framework instead.

## List All Teams

```go
func (c *MSGraphClient) ListTeams(ctx context.Context) ([]TeamInfo, error) {
    result, err := c.client.Teams().Get(ctx, nil)
    if err != nil {
        return nil, handleODataError(err)
    }
    var teams []TeamInfo
    for _, t := range result.GetValue() {
        teams = append(teams, TeamInfo{
            ID:          deref(t.GetId()),
            DisplayName: deref(t.GetDisplayName()),
        })
    }
    return teams, nil
}
```

## List Channels in a Team

```go
func (c *MSGraphClient) ListChannels(ctx context.Context, teamID string) ([]ChannelInfo, error) {
    result, err := c.client.Teams().ByTeamId(teamID).Channels().Get(ctx, nil)
    if err != nil {
        return nil, handleODataError(err)
    }
    var channels []ChannelInfo
    for _, ch := range result.GetValue() {
        channels = append(channels, ChannelInfo{
            ID:          deref(ch.GetId()),
            DisplayName: deref(ch.GetDisplayName()),
        })
    }
    return channels, nil
}
```

## Read Channel Messages (with Pagination)

```go
import (
    msgraphcore "github.com/microsoftgraph/msgraph-sdk-go-core"
    "github.com/microsoftgraph/msgraph-sdk-go/models"
)

func (c *MSGraphClient) GetChannelMessages(ctx context.Context, teamID, channelID string) ([]Message, error) {
    result, err := c.client.Teams().ByTeamId(teamID).Channels().ByChannelId(channelID).Messages().Get(ctx, nil)
    if err != nil {
        return nil, handleODataError(err)
    }

    var messages []Message
    pageIter, err := msgraphcore.NewPageIterator[models.ChatMessageable](
        result,
        c.client.GetAdapter(),
        models.CreateChatMessageCollectionResponseFromDiscriminatorValue,
    )
    if err != nil {
        return nil, err
    }
    err = pageIter.Iterate(ctx, func(msg models.ChatMessageable) bool {
        body := ""
        if b := msg.GetBody(); b != nil && b.GetContent() != nil {
            body = *b.GetContent()
        }
        messages = append(messages, Message{
            ID:      deref(msg.GetId()),
            Body:    body,
            Sender:  getSenderName(msg),
            Created: msg.GetCreatedDateTime(),
        })
        return true // continue
    })
    return messages, err
}

func getSenderName(msg models.ChatMessageable) string {
    if s := msg.GetFrom(); s != nil {
        if u := s.GetUser(); u != nil && u.GetDisplayName() != nil {
            return *u.GetDisplayName()
        }
    }
    return "unknown"
}
```

## Send a Channel Message (Delegated Auth Required)

```go
import graphmodels "github.com/microsoftgraph/msgraph-sdk-go/models"

func (c *MSGraphClient) SendChannelMessage(ctx context.Context, teamID, channelID, text string) error {
    msg := graphmodels.NewChatMessage()
    body := graphmodels.NewItemBody()
    body.SetContent(&text)
    msg.SetBody(body)

    _, err := c.client.Teams().ByTeamId(teamID).
        Channels().ByChannelId(channelID).
        Messages().Post(ctx, msg, nil)
    return handleODataError(err)
}
```

## List User's Chats (1:1 and Group Chats)

Requires delegated auth (DeviceCodeCredential with `Chat.Read` scope).

```go
func (c *MSGraphClient) ListMyChats(ctx context.Context) ([]ChatInfo, error) {
    result, err := c.client.Me().Chats().Get(ctx, nil)
    if err != nil {
        return nil, handleODataError(err)
    }
    var chats []ChatInfo
    for _, ch := range result.GetValue() {
        chats = append(chats, ChatInfo{
            ID:    deref(ch.GetId()),
            Topic: deref(ch.GetTopic()),
        })
    }
    return chats, nil
}
```

## Domain Models (place in internal/integration or internal/service)

```go
type TeamInfo struct {
    ID          string
    DisplayName string
}

type ChannelInfo struct {
    ID          string
    DisplayName string
}

type Message struct {
    ID      string
    Body    string
    Sender  string
    Created *time.Time
}

type ChatInfo struct {
    ID    string
    Topic string
}
```

## Bubble Tea Command Pattern

```go
type TeamsChannelsMsg struct {
    Channels []ChannelInfo
    Err      error
}

func fetchChannelsCmd(integration MSGraphIntegration, teamID string) tea.Cmd {
    return func() tea.Msg {
        ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
        defer cancel()
        channels, err := integration.ListChannels(ctx, teamID)
        return TeamsChannelsMsg{Channels: channels, Err: err}
    }
}
```

## Helper

```go
func deref(s *string) string {
    if s == nil {
        return ""
    }
    return *s
}
```
