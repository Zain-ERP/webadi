/* $Header: XX_PO_DW.sql 19.97.02 19/07/02 11:00:00 AHMED.LOTFY noship $ */

CREATE OR REPLACE VIEW APPS.XX_PO_HEADERS_DW_V
AS(
SELECT poh.org_id,
poh.po_header_id,
       poh.segment1 po_num,
       poh.creation_date,
       ppl.full_name buyer,
       poh.comments description,
       poh.currency_code,
       pov.vendor_name supplier
  FROM po_headers_all poh,
       po_agents agn,
       per_all_people_f ppl,
       po_vendors pov
 WHERE     0 = 0
       AND poh.agent_id = agn.agent_id
       AND agn.agent_id = ppl.person_id(+)
       AND poh.vendor_id = pov.vendor_id
       AND trunc(poh.creation_date) BETWEEN ppl.effective_start_date
                                 AND ppl.effective_end_date
);

/

CREATE OR REPLACE VIEW APPS.XX_PO_LINES_DW_V
AS(
SELECT pol.org_id,
pol.po_header_id,
       pol.po_line_id,
       pol.line_num,
       pol.item_description description,
       pol.unit_meas_lookup_code Unit,
       pol.quantity,
       pol.unit_price price,
       (pol.quantity * pol.unit_price) total
  FROM po_lines_all pol
);

/


CREATE OR REPLACE VIEW APPS.XX_PO_LINE_LOCATIONS_DW_V
AS(
SELECT ploc.org_id,
ploc.po_header_id,
       ploc.po_line_id,
       ploc.line_location_id,
       ploc.QUANTITY_RECEIVED RECEIVED,
       ploc.QUANTITY_BILLED BILLED
  FROM po_line_locations_all ploc
);

/

CREATE OR REPLACE VIEW APPS.XX_PO_DISTRIBUTIONS_DW_V
AS( 
SELECT pod.org_id,
pod.po_header_id,
       pod.po_line_id,
       pod.line_location_id,
       pod.REQ_DISTRIBUTION_ID
  FROM po_distributions_all pod
);

/


CREATE OR REPLACE VIEW APPS.XX_PO_ACTIONS_DW_V
AS( 
  SELECT poh.org_id,
  poh.PO_HEADER_ID,
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
         AND trunc(poh.creation_date) BETWEEN p.effective_start_date
                                   AND p.effective_end_date
);

/


CREATE OR REPLACE VIEW APPS.XX_REQ_HEADERS_DW_V
AS(
SELECT reqh.org_id,
reqh.REQUISITION_HEADER_ID,
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
);

/



CREATE OR REPLACE VIEW APPS.XX_REQ_LINES_DW_V
AS(
SELECT reql.org_id,
reql.requisition_header_id,
       reql.requisition_line_id,
       reql.line_num,
       reql.item_description description,
       reql.suggested_vendor_name SUGGESTED_SUPPLIER,
       reql.currency_code,
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
);

/


CREATE OR REPLACE VIEW APPS.XX_REQ_DISTRIBUTIONS_DW_V
AS(
SELECT reqd.org_id,reqd.requisition_line_id, reqd.distribution_id
  FROM po_req_distributions_all reqd
);

/
 


CREATE OR REPLACE VIEW APPS.XX_REQ_ACTIONS_DW_V
AS( 
  SELECT reqh.org_id,
  reqh.REQUISITION_HEADER_ID,
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
         AND trunc(reqh.creation_date) BETWEEN p.effective_start_date
                                   AND p.effective_end_date
);

/

begin
  sys.dbms_rls.drop_policy     (
    object_schema          => 'APPS'
    ,object_name           => 'XX_PO_HEADERS_DW_V'
    ,policy_name           => 'XX_PO_HEADERS_DW_V_DB');
  exception
    when others then null;
end;

/


begin
  sys.dbms_rls.add_policy     (
    object_schema         => 'APPS',
    object_name           => 'XX_PO_HEADERS_DW_V',
    policy_name           => 'XX_PO_HEADERS_DW_V_DB',
    function_schema       => 'APPS',
    policy_function       => 'XX_FUN_INT_UTIL_PKG.SECURE_DATA_PER_DB_USER',
    statement_types       => 'SELECT',
    policy_type           => dbms_rls.dynamic,
    long_predicate        => false,
    update_check          => false,
    static_policy         => false,
    enable                => true );
  commit;
end;

/

begin
  sys.dbms_rls.drop_policy     (
    object_schema          => 'APPS'
    ,object_name           => 'XX_PO_LINES_DW_V'
    ,policy_name           => 'XX_PO_LINES_DW_V_DB');
  exception
    when others then null;
end;

/


begin
  sys.dbms_rls.add_policy     (
    object_schema         => 'APPS',
    object_name           => 'XX_PO_LINES_DW_V',
    policy_name           => 'XX_PO_LINES_DW_V_DB',
    function_schema       => 'APPS',
    policy_function       => 'XX_FUN_INT_UTIL_PKG.SECURE_DATA_PER_DB_USER',
    statement_types       => 'SELECT',
    policy_type           => dbms_rls.dynamic,
    long_predicate        => false,
    update_check          => false,
    static_policy         => false,
    enable                => true );
  commit;
end;

/

begin
  sys.dbms_rls.drop_policy     (
    object_schema          => 'APPS'
    ,object_name           => 'XX_PO_LINE_LOCATIONS_DW_V'
    ,policy_name           => 'XX_PO_LINE_LOCATIONS_DW_V_DB');
  exception
    when others then null;
end;

/


begin
  sys.dbms_rls.add_policy     (
    object_schema         => 'APPS',
    object_name           => 'XX_PO_LINE_LOCATIONS_DW_V',
    policy_name           => 'XX_PO_LINE_LOCATIONS_DW_V_DB',
    function_schema       => 'APPS',
    policy_function       => 'XX_FUN_INT_UTIL_PKG.SECURE_DATA_PER_DB_USER',
    statement_types       => 'SELECT',
    policy_type           => dbms_rls.dynamic,
    long_predicate        => false,
    update_check          => false,
    static_policy         => false,
    enable                => true );
  commit;
end;

/

begin
  sys.dbms_rls.drop_policy     (
    object_schema          => 'APPS'
    ,object_name           => 'XX_PO_DISTRIBUTIONS_DW_V'
    ,policy_name           => 'XX_PO_DISTRIBUTIONS_DW_V_DB');
  exception
    when others then null;
end;

/


begin
  sys.dbms_rls.add_policy     (
    object_schema         => 'APPS',
    object_name           => 'XX_PO_DISTRIBUTIONS_DW_V',
    policy_name           => 'XX_PO_DISTRIBUTIONS_DW_V_DB',
    function_schema       => 'APPS',
    policy_function       => 'XX_FUN_INT_UTIL_PKG.SECURE_DATA_PER_DB_USER',
    statement_types       => 'SELECT',
    policy_type           => dbms_rls.dynamic,
    long_predicate        => false,
    update_check          => false,
    static_policy         => false,
    enable                => true );
  commit;
end;

/

begin
  sys.dbms_rls.drop_policy     (
    object_schema          => 'APPS'
    ,object_name           => 'XX_PO_ACTIONS_DW_V'
    ,policy_name           => 'XX_PO_ACTIONS_DW_V_DB');
  exception
    when others then null;
end;

/


begin
  sys.dbms_rls.add_policy     (
    object_schema         => 'APPS',
    object_name           => 'XX_PO_ACTIONS_DW_V',
    policy_name           => 'XX_PO_ACTIONS_DW_V_DB',
    function_schema       => 'APPS',
    policy_function       => 'XX_FUN_INT_UTIL_PKG.SECURE_DATA_PER_DB_USER',
    statement_types       => 'SELECT',
    policy_type           => dbms_rls.dynamic,
    long_predicate        => false,
    update_check          => false,
    static_policy         => false,
    enable                => true );
  commit;
end;

/

begin
  sys.dbms_rls.drop_policy     (
    object_schema          => 'APPS'
    ,object_name           => 'XX_REQ_HEADERS_DW_V'
    ,policy_name           => 'XX_REQ_HEADERS_DW_V_DB');
  exception
    when others then null;
end;

/


begin
  sys.dbms_rls.add_policy     (
    object_schema         => 'APPS',
    object_name           => 'XX_REQ_HEADERS_DW_V',
    policy_name           => 'XX_REQ_HEADERS_DW_V_DB',
    function_schema       => 'APPS',
    policy_function       => 'XX_FUN_INT_UTIL_PKG.SECURE_DATA_PER_DB_USER',
    statement_types       => 'SELECT',
    policy_type           => dbms_rls.dynamic,
    long_predicate        => false,
    update_check          => false,
    static_policy         => false,
    enable                => true );
  commit;
end;

/

begin
  sys.dbms_rls.drop_policy     (
    object_schema          => 'APPS'
    ,object_name           => 'XX_REQ_LINES_DW_V'
    ,policy_name           => 'XX_REQ_LINES_DW_V_DB');
  exception
    when others then null;
end;

/


begin
  sys.dbms_rls.add_policy     (
    object_schema         => 'APPS',
    object_name           => 'XX_REQ_LINES_DW_V',
    policy_name           => 'XX_REQ_LINES_DW_V_DB',
    function_schema       => 'APPS',
    policy_function       => 'XX_FUN_INT_UTIL_PKG.SECURE_DATA_PER_DB_USER',
    statement_types       => 'SELECT',
    policy_type           => dbms_rls.dynamic,
    long_predicate        => false,
    update_check          => false,
    static_policy         => false,
    enable                => true );
  commit;
end;

/

begin
  sys.dbms_rls.drop_policy     (
    object_schema          => 'APPS'
    ,object_name           => 'XX_REQ_DISTRIBUTIONS_DW_V'
    ,policy_name           => 'XX_REQ_DISTRIBUTIONS_DW_V_DB');
  exception
    when others then null;
end;

/


begin
  sys.dbms_rls.add_policy     (
    object_schema         => 'APPS',
    object_name           => 'XX_REQ_DISTRIBUTIONS_DW_V',
    policy_name           => 'XX_REQ_DISTRIBUTIONS_DW_V_DB',
    function_schema       => 'APPS',
    policy_function       => 'XX_FUN_INT_UTIL_PKG.SECURE_DATA_PER_DB_USER',
    statement_types       => 'SELECT',
    policy_type           => dbms_rls.dynamic,
    long_predicate        => false,
    update_check          => false,
    static_policy         => false,
    enable                => true );
  commit;
end;

/

begin
  sys.dbms_rls.drop_policy     (
    object_schema          => 'APPS'
    ,object_name           => 'XX_REQ_ACTIONS_DW_V'
    ,policy_name           => 'XX_REQ_ACTIONS_DW_V_DB');
  exception
    when others then null;
end;

/


begin
  sys.dbms_rls.add_policy     (
    object_schema         => 'APPS',
    object_name           => 'XX_REQ_ACTIONS_DW_V',
    policy_name           => 'XX_REQ_ACTIONS_DW_V_DB',
    function_schema       => 'APPS',
    policy_function       => 'XX_FUN_INT_UTIL_PKG.SECURE_DATA_PER_DB_USER',
    statement_types       => 'SELECT',
    policy_type           => dbms_rls.dynamic,
    long_predicate        => false,
    update_check          => false,
    static_policy         => false,
    enable                => true );
  commit;
end;

/


CREATE OR REPLACE SYNONYM xxziqint.XX_PO_HEADERS_DW_V FOR apps.XX_PO_HEADERS_DW_V;

/

CREATE OR REPLACE SYNONYM xxziqint.XX_PO_LINES_DW_V FOR apps.XX_PO_LINES_DW_V;

/

CREATE OR REPLACE SYNONYM xxziqint.XX_PO_LINE_LOCATIONS_DW_V FOR apps.XX_PO_LINE_LOCATIONS_DW_V;

/

CREATE OR REPLACE SYNONYM xxziqint.XX_PO_DISTRIBUTIONS_DW_V FOR apps.XX_PO_DISTRIBUTIONS_DW_V;

/

CREATE OR REPLACE SYNONYM xxziqint.XX_PO_ACTIONS_DW_V FOR apps.XX_PO_ACTIONS_DW_V;

/

CREATE OR REPLACE SYNONYM xxziqint.XX_REQ_HEADERS_DW_V FOR apps.XX_REQ_HEADERS_DW_V;

/

CREATE OR REPLACE SYNONYM xxziqint.XX_REQ_LINES_DW_V FOR apps.XX_REQ_LINES_DW_V;

/

CREATE OR REPLACE SYNONYM xxziqint.XX_REQ_DISTRIBUTIONS_DW_V FOR apps.XX_REQ_DISTRIBUTIONS_DW_V;

/

CREATE OR REPLACE SYNONYM xxziqint.XX_REQ_ACTIONS_DW_V FOR apps.XX_REQ_ACTIONS_DW_V;

/


CREATE OR REPLACE SYNONYM rac_accnt.XX_PO_HEADERS_DW_V FOR apps.XX_PO_HEADERS_DW_V;

/

CREATE OR REPLACE SYNONYM rac_accnt.XX_PO_LINES_DW_V FOR apps.XX_PO_LINES_DW_V;

/

CREATE OR REPLACE SYNONYM rac_accnt.XX_PO_LINE_LOCATIONS_DW_V FOR apps.XX_PO_LINE_LOCATIONS_DW_V;

/

CREATE OR REPLACE SYNONYM rac_accnt.XX_PO_DISTRIBUTIONS_DW_V FOR apps.XX_PO_DISTRIBUTIONS_DW_V;

/

CREATE OR REPLACE SYNONYM rac_accnt.XX_PO_ACTIONS_DW_V FOR apps.XX_PO_ACTIONS_DW_V;

/

CREATE OR REPLACE SYNONYM rac_accnt.XX_REQ_HEADERS_DW_V FOR apps.XX_REQ_HEADERS_DW_V;

/

CREATE OR REPLACE SYNONYM rac_accnt.XX_REQ_LINES_DW_V FOR apps.XX_REQ_LINES_DW_V;

/

CREATE OR REPLACE SYNONYM rac_accnt.XX_REQ_DISTRIBUTIONS_DW_V FOR apps.XX_REQ_DISTRIBUTIONS_DW_V;

/

CREATE OR REPLACE SYNONYM rac_accnt.XX_REQ_ACTIONS_DW_V FOR apps.XX_REQ_ACTIONS_DW_V;

/

GRANT SELECT ON XX_PO_HEADERS_DW_V TO XXZIQINT,RAC_ACCNT;

/

GRANT SELECT ON XX_PO_LINES_DW_V TO XXZIQINT,RAC_ACCNT;

/

GRANT SELECT ON XX_PO_LINE_LOCATIONS_DW_V TO XXZIQINT,RAC_ACCNT;

/

GRANT SELECT ON XX_PO_DISTRIBUTIONS_DW_V TO XXZIQINT,RAC_ACCNT;

/

GRANT SELECT ON XX_PO_ACTIONS_DW_V TO XXZIQINT,RAC_ACCNT;

/

GRANT SELECT ON XX_REQ_HEADERS_DW_V TO XXZIQINT,RAC_ACCNT;

/

GRANT SELECT ON XX_REQ_LINES_DW_V TO XXZIQINT,RAC_ACCNT;

/

GRANT SELECT ON XX_REQ_DISTRIBUTIONS_DW_V TO XXZIQINT,RAC_ACCNT;

/

GRANT SELECT ON XX_REQ_ACTIONS_DW_V TO XXZIQINT,RAC_ACCNT;

/
