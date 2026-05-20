class ZCL_ZCOFFEE_RH definition
  public
  final
  create public .

public section.

  types:
    ty_t_func TYPE TABLE OF ztb_funcionario .

  methods CRIAR_FUNCIONARIO
    importing
      !IS_FUNCIONARIO type ZTB_FUNCIONARIO
    exporting
      !EV_SUCESSO type ABAP_BOOL
      !EV_MENSSAGEM type BAPI_MSG
      !ES_FUNCIONARIO type ZTB_FUNCIONARIO .
  methods ATUALIZAR_FUNCIONARIO
    importing
      !IS_FUNCIONARIO type ZTB_FUNCIONARIO
    exporting
      !EV_SUCESSO type ABAP_BOOL
      !EV_MSG type BAPI_MSG
      !ES_FUNCIONARIO type ZTB_FUNCIONARIO .
  methods INATIVAR_FUNCIONARIO
    importing
      !IV_FUNCIONARIO type ZTB_FUNCIONARIO-ID_FUNC
    exporting
      !EV_MSG type BAPI_MSG
      value(EV_SUCESSO) type ABAP_BOOL .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZCOFFEE_RH IMPLEMENTATION.


METHOD atualizar_funcionario.

  DATA ls_func TYPE ztb_funcionario.

* Buscar funcionário
  SELECT SINGLE *
    FROM ztb_funcionario
    INTO ls_func
    WHERE id_func = is_funcionario-id_func.

  IF sy-subrc <> 0.
    ev_sucesso = abap_false.
    ev_msg = 'Funcionário não encontrado'.
    RETURN.
  ENDIF.

* Atualizar apenas campos permitidos
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

* Retornar dados atualizados
  SELECT SINGLE *
    FROM ztb_funcionario
    INTO es_funcionario
    WHERE id_func = is_funcionario-id_func.

* Sucesso
  ev_sucesso = abap_true.
  ev_msg = |Funcionário { is_funcionario-id_func } atualizado com sucesso!|.

ENDMETHOD.


METHOD criar_funcionario.

  DATA:
    ls_func          TYPE ztb_funcionario,
    ld_number        TYPE int4,
    lv_primeiro_nome TYPE string,
    lv_ultimo_nome   TYPE string.

* Copiar dados de entrada
  MOVE-CORRESPONDING is_funcionario TO ls_func.

* Validar CPF duplicado
  SELECT SINGLE @abap_true
    FROM ztb_funcionario
    INTO @DATA(ld_exists)
    WHERE cpf = @ls_func-cpf.

  IF sy-subrc = 0.
    ev_sucesso = abap_false.
    ev_menssagem = 'CPF já cadastrado'.
    RETURN.
  ENDIF.

* Gerar Id
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZNRO_FUNC'
    IMPORTING
      number      = ld_number.

  IF sy-subrc <> 0.
    ev_sucesso = abap_false.
    ev_menssagem = 'Erro ao gerar numeração automática'.
    RETURN.
  ENDIF.

* Preencher dados automáticos
  ls_func-id_func  = ld_number.
  ls_func-status   = 'A'.
  ls_func-data_adm = sy-datum.
  ls_func-moeda    = 'BRL'.

* Gerar login
  TRANSLATE ls_func-nome TO UPPER CASE.
  CONDENSE ls_func-nome.

  SPLIT ls_func-nome AT space INTO TABLE DATA(lt_nomes).

  IF lt_nomes IS NOT INITIAL.

    lv_primeiro_nome = lt_nomes[ 1 ].
    lv_ultimo_nome = lt_nomes[ lines( lt_nomes ) ].

    IF lines( lt_nomes ) >= 2.
      ls_func-login_user = |{ lv_primeiro_nome+0(1) }{ lv_ultimo_nome }|.
    ELSE.
      ls_func-login_user = lv_primeiro_nome.
    ENDIF.

    TRANSLATE ls_func-login_user TO LOWER CASE.

  ENDIF.

* Inserir funcionário
  INSERT ztb_funcionario FROM ls_func.

  IF sy-subrc <> 0.
    ev_sucesso = abap_false.
    ev_menssagem = 'Erro ao inserir funcionário'.
    RETURN.
  ENDIF.

* Retornar sucesso
  ev_sucesso = abap_true.
  ev_menssagem = |Funcionário { ls_func-id_func } cadastrado com sucesso|.

  MOVE-CORRESPONDING ls_func TO es_funcionario.

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
ENDCLASS.
