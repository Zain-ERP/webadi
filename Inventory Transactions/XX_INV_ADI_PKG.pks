CREATE OR REPLACE PACKAGE XX_INV_ADI_PKG
as
  /* $Header: XX_INV_ADI_PKG.pks 18.11.08 2018/11/08 00:00:00 kazem ship $ */

  function po_lcm_receipt(
    p_interface_trx_id        number,
    p_transaction_type        varchar2,  -- RECEIVE and RETURN TO VENDOR
    p_transaction_date        date, 
    p_org_id                  number,
    p_lcm_ship_num            varchar2,
    p_po_line_num             number,
    p_subinventory_code       varchar2, 
    p_loc_segment1            varchar2,
    p_item_segment1           varchar2,
    p_quantity                number,
    p_comments                varchar2 default null,
    p_fm_serial_number        varchar2,
    p_to_serial_number        varchar2)
  return varchar2;

  function po_receipt(
    p_header_interface_id     number,
    p_group_id                number,
    p_transaction_type        varchar2,  -- RECEIVE and RETURN TO VENDOR
    p_transaction_date        date, 
    p_org_id                  number,
    p_po_num                  varchar2,
    p_line_num                number,
    p_shipment_num            number,
    p_subinventory_code       varchar2, 
    p_loc_segment1            varchar2,
    p_item_segment1           varchar2,
    p_quantity                number,
    p_receipt_num             varchar2 default null,
    p_comments                varchar2 default null,
    p_fm_serial_number        varchar2,
    p_to_serial_number        varchar2)
  return varchar2;

  function subinventory_transfer(
    p_transaction_interface_id number,
    p_transaction_date         date, 
    p_organization_id          number,
    p_item_segment1            varchar2,
    p_subinventory_code        varchar2, 
    p_loc_segment1             varchar2,
    p_transfer_subinventory    varchar2, 
    p_xfer_loc_segment1        varchar2,
    p_transaction_uom          varchar2,
    p_quantity                 number,
    p_transaction_reference    varchar2 default null,
    p_fm_serial_number         varchar2,
    p_to_serial_number         varchar2)
  return varchar2;
    

end;
/

