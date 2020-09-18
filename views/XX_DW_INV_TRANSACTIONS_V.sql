CREATE OR REPLACE FORCE VIEW APPS.XX_DW_INV_TRANSACTIONS_V
(
   TRANSACTION_ID,
   CONSIGNED_FLAG,
   SUBINVENTORY_CODE,
   ITEM_CODE,
   ITEM_DESCRIPTION,
   SERIAL_FLAG,
   TRANSACTION_QUANTITY,
   TRANSACTION_UOM,
   TRANSACTION_DATE,
   TRANSACTION_TYPE_NAME,
   SOURCE_LINE_ID,
   TRANSACTION_SOURCE_TYPE,
   TRANSACTION_SOURCE_NAME,
   PO_NUM,
   VENDOR_NAME,
   TRANSACTION_ACTION,
   CREATED_BY
)
   BEQUEATH DEFINER
AS
   SELECT trx.transaction_id,
          CASE
             WHEN trx.owning_organization_id <> trx.organization_id
             THEN
                'C'
             ELSE
                DECODE (
                   (SELECT MAX (owning_organization_id)
                      FROM mtl_material_transactions
                     WHERE     TRANSACTION_set_ID = trx.TRANSACTION_SET_ID
                           AND owning_organization_id <>
                                  trx.owning_organization_id
                           AND inventory_item_id = trx.inventory_item_id
                           AND organization_id = trx.organization_id),
                   '', 'O',
                   'C')
          END
             consigned_flag,
          trx.subinventory_code,
          itm.segment1 item_code,
          itm.description item_description,
          DECODE (itm.serial_number_control_code, 1, 'N', 'Y') serial_flag,
          trx.transaction_quantity,
          trx.transaction_uom,
          trx.transaction_date,
          (SELECT typ.transaction_type_name
             FROM mtl_transaction_types typ
            WHERE typ.transaction_type_id = trx.transaction_type_id)
             transaction_type_name,
          trx.source_line_id,
          (SELECT src.transaction_source_type_name
             FROM mtl_txn_source_types src
            WHERE src.transaction_source_type_id =
                     trx.transaction_source_type_id)
             transaction_source_type,
          trx.transaction_source_name,
          poh.segment1 PO_NUM,
          pov.vendor_name,
          (SELECT act.meaning
             FROM mfg_lookups act
            WHERE     act.lookup_type = 'MTL_TRANSACTION_ACTION'
                  AND act.lookup_code = TO_CHAR (trx.transaction_action_id))
             transaction_action,
          (SELECT usr.user_name
             FROM fnd_user usr
            WHERE usr.user_id = trx.created_by)
             created_by
     FROM mtl_material_transactions trx,
          mtl_system_items_b itm,
          po_headers_all poh,
          ap_suppliers pov
    WHERE     1 = 1
          AND trx.inventory_item_id = itm.inventory_item_id
          AND trx.organization_id = itm.organization_id
          AND DECODE (trx.transaction_source_type_id,
                      1, trx.transaction_source_id,
                      -1) = poh.po_header_id(+)
          AND poh.vendor_id = pov.vendor_id(+)
          AND trx.organization_id = 1309;

/

CREATE OR REPLACE SYNONYM BOLINF.XX_DW_INV_TRANSACTIONS_V FOR APPS.XX_DW_INV_TRANSACTIONS_V;

/

CREATE OR REPLACE SYNONYM DWCON1.XX_DW_INV_TRANSACTIONS_V FOR APPS.XX_DW_INV_TRANSACTIONS_V;

/

CREATE OR REPLACE SYNONYM RAC_ACCNT.XX_DW_INV_TRANSACTIONS_V FOR APPS.XX_DW_INV_TRANSACTIONS_V;

/

CREATE OR REPLACE SYNONYM RAC_ACCNT_HR.XX_DW_INV_TRANSACTIONS_V FOR APPS.XX_DW_INV_TRANSACTIONS_V;

/

GRANT SELECT ON APPS.XX_DW_INV_TRANSACTIONS_V TO BOLINF;

/

GRANT SELECT ON APPS.XX_DW_INV_TRANSACTIONS_V TO DWCON1;

/

GRANT SELECT ON APPS.XX_DW_INV_TRANSACTIONS_V TO RAC_ACCNT;

/

GRANT SELECT ON APPS.XX_DW_INV_TRANSACTIONS_V TO RAC_ACCNT_HR;

/