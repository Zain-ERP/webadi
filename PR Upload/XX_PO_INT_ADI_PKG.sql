  CREATE OR REPLACE PACKAGE APPS.XX_PO_INT_ADI_PKG 
is

  /* $Header: XX_PO_INT_ADI_PKG.sql 20.09.14 2020/09/14 00:00:00 kazem ship $ */

  function import_pr_line(
    p_org_id                      number,
    p_batch_id                    number,
    p_interface_source_code       varchar2,
    p_source_type_code            varchar2,
    p_currency_code               varchar2,
    p_rate_type                   varchar2,
    p_rate_date                   date,
    p_rate                        number,
    --p_interface_source_line_id    number,
    p_line_num                    number,
    p_item_code                   varchar2,
    p_unit_of_measure             varchar2,
    p_currency_unit_price         number,
    p_requestor_number            varchar2,
    p_destination_organization_id number,
    p_deliver_to_location_id      number,
    p_need_by_date                date,
    p_suggested_vendor_num        varchar2,
    p_suggested_vendor_site_code  varchar2,
    p_note_to_buyer               varchar2,
    p_line_attribute_category     varchar2,
    p_line_attribute1             varchar2,
    p_line_attribute2             varchar2,
    p_line_attribute3             varchar2,
    p_line_attribute4             varchar2,
    p_line_attribute5             varchar2,
    p_line_attribute6             varchar2,
    p_line_attribute7             varchar2,
    p_line_attribute8             varchar2,
    p_line_attribute9             varchar2,
    p_line_attribute10            varchar2,
    p_line_attribute11            varchar2,
    p_line_attribute12            varchar2,
    p_line_attribute13            varchar2,
    p_line_attribute14            varchar2,
    p_line_attribute15            varchar2,
    p_allocation_type             varchar2,
    p_allocation_value            number,
    p_charge_account_id           number,
    p_dist_quantity               number,
    p_expenditure_type            varchar2,
    p_expenditure_item_date       date,
    p_gl_date                     date,
    p_project_num                 varchar2,
    p_task_num                    varchar2,
    p_distribution_attribute10    varchar2)
  return varchar2;


end;

/

CREATE OR REPLACE PACKAGE BODY APPS.XX_PO_INT_ADI_PKG 
is

  function import_pr_line (
    p_org_id                      number,
    p_batch_id                    number,
    p_interface_source_code       varchar2,
    p_source_type_code            varchar2,
    p_currency_code               varchar2,
    p_rate_type                   varchar2,
    p_rate_date                   date,
    p_rate                        number,
    --p_interface_source_line_id    number,
    p_line_num                    number,
    p_item_code                   varchar2,
    p_unit_of_measure             varchar2,
    p_currency_unit_price         number,
    p_requestor_number            varchar2,
    p_destination_organization_id number,
    p_deliver_to_location_id      number,
    p_need_by_date                date,
    p_suggested_vendor_num        varchar2,
    p_suggested_vendor_site_code  varchar2,
    p_note_to_buyer               varchar2,
    p_line_attribute_category     varchar2,
    p_line_attribute1             varchar2,
    p_line_attribute2             varchar2,
    p_line_attribute3             varchar2,
    p_line_attribute4             varchar2,
    p_line_attribute5             varchar2,
    p_line_attribute6             varchar2,
    p_line_attribute7             varchar2,
    p_line_attribute8             varchar2,
    p_line_attribute9             varchar2,
    p_line_attribute10            varchar2,
    p_line_attribute11            varchar2,
    p_line_attribute12            varchar2,
    p_line_attribute13            varchar2,
    p_line_attribute14            varchar2,
    p_line_attribute15            varchar2,
    p_allocation_type             varchar2,
    p_allocation_value            number,
    p_charge_account_id           number,
    p_dist_quantity               number,
    p_expenditure_type            varchar2,
    p_expenditure_item_date       date,
    p_gl_date                     date,
    p_project_num                 varchar2,
    p_task_num                    varchar2,
    p_distribution_attribute10    varchar2)
  return varchar2
  is
    lError       varchar2 (32676);
    lLine        po_requisitions_interface_all%rowtype;
    lDist        po_req_dist_interface_all%rowtype;
    lCapex       boolean;
    lfunc_curr   varchar2 (15);
    lRequestId   number; -- 200908 KS

    cursor lk (x_lookup_type varchar2, x_lookup_code varchar2) is
    select tag
    from fnd_lookup_values
    where lookup_type = x_lookup_type
      and lookup_code = x_lookup_code;

    cursor itm (
       x_organization_id    number,
       x_item_code          varchar2)is
    select
      inventory_item_id,
      item_type,
      (
        select cat.category_id
        from mtl_item_categories_v cat
        where     cat.inventory_item_id = mtl.inventory_item_id
          and cat.organization_id = mtl.organization_id
          and cat.structure_id = 201) category_id                        -- Purchasing Categories
    from mtl_system_items_kfv mtl
    where organization_id       = x_organization_id
      and concatenated_segments = x_item_code;

    cursor par (x_organization_id number) is
    select ap_accrual_account
    from mtl_parameters
    where organization_id = x_organization_id;

    cursor req (x_org_id number,x_employee_number    varchar2)
    is
      select person_id, current_employee_flag
      from
        per_all_people_f   per,
        hr_operating_units org
      where 1 = 1
        and per.business_group_id = org.business_group_id
        and per.employee_number = x_employee_number
        and trunc (sysdate) between per.effective_start_date and per.effective_end_date
        and org.organization_id = x_org_id;

    cursor vnd is
      select
        sup.vendor_id,
        sit.vendor_site_id
      from
        ap_suppliers          sup,
        ap_supplier_sites_all sit
      where sup.vendor_id           = sit.vendor_id(+)
        and sup.segment1            = p_suggested_vendor_num
        and sit.vendor_site_code(+) = p_suggested_vendor_site_code
        and sit.org_id(+)           = p_org_id;

      procedure append_error (x_message varchar2)
      is
      begin
         if lError is not null
         then
            lError := lError || CHR (10);
         end if;
         lError := lError || x_message;
      end;
  begin
    savepoint xx_po_int_adi_imp_pr_lin_sp1;

    begin
      select *
      into lLine
      from po_requisitions_interface_all
      where org_id   = p_org_id
        and batch_id = p_batch_id
        and line_num = p_line_num;
      --                and interface_source_line_id = p_interface_source_line_id;
    exception
       when no_data_found then
         null;
    end;

    -- new line
    if lLine.batch_id is null then
      lLine.batch_id := p_batch_id;
      lLine.group_code := TO_CHAR (p_batch_id);
      lLine.interface_source_code := p_interface_source_code;
      lLine.interface_source_line_id :=
        to_number (p_batch_id || '00' || p_line_num);
      lLine.line_num := p_line_num;
      lLine.source_type_code := p_source_type_code;

      for i in lk ('XX_PR_UPLOAD_DEST_TYPE', lLine.interface_source_code) loop
        lLine.destination_type_code := i.tag;
      end loop;

      if lLine.destination_type_code is null then
        append_error ('Unable to retrieve DESTinATION_TYPE_CODE from inTERFACE_SOURCE_CODE = "'|| lLine.interface_source_code|| '"');
      end if;

      lLine.quantity             := 0;          --  will be updated based on p_quantity
      --lLine.unit_price                  := p_unit_price                ;
      lLine.authorization_status := 'INCOMPLETE';
      lLine.preparer_id          := fnd_global.employee_id;
      lLine.created_by           := fnd_global.employee_id;
      lLine.creation_date        := sysdate;
      lLine.last_updated_by      := fnd_global.employee_id;
      lLine.last_update_date     := sysdate;
      lCapex                     := false;

      for i in itm (p_destination_organization_id, p_item_code) loop
        lLine.item_id := i.inventory_item_id;
        lLine.category_id := i.category_id;

        if i.item_type = 'CAPEX ITEM' then
          lCapex := true;
        end if;
      end loop;

      if lLine.item_id is null then
        append_error ('Unable to retrieve inventory item "' || p_item_code || '"');
      elsif lline.category_id is null then
        append_error ('Unable to retrieve "Purchasing Categories" from inventory item "'|| p_item_code|| '"');
      end if;

      for i in par (p_destination_organization_id)
      loop
        lLine.accrual_account_id := i.ap_accrual_account;
      end loop;

      if lLine.accrual_account_id is null then
        append_error ('Unable to retrieve AP Accrual Account from destination organization');
      end if;

      lLine.unit_of_measure             := p_unit_of_measure;
      lLine.destination_organization_id := p_destination_organization_id;

      for i in req (p_org_id, p_requestor_number) loop
        if i.current_employee_flag = 'Y'  then
          lLine.deliver_to_requestor_id := i.person_id;
        else
          append_error('Employee "' || p_requestor_number || '" is not active');
        end if;
      end loop;

      if lLine.deliver_to_requestor_id is null
      then
        append_error ('Invalid Employee Number "' || p_item_code || '"');
      end if;

      lLine.deliver_to_location_id := p_deliver_to_location_id;
      lLine.need_by_date := p_need_by_date;
      lLine.currency_code := p_currency_code;

      if lCapex then
        lLine.project_accounting_context := 'Y';
      else
        lLine.project_accounting_context := 'N';
      end if;

      begin
        select
          gl.currency_code
        into
          lfunc_curr
        from
          gl_ledgers         gl,
          hr_operating_units ou
        where gl.ledger_id = ou.set_of_books_id
          and ou.organization_id = p_org_id;

        if lfunc_curr = p_currency_code then
          lLine.unit_price := p_currency_unit_price;
        else
          lLine.currency_unit_price := p_currency_unit_price;
        end if;
      exception
         when no_data_found then
            append_error ('Unable to retrieve Local Currency Code from Profile: '|| fnd_profile.VALUE ('GL_SET_OF_BKS_ID'));
      end;

      lLine.rate                := p_rate;
      lLine.rate_date           := p_rate_date;
      lLine.rate_type           := p_rate_type;
      lLine.org_id              := p_org_id;
      lLine.multi_distributions := 'Y';

      select po_requisitions_interface_s.nextval
      into lline.req_dist_sequence_id
      from dual;

      lLine.line_attribute_category := p_line_attribute_category;
      lLine.line_attribute1         := p_line_attribute1;
      lLine.line_attribute2         := p_line_attribute2;
      lLine.line_attribute3         := p_line_attribute3;
      lLine.line_attribute4         := p_line_attribute4;
      lLine.line_attribute5         := p_line_attribute5;
      lLine.line_attribute6         := p_line_attribute6;
      lLine.line_attribute7         := p_line_attribute7;
      lLine.line_attribute8         := p_line_attribute8;
      lLine.line_attribute9         := p_line_attribute9;
      lLine.line_attribute10        := p_line_attribute10;
      lLine.line_attribute11        := p_line_attribute11;
      lLine.line_attribute12        := p_line_attribute12;
      lLine.line_attribute13        := p_line_attribute13;
      lLine.line_attribute14        := p_line_attribute14;
      lLine.line_attribute15        := p_line_attribute15;

      if p_suggested_vendor_num is not null then
        for i in vnd loop
           lLine.suggested_vendor_id := i.vendor_id;
           lLine.suggested_vendor_site_id := i.vendor_site_id;
        end loop;

        if lLine.suggested_vendor_id is null and p_suggested_vendor_num is not null then
           append_error (
              'Invalid Vendor Number "' || p_suggested_vendor_num || '"');
        end if;

        if     lLine.suggested_vendor_site_id is null and p_suggested_vendor_site_code is not null then
           append_error('Invalid Vendor Site "'|| p_suggested_vendor_site_code|| '"');
        end if;
      end if;

      lLine.note_to_buyer := p_note_to_buyer;

      if lError is null then
        insert into po_requisitions_interface_all(
          batch_id,
          group_code,
          project_accounting_context,
          interface_source_code,
          interface_source_line_id,
          line_num,
          source_type_code,
          destination_type_code,
          quantity,
          unit_price,
          authorization_status,
          preparer_id,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          item_id,
          category_id,
          unit_of_measure,
          destination_organization_id,
          deliver_to_requestor_id,
          deliver_to_location_id,
          need_by_date,
          currency_code,
          currency_unit_price,
          rate,
          rate_date,
          rate_type,
          org_id,
          multi_distributions,
          req_dist_sequence_id,
          line_attribute_category,
          line_attribute1,
          line_attribute2,
          line_attribute3,
          line_attribute4,
          line_attribute5,
          line_attribute6,
          line_attribute7,
          line_attribute8,
          line_attribute9,
          line_attribute10,
          line_attribute11,
          line_attribute12,
          line_attribute13,
          line_attribute14,
          line_attribute15,
          suggested_vendor_id,
          suggested_vendor_site_id,
          note_to_buyer)
        values (
          lLine.batch_id,
          lLine.group_code,
          lLine.project_accounting_context,
          lLine.interface_source_code,
          lLine.interface_source_line_id,
          lLine.line_num,
          lLine.source_type_code,
          lLine.destination_type_code,
          lLine.quantity,
          lLine.unit_price,
          lLine.authorization_status,
          lLine.preparer_id,
          lLine.created_by,
          lLine.creation_date,
          lLine.last_updated_by,
          lLine.last_update_date,
          lLine.item_id,
          lLine.category_id,
          lLine.unit_of_measure,
          lLine.destination_organization_id,
          lLine.deliver_to_requestor_id,
          lLine.deliver_to_location_id,
          lLine.need_by_date,
          lLine.currency_code,
          lLine.currency_unit_price,
          lLine.rate,
          lLine.rate_date,
          lLine.rate_type,
          lLine.org_id,
          lLine.multi_distributions,
          lLine.req_dist_sequence_id,
          lLine.line_attribute_category,
          lLine.line_attribute1,
          lLine.line_attribute2,
          lLine.line_attribute3,
          lLine.line_attribute4,
          lLine.line_attribute5,
          lLine.line_attribute6,
          lLine.line_attribute7,
          lLine.line_attribute8,
          lLine.line_attribute9,
          lLine.line_attribute10,
          lLine.line_attribute11,
          lLine.line_attribute12,
          lLine.line_attribute13,
          lLine.line_attribute14,
          lLine.line_attribute15,
          lLine.suggested_vendor_id,
          lLine.suggested_vendor_site_id,
          lLine.note_to_buyer);
      end if;
    end if;

    if lError is null  then
      lDist.batch_id                    := lLine.batch_id;
      lDist.interface_source_code       := lLine.interface_source_code;
      lDist.interface_source_line_id    := lLine.interface_source_line_id;
      lDist.dist_sequence_id            := lLine.req_dist_sequence_id;
      lDist.org_id                      := lLine.org_id;
      lDist.accrual_account_id          := lLine.accrual_account_id;
      lDist.allocation_type             := p_allocation_type;
      lDist.allocation_value            := p_allocation_value;
      lDist.budget_account_id           := p_charge_account_id;
      lDist.charge_account_id           := p_charge_account_id;
      lDist.destination_organization_id := lLine.destination_organization_id;
      lDist.destination_type_code       := lLine.destination_type_code;

      select nvl (max (distribution_number), 0) + 1
        into lDist.distribution_number
        from po_req_dist_interface_all
       where org_id                   = lLine.org_id
         and batch_id                 = lLine.batch_id
         and interface_source_line_id = lLine.interface_source_line_id;


      lDist.gl_date    := p_gl_date;
      lDist.group_code := lLine.group_code;

      if lCapex then
        lDist.project_accounting_context  := 'Y';
        lDist.expenditure_type            := p_expenditure_type;
        lDist.expenditure_item_date       := p_expenditure_item_date;
        lDist.expenditure_organization_id := lLine.org_id;
        lDist.project_num                 := p_project_num;
        lDist.task_num                    := p_task_num;

        if lDist.project_num is null then
           append_error ('Project Number is missing for CAPEX item');
        end if;

        if lDist.task_num is null then
           append_error ('Project Task Number is missing for CAPEX item');
        end if;
      else
        lDist.project_accounting_context := 'N';
      end if;

      lDist.quantity                 := p_dist_quantity;
      lDist.variance_account_id      := p_charge_account_id;
      lDist.distribution_attribute10 := p_distribution_attribute10;

      insert into po_req_dist_interface_all (
        batch_id,
        interface_source_code,
        interface_source_line_id,
        dist_sequence_id,
        org_id,
        accrual_account_id,
        allocation_type,
        allocation_value,
        budget_account_id,
        charge_account_id,
        destination_organization_id,
        destination_type_code,
        distribution_number,
        expenditure_type,
        expenditure_item_date,
        expenditure_organization_id,
        gl_date,
        group_code,
        project_accounting_context,
        project_num,
        task_num,
        quantity,
        variance_account_id,
        distribution_attribute10)
      values(
        lDist.batch_id,
        lDist.interface_source_code,
        lDist.interface_source_line_id,
        lDist.dist_sequence_id,
        lDist.org_id,
        lDist.accrual_account_id,
        lDist.allocation_type,
        lDist.allocation_value,
        lDist.budget_account_id,
        lDist.charge_account_id,
        lDist.destination_organization_id,
        lDist.destination_type_code,
        lDist.distribution_number,
        lDist.expenditure_type,
        lDist.expenditure_item_date,
        lDist.expenditure_organization_id,
        lDist.gl_date,
        lDist.group_code,
        lDist.project_accounting_context,
        lDist.project_num,
        lDist.task_num,
        lDist.quantity,
        lDist.variance_account_id,
        lDist.distribution_attribute10);

      select nvl (sum (quantity), 0)
        into lLine.quantity
        from po_req_dist_interface_all
       where org_id                   = lLine.org_id
         and batch_id                 = lLine.batch_id
         and interface_source_line_id = lLine.interface_source_line_id;

      update po_requisitions_interface_all
         set quantity                 = lLine.quantity
       where org_id                   = lLine.org_id
         and batch_id                 = lLine.batch_id
         and interface_source_line_id = lLine.interface_source_line_id;

      for i in (select 1 from dual where not exists (select 1 from fnd_concurrent_requests where program_application_id = 201 and concurrent_program_id = 32353 and argument1 = lLine.interface_source_code and argument2 = to_char(lLine.batch_id))) loop
        fnd_request.set_org_id(lLine.org_id);
        lRequestId := fnd_request.submit_request(
          application => 'PO',
          program     => 'REQIMPORT',
          description => null,
          start_time  => null,
          sub_request => false,
          argument1   => lLine.interface_source_code, -- INTERFACE_SOURCE_CODE
          argument2   => lLine.batch_id,              -- BATCH_ID
          argument3   => 'ALL',                       -- GROUP_BY
          argument4   => null,                        -- LAST_REQUISITION_NUMBER
          argument5   => lLine.multi_distributions,   -- MULTI_DISTRIBUTIONS
          argument6   => 'N');                        -- INITIATE_REQAPPR_AFTER_REQIMP
      end loop;
    end if;

    if lError is not null then
      rollback to xx_po_int_adi_imp_pr_lin_sp1;
    end if;

    return (lError);
  exception
    when others then
      lError := dbms_utility.format_error_stack||dbms_utility.format_error_backtrace;
      rollback to xx_po_int_adi_imp_pr_lin_sp1;
      return (lError);
  end;
end;

/
