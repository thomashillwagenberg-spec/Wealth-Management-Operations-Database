# ADR-002: Entra identity with application mapping and RLS

**Status:** Accepted

The API validates Entra tokens. The database connection uses App Service managed identity. End-user object IDs are mapped in `security.AppUser`; roles and advisor IDs are not accepted from request bodies. Advisor access is limited in the application and by SQL RLS. Non-advisor roles receive bypass only through an approved mapped role and still use curated procedures or views.
