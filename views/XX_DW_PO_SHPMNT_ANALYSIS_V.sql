CREATE OR REPLACE FORCE VIEW APPS.XX_DW_PO_SHPMNT_ANALYSIS_V
(
   OPEN_QUANTITY,
   DESTINATION_TYPE,
   ITEM,
   DESCRIPTION,
   LOCATION,
   REQUESTER,
   SUBINVENTORY,
   PO_CATEGORY,
   OPERATING_UNIT,
   ORDER_TYPE,
   PO_NUMBER,
   REL,
   LINE_NUM,
   SHIPMENT,
   SUPPLIER,
   QTY_ORDERED,
   DUE_DATE,
   RECEIVED_QTY,
   PO_STATUS,
   LINE_STATUS,
   COST_IN_PO,
   CURRANCY,
   PO_HEADER_ID,
   PO_LINE_ID,
   LINE_LOCATION_ID,
   PO_DISTRIBUTION_ID
)
   BEQUEATH DEFINER
AS
   (SELECT /*+ INDEX(pol PO_LINES_U2) INDEX(ploc PO_LINE_LOCATIONS_N1) INDEX(itm MTL_SYSTEM_ITEMS_B_U1) INDEX(catp.mtl_categories_b MTL_CATEGORIES_B_U1) */
           (  ploc.QUANTITY
            - (ploc.QUANTITY_RECEIVED + ploc.QUANTITY_CANCELLED))
              Open_Quantity,
           reql.DESTINATION_TYPE_CODE Destination_Type,
           itm.segment1 Item,
           itm.description Description,
           (SELECT location_code
              FROM HR_LOCATIONS
             WHERE location_id = reql.DELIVER_TO_LOCATION_ID)
              Location,
           ppl.full_name Requester,
           reql.DESTINATION_SUBINVENTORY Subinventory,
           catp.concatenated_segments PO_Category,
           ou.NAME Operating_Unit,
           poh.TYPE_LOOKUP_CODE Order_Type,
           poh.segment1 PO_Number,
           rel.RELEASE_NUM RELEASE_NUM,
           pol.line_num Line_NUM,
           ploc.shipment_num Shipment,
           pov.vendor_name Supplier,
           ploc.QUANTITY Qty_Ordered,
           ploc.need_by_date Due_Date,
           ploc.quantity_received Received_Qty,
           poh.AUTHORIZATION_STATUS || ' - ' || poh.CLOSED_CODE PO_Status,
           pol.CLOSED_CODE Line_Status,
           pol.unit_price Cost_In_PO,
           poh.currency_code Currancy,
           poh.po_header_id,
           pol.po_line_id,
           ploc.line_location_id,
           pod.po_distribution_id
      FROM po_headers_all poh,
           po_lines_all pol,
           po_line_locations_all ploc,
           po_distributions_all pod,
           mtl_categories_b_kfv catp,
           po_releases_all rel,
           po_vendors pov,
           hr_all_organization_units ou,
           (SELECT *
              FROM per_all_people_f
             WHERE TRUNC (SYSDATE) BETWEEN effective_start_date
                                       AND effective_end_date) ppl,
           mtl_system_items_b itm,
           po_req_distributions_all reqd,
           po_requisition_headers_all reqh,
           po_requisition_lines_all reql
     WHERE     1 = 1
           AND poh.authorization_status = 'APPROVED'
           AND poh.po_header_id + 0 = pol.po_header_id
           AND pol.po_line_id + 0 = ploc.po_line_id
           AND pol.category_id = catp.category_id
           AND ploc.line_location_id = pod.line_location_id
           AND poh.vendor_id = pov.vendor_id
           AND poh.org_id = ou.organization_id
           AND reql.to_person_id = ppl.person_id(+)
           AND pol.item_id + 0 = itm.INVENTORY_ITEM_ID
           AND itm.organization_id = 1264
           AND ploc.PO_RELEASE_ID = rel.PO_RELEASE_ID(+)
           AND pod.REQ_DISTRIBUTION_ID = reqd.DISTRIBUTION_ID
           AND reqd.REQUISITION_LINE_ID = reql.REQUISITION_LINE_ID
           AND reql.REQUISITION_HEADER_ID = reqh.REQUISITION_HEADER_ID
           AND ou.NAME IN ('Consigned OU', 'Zain Kuwait (OU)')
           AND ou.business_group_id = 81
           AND reql.DESTINATION_TYPE_CODE = 'INVENTORY');

/           

CREATE OR REPLACE SYNONYM DWCON1.XX_DW_PO_SHPMNT_ANALYSIS_V FOR APPS.XX_DW_PO_SHPMNT_ANALYSIS_V;

/

CREATE OR REPLACE SYNONYM RAC_ACCNT.XX_DW_PO_SHPMNT_ANALYSIS_V FOR APPS.XX_DW_PO_SHPMNT_ANALYSIS_V;

/

CREATE OR REPLACE SYNONYM RAC_ACCNT_HR.XX_DW_PO_SHPMNT_ANALYSIS_V FOR APPS.XX_DW_PO_SHPMNT_ANALYSIS_V;

/

GRANT SELECT ON APPS.XX_DW_PO_SHPMNT_ANALYSIS_V TO DWCON1;

/

GRANT SELECT ON APPS.XX_DW_PO_SHPMNT_ANALYSIS_V TO RAC_ACCNT;

/

GRANT SELECT ON APPS.XX_DW_PO_SHPMNT_ANALYSIS_V TO RAC_ACCNT_HR;

/