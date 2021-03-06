/* $Header: XX_DW_RCV_SN_TRANSACTIONS_V.sql 1.0 20/07/15 16:00:00 AHMED.LOTFY noship $ */

CREATE OR REPLACE FORCE VIEW APPS.XX_DW_RCV_SN_TRANSACTIONS_V
(
   TRANSACTION_ID,
   serial_num
)
AS
   (SELECT TRANSACTION_ID, serial_num
      FROM RCV_SERIAL_TRANSACTIONS
     WHERE 0 = 0)

/

CREATE OR REPLACE SYNONYM DWCON1.XX_DW_RCV_SN_TRANSACTIONS_V FOR APPS.XX_DW_RCV_SN_TRANSACTIONS_V;

/

CREATE OR REPLACE SYNONYM RAC_ACCNT.XX_DW_RCV_SN_TRANSACTIONS_V FOR APPS.XX_DW_RCV_SN_TRANSACTIONS_V;

/

CREATE OR REPLACE SYNONYM XXDW.XX_DW_RCV_SN_TRANSACTIONS_V FOR APPS.XX_DW_RCV_SN_TRANSACTIONS_V;

/

GRANT SELECT ON APPS.XX_DW_RCV_SN_TRANSACTIONS_V TO DWCON1;

/

GRANT SELECT ON APPS.XX_DW_RCV_SN_TRANSACTIONS_V TO RAC_ACCNT;

/

GRANT SELECT ON APPS.XX_DW_RCV_SN_TRANSACTIONS_V TO XXDW;

/