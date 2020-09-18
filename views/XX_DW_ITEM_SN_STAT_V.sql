CREATE OR REPLACE FORCE VIEW APPS.XX_DW_ITEM_SN_STAT_V
(
   ITEM_CODE,
   ITEM_DESCRIPTION,
   ITEM_COST,
   SERIAL_NUMBER,
   ITEM_CURRENT_STATUS,
   IS_CONSIGNED,
   CURRENT_SUBINVENTORY_CODE,
   SUBINVENTORY_DESCRIPTION,
   LAST_TRANSACTION_TYPE_NAME,
   LAST_TRANSACTION_SOURCE_NAME,
   LAST_TRANSACTION_SUBINVENTORY,
   LAST_TRANSACTION_QUANTITY,
   LAST_TRANSACTION_UOM,
   LAST_TRANSACTION_REFERENCE,
   MOVE_ORDER_NUMBER,
   MOVE_ORDER_DESCRIPTION,
   TRANSFER_DATE,
   TRANSACTED_DATE,
   FROM_SUBINVENTORY_CODE,
   TO_SUBINVENTORY_CODE
)
   BEQUEATH DEFINER
AS
   SELECT msi.segment1,
          msi.description,
          cost.item_Cost,
          msn.SERIAL_NUMBER,
          DECODE (msn.CURRENT_STATUS,
                  1, 'Defined but not used',
                  3, 'Resides in stores',
                  4, 'Issued out of stores',
                  5, 'Resides in intransit',
                  7, 'Resides in receiving',
                  8, 'Resides in WIP',
                  msn.CURRENT_STATUS),
          DECODE (msn.OWNING_ORGANIZATION_ID, 1309, 'Purchased', 'Consigned'),
          msn.CURRENT_SUBINVENTORY_CODE,
          SUBINV.DESCRIPTION,
          MTT.TRANSACTION_TYPE_NAME,
          MTST.TRANSACTION_SOURCE_TYPE_NAME,
          TXN.subinventory_code,
          TXN.transaction_quantity,
          TXN.transaction_UOM,
          TXN.TRANSACTION_REFERENCE,
          MTRH.REQUEST_NUMBER,
          MTRH.DESCRIPTION,
          MTRL.CREATION_DATE,
          MTRL.LAST_UPDATE_DATE,
          MTRL.FROM_SUBINVENTORY_CODE,
          MTRL.TO_SUBINVENTORY_CODE
     FROM MTL_SERIAL_NUMBERS msn,
          CST_ITEM_COST_TYPE_V cost,
          MTL_SYSTEM_ITEMS_B msi,
          MTL_MATERIAL_TRANSACTIONS TXN,
          MTL_TRANSACTION_TYPES MTT,
          MTL_TXN_SOURCE_TYPES MTST,
          MTL_TXN_REQUEST_LINES MTRL,
          MTL_TXN_REQUEST_HEADERS MTRH,
          MTL_SECONDARY_INVENTORIES SUBINV
    WHERE     1 = 1
          AND msi.organization_id = cost.ORGANIZATION_ID(+)
          AND msi.INVENTORY_ITEM_ID = cost.INVENTORY_ITEM_ID(+)
          AND msn.INVENTORY_ITEM_ID = msi.INVENTORY_ITEM_ID
          AND msn.CURRENT_ORGANIZATION_ID = msi.organization_id
          AND msi.organization_id = TXN.organization_id(+)
          AND msn.last_transaction_id = TXN.transaction_id(+)
          AND TXN.transaction_type_id = MTT.transaction_type_id
          AND MTT.TRANSACTION_SOURCE_TYPE_ID =
                 MTST.TRANSACTION_SOURCE_TYPE_ID
          AND MSN.CURRENT_SUBINVENTORY_CODE = SUBINV.SECONDARY_INVENTORY_NAME
          AND TXN.organization_id = subinv.organization_id
          AND TXN.SOURCE_LINE_ID = MTRL.LINE_ID(+)
          AND MTRL.HEADER_ID = MTRH.HEADER_ID(+)
          AND msn.CURRENT_ORGANIZATION_ID = 1309
          AND msn.CURRENT_STATUS = 3;

/

CREATE OR REPLACE SYNONYM DWCON1.XX_DW_ITEM_SN_STAT_V FOR APPS.XX_DW_ITEM_SN_STAT_V;

/

GRANT SELECT ON APPS.XX_DW_ITEM_SN_STAT_V TO DWCON1;

/