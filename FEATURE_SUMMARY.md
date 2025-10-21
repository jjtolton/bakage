# Feature: scryer_path/1 Manifest Term

## Summary

Added support for the `scryer_path/1` term in `scryer-manifest.pl` to allow projects to specify additional manifest files whose package directories should be searched. This provides a future-proof way to reference packages from other projects or custom locations.

## Changes Made

### 1. New Predicates in bakage.pl

#### `current_project_manifest/1`
Reads the current project's `scryer-manifest.pl` file and returns the parsed manifest.

```prolog
current_project_manifest(Manifest) :-
    find_project_root(Root),
    append([Root, "/scryer-manifest.pl"], ManifestPath),
    file_exists(ManifestPath),
    parse_manifest(ManifestPath, Manifest).
```

#### `manifest_scryer_paths/2`
Extracts the list of manifest file paths from a `scryer_path/1` term in the manifest.

```prolog
manifest_scryer_paths(Manifest, ManifestPaths) :-
    member(scryer_path(ManifestPaths), Manifest),
    ManifestPaths = [_|_].
```

#### `manifest_path_to_scryer_libs/2`
Given a path to a scryer-manifest.pl file, derives where that manifest's packages are located. For a manifest at `/path/to/project/scryer-manifest.pl`, packages are at `/path/to/project/scryer_libs`.

```prolog
manifest_path_to_scryer_libs(ManifestPathChars, ScryerLibsPath) :-
    join_sep_split(ManifestPathChars, "/", Segments),
    append(DirSegments, [_ManifestFile], Segments),
    join_sep_split(DirChars, "/", DirSegments),
    append([DirChars, "/scryer_libs"], ScryerLibsPath).
```

#### `scryer_path_candidate/1`
Generates package search path candidates via backtracking in order:
1. SCRYER_PATH environment variable
2. Package locations derived from scryer_path/1 manifest files
3. Default {project_root}/scryer_libs

```prolog
scryer_path_candidate(Path) :-
    getenv("SCRYER_PATH", Path).
scryer_path_candidate(ScryerLibsPath) :-
    current_project_manifest(Manifest),
    manifest_scryer_paths(Manifest, ManifestPaths),
    member(ManifestPath, ManifestPaths),
    manifest_path_to_scryer_libs(ManifestPath, ScryerLibsPath).
scryer_path_candidate(Path) :-
    find_project_root(RootChars),
    append([RootChars, "/scryer_libs"], Path).
```

### 2. Modified Predicates

#### `package_main_file/2`
Now uses `scryer_path_candidate/1` instead of `scryer_path/1` to enable backtracking through multiple search paths. Also added `file_exists/1` check before parsing to fail early if manifest doesn't exist.

```prolog
package_main_file(Package, PackageMainFile) :-
    atom_chars(Package, PackageChars),
    scryer_path_candidate(ScryerPath),  % Changed from scryer_path/1
    append([ScryerPath, "/packages/", PackageChars], PackagePath),
    append([PackagePath, "/", "scryer-manifest.pl"], ManifestPath),
    file_exists(ManifestPath),  % Added this check
    parse_manifest(ManifestPath, Manifest),
    member(main_file(MainFile), Manifest),
    append([PackagePath, "/", MainFile], PackageMainFileChars),
    atom_chars(PackageMainFile, PackageMainFileChars).
```

## Usage

Add to your `scryer-manifest.pl`:

```prolog
name("my_project").
main_file("main.pl").
scryer_path(["custom_libs", "vendor/packages"]).
dependencies([]).
```

Bakage will now search for packages in:
1. SCRYER_PATH (if set)
2. `custom_libs/packages/`
3. `vendor/packages/packages/`
4. `scryer_libs/packages/` (default)

## Testing

A test case has been added at:
`tests/integration/manifest_with_scryer_path/`

Run it with:
```bash
cd tests/integration/manifest_with_scryer_path
just run
```

The test demonstrates:
- Custom package location via scryer_path/1
- Backtracking through multiple paths (first path doesn't exist, finds package in second)

## Documentation

- `SCRYER_PATH_FEATURE.md` - Full feature documentation
- `tests/integration/manifest_with_scryer_path/README.md` - Test documentation

## Benefits

1. **Flexibility**: Projects can organize packages in custom locations
2. **Monorepo support**: Different subsystems can have different package locations
3. **Development workflows**: Local package overrides without environment variables
4. **Testing**: Easy to use mock/stub packages in test directories
5. **Backward compatible**: Existing projects without scryer_path/1 work unchanged
