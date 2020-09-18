/* $Header: XX_DW_ZBH_SUBINV_QTY_V.sql 20.08.19 20/08/19 11:00:00 AHMED.LOTFY noship $ */

CREATE OR REPLACE VIEW APPS.XX_DW_ZBH_SUBINV_QTY_V
as
(
SELECT si.secondary_inventory_name subinv_dtl,
          si.secondary_inventory_name
       || '                                        '
       || si.description
          subinv,
       si.description subinv_desc_dtl,
       si.description subinv_desc,
       si.attribute2 controller,
       si.attribute3 purpose,
       si.attribute4 TYPE,
       si.attribute5 franchise,
       msi.inventory_item_status_code item_status,
       DECODE (moqd.is_consigned,
               1, 'Consigned',
               2, 'Owned',
               moqd.is_consigned)
          consigned_status,
msi.segment1 item_code,
       msi.description item_description,
       moqd.revision item_revision,
       (SELECT cst.item_cost
          FROM cst_item_cost_type_v cst
         WHERE     cst.organization_id = moqd.organization_id
               AND cst.inventory_item_id = moqd.inventory_item_id
               AND cst.organization_id = moqd.owning_organization_id)
          item_cost2,
       moqd.locator_id locator_id,
       (SELECT mil.segment1
          FROM mtl_item_locations mil
         WHERE     moqd.locator_id = mil.inventory_location_id
               AND moqd.organization_id = mil.organization_id)
          locator_code,
       si.organization_id,
       msi.inventory_item_id item_id,
       msi.primary_uom_code uom_code,
       NVL (moqd.primary_transaction_quantity, 0) item_qty,
       DECODE (msi.reservable_type, '2', moqd.transaction_quantity, 0)
          rsrv_qty2,
       msi.list_price_per_unit list_price,
       msi.market_price
  FROM 
       mtl_system_items_b msi,
       mtl_onhand_quantities_detail moqd,
       mtl_secondary_inventories si,
       MTL_ITEM_LOCATIONS mil
 WHERE  0=0
       AND si.secondary_inventory_name = moqd.subinventory_code(+)
       AND si.organization_id = moqd.organization_id(+)
       AND moqd.organization_id = msi.organization_id(+)
       AND moqd.inventory_item_id = msi.inventory_item_id(+)
       and moqd.locator_id = mil.inventory_location_id(+) 
       and moqd.organization_id = mil.organization_id(+)
       AND si.quantity_tracked = 1
       AND si.organization_id = 1943
       AND si.status_id = 1
       AND msi.inventory_item_status_code = 'Active'
       AND msi.organization_id = si.organization_id   
union all
SELECT si.secondary_inventory_name subinv_dtl,
si.secondary_inventory_name||'                                        '||si.description      subinv, 
si.description                   subinv_desc_dtl,
si.description                         subinv_desc,
si.ATTRIBUTE2 Controller,
si.ATTRIBUTE3 Purpose,
si.ATTRIBUTE4 Type,
si.ATTRIBUTE5 Franchise,
msi.inventory_item_status_code item_status,
NULL consigned_status,
msi.segment1 item_code,
msi.description            item_description,
null   item_revision, 
       (SELECT cst.item_cost
          FROM cst_item_cost_type_v cst
         WHERE     cst.organization_id = moqd.organization_id
               AND cst.inventory_item_id = moqd.inventory_item_id
               AND cst.organization_id = moqd.owning_organization_id)
          item_cost2,
moqd.transfer_to_location  locator_id, 
       (SELECT mil.segment1
          FROM mtl_item_locations mil
         WHERE     moqd.locator_id = mil.inventory_location_id
               AND moqd.organization_id = mil.organization_id)
          locator_code,
si.organization_id,
msi.inventory_item_id        item_id,
msi.primary_uom_code      uom_code, 
0   item_qty, 
       DECODE (msi.reservable_type, '2', moqd.transaction_quantity, 0)
          rsrv_qty2,
msi.list_price_per_unit list_price,
msi.market_price
FROM 
  
   MTL_SYSTEM_ITEMS_VL     msi,
    mtl_material_transactions_temp moqd,
   MTL_SECONDARY_INVENTORIES si,
   MTL_ITEM_LOCATIONS mil
WHERE 0=0
and si.secondary_inventory_name = moqd.transfer_subinventory
and si.organization_id = moqd.organization_id 
and moqd.organization_id = msi.organization_id
and moqd.inventory_item_id = msi.inventory_item_id 
and moqd.transfer_to_location = mil.inventory_location_id
and moqd.organization_id = mil.organization_id
and si.quantity_tracked = 1
and si.organization_id = 1943
and not exists 
(
select '1' from MTL_ONHAND_QUANTITIES_detail onh
where  onh.organization_id = msi.organization_id
and onh.inventory_item_id = msi.inventory_item_id 
and onh.locator_id =moqd.transfer_to_location
)
);

/

CREATE OR REPLACE SYNONYM XXDWZBH.XX_DW_ZBH_SUBINV_QTY_V FOR APPS.XX_DW_ZBH_SUBINV_QTY_V;

/

GRANT SELECT ON APPS.XX_DW_ZBH_SUBINV_QTY_V TO XXDWZBH;

/

GRANT SELECT ON APPS.XX_DW_ZBH_SUBINV_QTY_V TO RAC_ACCNT;

/      
       