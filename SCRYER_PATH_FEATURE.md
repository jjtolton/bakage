# scryer_path/1 Manifest Term

## Overview

The `scryer_path/1` term in `scryer-manifest.pl` allows projects to specify additional scryer-manifest.pl files whose package directories should be searched.

## Syntax

In your `scryer-manifest.pl`:

```prolog
scryer_path([
    "path/to/other-project/scryer-manifest.pl",
    "vendor/lib/scryer-manifest.pl",
    "/absolute/path/to/project/scryer-manifest.pl"
]).
```

**Note**: You specify paths to manifest files, not package directories. Bakage will intelligently determine where each manifest's packages are located.

## Search Order

When resolving packages with `:- use_module(pkg(package_name)).`, bakage searches in this order:

1. **SCRYER_PATH environment variable** (if set)
2. **Manifest scryer_path/1 terms** (if present, tries each manifest's package location via backtracking)
3. **Default path**: `{project_root}/scryer_libs`

## Example

### Project Structure

```
my-project/
├── scryer-manifest.pl
├── vendor/
│   ├── scryer-manifest.pl
│   └── scryer_libs/
│       └── packages/
│           └── mypkg/
│               ├── scryer-manifest.pl
│               └── mypkg.pl
└── main.pl
```

### my-project/scryer-manifest.pl

```prolog
name("my-project").
main_file("main.pl").
scryer_path(["vendor/scryer-manifest.pl"]).
dependencies([]).
```

### main.pl

```prolog
:- use_module(bakage).
:- use_module(pkg(mypkg)).

main :- mypkg_predicate(X), write(X), nl.
```

Bakage will:
1. Read `vendor/scryer-manifest.pl`
2. Determine that vendor's packages are in `vendor/scryer_libs/packages/`
3. Find `mypkg` at `vendor/scryer_libs/packages/mypkg/`

**Why this design?** By specifying manifest files rather than package directories, bakage can intelligently determine package locations. This provides future compatibility if the package location logic changes.

## Use Cases

1. **Monorepos**: Different package locations for different subsystems
2. **Development**: Local package overrides during development
3. **Testing**: Mock packages in test directories
4. **Custom layouts**: Projects with non-standard directory structures

## Implementation

The feature is implemented in `bakage.pl` via:

- `current_project_manifest/1`: Reads the current project's manifest
- `manifest_scryer_paths/2`: Extracts scryer_path/1 terms
- `scryer_path_candidate/1`: Generates search path candidates via backtracking
- `package_main_file/2`: Modified to use `scryer_path_candidate/1`

## Testing

See `tests/integration/manifest_with_scryer_path/` for a working example.

Run the test:
```bash
cd tests/integration/manifest_with_scryer_path
just run
```

## Notes

- Paths in `scryer_path/1` should point to `scryer-manifest.pl` files
- Paths can be relative (to project root) or absolute
- Multiple manifest paths are tried in order via backtracking
- Bakage automatically determines where each manifest's packages are located (typically `{manifest_dir}/scryer_libs/packages/`)
- If a manifest's packages don't contain the requested package, bakage tries the next manifest
- The default `scryer_libs` location is always available as fallback
- **Future-proof**: If bakage's package location logic changes, existing `scryer_path/1` declarations will continue to work
