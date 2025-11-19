# Golang Coding Standards

This skill provides comprehensive code review for Go code based on idiomatic Go practices and industry best practices.

## When to Use This Skill

Invoke this skill when you want to:
- Review Go code for idiomatic patterns
- Get suggestions on code organization and structure
- Understand why certain patterns are preferred in Go
- Review error handling approaches
- Check naming conventions and documentation
- Identify anti-patterns and suggest improvements

## Standards Reference

This skill follows:
- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)

---

## Code Organization

### Package Structure and Naming
- Package names should be lowercase, single word, no underscores or mixedCaps
- Package names should be short and descriptive
- Avoid generic names like `util`, `common`, `base`
- Package name should match the directory name

### File Organization
- Group related functionality in the same file
- Keep files focused and reasonably sized (< 500 lines when possible)
- Use `internal/` packages for code that shouldn't be imported by external projects

### Import Grouping
Organize imports in three groups, separated by blank lines:
1. Standard library
2. Third-party packages
3. Local/project packages

```go
import (
    "context"
    "fmt"
    
    "github.com/pkg/errors"
    "go.uber.org/zap"
    
    "yourproject/internal/config"
    "yourproject/pkg/logger"
)
```

---

## Idiomatic Go Patterns

### Error Handling

**Always check errors** - Never ignore returned errors
```go
// Bad
data, _ := readFile()

// Good
data, err := readFile()
if err != nil {
    return fmt.Errorf("read file: %w", err)
}
```

**Use error wrapping** with `%w` to preserve error chains
```go
// Bad
return fmt.Errorf("failed: %s", err.Error())

// Good
return fmt.Errorf("failed to process: %w", err)
```

**Don't panic** - Use panic only for truly unrecoverable situations (e.g., initialization failures)

**Return errors, don't log and return** - Let callers decide how to handle errors
```go
// Bad
if err != nil {
    log.Error("failed", err)
    return err
}

// Good
if err != nil {
    return fmt.Errorf("operation failed: %w", err)
}
```

### Interface Usage

**Keep interfaces small** - Prefer single-method interfaces when possible
```go
type Reader interface {
    Read(p []byte) (n int, err error)
}
```

**Accept interfaces, return structs** - Functions should accept interfaces but return concrete types
```go
// Good
func ProcessData(r io.Reader) (*Result, error)
```

**Define interfaces where they're used** - Not where they're implemented
```go
// In consumer package
type DataStore interface {
    Save(data Data) error
}

func NewService(store DataStore) *Service
```

### Concurrency

**Use contexts for cancellation and timeouts**
```go
func DoWork(ctx context.Context) error {
    select {
    case <-ctx.Done():
        return ctx.Err()
    case result := <-workChan:
        return processResult(result)
    }
}
```

**Always handle goroutine lifecycle** - Don't leak goroutines
```go
// Use sync.WaitGroup or channels to coordinate
func processItems(items []Item) {
    var wg sync.WaitGroup
    for _, item := range items {
        wg.Add(1)
        go func(i Item) {
            defer wg.Done()
            process(i)
        }(item)
    }
    wg.Wait()
}
```

**Use channels for communication** - Don't communicate by sharing memory; share memory by communicating

### Defer, Panic, Recover

**Use defer for cleanup**
```go
f, err := os.Open(filename)
if err != nil {
    return err
}
defer f.Close()
```

**Defer runs LIFO** - Last deferred function runs first

**Recover only in the same goroutine** - Recover from panic only where it makes sense

---

## Naming Conventions

### General Rules
- Use **MixedCaps** or **mixedCaps** rather than underscores
- Exported names start with uppercase, unexported with lowercase
- Acronyms should be all caps: `HTTP`, `ID`, `URL`, `API`

### Variables
- **Short names in small scopes**: `i`, `j`, `k` for loop counters
- **Descriptive names in larger scopes**: `userCount`, `configPath`
- **Single-letter receivers**: `func (s *Service) Start()`
- **Consistent receiver names**: Use the same receiver name across all methods

```go
// Good
func (s *Service) Start() error
func (s *Service) Stop() error

// Bad - inconsistent receiver names
func (s *Service) Start() error
func (svc *Service) Stop() error
```

### Functions and Methods
- Use verb or verb phrases: `GetUser`, `SaveConfig`, `IsValid`
- Getters don't use "Get" prefix: `user.Name()` not `user.GetName()`
- Setters use "Set" prefix: `user.SetName(name)`

### Constants
- Use MixedCaps even for constants
```go
const MaxRetries = 3
const defaultTimeout = 30 * time.Second
```

---

## Code Quality

### Function Size and Complexity
- Keep functions small and focused (< 50 lines ideal)
- Each function should do one thing well
- Extract complex logic into helper functions
- Cyclomatic complexity should be reasonable (< 10)

### Comments

**Document all exported items**
```go
// Service manages the lifecycle of workers.
type Service struct {
    // ...
}

// Start begins processing work items.
// It returns an error if the service is already running.
func (s *Service) Start() error {
    // ...
}
```

**Use complete sentences** - Comments should be complete sentences with proper punctuation

**Explain why, not what** - Code shows what; comments explain why
```go
// Bad
// Set i to 0
i := 0

// Good
// Start from beginning since cache was invalidated
i := 0
```

### Testing

**Test file naming**: `foo_test.go` for testing `foo.go`

**Test function naming**: `TestFunctionName` or `TestFunctionName_Scenario`
```go
func TestParseConfig(t *testing.T)
func TestParseConfig_InvalidJSON(t *testing.T)
func TestParseConfig_MissingRequired(t *testing.T)
```

**Use table-driven tests** for multiple scenarios
```go
func TestValidate(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"valid input", "test", false},
        {"empty input", "", true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := Validate(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("got error %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

**Test exported behavior** - Don't test implementation details

---

## Performance Considerations

### Avoid Unnecessary Allocations
```go
// Bad - allocates on every call
func (s *Service) GetName() string {
    return fmt.Sprintf("%s-%s", s.prefix, s.name)
}

// Good - pre-compute if called frequently
func (s *Service) GetName() string {
    return s.fullName // computed once in constructor
}
```

### String Concatenation
```go
// Bad for multiple concatenations
s := "Hello"
s += " "
s += "World"

// Good
var b strings.Builder
b.WriteString("Hello")
b.WriteString(" ")
b.WriteString("World")
s := b.String()
```

### Pointers vs Values
- Use pointers for large structs (> 64 bytes)
- Use pointers when you need to modify the receiver
- Use values for small, immutable data
- Be consistent with receiver types (all pointer or all value)

---

## Common Anti-Patterns to Avoid

### Don't Use `init()` for Complex Logic
- Keep `init()` simple or avoid it
- Prefer explicit initialization

### Don't Ignore Context
- Always pass and respect `context.Context` in long-running operations
- First parameter should be `ctx context.Context`

### Don't Use Global State
- Avoid global variables
- Use dependency injection instead

### Don't Overuse Interfaces
- Don't create interfaces "just in case"
- Create interfaces when you have multiple implementations or need to mock

### Don't Return -1 or nil for Errors
- Always use proper error returns
```go
// Bad
func FindUser(id int) *User {
    // returns nil on error
}

// Good
func FindUser(id int) (*User, error) {
    // explicit error handling
}
```

---

## AI Instructions for Code Review

When this skill is invoked:

1. **Analyze the provided Go code** against the standards above
2. **Prioritize feedback** by impact:
   - **Critical Issues**: Things that could cause bugs or serious problems
   - **Idiomatic Improvements**: Ways to make code more Go-like
   - **Style Suggestions**: Minor improvements for consistency
   - **Positive Observations**: Call out well-written code

3. **Explain the "why"** - Don't just say something is wrong, explain why the Go community prefers certain patterns

4. **Provide examples** - Show both the problematic code and the improved version

5. **Be constructive** - Frame feedback as learning opportunities

6. **Reference standards** - Cite Effective Go, Code Review Comments, or other authoritative sources

7. **Consider context** - Some rules have exceptions; acknowledge when trade-offs are reasonable

8. **Don't duplicate linter output** - Focus on higher-level patterns and idioms that automated tools miss

### Example Response Format

```
## Critical Issues
None found.

## Idiomatic Improvements

### 1. Error Wrapping
**Current:**
```go
if err != nil {
    return fmt.Errorf("failed: %s", err.Error())
}
```

**Suggested:**
```go
if err != nil {
    return fmt.Errorf("failed: %w", err)
}
```

**Why:** Using `%w` preserves the error chain, allowing callers to use `errors.Is()` and `errors.As()` for error inspection. This follows the Go 1.13+ error wrapping conventions.

**Reference:** [Go Blog - Working with Errors](https://go.dev/blog/go1.13-errors)

## Style Suggestions
...

## Positive Observations
- Good use of context for timeout handling
- Clear and descriptive variable names
- Well-structured table-driven tests
```

---

## Notes
- This skill works best with complete functions or files, not fragments
- For mechanical issues (formatting, imports), run `gofmt` and `goimports` first
- For linting, run `golangci-lint` separately - this skill focuses on patterns and idioms
- This skill complements automated tools by providing context-aware, educational feedback
