CREATE OR REPLACE PACKAGE BODY XX_INV_ADI_PKG
as
  /* $Header: XX_INV_ADI_PKG.pkb 18.11.08 2018/11/08 00:00:00 kazem ship $ */
  
  vSameSession   boolean default false;
  vValAccessErr varchar2(4000);

  procedure submit_rvctp(
    p_group_id number,
    p_org_id   number)
  is
    lRequestId        number;
  begin
    lRequestId := fnd_request.submit_request(
      application => 'PO',
      program     => 'RVCTP',
      description => null,
      start_time  => null,
      sub_request => false,
      argument1   => 'BATCH',
      argument2   => p_group_id,
      argument3   => null);
  exception
    when others then
      null; 
  end;
  
  function validate_access(
    p_organization_id     number,
    p_organization_code   varchar2,
    p_subinventory_code   varchar2)
  return varchar2
  is
    validation_error exception ;
    cursor oa is
      select 1
      from
        org_access
      where organization_id   = p_organization_id
        and responsibility_id   = fnd_global.resp_id
        and resp_application_id = fnd_global.resp_appl_id;
    lDummy number;
    lOrgCode mtl_parameters.organization_code%type;
  begin
    if vSameSession then
      return(vValAccessErr);
    end if;
    
    
    lOrgCode := p_organization_code;
    if lOrgCode is null then
      select organization_code
      into lOrgCode
      from mtl_parameters
      where organization_id = p_organization_id;
    end if;
    
    select count(1)
    into lDummy
    from
      org_access
    where organization_id     = p_organization_id;
    
    if lDummy > 0 then
      select count(1)
      into lDummy
      from
        org_access
      where organization_id     = p_organization_id
        and responsibility_id   = fnd_global.resp_id
        and resp_application_id = fnd_global.resp_appl_id;
      if lDummy = 0 then
        vValAccessErr := 'No Access to Org:'||lOrgCode;
        raise validation_error;
      end if;
     
      select count(1)
      into lDummy
      from
        xxzn_subinv_access
      where organization_id     = p_organization_id
        and sub_inventory_name  = p_subinventory_code;
      if lDummy > 0 then
        select count(1)
        into lDummy
        from
          xxzn_subinv_access
        where organization_id     = p_organization_id
          and sub_inventory_name  = p_subinventory_code
          and responsibility_id   = fnd_global.resp_id
          and resp_application_id = fnd_global.resp_appl_id;
        if lDummy = 0 then
          vValAccessErr := 'No Access to Org:'||lOrgCode||' Subinventory:'||p_subinventory_code;
          raise validation_error;
        end if;
      end if;
    end if;
    
    vValAccessErr := null;
    return(vValAccessErr);
  exception
    when validation_error then
      return(vValAccessErr);
  end; 
    

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
  return varchar2
  is
    validation_error   exception ;
    lError             varchar2(4000);
    lGroupID           number;
    lTrxDate           date;
    lSerialCount       number;
    cursor shp is
      select
        hdr.ship_num,
        grp.ship_line_group_num,
        lin.ship_line_id lcm_shipment_line_id,
        lin.primary_qty,
        lin.primary_uom_code,
        itm.segment1 item_segment1,
        pll.line_location_id,
        pll.po_header_id,
        pll.po_line_id,  
        pol.item_id,
        pol.line_num po_line_num,
        poh.segment1 po_number,
        pod.destination_type_code, -- destination_type_code,
        pod.deliver_to_person_id,
        par.organization_id,
        par.organization_code, 
        sln.shipment_header_id,
        sln.shipment_line_id
      from
        inl_ship_headers_all  hdr,
        inl_ship_lines_all    lin,
        inl_ship_line_groups  grp,
        mtl_system_items_b    itm,
        po_line_locations_all pll,
        po_lines_all          pol,
        po_headers_all        poh,
        po_distributions_all  pod,
        mtl_parameters        par,
        rcv_shipment_lines    sln
      where hdr.ship_header_id          = lin.ship_header_id 
        and lin.ship_line_group_id      = grp.ship_line_group_id
        and lin.ship_to_organization_id = itm.organization_id
        and lin.inventory_item_id       = itm.inventory_item_id
        and lin.ship_line_source_id     = pll.line_location_id
        and pll.po_line_id              = pol.po_line_id 
        and pol.po_header_id            = poh.po_header_id 
        and pll.po_line_id              = pod.po_line_Id
        and pll.line_location_id        = pod.line_location_id
        and pll.ship_to_organization_id = par.organization_id
        and lin.ship_line_id            = sln.lcm_shipment_line_id
        and lin.ship_line_src_type_code = 'PO'
        and hdr.ship_num                = p_lcm_ship_num
        and lin.org_id                  = p_org_id
        and pol.line_num                = p_po_line_num;
    cursor hdr(x_shipment_num varchar2) is
      select 
        header_interface_id,
        group_id
      from rcv_headers_interface
      where asn_type = 'LCM'
        --and processing_status_code = 'SUCCESS'
        and receipt_source_code = 'VENDOR'
        and shipment_num        = x_shipment_num;
  begin
    savepoint adi_po_lcm_receipt_sp1;
    
    if trunc(p_transaction_date) = trunc(sysdate) then
      lTrxDate := sysdate;
    else
      lTrxDate := p_transaction_date;
    end if;
    
    begin
      select 
        group_id
      into 
        lGroupID
      from
        rcv_transactions_interface
      where interface_transaction_id = p_interface_trx_id;
    exception
      when no_data_found then
        null;
    end;
    if lGroupID is null then
      for s in shp loop
        lError := validate_access(
          p_organization_id     => s.organization_id,
          p_organization_code   => s.organization_code,
          p_subinventory_code   => p_subinventory_code);
        if lError is not null then
          raise validation_error;
        end if;
        if s.item_segment1 != p_item_segment1 then
          lError := 'Item code "'||p_item_segment1||'" is not valid for PO Line#'||p_po_line_num;
          raise validation_error;
        elsif s.primary_qty != p_quantity then
          lError := 'LCM Shipment quantity is '||s.primary_qty||' not '||p_quantity;
          raise validation_error;
        end if;
        for h in hdr(s.ship_num||'.'||s.ship_line_group_num) loop
          lGroupID := h.group_id;
          insert into rcv_transactions_interface( 
            interface_transaction_id,
            header_interface_id,
            group_id,
            last_update_date,
            last_updated_by,
            last_update_login,
            creation_date,
            created_by,
            transaction_type,
            transaction_date,
            processing_status_code,
            processing_mode_code,
            transaction_status_code,
            po_header_id,
            po_line_id,
            item_id,
            quantity,
            uom_code,
            po_line_location_id,
            auto_transact_code,
            receipt_source_code,
            to_organization_code,
            source_document_code,
            document_num,
            destination_type_code,
            deliver_to_person_id,
            deliver_to_location_id,
            locator,
            subinventory,
            validation_flag,
            comments,
            parent_transaction_id,
            lcm_shipment_line_id,
            shipment_header_id,
            shipment_line_id)
          values( 
            p_interface_trx_id , -- interface_transaction_id,
            null, -- header_interface_id,
            h.group_id, -- group_id,
            sysdate,                          -- last_update_date,
            fnd_global.user_id,                       -- last_updated_by,
             0         ,                      -- last_update_login,
            sysdate,                          -- creation_date,
            fnd_global.user_id,                       -- created_by,
            p_transaction_type, -- transaction_type,
            lTrxDate  , -- transaction_date,
            'PENDING', -- processing_status_code,
            'BATCH', -- processing_mode_code,
            'PENDING', -- transaction_status_code,
            s.po_header_id, -- po_header_id,
            s.po_line_id,   -- po_line_id,
            s.item_id, -- item_id,
            abs(p_quantity), -- quantity,  -- for CORRECT, it can be negative which is not handled today
            s.primary_uom_code, -- uom_code,
            s.line_location_id, -- po_line_location_id,
            'DELIVER', -- auto_transact_code,
            'VENDOR', -- receipt_source_code,
            s.organization_code, -- to_organization_code,
            'PO', -- source_document_code,
            s.po_number, -- document_num,
            s.destination_type_code, -- destination_type_code,
            s.deliver_to_person_id, -- deliver_to_person_id,
            null, -- deliver_to_location_id,
            upper(p_loc_segment1), -- locator,
            p_subinventory_code, -- subinventory,
            'Y', -- validation_flag,
            p_comments,  -- comments
            null,--s.parent_transaction_id);
            s.lcm_shipment_line_id, -- lcm_shipment_line_id,
            s.shipment_header_id,
            s.shipment_line_id);
        end loop;
      end loop;
      if lGroupID is null then
        lError := 'Unable to find LCM Shipment:'||p_lcm_ship_num||' for PO Line:'||p_po_line_num;
        raise validation_error;
      end if;
    end if;
    
    insert into mtl_serial_numbers_interface(
      transaction_interface_id,
      last_update_date,
      last_updated_by,
      creation_date,
      created_by,
      last_update_login,
      fm_serial_number,
      to_serial_number,
      product_code,
      product_transaction_id)
     values(
      mtl_material_transactions_s.nextval,
      sysdate,
      fnd_global.user_id,
      sysdate,
      fnd_global.user_id,
      1,
      p_fm_serial_number,
      p_to_serial_number,
      'RCV',
      p_interface_trx_id);
      
    vSameSession := true;
      
    select count(*)
    into lSerialCount 
    from mtl_serial_numbers_interface
    where product_transaction_id = p_interface_trx_id;
    if lSerialCount = p_quantity then
      vSameSession := false;
      submit_rvctp(
        p_group_id => lGroupID,
        p_org_id   => p_org_id);
    end if;
    
    return(null);
  exception
    when validation_error then
      rollback to adi_po_lcm_receipt_sp1;
      return(lError);
    when others then
      lError := dbms_utility.format_error_stack||dbms_utility.format_error_backtrace;
      rollback to adi_po_lcm_receipt_sp1;
      return(lError); 
  end;

  function po_receipt(
    p_header_interface_id     number,
    p_group_id                number,
    p_transaction_type        varchar2,  -- 'RECEIVE' and 'RETURN TO VENDOR'
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
  return varchar2
  is
    validation_error exception ;
    lError       varchar2(4000);
    lIntTrxID    number;
    lTrxDate     date;
    lSerialCount number;
    cursor po is
      select
        po_header_id,
        vendor_id,
        vendor_site_id,
        segment1 po_number
      from
        po_headers_all
      where segment1 = p_po_num
        and org_id   = p_org_id;
  cursor vendor_shipment(x_po_header_id number) is
    select distinct
      pol.po_header_id, -- po_header_id,
      pol.po_line_id,   -- po_line_id,
      pol.line_num,
      pol.item_id, -- item_id,
      itm.segment1 item_segment1,
      pol.unit_meas_lookup_code, -- unit_of_measure,
      pll.line_location_id, -- po_line_location_id,
      pod.destination_type_code, -- destination_type_code,
      pod.deliver_to_person_id,
      par.organization_id,
      par.organization_code,
      pod.destination_subinventory,
      (
        select trx.transaction_id
        from
          rcv_shipment_headers hdr,
          rcv_shipment_lines   lin,
          rcv_transactions     trx
        where 1=1
          and hdr.shipment_header_id = lin.shipment_header_id
          and lin.shipment_header_id = trx.shipment_header_id
          and lin.shipment_line_id   = trx.shipment_line_id
          and hdr.ship_to_org_id     = pll.ship_to_organization_id
          and lin.item_id            = pol.item_id
          and trx.transaction_type   = 'DELIVER'
          and hdr.receipt_num        = p_receipt_num
          and p_transaction_type     = 'RETURN TO VENDOR'
      ) parent_transaction_id
    from
      po_lines_all          pol,
      po_line_locations_all pll,
      po_distributions_all  pod,
      mtl_parameters        par,
      mtl_system_items_b    itm
    where 1=1
      and pol.po_line_id       = pll.po_line_id
      and pll.po_line_id       = pod.po_line_Id
      and pll.line_location_id = pod.line_location_id
      and pll.ship_to_organization_id = par.organization_id
      and pol.item_id          = itm.inventory_item_id
      and pll.ship_to_organization_id = itm.organization_id
      and pol.po_header_id     = x_po_header_id
      and pol.line_num         = p_line_num
      and pll.shipment_num     = p_shipment_num;
  begin
    savepoint adi_po_receipt_sp1;
    
    if p_transaction_type = 'RETURN TO VENDOR' and p_receipt_num is null then
      lError := 'Receipt Number is missing for Return to Vendor transaction type';
      raise validation_error;
    end if;
    if trunc(p_transaction_date) = trunc(sysdate) then
      lTrxDate := sysdate;
    else
      lTrxDate := p_transaction_date;
    end if;
    
    for i in po loop
      begin
        insert into rcv_headers_interface(
          header_interface_id,
          group_id,
          processing_status_code,
          receipt_source_code,
          transaction_type,
          last_update_date,
          last_updated_by,
          last_update_login,
          creation_date,
          created_by,
          vendor_id,
          expected_receipt_date,
          validation_flag,
          comments)
        values(
          p_header_interface_id,  -- header_interface_id,
          p_group_id,   -- group_id,
          'PENDING',                        -- processing_status_code,
          'VENDOR',                         -- receipt_source_code,
          'NEW',                            -- transaction_type,
          sysdate,                          -- last_update_date,
          fnd_global.user_id,               -- last_updated_by,
           0         ,                      -- last_update_login,
          sysdate,                          -- creation_date,
          fnd_global.user_id,               -- created_by,
          i.vendor_id,                      -- vendor_id,
          sysdate    ,                      -- expected_receipt_date,
          'Y'        ,                      -- validation_flag,
          p_comments );                      -- comments)
          
        for s in vendor_shipment(i.po_header_id) loop
          lError := validate_access(
            p_organization_id     => s.organization_id,
            p_organization_code   => s.organization_code,
            p_subinventory_code   => p_subinventory_code);
          if lError is not null then
            raise validation_error;
          end if;
          if s.item_segment1 != p_item_segment1 then
            lError := 'Item code "'||p_item_segment1||'" is not valid for PO Line#'||p_line_num;
            raise validation_error;
          end if;
          if p_transaction_type = 'RETURN TO VENDOR' and s.parent_transaction_id is null then
            lError := 'Invalid Receipt Number';
            raise validation_error;
          end if;
          insert into rcv_transactions_interface( 
            interface_transaction_id,
            header_interface_id,
            group_id,
            last_update_date,
            last_updated_by,
            last_update_login,
            creation_date,
            created_by,
            transaction_type,
            transaction_date,
            processing_status_code,
            processing_mode_code,
            transaction_status_code,
            po_header_id,
            po_line_id,
            item_id,
            quantity,
            unit_of_measure,
            po_line_location_id,
            auto_transact_code,
            receipt_source_code,
            to_organization_code,
            source_document_code,
            document_num,
            destination_type_code,
            deliver_to_person_id,
            deliver_to_location_id,
            locator,
            subinventory,
            validation_flag,
            comments,
            parent_transaction_id)
          values( 
            rcv_transactions_interface_s.nextval , -- interface_transaction_id,
            p_header_interface_id, -- header_interface_id,
            p_group_id, -- group_id,
            sysdate,                          -- last_update_date,
            fnd_global.user_id,                       -- last_updated_by,
             0         ,                      -- last_update_login,
            sysdate,                          -- creation_date,
            fnd_global.user_id,                       -- created_by,
            p_transaction_type, -- transaction_type,
            lTrxDate  , -- transaction_date,
            'PENDING', -- processing_status_code,
            'BATCH', -- processing_mode_code,
            'PENDING', -- transaction_status_code,
            s.po_header_id, -- po_header_id,
            s.po_line_id,   -- po_line_id,
            s.item_id, -- item_id,
            abs(p_quantity), -- quantity,  -- for CORRECT, it can be negative which is not handled today
            s.unit_meas_lookup_code, -- unit_of_measure,
            s.line_location_id, -- po_line_location_id,
            'DELIVER', -- auto_transact_code,
            'VENDOR', -- receipt_source_code,
            s.organization_code, -- to_organization_code,
            'PO', -- source_document_code,
            i.po_number, -- document_num,
            s.destination_type_code, -- destination_type_code,
            s.deliver_to_person_id, -- deliver_to_person_id,
            null, -- deliver_to_location_id,
            upper(p_loc_segment1), -- locator,
            p_subinventory_code, -- subinventory,
            'Y', -- validation_flag,
            p_comments,  -- comments
            s.parent_transaction_id)
          returning interface_transaction_id into lIntTrxID;
        end loop;
      exception 
        when dup_val_on_index then
          select
            interface_transaction_id
          into
            lIntTrxID
          from
            rcv_transactions_interface
          where header_interface_id = p_header_interface_id;
      end;
      if lIntTrxID is not null then
        insert into mtl_serial_numbers_interface(
          transaction_interface_id,
          last_update_date,
          last_updated_by,
          creation_date,
          created_by,
          last_update_login,
          fm_serial_number,
          to_serial_number,
          product_code,
          product_transaction_id)
         values(
          mtl_material_transactions_s.nextval,
          sysdate,
          fnd_global.user_id,
          sysdate,
          fnd_global.user_id,
          1,
          p_fm_serial_number,
          p_to_serial_number,
          'RCV',
          lIntTrxID);
          
        vSameSession := true;
        
        select count(*)
        into lSerialCount 
        from mtl_serial_numbers_interface
        where product_transaction_id = lIntTrxID;
        if lSerialCount = p_quantity then
          vSameSession := false;
          submit_rvctp(
            p_group_id => p_group_id,
            p_org_id   => p_org_id);
        end if;
        
      end if;
    end loop;
    
    return(null);
  exception
    when validation_error then
      rollback to adi_po_receipt_sp1;
      return(lError);
    when others then
      lError := dbms_utility.format_error_stack||dbms_utility.format_error_backtrace;
      rollback to adi_po_receipt_sp1;
      return(lError); 
  end;

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
  return varchar2
  is
    validation_error exception ;
    lError       varchar2(4000);
    lTrxDate     date;
    lSerialCount number;
  begin
    savepoint adi_subinv_xfer_sp1;

    if trunc(p_transaction_date) = trunc(sysdate) then
      lTrxDate := sysdate;
    else
      lTrxDate := p_transaction_date;
    end if;
        
    lError := validate_access(
      p_organization_id     => p_organization_id,
      p_organization_code   => null,
      p_subinventory_code   => p_subinventory_code);
    if lError is not null then
      raise validation_error;
    end if;
      
    lError := validate_access(
      p_organization_id     => p_organization_id,
      p_organization_code   => null,
      p_subinventory_code   => p_transfer_subinventory);
    if lError is not null then
      raise validation_error;
    end if;
    
    begin
      insert into mtl_transactions_interface(
        transaction_interface_id,
        transaction_header_id,
        source_code,
        source_line_id,
        source_header_id,
        process_flag,
        transaction_mode,
        transaction_type_id,
        transaction_date,
        organization_id,
        item_segment1,
        transaction_uom,
        transaction_quantity,
        subinventory_code,
        loc_segment1,
        transfer_subinventory,
        xfer_loc_segment1,
        transaction_reference,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        last_update_login)
      values(
        p_transaction_interface_id,  -- transaction_interface_id
        p_transaction_interface_id,  -- transaction_header_id,
        'Inventory',                 -- source_code,
        p_transaction_interface_id,  -- source_line_id,
        p_transaction_interface_id,  -- source_header_id,
        1,                           -- process_flag,
        3,                           -- transaction_mode,
        2,                           -- transaction_type_id, Subinventory Transfer
        lTrxDate,                    -- transaction_date,
        p_organization_id,           -- organization_id,
        p_item_segment1,             -- item_segment1,
        p_transaction_uom,           -- transaction_uom,
        p_quantity,                  -- transaction_quantity,
        p_subinventory_code,         -- subinventory_code,
        upper(p_loc_segment1),       -- loc_segment1,
        p_transfer_subinventory,     -- transfer_subinventory,
        upper(p_xfer_loc_segment1),  -- xfer_loc_segment1,
        p_transaction_reference,     -- transaction_reference,
        fnd_global.user_id,          -- created_by,
        sysdate,                     -- creation_date,
        fnd_global.user_id,          -- last_updated_by,
        sysdate,                     -- last_update_date,
        fnd_global.login_id);        -- last_update_login);
    exception 
      when dup_val_on_index then
        null;
    end;
    insert into mtl_serial_numbers_interface(
      transaction_interface_id,
      fm_serial_number,
      to_serial_number,
      last_update_date,
      last_updated_by,
      creation_date,
      created_by,
      source_code,
      source_line_id)
    values (
      p_transaction_interface_id,
      p_fm_serial_number,
      p_to_serial_number,
      sysdate,
      fnd_global.user_id,
      sysdate,
      fnd_global.user_id,
      'Inventory',
      p_transaction_interface_id);
      
    vSameSession := true;
      
    select count(*)
    into lSerialCount 
    from mtl_serial_numbers_interface
    where transaction_interface_id = p_transaction_interface_id;
    if lSerialCount = p_quantity then
      vSameSession := false;
    end if;
    
    return(null);
  exception
    when validation_error then
      rollback to adi_subinv_xfer_sp1;
      return(lError);
    when others then
      lError := dbms_utility.format_error_stack||dbms_utility.format_error_backtrace;
      rollback to adi_subinv_xfer_sp1;
      return(lError); 
  end;
  
    

end;
/

