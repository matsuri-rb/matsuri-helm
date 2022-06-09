# Design Notes

This document sketches out the design for the `matsuri-helm` plugin

## Design Consideration

The main goal of this is not to replace Helm, but to manage things that Helm
does not manage. These are:

  - Helm repo and version pinning
  - Opinionated way of structuring values.yml
  - Defaults to atomically upgrading releases
  - Integration with other manifests that are not managed by Helm
  - TODO: helm diff
  


