CREATE OR REPLACE FORCE VIEW APPS.XX_DW_INV_ONHAND_QTY_V
(
   SUBINVENTORY_CODE,
   ITEM_CODE,
   ITEM_DESCRIPTION,
   SERIAL_FLAG,
   SERIAL_NUMBER,
   ONHAND,
   AVAILABLE
)
   BEQUEATH DEFINER
AS
   SELECT /*+ INDEX(mtx.x MTL_MATERIAL_TRANS_TEMP_N2) INDEX(itm MTL_SYSTEM_ITEMS_B_U1) */
         qty.subinventory_code,
          itm.segment1 item_code,
          itm.description item_description,
          DECODE (itm.serial_number_control_code, 1, 'N', 'Y') serial_flag,
          msn.serial_number,
          DECODE (itm.serial_number_control_code,
                  1, qty.transaction_quantity,
                  1)
             onhand,
          DECODE (
             itm.serial_number_control_code,
             1, (qty.transaction_quantity - NVL (mtx.transaction_quantity, 0)),
               1
             - (SELECT COUNT (1)
                  FROM mtl_serial_numbers_temp
                 WHERE msn.serial_number BETWEEN fm_serial_number
                                             AND to_serial_number))
             available
     FROM mtl_system_items_b itm,
          (  SELECT organization_id,
                    subinventory_code,
                    inventory_item_id,
                    SUM (transaction_quantity) transaction_quantity
               FROM mtl_onhand_quantities_detail
           GROUP BY organization_id, subinventory_code, inventory_item_id)
          qty,
          (  SELECT organization_id,
                    subinventory_code,
                    inventory_item_id,
                    SUM (transaction_quantity) transaction_quantity
               FROM mtl_material_transactions_temp x
           GROUP BY organization_id, subinventory_code, inventory_item_id)
          mtx,
          (SELECT serial_number,
                  current_organization_id,
                  current_subinventory_code,
                  inventory_item_id
             FROM mtl_serial_numbers
            WHERE current_status = 3) msn
    WHERE     1 = 1
          AND itm.organization_id = qty.organization_id + 0
          AND itm.inventory_item_id = qty.inventory_item_id + 0
          AND qty.organization_id = msn.current_organization_id(+)
          AND qty.subinventory_code = msn.current_subinventory_code(+)
          AND qty.inventory_item_id = msn.inventory_item_id(+)
          AND qty.organization_id = mtx.organization_id(+)
          AND qty.inventory_item_id = mtx.inventory_item_id(+)
          AND qty.subinventory_code = mtx.subinventory_code(+)
          AND itm.organization_id = 1309;

/

CREATE OR REPLACE SYNONYM BOLINF.XX_DW_INV_ONHAND_QTY_V FOR APPS.XX_DW_INV_ONHAND_QTY_V;

/

CREATE OR REPLACE SYNONYM DWCON1.XX_DW_INV_ONHAND_QTY_V FOR APPS.XX_DW_INV_ONHAND_QTY_V;

/

CREATE OR REPLACE SYNONYM RAC_ACCNT.XX_DW_INV_ONHAND_QTY_V FOR APPS.XX_DW_INV_ONHAND_QTY_V;

/

CREATE OR REPLACE SYNONYM RAC_ACCNT_HR.XX_DW_INV_ONHAND_QTY_V FOR APPS.XX_DW_INV_ONHAND_QTY_V;

/

GRANT SELECT ON APPS.XX_DW_INV_ONHAND_QTY_V TO BOLINF;

/

GRANT SELECT ON APPS.XX_DW_INV_ONHAND_QTY_V TO DWCON1;

/

GRANT SELECT ON APPS.XX_DW_INV_ONHAND_QTY_V TO RAC_ACCNT;

/

GRANT SELECT ON APPS.XX_DW_INV_ONHAND_QTY_V TO RAC_ACCNT_HR;

/