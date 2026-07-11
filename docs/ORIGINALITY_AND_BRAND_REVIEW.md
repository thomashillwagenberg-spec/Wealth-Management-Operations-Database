# Originality and Brand Review

**Project:** Wealth Management Operations Platform  
**Review date:** July 11, 2026  
**Scope:** Design, engineering, documentation, naming, source independence, and Microsoft/Azure brand separation.  
**Disclaimer:** This is an internal design and engineering review, not legal advice, an infringement opinion, or a guarantee of legal clearance.

## 1. Review conclusion

The application is independently framed as a wealth-management operations product. Its tasks, data model, language, routes, authorization model, and source code are domain-specific. Microsoft and Azure appear only as factual technology and research references.

The Azure account-selection experience and Azure SQL documentation were studied for general quality principles such as clear comparison, categorized information, progressive disclosure, trust content, accessibility, reliability, and operational evidence. The project does not reproduce Microsoft page structure, product copy, source code, logos, Azure icons, media, customer stories, screenshots, or proprietary assets.

The remaining risk is not direct copying. It is the ordinary possibility that common enterprise patterns such as side navigation, summary cards, tables, health states, and blue accents may resemble many business applications. Those patterns are generic, and the project distinguishes itself through original wealth-management terminology, synthetic data, workflows, and visual composition. Human design and legal review remains appropriate before commercial release.

## 2. Microsoft patterns studied

Research sources are listed in [AZURE_SQL_REFERENCE_RESEARCH.md](AZURE_SQL_REFERENCE_RESEARCH.md). The general patterns studied were:

- Clear opening proposition
- Account or operating-model comparison
- Product categorization
- Search and filtering
- Section navigation
- Progressive disclosure
- Resource libraries
- Pricing and cost explanation
- Frequently asked questions
- Trust and limitation content
- Calls to action and next steps
- Service health and monitoring concepts
- Role-based access
- Activity and deployment history
- Security recommendations
- Responsive and accessible component behavior

## 3. General concepts adopted and transformed

| Studied concept | Transformation in this project | Why the result is independent |
|---|---|---|
| Cloud product categories | Client, portfolio, risk, compliance, trade, audit, and health modules | Categories come from wealth-management operations and repository authorization requirements |
| Account-plan comparison | Local learning mode versus Azure application mode | The comparison explains how one database project can be studied locally or deployed through a cloud reference architecture |
| Azure resource cards | Client count, portfolio value, and control-case summaries | Metrics are generated from the fictional wealth data model, not Azure services |
| Product filtering | Compliance-alert status filter and pagination | The filter supports a specific review workflow and stored procedure |
| Activity log | Domain audit-evidence view | Events use actor, action, entity, outcome, timestamp, and correlation ID from the application's audit design |
| Service health | API liveness, readiness, database connectivity, and version | Health checks are operational endpoints for this application, not Azure service status |
| Security center | Threat model, control mapping, validation scripts, and deployment options | The result is documentation and code evidence, not a copied portal experience |
| Performance guidance | Query Store and telemetry runbook | The project does not present invented utilization metrics or copy Azure charts |
| Pricing explanation | Development, staging, and production cost categories | No exact Azure price or copied calculator is displayed |
| Resource library | Original architecture, security, operations, compliance, and learning documentation | Every document is written for this repository's decisions and limitations |
| Progressive disclosure | Dashboard to client to account allocation flow | The sequence follows wealth-management review tasks rather than an Azure sales page |

## 4. Microsoft elements intentionally excluded

The repository intentionally excludes:

- Microsoft and Azure logos
- Microsoft and Azure product icons
- Microsoft photography, video, illustrations, or screenshots
- Microsoft customer stories
- Microsoft source code, HTML, CSS, or scraped page source
- Azure portal code or copied portal components
- Exact Microsoft marketing wording
- Exact Azure navigation labels
- Exact page section order
- Exact card wording or composition
- Exact animation or transition sequences
- Exact spacing measurements or color combinations
- Proprietary Microsoft templates
- Microsoft performance claims
- Claims of Microsoft approval, sponsorship, certification, or affiliation
- Claims that the application reproduces the complete capabilities of Azure SQL

## 5. Brand identity differences

### Product name

The product is named **Wealth Management Operations Platform**. “Microsoft,” “Azure,” “Azure SQL,” and confusingly similar wording are not part of the application name, company identity, logo, or domain.

### Product promise

The product promise is to demonstrate fictional wealth-management operations, database controls, secure reporting, and a deployment-ready reference architecture. It is not a cloud-account marketplace, cloud portal, or database platform.

### Brand language

The application uses terms such as:

- Client portfolios
- Account allocation
- Risk alignment
- Compliance alerts
- Synthetic trade entry
- Audit evidence
- System health

These are derived from the domain model. Microsoft product names are used only where necessary to state technical compatibility, identity provider, deployment target, or research source.

### Color and typography

The interface uses an original restrained financial-operations palette and ordinary web typography. It does not import Microsoft brand fonts, Azure gradients, Microsoft color tokens, or Fluent assets. General use of blue, white, gray, cards, and tables is not intended to indicate affiliation.

### Iconography and imagery

The current application relies primarily on text, native controls, status language, and data tables. It does not include Microsoft icons or imagery. Any future icons must be original or obtained under a license permitting the intended use.

## 6. Navigation differences

The Azure account reference organizes purchasing options, services, free offers, resources, locations, and FAQs. This application organizes authenticated operational tasks:

1. Dashboard
2. Clients
3. Risk alignment
4. Compliance
5. Trade demonstration
6. Audit
7. System health

The sequence is justified by user tasks and role permissions. It is not based on Azure portal or Azure marketing navigation.

## 7. Page-structure differences

- The application has a persistent role-focused sidebar, not the Azure account site's sales navigation.
- The dashboard begins with authorized operational data, not a purchase call to action.
- Client pages use financial tables and drill-down links, not product cards.
- Compliance uses status filters, row-version updates, and role-restricted actions.
- Trade entry is a clearly labeled fictional form that invokes domain controls.
- Audit presents application evidence rather than Azure control-plane resources.
- Health presents local endpoints rather than a global service-status experience.
- Research, cost, and deployment information lives in repository documentation instead of being mixed into the authenticated application.

## 8. Terminology differences

| Microsoft or Azure context | This project's original terminology |
|---|---|
| Account or subscription | Operating mode or deployment profile |
| Azure service | Wealth-management module or infrastructure dependency |
| Resource | Client, account, holding, alert, audit event, application, or database object |
| Activity log | Audit evidence |
| Service health | System health |
| Security recommendation | Security control or production-readiness item |
| Pricing calculator | Deployment-time Azure cost estimate |
| Deployment history | GitHub Actions and repository change evidence |
| Role-based access | Administrator, advisor, compliance, reporting, and auditor policies |

The application does not rename Azure concepts merely to disguise copying. It uses domain terms because the underlying problems are different.

## 9. Visual-design differences

The application uses:

- A dark original sidebar with text navigation
- A simple authenticated top bar
- Restrained financial summary cards
- Dense but readable tables
- Original warning and status treatments
- Form layouts designed around compliance and trade-entry tasks
- No Azure blades, tiles, command bars, resource groups, subscriptions, portal chrome, or Microsoft media

The application header now says **“Enterprise-style wealth operations reference”** so Azure is not presented as primary application branding. Azure remains identified factually in documentation and deployment configuration.

## 10. Source-code independence

- The API, application, infrastructure, contracts, Blazor pages, tests, T-SQL extensions, Bicep, workflows, and documentation are repository-specific source files.
- No Microsoft page source was scraped or reused.
- No Azure portal code is included.
- Microsoft samples were used only as conceptual documentation references, not copied implementation blocks.
- Package dependencies are normal platform libraries and are governed by their own licenses.
- The existing hand-written T-SQL remains the central domain implementation.
- Generated build output, proprietary binaries, and Microsoft media are not packaged.

## 11. Independent-design test by major page

| Page | Solves a wealth-management problem? | Independently justified order and wording? | Original or licensed assets? | Clearly not a Microsoft product? | Current review result |
|---|---|---|---|---|---|
| Login | Yes. Separates development identity from production Entra sign-in | Yes. Synthetic-data warning and environment-specific paths are domain and security requirements | No external visual asset | Yes. Own product and form | Pass in source; authentication flow not executed |
| Executive dashboard | Yes. Summarizes authorized clients, value, and control cases | Yes. Metrics derive from the wealth data model | No external visual asset | Yes | Pass in source; data output not executed |
| Client portfolios | Yes. Lists only authorized client portfolios | Yes. Columns derive from reporting views | No external visual asset | Yes | Pass in source; RLS and authorization not executed |
| Client portfolio | Yes. Shows client totals and account drill-down | Yes. Hierarchy follows client and account entities | No external visual asset | Yes | Pass in source; calculations not executed |
| Account allocation | Yes. Shows asset class value and allocation | Yes. Based on existing holdings and reporting logic | No external visual asset | Yes | Pass in source; calculations not executed |
| Risk alignment | Yes. Compares allocation with fictional risk-profile ranges | Yes. Domain-specific status and columns | No external visual asset | Yes | Pass in source; reporting view not executed |
| Compliance alerts | Yes. Filters and updates compliance workflow | Yes. Statuses, pagination, and actions come from domain controls | No external visual asset | Yes | Pass in source; concurrency and permissions not executed |
| Synthetic trade entry | Yes. Demonstrates controlled fictional trade recording | Yes. Fields and warning follow the existing procedure | No external visual asset | Yes | Pass in source; procedure and idempotency not executed |
| Audit evidence | Yes. Gives authorized users traceable event metadata | Yes. Columns come from the audit model | No external visual asset | Yes | Pass in source; audit creation not executed |
| System health | Yes. Identifies liveness, readiness, database health, and version | Yes. Operational endpoints are application-specific | No external visual asset | Yes | Pass in source; endpoint behavior not executed |

## 12. Independent-design approval questions

Before approving any new major page, the reviewer must answer:

1. Does it solve a wealth-management problem rather than an Azure sales problem?
2. Is its section order justified by the application's users and tasks?
3. Is every sentence original?
4. Are all visual assets original or correctly licensed?
5. Is navigation based on application workflows and authorization?
6. Would a reasonable viewer immediately understand that this is not a Microsoft product?
7. Does it use the platform's own recognizable design language?
8. Is every externally sourced fact attributed in documentation?
9. Is the source code independently written?
10. Is any similarity limited to general quality or function rather than copied expression?

A “no” requires redesign before release.

## 13. Microsoft trademark and factual-reference rules

Based on the [Microsoft trademark and brand guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks), this repository applies these rules:

- Keep the application's own name more prominent than Microsoft product names.
- Use Microsoft product names only to describe compatibility, identity, hosting, or research.
- Do not modify or create confusingly similar Microsoft brand marks.
- Do not use Microsoft logos, Azure icons, or Microsoft design assets without explicit rights.
- Do not imply endorsement, sponsorship, certification, or affiliation.
- Include attribution where required by applicable license or guideline.

## 14. Remaining similarity concerns requiring human review

1. **Generic enterprise patterns:** Side navigation, summary cards, tables, and blue accents are common across software. A visual designer should confirm that the total composition remains distinct before a public commercial launch.
2. **Technology references:** “Microsoft Entra ID” on the production sign-in path is a factual identity-provider reference. Legal and brand review should confirm final presentation if the product becomes commercial.
3. **Screenshots and launch video:** Future media must record only this application. It must not splice in Azure portal or Microsoft product footage unless separately licensed and clearly contextualized.
4. **Third-party packages:** A release process should generate an SBOM and review all package licenses.
5. **Claims:** “Azure-ready” or “Azure SQL deployment readiness” must be paired with the fact that deployment and runtime verification are still pending.
6. **Accessibility:** Source-level design intent is not a substitute for manual accessibility testing.

## 15. Approval statement

The current repository passes its internal originality and brand-separation review at the source and documentation level. That finding means the design is intentionally independent and avoids identified Microsoft assets and copied expression. It does not provide legal clearance, validate deployment, or eliminate the need for human review before commercial use.
