*&---------------------------------------------------------------------*
*& Report ztoc
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report ztoc.

" -----------------------------------------------------------------------
tables: e070, e07t.

selection-screen begin of block b01 with frame title text-b01.
  select-options so_trnum for e070-trkorr. " Transport numbers
  select-options so_owner for e070-as4user default sy-uname. " Transport owners
  select-options so_descr for e07t-as4text.
  parameters p_reltr as checkbox. " Include released transports
  parameters p_tocs as checkbox. " Include ToCs
  parameters p_sub as checkbox. " Include subtransports
selection-screen end of block b01.

selection-screen begin of block b02 with frame title text-b02.
  parameters p_layout type disvariant-variant.
selection-screen end of block b02.

" -----------------------------------------------------------------------
initialization.
  data(report) = new zcl_zabap_toc_report( report_id = sy-repid ).

  " -----------------------------------------------------------------------
start-of-selection.
  report->gather_transports( tranports = so_trnum[] owners = so_owner[] descriptions = so_descr[]
                             include_released = p_reltr include_tocs = p_tocs include_subtransports = p_sub ).
  report->display( p_layout ).

  " -----------------------------------------------------------------------
at selection-screen on value-request for p_layout.
  p_layout = report->get_layout_from_f4_selection( ).
