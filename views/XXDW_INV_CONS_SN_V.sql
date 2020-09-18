/* $Header: XXDW_INV_CONS_SN_V_20_06_30.sql 20.06.30 20/06/30 15:25:00 AHMED.LOTFY noship $ */

CREATE OR REPLACE VIEW XXDW_INV_CONS_SN_V
(
   ITEM_CODE,
   ITEM_DESCRIPTION,
   SERIAL_NUMBER,
   PO_NUMBER,
   RECEIPT_NUM,
   SUPPLIER_NAME,
   PO_DATE,
   RECEIPT_DATE,
   PO_QUANTITY,
   PO_OPEN_QUANTITY
)
   BEQUEATH DEFINER
AS
SELECT /*+ INDEX(rst RCV_SERIAL_TRANSACTIONS_N4) INDEX(rcv RCV_TRANSACTIONS_N3) */
       msib.segment1 ITEM_CODE,
       msib.description ITEM_DESCRIPTION,
       msn.SERIAL_NUMBER,
       poh.segment1 PO_NUMBER,
       shph.RECEIPT_NUM,
       (select osupp.vendor_name from po_vendors osupp, po_vendor_sites_all osups where msn.owning_organization_id = osups.vendor_site_id and osups.vendor_id = osupp.vendor_id) supplier_name,
       poh.creation_date PO_DATE,
       rcv.transaction_date RECEIPT_DATE,
       (pod.QUANTITY_ORDERED - QUANTITY_CANCELLED) PO_QUANTITY,
       (  pod.QUANTITY_ORDERED
        - pod.QUANTITY_DELIVERED
        - pod.QUANTITY_CANCELLED)
          PO_OPEN_QUANTITY
  FROM MTL_SERIAL_NUMBERS msn,
       mtl_system_items_b msib,
       RCV_SERIAL_TRANSACTIONS RST,
       RCV_TRANSACTIONS rcv,
       RCV_SHIPMENT_LINES shpl,
       RCV_SHIPMENT_HEADERS_V shph,
       po_distributions_all pod,
       po_headers_all poh
 WHERE     1 = 1
       AND msn.INVENTORY_ITEM_ID = msib.INVENTORY_ITEM_ID
       AND msn.CURRENT_ORGANIZATION_ID = msib.organization_id
       AND msn.SERIAL_NUMBER = RST.SERIAL_NUM(+)
       AND rst.shipment_line_id = rcv.shipment_line_id(+)
       AND rst.TRANSACTION_ID = rcv.TRANSACTION_ID(+)
       AND rcv.shipment_line_id = shpl.shipment_line_id(+)
       AND shpl.shipment_header_id = shph.shipment_header_id(+)
       AND shpl.PO_DISTRIBUTION_ID = pod.PO_DISTRIBUTION_ID(+)
       AND pod.po_header_id = poh.po_header_id(+)
       AND msn.CURRENT_STATUS = 3
       AND rcv.TRANSACTION_TYPE = 'DELIVER'
       AND msn.OWNING_ORGANIZATION_ID <> 1309
       and msn.current_organization_id = 1309;
		  
/
