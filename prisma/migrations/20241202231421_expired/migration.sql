
-- We want a default value of false
ALTER TABLE "LnurlWithdrawEntity" ADD COLUMN "expiredCalledback" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "LnurlWithdrawEntity" ADD COLUMN "expiredCalledbackTs" DATETIME;

-- but we want the existing rows to be set to true so we won't callback all of the existing ones
UPDATE "LnurlWithdrawEntity" SET "expiredCalledback" = true;

CREATE INDEX "LnurlWithdrawEntity_deleted_paid_expiresAt_fallbackDone_btcFallbackAddress_idx" ON "LnurlWithdrawEntity"("deleted", "paid", "expiresAt", "fallbackDone", "btcFallbackAddress");
CREATE INDEX "LnurlWithdrawEntity_deleted_webhookUrl_withdrawnDetails_paid_batchRequestId_paidCalledback_batchedCalledback_idx" ON "LnurlWithdrawEntity"("deleted", "webhookUrl", "withdrawnDetails", "paid", "batchRequestId", "paidCalledback", "batchedCalledback");
