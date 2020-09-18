/* $Header: XX_DW_ZBH_INV_DETAILS_V.sql 20.03.05 20/03/05 09:00:00 AHMED.LOTFY noship $ */

CREATE OR REPLACE VIEW XX_DW_ZBH_INV_DETAILS_V
AS
   SELECT inv.invoice_type_lookup_code invoice_type,
          inv.gl_date invoice_gl_date,
          inv.invoice_num invoice_number,
          inv.INVOICE_DATE,
          inv.invoice_currency_code invoice_currency,
          inv.exchange_rate invoice_rate,
          INV.amount_paid invoice_paid_amount,
          invd.amount invoice_distribution_Amount,
          invd.PO_DISTRIBUTION_ID
     FROM ap_invoices_all inv, ap_invoice_distributions_all invd
    WHERE     0 = 0
          AND invd.INVOICE_ID = inv.INVOICE_ID
          AND inv.org_id IN (1937, 1938);

/

CREATE OR REPLACE SYNONYM XXDWZBH.XX_DW_ZBH_INV_DETAILS_V FOR APPS.XX_DW_ZBH_INV_DETAILS_V;

/

GRANT SELECT ON APPS.XX_DW_ZBH_INV_DETAILS_V TO XXDWZBH;

/

GRANT SELECT ON APPS.XX_DW_ZBH_INV_DETAILS_V TO RAC_ACCNT;

/