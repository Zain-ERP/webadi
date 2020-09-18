/* $Header: XX_DW_ZBH_PO_DETAILS_V.sql 20.04.24 20/04/43 12:00:00 AHMED.LOTFY noship $ */

CREATE OR REPLACE VIEW APPS.XX_DW_ZBH_PO_DETAILS_V
/* $Header: XX_DW_ZBH_PO_DETAILS_V.sql 20.04.24 20/04/24 12:00:00 AHMED.LOTFY noship $ */
(
   OPERATING_UNIT,
   PO_NUM,
   ORDER_DATE,
   ORDER_TYPE,
   PO_DESCRIPTION,
   VENDOR_NUMBER,
   VENDOR_NAME,
   PO_CANCEL_FLAG,
   STATUS,
   LINE_NUM,
   ITEM_CODE,
   ITEM_DESCRIPTION,
   CATEGORY_NAME,
   CAT_TYPE,
   CAT_FAMILY,
   CAT_CLASSS,
   UNIT_PRICE,
   QUANTITY,
   CURRENCY_CODE,
   CURRENCY_RATE,
   LINE_AMOUNT,
   LINE_LOCAL_CURR_AMOUNT,
   NEED_BY_DATE,
   PROMISED_DATE,
   CHARGE_ACCOUNT,
   PO_DISTRIBUTION_ID,
   LINE_CANCEL_FLAG
)
   BEQUEATH DEFINER
AS
   SELECT org.name operating_unit,
          poh.segment1 po_num,
          poh.creation_date order_date,
          doc.type_name order_type,
          poh.comments PO_DESCRIPTION,
          sup.segment1 vendor_number,
          sup.vendor_name,
          NVL (poh.cancel_flag, 'N') po_cancel_flag,
          DECODE (
             poh.cancel_flag,
             'Y', 'CANCELLED',
             DECODE (
                nvl(poh.closed_code,'OPEN'),
                'CLOSED', 'CLOSED',
                'FINALLY CLOSED', 'CLOSED',
                'OPEN', DECODE (nvl(poh.authorization_status,'INCOMPLETE'),
                                'APPROVED', 'APPROVED',
                                'REJECTED', 'REJECTED',
                                'IN PROCESS', 'IN PROCESS',
                                'INCOMPLETE', 'INCOMPLETE',
                                'REQUIRES REAPPROVAL', 'REQUIRES REAPPROVAL',
                                'PRE-APPROVED', 'PRE-APPROVED',
                                'UNKNOWN'),
                'UNKNOWN'))
             status,
          pol.line_num,
          itm.concatenated_segments item_code,
          itm.description item_description,
          cat.concatenated_segments category_name,
          cat.segment1 cat_type,
          cat.segment2 cat_family,
          cat.segment3 cat_classs,
          pol.unit_price,
          pol.quantity,
          poh.currency_code,
          NVL (poh.rate, 1) currency_rate,
          (pol.quantity * pol.unit_price) line_amount,
          (pol.quantity * pol.unit_price * NVL (poh.rate, 1))
             line_local_curr_amount,
          ploc.NEED_BY_DATE,
          ploc.PROMISED_DATE,
          gcc.CONCATENATED_SEGMENTS CHARGE_ACCOUNT,
          pod.PO_DISTRIBUTION_ID,
          NVL (pol.cancel_flag, 'N') line_cancel_flag
     FROM hr_operating_units org,
          po_headers_all poh,
          ap_suppliers sup,
          po_document_types_all_tl doc,
          (SELECT l.*, p.inventory_organization_id
             FROM po_lines_all l, financials_system_params_all p
            WHERE l.org_id = p.org_id) pol,
          po_line_locations_all ploc,
          po_distributions_all pod,
          gl_code_combinations_kfv gcc,
          mtl_system_items_kfv itm,
          mtl_categories_kfv cat
    WHERE     1 = 1
          AND org.organization_id = poh.org_id
          AND poh.vendor_id = sup.vendor_id(+)
          AND poh.org_id = doc.org_id
          AND 'PO' = doc.document_type_code
          AND poh.type_lookup_code = doc.document_subtype
          AND poh.po_header_id = pol.po_header_id
          AND pol.po_line_id = ploc.po_line_id(+)
          AND ploc.line_location_id = pod.line_location_id(+)
          AND pod.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID(+)
          AND pol.item_id = itm.inventory_item_id(+)
          AND pol.inventory_organization_id = itm.organization_id(+)
          AND pol.category_id = cat.category_id(+)
          AND poh.org_id IN (1937, 1938);

/
