# ADF to Markdown Conversion

Practical guide for converting Atlassian Document Format (ADF) from Jira tickets to readable Markdown for LLM consumption.

## Overview

Jira uses ADF (Atlassian Document Format) for rich text fields including descriptions, comments, and custom fields. This guide focuses on reading and converting ADF to Markdown for documentation purposes.

For general ADF structure and field requirements, see [Jira MCP API Reference](jira-mcp.md#custom-fields--adf-format).

## Conversion Strategy

1. **Parse ADF JSON** - Validate document structure
2. **Process content array** - Recursively handle nested elements
3. **Apply formatting** - Convert ADF marks to Markdown syntax
4. **Handle edge cases** - Graceful degradation for unsupported elements
5. **Validate output** - Ensure readable Markdown

## Basic Element Conversion

### Text Elements

**Plain Text**
```javascript
// ADF
{"type": "text", "text": "Hello world"}

// Markdown
Hello world
```

**Bold Text**
```javascript
// ADF
{
  "type": "text",
  "text": "important",
  "marks": [{"type": "strong"}]
}

// Markdown
**important**
```

**Italic Text**
```javascript
// ADF
{
  "type": "text",
  "text": "emphasis",
  "marks": [{"type": "em"}]
}

// Markdown
*emphasis*
```

**Combined Formatting**
```javascript
// ADF
{
  "type": "text",
  "text": "bold italic",
  "marks": [
    {"type": "strong"},
    {"type": "em"}
  ]
}

// Markdown
***bold italic***
```

**Inline Code**
```javascript
// ADF
{
  "type": "text",
  "text": "function()",
  "marks": [{"type": "code"}]
}

// Markdown
`function()`
```

### Block Elements

**Paragraphs**
```javascript
// ADF
{
  "type": "paragraph",
  "content": [
    {"type": "text", "text": "First paragraph"}
  ]
}

// Markdown
First paragraph

```

**Headings**
```javascript
// ADF - Heading 2
{
  "type": "heading",
  "attrs": {"level": 2},
  "content": [{"type": "text", "text": "Section Title"}]
}

// Markdown
## Section Title
```

**Code Blocks**
```javascript
// ADF
{
  "type": "codeBlock",
  "attrs": {"language": "javascript"},
  "content": [
    {"type": "text", "text": "const x = 42;"}
  ]
}

// Markdown
```javascript
const x = 42;
```
```

**Blockquotes**
```javascript
// ADF
{
  "type": "blockquote",
  "content": [
    {
      "type": "paragraph",
      "content": [{"type": "text", "text": "Quoted text"}]
    }
  ]
}

// Markdown
> Quoted text
```

### Lists

**Bullet Lists**
```javascript
// ADF
{
  "type": "bulletList",
  "content": [
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [{"type": "text", "text": "First item"}]
        }
      ]
    },
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [{"type": "text", "text": "Second item"}]
        }
      ]
    }
  ]
}

// Markdown
- First item
- Second item
```

**Ordered Lists**
```javascript
// ADF
{
  "type": "orderedList",
  "content": [
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [{"type": "text", "text": "Step one"}]
        }
      ]
    }
  ]
}

// Markdown
1. Step one
```

**Nested Lists**
```javascript
// ADF
{
  "type": "bulletList",
  "content": [
    {
      "type": "listItem",
      "content": [
        {
          "type": "paragraph",
          "content": [{"type": "text", "text": "Parent"}]
        },
        {
          "type": "bulletList",
          "content": [
            {
              "type": "listItem",
              "content": [
                {
                  "type": "paragraph",
                  "content": [{"type": "text", "text": "Child"}]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}

// Markdown
- Parent
  - Child
```

### Links

```javascript
// ADF
{
  "type": "text",
  "text": "Documentation",
  "marks": [
    {
      "type": "link",
      "attrs": {
        "href": "https://docs.example.com",
        "title": "Docs"
      }
    }
  ]
}

// Markdown
[Documentation](https://docs.example.com "Docs")
```

### Images and Media

```javascript
// ADF - Media Single (block image)
{
  "type": "mediaSingle",
  "content": [
    {
      "type": "media",
      "attrs": {
        "id": "abc123",
        "type": "file",
        "collection": "contentId",
        "alt": "Screenshot"
      }
    }
  ]
}

// Markdown
![Screenshot](image-reference)
```

**Note**: Image URLs require authentication. Create references in `images/README.md` for manual download.

## Company-Specific Fields

### Resolution Details (customfield_11828)

This field is required when transitioning tickets to "In Review" status. It uses ADF format.

**Reading Resolution Details**
```javascript
// Fetch with custom field
const issue = mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-402",
  fields: ["summary", "status", "customfield_11828"]
});

// Extract and convert
const resolutionDetails = issue.fields.customfield_11828;
// Convert ADF to Markdown using conversion rules
```

**Common Content Pattern**
```markdown
# Resolution Details

## Changes Made
- Fixed validation logic in UserService
- Updated error handling in authentication flow

## Testing Performed
- Verified login works with valid credentials
- Confirmed error messages display correctly
- Tested edge cases with invalid input

## Files Modified
- `src/services/UserService.ts`
- `src/middleware/auth.ts`
```

### Other Custom Fields

Check `expand=names` in issue response to identify custom fields:
```javascript
const issue = mcp_atlassian-mcp-server_getJiraIssue({
  cloudId: cloudId,
  issueIdOrKey: "MCA-402",
  expand: "names"
});

// Check issue.names for field mappings
// Example: issue.names["customfield_12345"] = "QA Notes"
```

## Conversion Implementation

### Pseudocode

```javascript
function convertADFToMarkdown(adf) {
  if (!adf || adf.type !== 'doc') {
    return extractPlainText(adf);
  }
  
  return adf.content
    .map(node => convertNode(node))
    .join('\n\n');
}

function convertNode(node, indent = 0) {
  switch (node.type) {
    case 'paragraph':
      return convertInlineContent(node.content);
    
    case 'heading':
      const level = '#'.repeat(node.attrs.level);
      return `${level} ${convertInlineContent(node.content)}`;
    
    case 'bulletList':
      return node.content
        .map(item => convertListItem(item, '- ', indent))
        .join('\n');
    
    case 'orderedList':
      return node.content
        .map((item, i) => convertListItem(item, `${i+1}. `, indent))
        .join('\n');
    
    case 'codeBlock':
      const lang = node.attrs?.language || '';
      const code = node.content.map(n => n.text).join('');
      return `\`\`\`${lang}\n${code}\n\`\`\``;
    
    case 'blockquote':
      return node.content
        .map(n => '> ' + convertNode(n))
        .join('\n');
    
    default:
      return handleUnsupported(node);
  }
}

function convertInlineContent(content) {
  return content.map(node => {
    if (node.type !== 'text') return '';
    
    let text = node.text;
    
    if (node.marks) {
      node.marks.forEach(mark => {
        text = applyMark(text, mark);
      });
    }
    
    return text;
  }).join('');
}

function applyMark(text, mark) {
  switch (mark.type) {
    case 'strong':
      return `**${text}**`;
    case 'em':
      return `*${text}*`;
    case 'code':
      return `\`${text}\``;
    case 'strike':
      return `~~${text}~~`;
    case 'link':
      const href = mark.attrs.href;
      const title = mark.attrs.title ? ` "${mark.attrs.title}"` : '';
      return `[${text}](${href}${title})`;
    default:
      return text;
  }
}
```

## Error Handling

### Unsupported Elements

When encountering unknown ADF elements:

1. **Log Warning**
   ```
   WARN: Unsupported ADF element type: {type}
   ```

2. **Extract Text**
   ```javascript
   function extractPlainText(node) {
     if (node.type === 'text') return node.text;
     if (node.content) {
       return node.content.map(extractPlainText).join(' ');
     }
     return '';
   }
   ```

3. **Add Comment**
   ```markdown
   <!-- Unsupported ADF element: {type} -->
   ```

4. **Continue Processing**
   - Don't fail the entire conversion
   - Process remaining content
   - Report unsupported elements at end

### Malformed ADF

For invalid or incomplete ADF structures:

```javascript
function safeConvert(adf) {
  try {
    return convertADFToMarkdown(adf);
  } catch (error) {
    console.error('ADF conversion failed:', error.message);
    
    // Attempt plain text extraction
    try {
      const text = extractPlainText(adf);
      if (text) {
        return `<!-- Conversion failed, plain text only -->\n${text}`;
      }
    } catch (e) {
      // Last resort
      return `<!-- Conversion failed: ${error.message} -->`;
    }
  }
}
```

### Empty or Null Content

```javascript
function handleEmptyContent(content) {
  if (!content) return '_No content provided_';
  if (Array.isArray(content) && content.length === 0) return '_Empty_';
  return convertContent(content);
}
```

## Testing Conversion

### Test Cases

1. **Simple Text**
   - Plain paragraphs
   - Single formatting marks

2. **Complex Formatting**
   - Multiple marks combined
   - Nested formatting

3. **Lists**
   - Bullet lists
   - Numbered lists
   - Nested lists (3+ levels)

4. **Code Blocks**
   - With language specified
   - Without language
   - Multi-line content

5. **Links and References**
   - Plain links
   - Links with formatted text
   - Multiple links in paragraph

6. **Edge Cases**
   - Empty nodes
   - Missing content arrays
   - Null fields
   - Malformed structure

### Validation

After conversion, verify:
- No unclosed Markdown syntax
- Proper line breaks between blocks
- Correct indentation for nested lists
- Valid link syntax
- Special characters escaped where needed

## Best Practices

1. **Always validate ADF structure** before conversion
2. **Use recursive processing** for nested elements
3. **Preserve formatting** where possible
4. **Graceful degradation** for unsupported elements
5. **Never fail completely** - extract what you can
6. **Log warnings** for debugging
7. **Test with real ticket data** from your Jira instance

## References

- [Jira MCP API Reference](jira-mcp.md) - Field specifications and ADF requirements
- [Atlassian ADF Specification](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/)
