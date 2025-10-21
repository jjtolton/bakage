# Test: Manifest with scryer_path

This test demonstrates the `scryer_path/1` manifest term feature.

## Feature

The `scryer_path([...])` term in `scryer-manifest.pl` allows you to specify additional search paths for packages.

## How it Works

Bakage searches for packages in this order:

1. `SCRYER_PATH` environment variable (if set)
2. Paths listed in `scryer_path([...])` from the project's manifest (if present)
3. Default: `{project_root}/scryer_libs`

The search backtracks through all candidates until a package is found.

## This Test

**Setup:**
- `scryer-manifest.pl` specifies `scryer_path(["custom_libs"])`
- A test package `testpkg` is placed in `custom_libs/packages/testpkg/`
- `main.pl` loads the package using `:- use_module(pkg(testpkg)).`

**Expected Result:**
- Bakage finds the package in `custom_libs/packages/testpkg/`
- The program prints: `Success: hello_from_custom_path`

## Running

```bash
just run
```

## Use Cases

This feature is useful for:
- Monorepos with packages in different locations
- Development setups with custom package directories
- Projects that want to override standard package locations
- Testing with mock/stub packages in different directories
