# <directory path from root> Directory

## Summary

<short description, one or two sentences>

## Details

<more detailed description of the contents, about two to four paragraphs as needed>

## Notes from Humans
### GUARDRAIL: The AI Agents do not touch this.

<Add, leave empty. Never edit. Messages from humans to agents go here.>

## Directory Structure

<limit depth, only elements on this level. Subdirectories have their own AGENTS.md.>

```
.
├── subdirectory_1/     # <very short description>
├── subdirectory_2/     # <very short description>
└── file_1.h            # <very short description>
└── file_2.py           # <very short description>
```

## Technologies

<For example>

 - Languages: C++, Python, Java, ...
 - Frameworks: vue.js, ASP.NET, Blazor, ...
 - Tools: gcc, CMake, ...

## Coding Conventions

<respect local configuration in .editorconfig and .clang-format>
<follow well established best practices>
<**IMPORTANT**: demonstrate coding conventions per language, such as>
```cpp
class CamelCase
{
public:
    constexpr CamelCase() noexcept
    {        
    }

    constexpr void snake_case_function() const noexcept
    {
    }

    virtual void do_stuff() noexcept
    {
    }
protected:
private:
    int m_snake_case_variable{};
};

final class Derived: public CamelCase
{
public:
    void do_stuff() noexcept override
    {
    }
};
```

## Key Patterns

<TBD>

## Build System

<TBD>

## Automated Tests

<TBD>

## <Other sections as appropriate for the content>
