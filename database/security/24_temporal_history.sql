/*
  24_temporal_history.sql
  Purpose: Add system-versioned history to mutable risk and compliance records.
  This is an optional application-mode extension, not part of the original learning build.
*/
USE WealthManagementOperations;
GO
SET XACT_ABORT ON;
GO

IF COL_LENGTH(N'core.ClientRiskProfile', N'ValidFrom') IS NULL
BEGIN
    ALTER TABLE core.ClientRiskProfile ADD
        ValidFrom datetime2(7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL CONSTRAINT DF_ClientRiskProfile_ValidFrom DEFAULT (SYSUTCDATETIME()),
        ValidTo datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL CONSTRAINT DF_ClientRiskProfile_ValidTo DEFAULT (CONVERT(datetime2(7),'9999-12-31 23:59:59.9999999')),
        PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
    ALTER TABLE core.ClientRiskProfile SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = core.ClientRiskProfileHistory, DATA_CONSISTENCY_CHECK = ON));
END;
GO

IF COL_LENGTH(N'compliance.ComplianceReview', N'ValidFrom') IS NULL
BEGIN
    ALTER TABLE compliance.ComplianceReview ADD
        ValidFrom datetime2(7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL CONSTRAINT DF_ComplianceReview_ValidFrom DEFAULT (SYSUTCDATETIME()),
        ValidTo datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL CONSTRAINT DF_ComplianceReview_ValidTo DEFAULT (CONVERT(datetime2(7),'9999-12-31 23:59:59.9999999')),
        PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
    ALTER TABLE compliance.ComplianceReview SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = compliance.ComplianceReviewHistory, DATA_CONSISTENCY_CHECK = ON));
END;
GO

IF COL_LENGTH(N'compliance.ComplianceAlert', N'ValidFrom') IS NULL
BEGIN
    ALTER TABLE compliance.ComplianceAlert ADD
        ValidFrom datetime2(7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL CONSTRAINT DF_ComplianceAlert_ValidFrom DEFAULT (SYSUTCDATETIME()),
        ValidTo datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL CONSTRAINT DF_ComplianceAlert_ValidTo DEFAULT (CONVERT(datetime2(7),'9999-12-31 23:59:59.9999999')),
        PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
    ALTER TABLE compliance.ComplianceAlert SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = compliance.ComplianceAlertHistory, DATA_CONSISTENCY_CHECK = ON));
END;
GO

PRINT N'Temporal history enabled or already present for selected mutable records.';
GO
