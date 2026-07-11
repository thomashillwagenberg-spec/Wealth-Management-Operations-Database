/*
  AZURE SQL OPTIONAL PROFILE.
  Creates an append-only ledger table for high-assurance audit evidence without changing the local audit table.
  Validate feature availability in the selected Azure SQL region and service tier before execution.
*/
IF OBJECT_ID(N'audit.LedgerAuditEvent', N'U') IS NULL
BEGIN
    CREATE TABLE audit.LedgerAuditEvent
    (
        LedgerAuditEventID bigint IDENTITY(1,1) NOT NULL,
        EventTime datetime2(3) NOT NULL,
        ActorID nvarchar(254) NOT NULL,
        ActionName varchar(80) NOT NULL,
        EntityType varchar(80) NOT NULL,
        EntityID nvarchar(100) NULL,
        Outcome varchar(20) NOT NULL,
        CorrelationID uniqueidentifier NOT NULL,
        MetadataJson nvarchar(2000) NULL,
        CONSTRAINT PK_LedgerAuditEvent PRIMARY KEY (LedgerAuditEventID)
    ) WITH (LEDGER = ON (APPEND_ONLY = ON));
END;
GO
