/* $Header: XXDW_INV_SUBINV_QTY_V.sql 20.05.06 20/05/06 16:00:00 AHMED.LOTFY noship $ */


CREATE OR REPLACE VIEW XXDW_INV_SUBINV_QTY_V
(
   SUBINVENTORY_CODE,
   SUBINVENTORY_DESCRIPTION,
   CONTROLLER,
   PURPOSE,
   TYPE,
   FRANCHISE,
   ITEM_CODE,
   ITEM_STATUS,
   ITEM_DESCRIPTION,
   CONSIGNED_STATUS,
   LOCATOR_CODE,
   UOM_CODE,
   ITEM_ONHAND_QTY,
   RESERVED_QTY,
   EXPECTED_OUTGOING_QUANTITY,
   EXPECTED_INCOMING_QTY
)
   BEQUEATH DEFINER
AS
     SELECT si.secondary_inventory_name subinventory_code,
            si.description subinventory_description,
            si.ATTRIBUTE2 Controller,
            si.ATTRIBUTE3 Purpose,
            si.ATTRIBUTE4 TYPE,
            si.ATTRIBUTE5 Franchise,
            msi.segment1 item_code,
            msi.inventory_item_status_code item_status,
            msi.description item_description,
            DECODE (moqd.is_consigned,
                    1, 'Consigned',
                    2, 'Owned',
                    moqd.is_consigned)
               Consigned_status,
            mil.segment1 locator_code,
            msi.primary_uom_code uom_code,
            NVL (moqd.primary_transaction_quantity, 0) ITEM_ONHAND_QTY,
            (SELECT NVL (SUM (r.reservation_quantity), 0)
               FROM mtl_reservations r
              WHERE     r.organization_id = moqd.organization_id
                    AND r.inventory_item_id = moqd.inventory_item_id
                    AND r.subinventory_code = moqd.subinventory_code)
               RESERVED_QTY,
            (SELECT SUM (transaction_quantity)
               FROM mtl_material_transactions_temp mmtta
              WHERE     mmtta.inventory_item_id = moqd.inventory_item_id
                    AND mmtta.organization_id = moqd.organization_id
                    AND mmtta.LOCATOR_ID = moqd.locator_id)
               EXPECTED_OUTGOING_QUANTITY,
            (SELECT SUM (transaction_quantity)
               FROM mtl_material_transactions_temp mmttx
              WHERE     mmttx.inventory_item_id = moqd.inventory_item_id
                    AND mmttx.organization_id = moqd.organization_id
                    AND mmttx.transfer_to_location = moqd.locator_id)
               EXPECTED_INCOMING_QTY
       FROM MTL_SYSTEM_ITEMS_VL msi,
            MTL_ONHAND_QUANTITIES_detail moqd,
            mtl_onhand_qty_cost_v moqc,
            MTL_SECONDARY_INVENTORIES si,
            MTL_ITEM_LOCATIONS mil
      WHERE     0 = 0
            AND si.secondary_inventory_name = moqd.subinventory_code(+)
            AND si.organization_id = moqd.organization_id(+)
            AND moqd.organization_id = msi.organization_id(+)
            AND moqd.inventory_item_id = msi.inventory_item_id(+)
            AND moqd.locator_id = mil.inventory_location_id(+)
            AND moqd.organization_id = mil.organization_id(+)
            AND moqd.organization_id = moqc.organization_id(+)
            AND moqd.inventory_item_id = moqc.inventory_item_id(+)
            AND moqd.UPDATE_TRANSACTION_ID = moqc.UPDATE_TRANSACTION_ID(+)
            AND moqd.subinventory_code = moqc.subinventory_code(+)
            AND si.quantity_tracked = 1
            AND si.organization_id = 1309
            AND msi.ORGANIZATION_ID = si.organization_id
   ORDER BY 1, 4;
		  
/

CREATE OR REPLACE SYNONYM DWCON1.XXDW_INV_SUBINV_QTY_V FOR APPS.XXDW_INV_SUBINV_QTY_V;

/

CREATE OR REPLACE SYNONYM RAC_ACCNT.XXDW_INV_SUBINV_QTY_V FOR APPS.XXDW_INV_SUBINV_QTY_V;

/

CREATE OR REPLACE SYNONYM XXDW.XXDW_INV_SUBINV_QTY_V FOR APPS.XXDW_INV_SUBINV_QTY_V;

/

GRANT SELECT ON APPS.XXDW_INV_SUBINV_QTY_V TO DWCON1;

/

GRANT SELECT ON APPS.XXDW_INV_SUBINV_QTY_V TO RAC_ACCNT;

/

GRANT SELECT ON APPS.XXDW_INV_SUBINV_QTY_V TO XXDW;

/