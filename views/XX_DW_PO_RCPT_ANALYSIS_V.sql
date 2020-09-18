/* $Header: XX_DW_PO_RCPT_ANALYSIS_V1.sql 2.0 20/07/15 16:00:00 AHMED.LOTFY noship $ */
CREATE OR REPLACE FORCE VIEW APPS.XX_DW_PO_RCPT_ANALYSIS_V
(
   PO_HEADER_ID,
   PO_LINE_ID,
   LINE_LOCATION_ID,
   PO_DISTRIBUTION_ID,
   RECEIVED_QTY,
   RECEIVED_DATE,
   TRANSACTION_ID,
   RECEIPT,
   COMMENTS,
   PACKING_SLIP,
   RECEIVER,
   WAYBILL_AIRBILL
)
AS
   (SELECT rcv.po_header_id,
           rcv.po_line_id,
           rcv.po_line_location_id,
           rcv.po_distribution_id,
           rcv.QUANTITY Received_Qty,
           rcv.TRANSACTION_DATE Received_Date,
           rcv.TRANSACTION_ID,
           shph.RECEIPT_NUM Receipt,
           shph.COMMENTS Comments,
           shph.PACKING_SLIP Packing_Slip,
           ppl2.full_name Receiver,
           shph.WAYBILL_AIRBILL_NUM Waybill_Airbill
      FROM RCV_TRANSACTIONS rcv,
           RCV_SHIPMENT_LINES shpl,
           RCV_SHIPMENT_HEADERS_V shph,
           (SELECT *
              FROM per_all_people_f
             WHERE TRUNC (SYSDATE) BETWEEN effective_start_date
                                       AND effective_end_date) ppl2
     WHERE     0 = 0
           AND rcv.TRANSACTION_TYPE = 'DELIVER'
           AND rcv.shipment_line_id = shpl.shipment_line_id
           AND shpl.shipment_header_id = shph.shipment_header_id
           AND shph.EMPLOYEE_ID = ppl2.person_id(+))
/