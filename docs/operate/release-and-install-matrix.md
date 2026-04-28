# Release and Install Matrix

Use this page to answer:

- is this project part of the ecosystem?
- does it ship as a local binary?
- is it part of the default bootstrap install?

## Matrix

| Project    | macOS | Linux | Windows | Bootstrap-installed by default | Optional install | Source-only or package-only |
|------------|-------|-------|---------|--------------------------------|------------------|-----------------------------|
| `stipe`    | Yes   | Yes   | Yes     | Yes                            | No               | No                          |
| `mycelium` | Yes   | Yes   | Yes     | Yes                            | No               | No                          |
| `hyphae`   | Yes   | Yes   | Yes     | Yes                            | No               | No                          |
| `rhizome`  | Yes   | Yes   | Yes     | Yes                            | No               | No                          |
| `cortina`  | Yes   | Yes   | Yes     | Yes                            | No               | No                          |
| `canopy`   | Yes   | Yes   | Yes     | No                             | Yes              | No                          |
| `annulus`  | Yes   | Yes   | Yes     | No                             | Yes              | No                          |
| `hymenium` | Yes   | Yes   | Yes     | No                             | Yes              | No                          |
| `volva`    | Yes   | Yes   | Yes     | No                             | Yes              | No                          |
| `cap`      | Yes   | Yes   | Yes     | No                             | No               | Yes                         |
| `lamella`  | Yes   | Yes   | Yes     | No                             | No               | Yes                         |
| `spore`    | Yes   | Yes   | Yes     | No                             | No               | Yes                         |

## How to Read This

- `Bootstrap-installed by default`
  - installed by the top-level `install.sh` or `install.ps1`
- `Optional install`
  - part of the ecosystem, but you add it later, usually through `stipe`
- `Source-only or package-only`
  - part of the ecosystem, but not a bootstrap-installed end-user binary

## Practical Notes

- `annulus`
  - operator utilities and statusline tooling
  - install it for local status and operator surfaces
- `canopy`
  - optional coordination runtime
  - install it when you need multi-agent runtime state
- `hymenium`
  - workflow orchestration engine
  - install it for advanced workflow automation
- `volva`
  - execution-host runtime layer
  - install it for enhanced execution environments
- `cap`
  - dashboard surface
  - run or deploy it separately
- `lamella`
  - packaging and template layer
  - not an operator runtime binary
- `spore`
  - shared Rust library
  - not installed directly

## Related

- [What Gets Installed](../getting-started/install-scope.md)
- [Host Support](../getting-started/host-support.md)
- [Operator Quickstart](../getting-started/operator-quickstart.md)
