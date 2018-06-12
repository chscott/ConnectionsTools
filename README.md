### Overview

ConnectionsTools is a set of administrative scripts designed to make life easier for Connections administrators. The 
scripts contain both user-friendly wrappers around existing administration tools and new tools that don't already exist in 
the product.

Tools exist for both Connections Blue (WebSphere) and Connections Pink (Kubernetes). You can install the full set of tools on
on every Connections node in the environment without worrying about which ones target Blue and Pink. Each tool understands
its dependencies and will report an appropriate error message if you try to run a tool on a system that doesn't host the
target component.


### Installation

- [Linux](doc/install_linux.md)
- [Windows](doc/install_windows.md)


### The tools

- [Connections Blue](doc/blue.md)
- [Connections Pink](doc/pink.md)