CREATE OR REPLACE FORCE VIEW APPS.XX_DW_INV_ITEMS_V
(
   ORG,
   ITEM_CODE,
   DESCRIPTION,
   PRIMARY_UNIT_OF_MEASURE,
   PURCHASING_CATEGORY,
   INVENTORY_CATEGORY,
   ASSET_CATEGORY,
   EXPENSE_ACCOUNT,
   STATUS
)
   BEQUEATH DEFINER
AS
   SELECT organization_code Org                       --,itm.INVENTORY_ITEM_ID
                               ,
          itm.SEGMENT1 Item_Code,
          itm.DESCRIPTION,
          itm.PRIMARY_UNIT_OF_MEASURE --,decode(itc.category_set_id,'1100000042','Purchasing Category',itc.category_set_id) "Category Set"
                                                            --,itc.category_id
          ,
          catp.segment1 || '.' || catp.segment2 || '.' || catp.segment3
             Purchasing_Category,
          catv.segment1 || '.' || catv.segment2 || '.' || catv.segment3
             Inventory_Category,
             fcat.segment1
          || '.'
          || fcat.segment2
          || '.'
          || fcat.segment3
          || '.'
          || fcat.segment4
          || '.'
          || fcat.segment5
             Asset_Category,
             gcc.segment1
          || '.'
          || gcc.segment2
          || '.'
          || gcc.segment3
          || '.'
          || gcc.segment4
          || '.'
          || gcc.segment5
          || '.'
          || gcc.segment6
             Expense_Account,
          inventory_item_status_code status
     FROM mtl_system_items_b itm,
          (SELECT *
             FROM MTL_ITEM_CATEGORIES
            WHERE category_set_id = '1100000042') itcp,
          (SELECT *
             FROM MTL_ITEM_CATEGORIES
            WHERE category_set_id = '1100000041') itcv,
          mtl_categories_b catp,
          mtl_categories_b catv,
          gl_code_combinations gcc,
          FA_CATEGORIES_B fcat,
          INVBV_INVENTORY_ORGANIZATIONS org
    WHERE     1 = 1
          --and itm.organization_id='1329'--
          --and itm.segment1='AST-001-0001'
          --and itm.INVENTORY_ITEM_STATUS_CODE = 'Active'
          AND itm.organization_id = org.organization_id
          AND itm.inventory_item_id = itcp.inventory_item_id(+)
          AND itm.organization_id = itcp.organization_id(+)
          AND itcp.category_id = catp.category_id(+)
          AND itm.inventory_item_id = itcv.inventory_item_id(+)
          AND itm.organization_id = itcv.organization_id(+)
          AND itcv.category_id = catv.category_id(+)
          AND itm.EXPENSE_ACCOUNT = gcc.code_combination_id
          AND itm.ASSET_CATEGORY_ID = fcat.category_id(+)
          AND itm.organization_id = 1309;

/

CREATE OR REPLACE SYNONYM BOLINF.XX_DW_INV_ITEMS_V FOR APPS.XX_DW_INV_ITEMS_V;

/

CREATE OR REPLACE SYNONYM DWCON1.XX_DW_INV_ITEMS_V FOR APPS.XX_DW_INV_ITEMS_V;

/

CREATE OR REPLACE SYNONYM RAC_ACCNT.XX_DW_INV_ITEMS_V FOR APPS.XX_DW_INV_ITEMS_V;

/

CREATE OR REPLACE SYNONYM RAC_ACCNT_HR.XX_DW_INV_ITEMS_V FOR APPS.XX_DW_INV_ITEMS_V;

/

GRANT SELECT ON APPS.XX_DW_INV_ITEMS_V TO BOLINF;

/

GRANT SELECT ON APPS.XX_DW_INV_ITEMS_V TO DWCON1;

/

GRANT SELECT ON APPS.XX_DW_INV_ITEMS_V TO RAC_ACCNT;

/

GRANT SELECT ON APPS.XX_DW_INV_ITEMS_V TO RAC_ACCNT_HR;

/