CLASS ltc_forn_produto DEFINITION FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.

    METHODS create_com_sucesso FOR TESTING RAISING cx_static_check.
    METHODS create_duplicado_falha FOR TESTING RAISING cx_static_check.
    METHODS create_forn_inativo_falha FOR TESTING RAISING cx_static_check.
    METHODS update_atualiza_campos FOR TESTING RAISING cx_static_check.
    METHODS delete_inativa_logicamente FOR TESTING RAISING cx_static_check.

    METHODS limpar_relacao
      IMPORTING iv_id_forn TYPE zde_forn_id
                iv_id_prod TYPE zidprod.

ENDCLASS.


CLASS ltc_forn_produto IMPLEMENTATION.

  METHOD create_com_sucesso.

    DATA lo_rel TYPE REF TO zcl_mm_forn_produto.
    DATA ls_ent TYPE zcl_mm_forn_produto=>ty_relacao_entity.

    ls_ent-idforn           = '000003'.
    ls_ent-idprod           = '000004'.
    ls_ent-precocompra      = '3.80'.
    ls_ent-moeda            = 'BRL'.
    ls_ent-prazoentregadias = 2.
    ls_ent-codprodforn      = 'CAF-EXP-01'.
    ls_ent-dataultimacompra = sy-datum.

    lo_rel = NEW zcl_mm_forn_produto( ).
    lo_rel->create_relacao( is_entity_relacao = ls_ent ).

    DATA(lt_msg) = lo_rel->get_messages( ).
    cl_abap_unit_assert=>assert_equals( act = lt_msg[ 1 ]-type exp = 'S' ).

    DATA(ls_criada) = lo_rel->map_relacao_to_entity( ).

    cl_abap_unit_assert=>assert_equals( act = ls_criada-status      exp = 'A' ).
    cl_abap_unit_assert=>assert_equals( act = ls_criada-precocompra exp = '3.80' ).
    cl_abap_unit_assert=>assert_not_initial( ls_criada-nomefornecedor ).
    cl_abap_unit_assert=>assert_not_initial( ls_criada-nomeproduto ).

    me->limpar_relacao( iv_id_forn = '000003' iv_id_prod = '000004' ).

  ENDMETHOD.


  METHOD create_duplicado_falha.

    DATA lo_rel TYPE REF TO zcl_mm_forn_produto.
    DATA ls_ent TYPE zcl_mm_forn_produto=>ty_relacao_entity.

    ls_ent-idforn           = '000003'.
    ls_ent-idprod           = '000004'.
    ls_ent-precocompra      = '3.80'.
    ls_ent-moeda            = 'BRL'.
    ls_ent-prazoentregadias = 2.
    ls_ent-codprodforn      = 'CAF-EXP-01'.

    lo_rel = NEW zcl_mm_forn_produto( ).
    lo_rel->create_relacao( is_entity_relacao = ls_ent ).

    DATA(lo_rel2) = NEW zcl_mm_forn_produto( ).
    lo_rel2->create_relacao( is_entity_relacao = ls_ent ).

    DATA(lt_msg) = lo_rel2->get_messages( ).
    cl_abap_unit_assert=>assert_equals( act = lt_msg[ 1 ]-type exp = 'E' ).

    me->limpar_relacao( iv_id_forn = '000003' iv_id_prod = '000004' ).

  ENDMETHOD.


  METHOD create_forn_inativo_falha.

    DATA lo_rel TYPE REF TO zcl_mm_forn_produto.
    DATA ls_ent TYPE zcl_mm_forn_produto=>ty_relacao_entity.

    " 000002 é fornecedor inativo (massa de dados do sistema)
    ls_ent-idforn           = '000002'.
    ls_ent-idprod           = '000002'.
    ls_ent-precocompra      = '1.00'.
    ls_ent-moeda            = 'BRL'.
    ls_ent-prazoentregadias = 1.
    ls_ent-codprodforn      = 'X'.

    lo_rel = NEW zcl_mm_forn_produto( ).
    lo_rel->create_relacao( is_entity_relacao = ls_ent ).

    DATA(lt_msg) = lo_rel->get_messages( ).
    cl_abap_unit_assert=>assert_equals( act = lt_msg[ 1 ]-type exp = 'E' ).

  ENDMETHOD.


  METHOD update_atualiza_campos.

    DATA lo_rel TYPE REF TO zcl_mm_forn_produto.
    DATA ls_ent TYPE zcl_mm_forn_produto=>ty_relacao_entity.

    ls_ent-idforn           = '000003'.
    ls_ent-idprod           = '000004'.
    ls_ent-precocompra      = '3.80'.
    ls_ent-moeda            = 'BRL'.
    ls_ent-prazoentregadias = 2.
    ls_ent-codprodforn      = 'CAF-EXP-01'.

    lo_rel = NEW zcl_mm_forn_produto( ).
    lo_rel->create_relacao( is_entity_relacao = ls_ent ).

    ls_ent-precocompra      = '4.20'.
    ls_ent-prazoentregadias = 3.
    ls_ent-codprodforn      = 'CAF-EXP-01-B'.
    ls_ent-status           = 'A'.

    DATA(lo_upd) = NEW zcl_mm_forn_produto( ).
    lo_upd->update_relacao( is_entity_relacao = ls_ent
                            iv_id_forn        = '000003'
                            iv_id_prod        = '000004' ).

    DATA(lt_msg) = lo_upd->get_messages( ).
    cl_abap_unit_assert=>assert_equals( act = lt_msg[ 1 ]-type exp = 'S' ).

    DATA(ls_atualizada) = lo_upd->map_relacao_to_entity( ).

    cl_abap_unit_assert=>assert_equals( act = ls_atualizada-precocompra      exp = '4.20' ).
    cl_abap_unit_assert=>assert_equals( act = ls_atualizada-prazoentregadias exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = ls_atualizada-codprodforn      exp = 'CAF-EXP-01-B' ).

    me->limpar_relacao( iv_id_forn = '000003' iv_id_prod = '000004' ).

  ENDMETHOD.


  METHOD delete_inativa_logicamente.

    DATA lo_rel TYPE REF TO zcl_mm_forn_produto.
    DATA ls_ent TYPE zcl_mm_forn_produto=>ty_relacao_entity.

    ls_ent-idforn           = '000003'.
    ls_ent-idprod           = '000004'.
    ls_ent-precocompra      = '3.80'.
    ls_ent-moeda            = 'BRL'.
    ls_ent-prazoentregadias = 2.
    ls_ent-codprodforn      = 'CAF-EXP-01'.

    lo_rel = NEW zcl_mm_forn_produto( ).
    lo_rel->create_relacao( is_entity_relacao = ls_ent ).

    DATA(lo_del) = NEW zcl_mm_forn_produto( ).
    lo_del->delete_relacao( iv_id_forn = '000003'
                            iv_id_prod = '000004' ).

    DATA(lt_msg) = lo_del->get_messages( ).
    cl_abap_unit_assert=>assert_equals( act = lt_msg[ 1 ]-type exp = 'S' ).

    DATA(ls_final) = lo_del->map_relacao_to_entity( ).
    cl_abap_unit_assert=>assert_equals( act = ls_final-status exp = 'I' ).

    me->limpar_relacao( iv_id_forn = '000003' iv_id_prod = '000004' ).

  ENDMETHOD.


  METHOD limpar_relacao.

    DELETE FROM ztb_forn_prod
      WHERE id_forn = iv_id_forn
        AND id_prod = iv_id_prod.

  ENDMETHOD.

ENDCLASS.
