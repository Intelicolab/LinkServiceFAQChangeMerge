# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-03-19

### Added

- **TicketMerge** (`POST /TicketMerge`) — irreversible merge of two tickets; the source ticket is closed and linked to the target.
- **LinkList** (`GET|POST /LinkList`) — list all links for any OTOBO object (Ticket, FAQ article, Config Item, etc.).
- **LinkAdd** (`POST /LinkAdd`) — create a typed link between two objects.
- **LinkDelete** (`POST /LinkDelete`) — remove a specific link between two objects.
- **FAQSearch** (`GET|POST /FAQSearch`) — search FAQ articles at agent level, including internal and public states.
- **FAQGet** (`GET /FAQGet/:ItemID`) — retrieve a FAQ article by ID at agent level, without state restrictions.
- **ServiceGet** (`GET /ServiceGet/:ServiceID`) — retrieve full service details; includes ITSM fields (Type, Criticality) when ITSMCore is installed.
- **ServiceList** (`GET /ServiceList`) — list all services in the catalog.
- **ServiceSearch** (`GET|POST /ServiceSearch`) — search services by name pattern.
- **SLAGet** (`GET /SLAGet/:SLAID`) — retrieve SLA details by ID.
- **SLAList** (`GET /SLAList`) — list all SLAs.
- **Extensions::Common** — internal shared base class providing `ValidateRequiredParams` used by all operation modules.
- **`bin/build-opm.sh`** — portable build script that produces a self-contained `.opm` without requiring an OTOBO installation.
- **Webservice YAML template** (`development/webservices/LinkServiceFAQMergeConnectorREST.yml`) — ready-to-import Generic Interface webservice definition covering all 11 operations.
- **Soft dependencies** — FAQ and ITSMCore packages are optional; missing packages produce graceful errors rather than hard failures.
- **SysConfig XML registration** (`Kernel/Config/Files/XML/LinkServiceFAQMerge.xml`) — all operations are auto-discovered by OTOBO after a config rebuild.
