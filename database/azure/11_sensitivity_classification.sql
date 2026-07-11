/* Azure SQL and supported SQL Server sensitivity metadata. Review labels with privacy and legal owners. */
ADD SENSITIVITY CLASSIFICATION TO core.Client.FirstName WITH (LABEL='Confidential', INFORMATION_TYPE='Name', RANK=HIGH);
ADD SENSITIVITY CLASSIFICATION TO core.Client.LastName WITH (LABEL='Confidential', INFORMATION_TYPE='Name', RANK=HIGH);
ADD SENSITIVITY CLASSIFICATION TO core.Client.Email WITH (LABEL='Confidential', INFORMATION_TYPE='Contact Info', RANK=HIGH);
ADD SENSITIVITY CLASSIFICATION TO core.InvestmentAccount.AccountNumber WITH (LABEL='Highly Confidential', INFORMATION_TYPE='Financial', RANK=CRITICAL);
ADD SENSITIVITY CLASSIFICATION TO trading.CurrentHolding.Quantity WITH (LABEL='Highly Confidential', INFORMATION_TYPE='Financial', RANK=HIGH);
ADD SENSITIVITY CLASSIFICATION TO trading.CurrentHolding.AverageCost WITH (LABEL='Highly Confidential', INFORMATION_TYPE='Financial', RANK=HIGH);
ADD SENSITIVITY CLASSIFICATION TO compliance.ComplianceAlert.Description WITH (LABEL='Highly Confidential', INFORMATION_TYPE='Compliance', RANK=CRITICAL);
ADD SENSITIVITY CLASSIFICATION TO compliance.ComplianceReview.Notes WITH (LABEL='Highly Confidential', INFORMATION_TYPE='Compliance', RANK=CRITICAL);
GO
