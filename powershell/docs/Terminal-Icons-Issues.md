# Terminal-Icons Issues and Solutions

## Common Issues

### 1. XML Parsing Error
**Error**: `'Element' is an invalid XmlNodeType. Line 1213, position 26.`

**Cause**: Terminal-Icons has some XML parsing warnings during module initialization, but these don't prevent the module from functioning.

**Solution**: 
- Suppress stderr output during import: `Import-Module Terminal-Icons 2>$null`
- Verify successful loading after import: `Get-Module Terminal-Icons`
- The module functions correctly despite the XML warnings

### 2. Export-ModuleMember Error
**Error**: `The Export-ModuleMember cmdlet can only be called from inside a module.`

**Cause**: Using `Export-ModuleMember` in a .ps1 script file instead of a .psm1 module file.

**Solution**: Remove `Export-ModuleMember` calls from scripts that are dot-sourced into profiles.

### 3. Complete Module Failure
**Error**: Module fails to load entirely

**Solutions**:
1. Use the `Repair-TerminalIcons` function to completely reinstall
2. Clear module cache and reinstall fresh
3. Use fallback icon functions for basic functionality

## Repair Process

```powershell
# Import repair utilities
Import-Module ./TerminalIconsRepair.psm1

# Run diagnostic and repair
Repair-TerminalIcons

# Test functionality
Test-TerminalIcons
```

## Fallback Icon Function

If Terminal-Icons completely fails, a basic icon fallback is available:

```powershell
Get-ChildItemPretty  # Basic icon function
lsi                  # Alias for the above
```

## Performance Impact

- **Normal load**: ~20-50ms with warnings suppressed
- **With XML warnings**: Same functionality, just noisy output
- **Fallback mode**: Minimal performance impact, basic icons only

## Best Practices

1. **Suppress warnings**: Use `2>$null` during import
2. **Verify loading**: Always check if module loaded successfully
3. **Graceful degradation**: Provide fallback if module fails
4. **Cache results**: Don't repeatedly try to load failed modules
5. **Monitor performance**: Use profile performance tools to track impact

## Profile Integration

The optimized profile now:
- ✅ Handles Terminal-Icons XML warnings gracefully
- ✅ Provides fallback functionality if module fails
- ✅ Caches module availability to avoid repeated failures
- ✅ Shows clear status in performance reports
- ✅ Maintains fast startup times even with module issues
