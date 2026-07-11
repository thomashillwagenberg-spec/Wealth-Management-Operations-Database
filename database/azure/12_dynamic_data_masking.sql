/*
  Supplemental masking only. Dynamic data masking is not a security boundary and does not replace RLS or permissions.
  Execute after confirming application result shapes and UNMASK assignments.
*/
ALTER TABLE core.Client ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
ALTER TABLE core.InvestmentAccount ALTER COLUMN AccountNumber ADD MASKED WITH (FUNCTION = 'partial(2,"XXXXX",4)');
GO

DENY UNMASK TO WealthManagementApplication;
GRANT UNMASK TO DatabaseAdministrator;
GO
