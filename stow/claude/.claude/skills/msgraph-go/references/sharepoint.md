# SharePoint Integration Reference

Using `github.com/microsoftgraph/msgraph-sdk-go` for SharePoint/OneDrive operations.

## Required App Permissions

| Permission | Type | Use |
|-----------|------|-----|
| `Sites.Read.All` | Application | Read all SharePoint sites |
| `Sites.ReadWrite.All` | Application | Read and write to sites |
| `Files.Read.All` | Application | Read files in all drives |
| `Files.ReadWrite.All` | Application | Read/write files in all drives |

## List All Sites

```go
func (c *MSGraphClient) ListAllSites(ctx context.Context) ([]SiteInfo, error) {
    result, err := c.client.Sites().GetAllSites().Get(ctx, nil)
    if err != nil {
        return nil, handleODataError(err)
    }
    var sites []SiteInfo
    for _, s := range result.GetValue() {
        sites = append(sites, SiteInfo{
            ID:          deref(s.GetId()),
            Name:        deref(s.GetName()),
            DisplayName: deref(s.GetDisplayName()),
            WebURL:      deref(s.GetWebUrl()),
        })
    }
    return sites, nil
}
```

## Get a Specific Site by URL

```go
// siteHostname: e.g. "myorg.sharepoint.com"
// sitePath:     e.g. "/sites/myteamsite"
func (c *MSGraphClient) GetSite(ctx context.Context, siteHostname, sitePath string) (*SiteInfo, error) {
    siteID := siteHostname + ":" + sitePath
    result, err := c.client.Sites().BySiteId(siteID).Get(ctx, nil)
    if err != nil {
        return nil, handleODataError(err)
    }
    return &SiteInfo{
        ID:          deref(result.GetId()),
        Name:        deref(result.GetName()),
        DisplayName: deref(result.GetDisplayName()),
        WebURL:      deref(result.GetWebUrl()),
    }, nil
}
```

## List Drives (Document Libraries) in a Site

```go
func (c *MSGraphClient) ListDrives(ctx context.Context, siteID string) ([]DriveInfo, error) {
    result, err := c.client.Sites().BySiteId(siteID).Drives().Get(ctx, nil)
    if err != nil {
        return nil, handleODataError(err)
    }
    var drives []DriveInfo
    for _, d := range result.GetValue() {
        drives = append(drives, DriveInfo{
            ID:   deref(d.GetId()),
            Name: deref(d.GetName()),
        })
    }
    return drives, nil
}
```

## List Files in a Drive/Folder

```go
func (c *MSGraphClient) ListDriveItems(ctx context.Context, siteID, driveID, folderID string) ([]DriveItemInfo, error) {
    var result models.DriveItemCollectionResponseable
    var err error

    if folderID == "" || folderID == "root" {
        result, err = c.client.Sites().BySiteId(siteID).
            Drives().ByDriveId(driveID).Root().Children().Get(ctx, nil)
    } else {
        result, err = c.client.Sites().BySiteId(siteID).
            Drives().ByDriveId(driveID).Items().ByDriveItemId(folderID).Children().Get(ctx, nil)
    }
    if err != nil {
        return nil, handleODataError(err)
    }

    var items []DriveItemInfo
    for _, item := range result.GetValue() {
        isFolder := item.GetFolder() != nil
        items = append(items, DriveItemInfo{
            ID:       deref(item.GetId()),
            Name:     deref(item.GetName()),
            IsFolder: isFolder,
            WebURL:   deref(item.GetWebUrl()),
            Size:     item.GetSize(),
        })
    }
    return items, nil
}
```

## Download File Content

```go
func (c *MSGraphClient) DownloadFile(ctx context.Context, siteID, driveID, itemID string) ([]byte, error) {
    stream, err := c.client.Sites().BySiteId(siteID).
        Drives().ByDriveId(driveID).
        Items().ByDriveItemId(itemID).Content().Get(ctx, nil)
    if err != nil {
        return nil, handleODataError(err)
    }
    defer stream.Close()
    return io.ReadAll(stream)
}
```

## Upload File Content

```go
func (c *MSGraphClient) UploadFile(ctx context.Context, siteID, driveID, parentFolderID, filename string, content []byte) error {
    itemPath := parentFolderID + ":/" + filename + ":"
    reader := bytes.NewReader(content)
    _, err := c.client.Sites().BySiteId(siteID).
        Drives().ByDriveId(driveID).
        Items().ByDriveItemId(itemPath).Content().Put(ctx, reader, nil)
    return handleODataError(err)
}
```

For files larger than 4 MB, use the [large file upload session API](https://learn.microsoft.com/graph/api/driveitem-createuploadsession).

## Search Files in a Site

```go
import "github.com/microsoftgraph/msgraph-sdk-go/sites"

func (c *MSGraphClient) SearchFiles(ctx context.Context, siteID, query string) ([]DriveItemInfo, error) {
    result, err := c.client.Sites().BySiteId(siteID).
        Drive().Root().SearchWithQ(&query).Get(ctx, nil)
    if err != nil {
        return nil, handleODataError(err)
    }
    var items []DriveItemInfo
    for _, item := range result.GetValue() {
        items = append(items, DriveItemInfo{
            ID:     deref(item.GetId()),
            Name:   deref(item.GetName()),
            WebURL: deref(item.GetWebUrl()),
        })
    }
    return items, nil
}
```

## SharePoint Lists

```go
func (c *MSGraphClient) GetListItems(ctx context.Context, siteID, listID string) ([]map[string]any, error) {
    result, err := c.client.Sites().BySiteId(siteID).
        Lists().ByListId(listID).Items().Get(ctx, nil)
    if err != nil {
        return nil, handleODataError(err)
    }
    var out []map[string]any
    for _, item := range result.GetValue() {
        fields := item.GetFields()
        if fields != nil {
            out = append(out, fields.GetAdditionalData())
        }
    }
    return out, nil
}
```

## Domain Models

```go
type SiteInfo struct {
    ID          string
    Name        string
    DisplayName string
    WebURL      string
}

type DriveInfo struct {
    ID   string
    Name string
}

type DriveItemInfo struct {
    ID       string
    Name     string
    IsFolder bool
    WebURL   string
    Size     *int64
}
```

## Bubble Tea Command Pattern

```go
type SharePointFilesMsg struct {
    Items []DriveItemInfo
    Err   error
}

func fetchSharePointFilesCmd(integration MSGraphIntegration, siteID, driveID string) tea.Cmd {
    return func() tea.Msg {
        ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
        defer cancel()
        items, err := integration.ListDriveItems(ctx, siteID, driveID, "root")
        return SharePointFilesMsg{Items: items, Err: err}
    }
}
```

## Notes

- SharePoint site IDs use the format: `{hostname},{siteGUID},{webGUID}` — always obtain programmatically
- For tenant-wide root site: use `c.client.Sites().BySiteId("root")`
- For user's OneDrive: use `c.client.Me().Drive()` (delegated auth required)
- Large file downloads should stream to disk, not load fully into memory
