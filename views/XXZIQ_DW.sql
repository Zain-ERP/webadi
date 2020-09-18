CREATE OR REPLACE VIEW APPS.XXZIQ_DW_PO_HEADERS_V
AS(
SELECT poh.po_header_id,
       poh.segment1 po_num,
       ppl.full_name buyer,
       poh.comments description,
       pov.vendor_name supplier
  FROM po_headers_all poh,
       po_agents agn,
       per_all_people_f ppl,
       po_vendors pov
 WHERE     0 = 0
       AND poh.agent_id = agn.agent_id
       AND agn.agent_id = ppl.person_id(+)
       AND poh.vendor_id = pov.vendor_id
       AND poh.creation_date BETWEEN ppl.effective_start_date
                                 AND ppl.effective_end_date
       AND poh.org_id = 3350
);

/

CREATE OR REPLACE VIEW APPS.XXZIQ_DW_PO_LINES_V
AS(
SELECT pol.po_header_id,
       pol.po_line_id,
       pol.line_num,
       pol.item_description description,
       pol.unit_meas_lookup_code Unit,
       pol.quantity,
       pol.unit_price price,
       (pol.quantity * pol.unit_price) total
  FROM po_lines_all pol
 WHERE 0 = 0 AND pol.org_id = 3350
);

/


CREATE OR REPLACE VIEW APPS.XXZIQ_DW_PO_LINE_LOCATIONS_V
AS(
SELECT ploc.po_header_id,
       ploc.po_line_id,
       ploc.line_location_id,
       ploc.QUANTITY_RECEIVED RECEIVED,
       ploc.QUANTITY_BILLED BILLED
  FROM po_line_locations_all ploc
 WHERE 0 = 0 AND ploc.org_id = 3350
);

/

CREATE OR REPLACE VIEW APPS.XXZIQ_DW_PO_DISTRIBUTIONS_V
AS( 
SELECT pod.po_header_id,
       pod.po_line_id,
       pod.line_location_id,
       pod.REQ_DISTRIBUTION_ID
  FROM po_distributions_all pod
 WHERE 0 = 0 AND pod.org_id = 3350
);

/


CREATE OR REPLACE VIEW APPS.XXZIQ_DW_PO_ACTIONS_V
AS( 
  SELECT poh.PO_HEADER_ID,
         act.sequence_num,
         p.full_name NAME,
         act.action_code ACTION,
         act.action_date ACTION_DATE,
         act.note
    FROM po_headers_all poh, po_action_history act, per_all_people_f p
   WHERE     0 = 0
         AND act.object_id = poh.PO_HEADER_ID
         AND act.object_type_code = 'PO'
         AND act.EMPLOYEE_ID = p.person_id
         AND poh.creation_date BETWEEN p.effective_start_date
                                   AND p.effective_end_date
         AND poh.org_id = 3350
);

/


CREATE OR REPLACE VIEW APPS.XXZIQ_DW_REQ_HEADERS_V
AS(
SELECT reqh.REQUISITION_HEADER_ID,
       reqh.segment1 PR_NUM,
       (SELECT DISTINCT p.full_name
          FROM per_all_people_f p
         WHERE     1 = 1
               AND p.person_id = reqh.preparer_id
               AND reqh.creation_date BETWEEN p.effective_start_date
                                          AND p.effective_end_date)
          PREPARER_NAME,
       reqh.description,
       reqh.note_to_authorizer JUSTIFICATION
  FROM po_requisition_headers_all reqh
 WHERE 0 = 0 AND reqh.org_id = 3350
);

/



CREATE OR REPLACE VIEW APPS.XXZIQ_DW_REQ_LINES_V
AS(
SELECT reql.requisition_header_id,
       reql.requisition_line_id,
       reql.line_num,
       reql.item_description description,
       reql.suggested_vendor_name SUGGESTED_SUPPLIER,
       reql.UNIT_MEAS_LOOKUP_CODE UNIT,
       reql.QUANTITY,
       reql.UNIT_PRICE PRICE,
       (reql.QUANTITY * reql.UNIT_PRICE) total,
       (SELECT DISTINCT p.full_name
          FROM per_all_people_f p
         WHERE     1 = 1
               AND p.person_id = reql.to_person_id
               AND reql.creation_date BETWEEN p.effective_start_date
                                          AND p.effective_end_date)
          REQUESTER_NAME
  FROM po_requisition_lines_all reql
 WHERE 0 = 0 AND reql.org_id = 3350
);

/


CREATE OR REPLACE VIEW APPS.XXZIQ_DW_REQ_DISTRIBUTIONS_V
AS(
SELECT reqd.requisition_line_id, reqd.distribution_id
  FROM po_req_distributions_all reqd
 WHERE 0 = 0 AND reqd.org_id = 3350
);

/
 


CREATE OR REPLACE VIEW APPS.XXZIQ_DW_REQ_ACTIONS_V
AS( 
  SELECT reqh.REQUISITION_HEADER_ID,
         act.sequence_num,
         p.full_name NAME,
         act.action_code ACTION,
         act.action_date ACTION_DATE,
         act.note
    FROM po_requisition_headers_all reqh, po_action_history act, per_all_people_f p
   WHERE     0 = 0
         AND act.object_id = reqh.REQUISITION_HEADER_ID
         AND act.object_type_code = 'REQUISITION'
         AND act.EMPLOYEE_ID = p.person_id
         AND reqh.creation_date BETWEEN p.effective_start_date
                                   AND p.effective_end_date
         AND reqh.org_id = 3350
);

/



CREATE OR REPLACE PUBLIC SYNONYM XXZIQ_DW_PO_HEADERS_V FOR XXZIQ_DW_PO_HEADERS_V;
/

CREATE OR REPLACE PUBLIC SYNONYM XXZIQ_DW_PO_LINES_V FOR XXZIQ_DW_PO_LINES_V;
/

CREATE OR REPLACE PUBLIC SYNONYM XXZIQ_DW_PO_LINE_LOCATIONS_V FOR XXZIQ_DW_PO_LINE_LOCATIONS_V;
/

CREATE OR REPLACE PUBLIC SYNONYM XXZIQ_DW_PO_DISTRIBUTIONS_V FOR XXZIQ_DW_PO_DISTRIBUTIONS_V;
/

CREATE OR REPLACE PUBLIC SYNONYM XXZIQ_DW_PO_ACTIONS_V FOR XXZIQ_DW_PO_ACTIONS_V;
/

CREATE OR REPLACE PUBLIC SYNONYM XXZIQ_DW_REQ_HEADERS_V FOR XXZIQ_DW_REQ_HEADERS_V;
/

CREATE OR REPLACE PUBLIC SYNONYM XXZIQ_DW_REQ_LINES_V FOR XXZIQ_DW_REQ_LINES_V;
/

CREATE OR REPLACE PUBLIC SYNONYM XXZIQ_DW_REQ_DISTRIBUTIONS_V FOR XXZIQ_DW_REQ_DISTRIBUTIONS_V;
/

CREATE OR REPLACE PUBLIC SYNONYM XXZIQ_DW_REQ_ACTIONS_V FOR XXZIQ_DW_REQ_ACTIONS_V;
/

GRANT SELECT ON XXZIQ_DW_PO_HEADERS_V TO XXZIQINT,RAC_ACCNT;
/

GRANT SELECT ON XXZIQ_DW_PO_LINES_V TO XXZIQINT,RAC_ACCNT;
/

GRANT SELECT ON XXZIQ_DW_PO_LINE_LOCATIONS_V TO XXZIQINT,RAC_ACCNT;
/

GRANT SELECT ON XXZIQ_DW_PO_DISTRIBUTIONS_V TO XXZIQINT,RAC_ACCNT;
/

GRANT SELECT ON XXZIQ_DW_PO_ACTIONS_V TO XXZIQINT,RAC_ACCNT;
/

GRANT SELECT ON XXZIQ_DW_REQ_HEADERS_V TO XXZIQINT,RAC_ACCNT;
/

GRANT SELECT ON XXZIQ_DW_REQ_LINES_V TO XXZIQINT,RAC_ACCNT;
/

GRANT SELECT ON XXZIQ_DW_REQ_DISTRIBUTIONS_V TO XXZIQINT,RAC_ACCNT;
/

GRANT SELECT ON XXZIQ_DW_REQ_ACTIONS_V TO XXZIQINT,RAC_ACCNT;
/
