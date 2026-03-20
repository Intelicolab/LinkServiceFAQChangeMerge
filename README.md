# OTOBOLinkServiceFAQMerge

OPM package for OTOBO that adds 11 REST operations to the Generic Interface: LinkObject (List/Add/Delete), Service catalog (Get/List/Search), SLA (Get/List), agent-level FAQ (Search/Get), and TicketMerge.

## Compatibility

- OTOBO 10.1.x
- OTOBO 11.x

## Operations

| # | Group | Operation | Method | Route | Description |
|---|-------|-----------|--------|-------|-------------|
| 1 | Ticket | TicketMerge | POST | `/TicketMerge` | Merge two tickets (irreversible) |
| 2 | LinkObject | LinkList | GET/POST | `/LinkList` | List links for any object |
| 3 | LinkObject | LinkAdd | POST | `/LinkAdd` | Create a link between objects |
| 4 | LinkObject | LinkDelete | POST | `/LinkDelete` | Delete a link between objects |
| 5 | FAQ | FAQSearch | GET/POST | `/FAQSearch` | Search FAQ articles (agent-level, all states) |
| 6 | FAQ | FAQGet | GET | `/FAQGet/:ItemID` | Get FAQ article (agent-level, no state restriction) |
| 7 | Service | ServiceGet | GET | `/ServiceGet/:ServiceID` | Get service details |
| 8 | Service | ServiceList | GET | `/ServiceList` | List all services |
| 9 | Service | ServiceSearch | GET/POST | `/ServiceSearch` | Search services by name |
| 10 | SLA | SLAGet | GET | `/SLAGet/:SLAID` | Get SLA details |
| 11 | SLA | SLAList | GET | `/SLAList` | List all SLAs |

## Installation

### Via Package Manager (recommended)

1. Build the OPM file:
   ```bash
   perl bin/otobo.Console.pl Dev::Package::Build /path/to/OTOBOLinkServiceFAQMerge.sopm /path/to/output/
   ```
2. Go to **Admin → Package Manager** and install the `.opm` file.

### Manual installation

Copy the `Kernel/` directory to your OTOBO installation and rebuild the config:
```bash
cp -r Kernel/ /opt/otobo/
perl bin/otobo.Console.pl Maint::Config::Rebuild
```

## Configuration

After installation, register the operations in your webservice:

**Option A:** Import the included YAML template from **Admin → Web Services → Add Web Service → Import**:
```
development/webservices/LinkServiceFAQMergeConnectorREST.yml
```

**Option B:** Add individual operations to an existing webservice via **Admin → Web Services → Edit**.

## Soft Dependencies

- **FAQ package** — FAQSearch and FAQGet require the FAQ package to be installed. If not present, these operations return a `.ModuleNotAvailable` error gracefully.
- **ITSMCore** — ServiceGet automatically includes ITSM fields (Type, Criticality) if the ITSMCore package is installed.

## License

GNU General Public License v3.0 — see [COPYING](COPYING).
