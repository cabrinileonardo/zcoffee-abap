CLASS zcl_zcoffee_rh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_func TYPE TABLE OF ztb_funcionario.

    METHODS criar_funcionario
      IMPORTING
        is_funcionario TYPE ztb_funcionario
      EXPORTING
        ev_sucesso     TYPE abap_bool
        ev_menssagem   TYPE bapi_msg
        es_funcionario TYPE ztb_funcionario.

    METHODS atualizar_funcionario
      IMPORTING
        is_funcionario TYPE ztb_funcionario
      EXPORTING
        ev_sucesso     TYPE abap_bool
        ev_msg         TYPE bapi_msg
        es_funcionario TYPE ztb_funcionario.

    METHODS inativar_funcionario
      IMPORTING
        iv_funcionario TYPE ztb_funcionario-id_func
      EXPORTING
        ev_msg         TYPE bapi_msg
        ev_sucesso     TYPE abap_bool.

private section.

  methods VALIDAR_CPF
    importing
      !IV_CPF type ZCPF
    exporting
      !EV_EXIST type ABAP_BOOL
      !EV_MSG type STRING .
  methods GERAR_ID
    changing
      !CS_FUNCIONARIO type ZTB_FUNCIONARIO .
  methods PREENCHER_DADOS_PADRAO
    changing
      !CS_FUNCIONARIO type ZTB_FUNCIONARIO .
  methods GERAR_LOGIN
    changing
      !CS_FUNCIONARIO type ZTB_FUNCIONARIO .
  methods INSERIR_FUNCIONARIO
    importing
      !IS_FUNCIONARIO type ZTB_FUNCIONARIO
    exporting
      !EV_SUCESSO type ABAP_BOOL
      !EV_MSG type BAPI_MSG .
  methods GERAR_ID_HIST_SALARIO
    returning
      value(RV_NEW_ID) type ZDE_ID_HSAL .
ENDCLASS.



CLASS ZCL_ZCOFFEE_RH IMPLEMENTATION.


  METHOD atualizar_funcionario.

    DATA: ls_func TYPE ztb_funcionario.

* Buscar funcionário atual
    SELECT SINGLE *
      FROM ztb_funcionario
      INTO ls_func
      WHERE id_func = is_funcionario-id_func.

    IF sy-subrc <> 0.
      ev_sucesso = abap_false.
      ev_msg = 'Funcionário não encontrado'.
      RETURN.
    ENDIF.

* Salário antigo
    DATA(lv_salario_antigo) = ls_func-salario.

* Verifica alteração salarial
    IF lv_salario_antigo <> is_funcionario-salario.

*>>> ABACO - LCM - ZCOFFEE_FIORI - INICIO - 06/10/2026

** Gerar próximo ID do histórico
*      SELECT MAX( id )
*        FROM zrh_hist_salario
*        INTO @DATA(lv_max).
*
*      DATA(lv_new_id) = lv_max + 1.

* Gerar próximo ID do histórico (number range ZNRO_HSAL)
      DATA(lv_new_id) = me->gerar_id_hist_salario( ).

      IF lv_new_id IS INITIAL.
        ev_sucesso = abap_false.
        ev_msg = 'Erro ao gerar ID do histórico salarial (ZNRO_HSAL).'.
        RETURN.
      ENDIF.

*>>> ABACO - LCM - ZCOFFEE_FIORI - FIM - 06/10/2026

* Estrutura histórico
      DATA(ls_hist) = VALUE zrh_hist_salario(

        id_hsal          = lv_new_id
        funcionario_id   = is_funcionario-id_func
        salario_antigo   = lv_salario_antigo
        salario_novo     = is_funcionario-salario
        data_alteracao   = sy-datum
        hora_alteracao   = sy-uzeit
        usuario          = sy-uname
        moeda            = 'BRL'

      ).

* Inserir histórico
      INSERT zrh_hist_salario FROM ls_hist.

*>>> ABACO - LCM - ZCOFFEE_FIORI - INICIO - 06/10/2026
* Sem histórico gravado o funcionário não é atualizado: o erro volta para a
* DPC_EXT, que lança exceção e o Gateway desfaz a LUW.
      IF sy-subrc <> 0.
        ev_sucesso = abap_false.
        ev_msg = |Erro ao gravar o histórico salarial { lv_new_id }.|.
        RETURN.
      ENDIF.
*>>> ABACO - LCM - ZCOFFEE_FIORI - FIM - 06/10/2026

    ENDIF.

* Atualizar funcionário
    UPDATE ztb_funcionario
      SET nome      = is_funcionario-nome
          email     = is_funcionario-email
          telefone  = is_funcionario-telefone
          cargo     = is_funcionario-cargo
          dt_nasc   = is_funcionario-dt_nasc
          salario   = is_funcionario-salario
      WHERE id_func = is_funcionario-id_func.

    IF sy-subrc <> 0.
      ev_sucesso = abap_false.
      ev_msg = 'Erro ao atualizar funcionário'.
      RETURN.
    ENDIF.

* Retornar funcionário atualizado
    SELECT SINGLE *
      FROM ztb_funcionario
      INTO es_funcionario
      WHERE id_func = is_funcionario-id_func.

* Sucesso
    ev_sucesso = abap_true.

    IF lv_salario_antigo <> is_funcionario-salario.
      ev_msg = |Funcionário atualizado e histórico salarial registrado!|.
    ELSE.
      ev_msg = |Funcionário { is_funcionario-id_func } atualizado com sucesso!|.
    ENDIF.

  ENDMETHOD.


  METHOD criar_funcionario.

    DATA ls_func TYPE ztb_funcionario.

    MOVE-CORRESPONDING is_funcionario TO ls_func.

* Validar CPF
    me->validar_cpf(
      EXPORTING
        iv_cpf   = ls_func-cpf
      IMPORTING
        ev_exist = DATA(lv_exist)
        ev_msg   = DATA(lv_msg) ).

    IF lv_exist = abap_true.
      ev_sucesso   = abap_false.
      ev_menssagem = lv_msg.
      RETURN.
    ENDIF.

* Gerar ID
    me->gerar_id(
      CHANGING
        cs_funcionario = ls_func ).

* Dados padrão
    me->preencher_dados_padrao(
      CHANGING
        cs_funcionario = ls_func ).

* Login
    me->gerar_login(
      CHANGING
        cs_funcionario = ls_func ).

* Inserção
    me->inserir_funcionario(
      EXPORTING
        is_funcionario = ls_func
      IMPORTING
        ev_sucesso     = ev_sucesso
        ev_msg         = ev_menssagem ).

    IF ev_sucesso = abap_false.
      RETURN.
    ENDIF.

    es_funcionario = ls_func.

    ev_menssagem = |Funcionário { ls_func-id_func } cadastrado com sucesso|.

  ENDMETHOD.


  METHOD inativar_funcionario.

    SELECT SINGLE *
      FROM ztb_funcionario
      INTO @DATA(ls_func)
      WHERE id_func = @iv_funcionario.

    IF sy-subrc <> 0.
      ev_sucesso = abap_false.
      ev_msg = 'Funcionário não encontrado'.
      RETURN.
    ENDIF.

    UPDATE ztb_funcionario
      SET status = 'I'
      WHERE id_func = iv_funcionario.

    IF sy-subrc <> 0.
      ev_sucesso = abap_false.
      ev_msg = 'Erro ao inativar funcionário!'.
      RETURN.
    ENDIF.

    ev_sucesso = abap_true.
    ev_msg = |Funcionário { iv_funcionario } inativado com sucesso!|.

  ENDMETHOD.


  METHOD gerar_id.

    DATA lv_number TYPE int4.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr = '01'
        object      = 'ZNRO_FUNC'
      IMPORTING
        number      = lv_number.

    IF sy-subrc = 0.
      cs_funcionario-id_func = lv_number.
    ENDIF.

  ENDMETHOD.


  METHOD gerar_login.

    DATA:
      lv_primeiro_nome TYPE string,
      lv_ultimo_nome   TYPE string.

    CONDENSE cs_funcionario-nome.

    SPLIT cs_funcionario-nome
      AT space
      INTO TABLE DATA(lt_nomes).

    IF lt_nomes IS INITIAL.
      RETURN.
    ENDIF.

    lv_primeiro_nome = lt_nomes[ 1 ].
    lv_ultimo_nome   = lt_nomes[ lines( lt_nomes ) ].

    IF lines( lt_nomes ) > 1.
      cs_funcionario-login_user =
        |{ lv_primeiro_nome+0(1) }{ lv_ultimo_nome }|.
    ELSE.
      cs_funcionario-login_user = lv_primeiro_nome.
    ENDIF.

    TRANSLATE cs_funcionario-login_user TO LOWER CASE.

  ENDMETHOD.


  METHOD inserir_funcionario.

    INSERT ztb_funcionario FROM is_funcionario.

    IF sy-subrc = 0.
      ev_sucesso = abap_true.
    ELSE.
      ev_sucesso = abap_false.
      ev_msg = 'Erro ao inserir funcionário'.
    ENDIF.

  ENDMETHOD.


  METHOD preencher_dados_padrao.

    cs_funcionario-status   = 'A'.
    cs_funcionario-data_adm = sy-datum.
    cs_funcionario-moeda    = 'BRL'.

  ENDMETHOD.


  METHOD validar_cpf.

    SELECT SINGLE cpf
      FROM ztb_funcionario
      INTO @DATA(lv_cpf_check)
      WHERE cpf = @iv_cpf.

    IF sy-subrc = 0.
      ev_exist = abap_true.
      ev_msg = |CPF { iv_cpf } já está em uso por outro colaborador.|.
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD gerar_id_hist_salario.

* Em caso de falha devolve o ID inicial: o intervalo 01 começa em 000001,
* então quem chama trata ID inicial como erro e não grava o histórico.
    DATA lv_number TYPE zde_id_hsal.

    CLEAR rv_new_id.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr             = '01'
        object                  = 'ZNRO_HSAL'
      IMPORTING
        number                  = lv_number
      EXCEPTIONS
        interval_not_found      = 1
        number_range_not_intern = 2
        object_not_found        = 3
        quantity_is_0           = 4
        quantity_is_not_1       = 5
        interval_overflow       = 6
        buffer_overflow         = 7
        OTHERS                  = 8.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    rv_new_id = lv_number.

  ENDMETHOD.
ENDCLASS.
