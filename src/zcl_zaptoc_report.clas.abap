class zcl_zaptoc_report definition public final create public.

  public section.
    types:
      tt_range_of_transport   type range of trkorr,
      tt_range_of_owner       type range of tr_as4user,
      tt_range_of_description type range of as4text.

    methods:
      constructor importing report_id type sy-repid,
      gather_transports importing tranports type tt_range_of_transport optional owners type tt_range_of_owner optional
                        descriptions type tt_range_of_description optional
                        include_released type abap_bool default abap_true include_tocs type abap_bool default abap_false
                        include_subtransports type abap_bool default abap_false,
      display importing layout_name type slis_vari optional,
      get_layout_from_f4_selection returning value(layout) type slis_vari.

  private section.
    types:
      t_icon type c length 4,
      begin of t_report,
        transport                 type trkorr,
        type                      type trfunction,
        target_system             type tr_target,
        owner                     type tr_as4user,
        creation_date             type as4date,
        description               type as4text,
        create_toc                type t_icon,
        create_release_toc        type t_icon,
        create_release_import_toc type t_icon,
        toc_number                type trkorr,
        toc_status                type string,
        color                     type lvc_t_scol,
      end of t_report,
      tt_report type standard table of t_report with key transport with non-unique sorted key toc components toc_number.

    constants:
      begin of c_icon,
        create                type t_icon value '@EZ@',
        create_release        type t_icon value '@4A@',
        create_release_import type t_icon value '@K5@',
      end of c_icon,
      begin of c_toc_columns,
        create_toc                type string value 'CREATE_TOC',
        create_release_toc        type string value 'CREATE_RELEASE_TOC',
        create_release_import_toc type string value 'CREATE_RELEASE_IMPORT_TOC',
      end of c_toc_columns,
      begin of c_status_color,
        green  type i value 5,
        yellow type i value 3,
        red    type i value 6,
      end of c_status_color,
      c_status_check_interval_sec type i value 5.

    data:
      timer         type ref to cl_gui_timer,
      alv_table     type ref to cl_salv_table,
      toc_manager   type ref to zcl_zaptoc,
      layout_key    type salv_s_layout_key,
      report_data   type tt_report,
      tocs_to_check type hashed table of trkorr with unique key table_line.

    methods:
      set_column_hotspot_icon importing column type lvc_fname,
      set_fixed_column_text   importing column type lvc_fname text type scrtext_l,
      set_status_color importing row type i color type i,
      set_entry_color importing entry type ref to t_report color type i,
      set_status_timer importing transport_to_check type trkorr,
      prepare_alv_table       importing layout_name type slis_vari optional,
      update_import_status,
      on_timer_finished for event finished of cl_gui_timer importing sender,
      on_link_click for event link_click of cl_salv_events_table importing row column,
      on_double_click for event double_click of cl_salv_events_table importing row column,
      show_transport_details importing transport type trkorr.
endclass.


class zcl_zaptoc_report implementation.
  method constructor.
    layout_key = value salv_s_layout_key( report = report_id ).
    toc_manager = new #( ).
    timer = new #( ).
    timer->interval = c_status_check_interval_sec.
    set handler on_timer_finished for timer.
  endmethod.

  method gather_transports.
    select from e070
                left join e07t on e07t~trkorr = e070~trkorr
                left join e070 as sup on sup~trkorr = e070~strkorr
      fields e070~trkorr as transport, e070~trfunction as type, e070~as4user as owner, e070~as4date as creation_date,
          case when e070~tarsystem <> @space then e070~tarsystem else sup~tarsystem end as target_system,
          e07t~as4text as description,
          @c_icon-create as create_toc, @c_icon-create_release as create_release_toc,
          @c_icon-create_release_import as create_release_import_toc
      where e070~trkorr in @tranports and e070~as4user in @owners and as4text in @descriptions
        and ( @include_subtransports = @abap_true or e070~strkorr     = @space )
        and ( @include_released      = @abap_true or e070~trstatus   in ( 'L', 'D' ) )
        and ( @include_tocs          = @abap_true or e070~trfunction <> 'T' )
      order by e070~trkorr descending, e070~as4date descending
      into corresponding fields of table @report_data.

    delete adjacent duplicates from report_data comparing transport.
  endmethod.

  method display.
    prepare_alv_table( layout_name ).
    alv_table->display( ).
  endmethod.

  method on_link_click.
    data(selected) = ref #( report_data[ row ] ).
    clear selected->color.
    delete tocs_to_check where table_line = selected->toc_number.

    try.
        case column.
            "--------------------------------------------------
          when c_toc_columns-create_toc.
            selected->toc_number = toc_manager->create(
              source_transport = selected->transport target_system = selected->target_system ).
            selected->toc_status = text-s01.
            set_status_color( row = row color = c_status_color-green ).

            "--------------------------------------------------
          when c_toc_columns-create_release_toc.
            selected->toc_number = toc_manager->create(
              source_transport = selected->transport target_system = selected->target_system ).
            toc_manager->release( selected->toc_number ).
            selected->toc_status = text-s02.
            set_status_color( row = row color = c_status_color-green ).

            "--------------------------------------------------
          when c_toc_columns-create_release_import_toc.
            selected->toc_number = toc_manager->create(
              source_transport = selected->transport target_system = selected->target_system ).
            toc_manager->release( selected->toc_number ).
            data(rc) = conv i( toc_manager->import(
              toc = selected->toc_number target_system = selected->target_system ) ).
            selected->toc_status = replace( val = text-s04 sub = '&1' with = |{ rc }| ).
            set_status_color( row = row color = cond #( when rc = 0 then c_status_color-green
                                                        when rc = 4 then c_status_color-yellow
                                                        else             c_status_color-red ) ).

            "--------------------------------------------------
          when others.
        endcase.

      catch zcx_zaptoc_exception into data(exception).
        selected->toc_status = exception->get_text( ).
        set_status_color( row = row color = c_status_color-red ).

    endtry.

    alv_table->refresh( refresh_mode = if_salv_c_refresh=>full ).
  endmethod.

  method set_column_hotspot_icon.
    data(col) = cast cl_salv_column_table( me->alv_table->get_columns( )->get_column( column ) ).
    col->set_icon( if_salv_c_bool_sap=>true ).
    col->set_cell_type( if_salv_c_cell_type=>hotspot ).
  endmethod.

  method set_fixed_column_text.
    data(col) = alv_table->get_columns( )->get_column( column ).
    if strlen( text ) > 20.
      col->set_long_text( text ).
      col->set_fixed_header_text( 'L' ).
    elseif strlen( text ) > 10.
      col->set_long_text( text ).
      col->set_medium_text( conv #( text ) ).
      col->set_fixed_header_text( 'M' ).
    else.
      col->set_long_text( text ).
      col->set_medium_text( conv #( text ) ).
      col->set_short_text( conv #( text ) ).
      col->set_fixed_header_text( 'S' ).
    endif.
  endmethod.

  method prepare_alv_table.
    cl_salv_table=>factory( importing r_salv_table = alv_table changing  t_table = report_data ).

    " Set columns as icons
    set_column_hotspot_icon( conv #( c_toc_columns-create_toc ) ).
    set_column_hotspot_icon( conv #( c_toc_columns-create_release_toc ) ).
    set_column_hotspot_icon( conv #( c_toc_columns-create_release_import_toc ) ).

    " Set column texts
    set_fixed_column_text( column = conv #( c_toc_columns-create_toc ) text = conv #( text-c01 ) ).
    set_fixed_column_text( column = conv #( c_toc_columns-create_release_toc ) text = conv #( text-c02 ) ).
    set_fixed_column_text( column = conv #( c_toc_columns-create_release_import_toc ) text = conv #(  text-c03 ) ).
    set_fixed_column_text( column = 'TOC_NUMBER' text =  conv #( text-c04 ) ).
    set_fixed_column_text( column = 'TOC_STATUS' text =  conv #( text-c05 ) ).

    " Set handlers
    data(event) = alv_table->get_event( ).
    set handler me->on_link_click for event.
    set handler me->on_double_click for event.

    " Set layouts
    alv_table->get_layout( )->set_key( layout_key ).
    alv_table->get_layout( )->set_save_restriction( if_salv_c_layout=>restrict_none ).
    alv_table->get_layout( )->set_default( abap_true ).
    if layout_name is not initial.
      alv_table->get_layout( )->set_initial_layout( layout_name ).
    endif.

    " Enable standard report functions
    alv_table->get_functions( )->set_all( ).

    " Color
    alv_table->get_columns( )->set_color_column( 'COLOR' ).
  endmethod.

  method get_layout_from_f4_selection.
    layout = cl_salv_layout_service=>f4_layouts( s_key = layout_key restrict = if_salv_c_layout=>restrict_none )-layout.
  endmethod.

  method set_status_color.
    data(color_cell) = ref #( report_data[ row ]-color ).
    clear color_cell->*.
    append value #( fname = 'TOC_STATUS' color = value #( col = color ) ) to color_cell->*.
  endmethod.

  method set_entry_color.
    clear entry->color.
    append value #( fname = 'TOC_STATUS' color = value #( col = color ) ) to entry->color.
  endmethod.

  method on_timer_finished.
    update_import_status( ).
    if lines( tocs_to_check ) > 0.
      sender->interval = c_status_check_interval_sec.
      sender->run( ).
    endif.
  endmethod.

  method set_status_timer.
    if not line_exists( tocs_to_check[ table_line = transport_to_check ] ).
      insert transport_to_check into table tocs_to_check.
    endif.

    timer->run( ).
  endmethod.

  method update_import_status.
    data tocs_to_remove type range of trkorr.

    loop at tocs_to_check reference into data(toc).
      data(entry) = ref #( me->report_data[ key toc toc_number = toc->* ] optional ).
      if not entry is bound.
        append value #( sign = 'I' option = 'EQ' low = toc->* ) to tocs_to_remove.
        continue.
      endif.

      try.
          toc_manager->check_status_in_system(
            exporting toc = toc->* system = entry->target_system
            importing imported = data(imported) rc = data(rc) ).
          if imported = abap_true.
            entry->toc_status = replace( val = text-s04 sub = '&1' with = |{ rc }| ).
            set_entry_color( entry = entry color = cond #( when rc = 0 then c_status_color-green
                                                           when rc = 8 then c_status_color-red
                                                           else             c_status_color-yellow ) ).
            append value #( sign = 'I' option = 'EQ' low = toc->* ) to tocs_to_remove.
          endif.

        catch zcx_zaptoc_exception into data(exception).
          entry->toc_status = exception->get_text( ).
          set_entry_color( entry = entry color = c_status_color-red ).

      endtry.
    endloop.
    if lines( tocs_to_remove ) > 0.
      delete tocs_to_check where table_line in tocs_to_remove.
    endif.

    alv_table->refresh( s_stable = value #( ) refresh_mode = if_salv_c_refresh=>full ).
    cl_gui_cfw=>set_new_ok_code( new_code = '&REFRESHG' ).
  endmethod.

  method show_transport_details.
    data batch_input type table of bdcdata.

    append value #( program = 'RDDM0001' dynpro = '0200' dynbegin = 'X'  ) to batch_input.
    append value #( fnam = 'BDC_OKCODE' fval = '=TSSN' ) to batch_input.
    append value #( program = 'RDDM0001' dynpro = '0200' dynbegin = 'X'  ) to batch_input.
    append value #( fnam = 'BDC_SUBSCR'
                    fval = 'RDDM0001                                0210COMMONSUBSCREEN' ) to batch_input.
    append value #( fnam = 'BDC_CURSOR' fval = 'TRDYSE01SN-TR_TRKORR' ) to batch_input.
    append value #( fnam = 'TRDYSE01SN-TR_TRKORR' fval = transport ) to batch_input.

    call transaction 'SE01' using batch_input mode 'E' update 'A'.
  endmethod.

  method on_double_click.
    data(selected) = ref #( report_data[ row ] ).

    case column.
      when 'TRANSPORT'.
        show_transport_details( selected->transport ).

      when others.

    endcase.
  endmethod.

endclass.
