# Troubleshooting Guide

Common issues and solutions for the jira-ticket-reader skill.

## Quick Diagnosis

### Symptom Checklist

Run through this checklist to identify the issue:

- [ ] Is Git CLI installed? (`git --version`)
- [ ] Are you in a git repository? (`git rev-parse --git-dir`)
- [ ] Is Atlassian MCP server connected?
- [ ] Do you have Jira permissions for the ticket?
- [ ] Does the ticket exist in Jira?
- [ ] Is the branch name format correct?

## Common Issues

### 1. No Ticket ID Found in Branch

**Symptoms:**
- Skill reports "No ticket ID found in branch name"
- Branch doesn't contain expected ticket pattern

**Causes:**
- Branch name doesn't follow convention (e.g., `feature/new-feature`)
- Ticket ID uses lowercase (e.g., `mca-402` instead of `MCA-402`)
- Ticket ID has different format (e.g., `PROJ_123` instead of `PROJ-123`)

**Solutions:**

**Option 1: Rename Branch**
```powershell
# Rename current branch to include ticket ID
git branch -m "feature/MCA-402-new-feature"
```

**Option 2: Manual Input**
The skill will automatically:
1. Query Jira for tickets in "In Development"
2. List available tickets
3. Ask you to choose one
4. Or accept manual ticket ID input

**Option 3: Update Regex Pattern**
If your project uses different ticket format, update the regex in SKILL.md.

---

### 2. MCP Unauthorized Error

**Symptoms:**
- `401 Unauthorized` error from Atlassian MCP
- "Authentication failed" message

**Causes:**
- MCP server not connected
- Authentication token expired
- Invalid credentials

**Solutions:**

**Step 1: Check MCP Connection**
```javascript
// Test MCP connection
mcp_atlassian-mcp-server_getAccessibleAtlassianResources()
```

**Step 2: Reconnect MCP Server**
1. Open MCP settings in your IDE
2. Disconnect Atlassian MCP server
3. Reconnect with valid credentials
4. Retry the operation

**Step 3: Verify Permissions**
- Ensure you have Jira access
- Check project permissions
- Verify API token is valid

**Note:** The skill automatically retries unauthorized errors up to 3 times with exponential backoff.

---

### 3. Ticket Not Found (404)

**Symptoms:**
- `404 Not Found` error
- "Ticket does not exist" message

**Causes:**
- Ticket ID doesn't exist in Jira
- Typo in ticket ID
- No permission to view ticket
- Ticket is in different Jira instance

**Solutions:**

**Verify Ticket Exists:**
1. Open Jira in browser
2. Navigate to: `https://metrc-tech.atlassian.net/browse/{TICKET-ID}`
3. Confirm ticket is accessible

**Check Permissions:**
- Verify you're assigned to the project
- Check if ticket is restricted
- Confirm you have "Browse Projects" permission

**Verify Cloud ID:**
```javascript
// Ensure correct Jira instance
const resources = mcp_atlassian-mcp-server_getAccessibleAtlassianResources();
// Should return metrc-tech.atlassian.net
```

---

### 4. Empty or Missing Description

**Symptoms:**
- Documentation created but description is empty
- "No description provided" in output

**Causes:**
- Ticket description field is actually empty
- Description is in a custom field
- ADF conversion failed

**Solutions:**

**Check Custom Fields:**
```javascript
// Fetch issue with all fields
const issue = mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-402",
  expand: "names"
});

// Check names object for custom description fields
console.log(issue.names);
```

**Use Comments Instead:**
If description is empty but comments exist, the skill will include comments in the documentation.

**Manual Description:**
Add description directly in Jira, then re-run the skill.

---

### 5. ADF Conversion Failure

**Symptoms:**
- Garbled or malformed Markdown output
- Raw JSON in documentation
- Conversion error messages

**Causes:**
- Malformed ADF structure
- Unsupported ADF elements
- Nested structures too deep

**Solutions:**

**Fallback to Plain Text:**
The skill automatically attempts plain text extraction if ADF conversion fails.

**Check ADF Structure:**
```javascript
// Inspect raw description
const issue = mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-402",
  fields: ["description"]
});

console.log(JSON.stringify(issue.fields.description, null, 2));
```

**Report Unsupported Elements:**
If you encounter unsupported ADF elements, note the element type and structure for future improvements.

---

### 6. File Creation Failed

**Symptoms:**
- "Permission denied" error
- Files not created in expected location
- Empty files created

**Causes:**
- Insufficient file system permissions
- Disk space full
- Directory doesn't exist
- Path too long (Windows)

**Solutions:**

**Check Permissions:**
```powershell
# Verify write access
Test-Path "personal/docs/" -PathType Container

# Create directory if missing
New-Item -ItemType Directory -Force -Path "personal/docs/"
```

**Check Disk Space:**
```powershell
# Windows
Get-PSDrive C | Select-Object Used,Free

# Unix/Mac
df -h .
```

**Shorten Path:**
If on Windows and path is too long, move project closer to root:
- `C:\projects\metrc` instead of `C:\Users\...\very\long\path\`

---

### 7. Images Not Downloaded

**Symptoms:**
- Images README created but images not present
- "Cannot download images" message

**Expected Behavior:**
This is **not an error**. Images cannot be downloaded automatically because:
- Jira image URLs require browser authentication
- MCP doesn't support authenticated file downloads
- Security restrictions prevent direct access

**Solution:**
Follow the manual download instructions in `images/README.md`:
1. Open ticket in browser
2. Right-click each image
3. Save to `images/` folder

---

### 8. Multiple Tickets in Development

**Symptoms:**
- Skill lists multiple tickets
- Asks which one to use

**Expected Behavior:**
This is **not an error**. The skill is asking you to choose because:
- You have multiple tickets in "In Development" status
- Branch name doesn't contain a ticket ID

**Solution:**
1. Review the listed tickets
2. Choose the one you want to document
3. Or checkout the correct branch first

---

### 9. Git Not Found

**Symptoms:**
- `git: command not found`
- "Git CLI not installed" error

**Causes:**
- Git not installed
- Git not in PATH
- Using wrong shell

**Solutions:**

**Install Git:**
- **Windows:** Download from [git-scm.com](https://git-scm.com/)
- **Mac:** `brew install git` or Xcode Command Line Tools
- **Linux:** `sudo apt install git` or `sudo yum install git`

**Verify Installation:**
```powershell
git --version
# Should output: git version 2.x.x
```

**Add to PATH:**
If installed but not found, add Git to your PATH environment variable.

---

### 10. Validation Failed

**Symptoms:**
- "File validation failed" message
- Files created but reported as invalid
- File size is 0 bytes

**Causes:**
- ADF conversion produced empty output
- File write operation failed
- Encoding issues

**Solutions:**

**Check File Contents:**
```powershell
# View file contents
Get-Content "personal/docs/MCA-402/MCA-402.md"

# Check file size
(Get-Item "personal/docs/MCA-402/MCA-402.md").Length
```

**Retry with Verbose Logging:**
Enable detailed logging to see where the process fails.

**Manual Verification:**
Open the files in a text editor to verify contents.

---

## Error Codes Reference

| Code | Category | Meaning | Action |
|------|----------|---------|--------|
| `BRANCH_NO_TICKET` | Validation | No ticket ID in branch name | Provide ticket ID manually |
| `MCP_UNAUTHORIZED` | Authentication | MCP auth failed | Reconnect MCP server |
| `TICKET_NOT_FOUND` | Data | Ticket doesn't exist | Verify ticket ID |
| `PERMISSION_DENIED` | Authentication | No access to ticket | Check Jira permissions |
| `NETWORK_TIMEOUT` | Network | Request timed out | Retry operation |
| `INVALID_CLOUD_ID` | Validation | Wrong Jira instance | Re-fetch resources |
| `ADF_CONVERSION_FAILED` | Data | ADF parsing error | Use plain text fallback |
| `IMAGE_DOWNLOAD_BLOCKED` | Network | Can't download images | Manual download required |
| `EMPTY_DESCRIPTION` | Data | No description content | Check custom fields |
| `FILE_CREATION_FAILED` | System | Can't write files | Check permissions |

## Advanced Troubleshooting

### Enable Debug Mode

For detailed diagnostics, enable verbose output:

```powershell
# Set verbose preference
$VerbosePreference = "Continue"

# Run skill with verbose output
# (Implementation depends on how skill is invoked)
```

### Inspect MCP Responses

To debug MCP issues, inspect raw responses:

```javascript
// Get raw issue data
const issue = mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-402"
});

// Log full response
console.log(JSON.stringify(issue, null, 2));
```

### Test Individual Steps

Isolate the failing step:

1. **Test Git:** `git branch --show-current`
2. **Test MCP:** `mcp_atlassian-mcp-server_getAccessibleAtlassianResources()`
3. **Test Jira Access:** Fetch a known ticket
4. **Test File Creation:** Create test file in `personal/docs/`

### Check Logs

Review logs for detailed error messages:
- IDE console output
- MCP server logs
- System error logs

## Getting Help

If issues persist:

1. **Gather Information:**
   - Error message (full text)
   - Steps to reproduce
   - Git branch name
   - Ticket ID
   - MCP connection status

2. **Check Documentation:**
   - [Jira MCP API Reference](jira-mcp.md)
   - [ADF Conversion Guide](adf-conversion.md)
   - [Git Operations](git-operations.md)

3. **Report Issue:**
   - Provide error details
   - Include relevant logs
   - Describe expected vs actual behavior

## Prevention

### Best Practices to Avoid Issues

1. **Use Standard Branch Naming:**
   - Format: `type/TICKET-ID-description`
   - Example: `fix/MCA-402-bug-fix`

2. **Verify Prerequisites:**
   - Git installed and in PATH
   - MCP server connected
   - In correct directory

3. **Check Permissions:**
   - Jira project access
   - File system write access
   - Network connectivity

4. **Keep Tools Updated:**
   - Latest Git version
   - Updated MCP server
   - Current IDE version

5. **Test Regularly:**
   - Verify MCP connection
   - Test with known tickets
   - Validate output files

## References

- [Jira MCP API Reference](jira-mcp.md)
- [ADF Conversion Guide](adf-conversion.md)
- [Git Operations](git-operations.md)
- [SKILL.md](../SKILL.md) - Main skill documentation
