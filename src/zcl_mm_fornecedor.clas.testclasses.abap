*"* use this source file for your ABAP unit test classes

CLASS ltc_fornecedor DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA mo_cut TYPE REF TO zcl_mm_fornecedor.

    METHODS setup.

    "! Procura um trecho de texto nas mensagens acumuladas pela CUT.
    METHODS tem_msg
      IMPORTING iv_trecho     TYPE string
      RETURNING VALUE(rv_tem) TYPE abap_bool.

    "! Monta um fornecedor válido a menos do campo que o teste quer quebrar.
    "! O CNPJ fica propositalmente inválido para a validação parar antes do
    "! SELECT de duplicidade - assim os testes não dependem do conteúdo da tabela.
    METHODS dado_fornecedor_base.

    METHODS cnpj_aceita_dv_correto        FOR TESTING.
    METHODS cnpj_aceita_campo_preenchido  FOR TESTING.
    METHODS cnpj_rejeita_dv_errado        FOR TESTING.
    METHODS cnpj_rejeita_repetido         FOR TESTING.
    METHODS cnpj_rejeita_tamanho          FOR TESTING.
    METHODS cnpj_rejeita_com_mascara      FOR TESTING.
    METHODS cnpj_rejeita_nao_numerico     FOR TESTING.
    METHODS cnpj_campo_e_char14           FOR TESTING.
    METHODS preparar_normaliza_campos     FOR TESTING.
    METHODS validar_exige_nome            FOR TESTING.
    METHODS validar_exige_email_valido    FOR TESTING.
    METHODS validar_exige_telefone        FOR TESTING.
    METHODS validar_aceita_dados_bons     FOR TESTING.
    METHODS update_exige_status_valido    FOR TESTING.
    METHODS update_aceita_status_a_e_i    FOR TESTING.
    METHODS create_nao_valida_status      FOR TESTING.
    METHODS update_nao_conflita_consigo   FOR TESTING.
    METHODS buscar_inexistente_da_erro    FOR TESTING.

ENDCLASS.


CLASS zcl_mm_fornecedor DEFINITION LOCAL FRIENDS ltc_fornecedor.


CLASS ltc_fornecedor IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW zcl_mm_fornecedor( ).
  ENDMETHOD.


  METHOD tem_msg.

    rv_tem = abap_false.

    LOOP AT mo_cut->mt_msg INTO DATA(ls_msg).
      IF ls_msg-message CS iv_trecho.
        rv_tem = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD dado_fornecedor_base.

    CLEAR mo_cut->ms_fornecedor.

    mo_cut->ms_fornecedor-nome     = 'Padaria do Joao'.
    mo_cut->ms_fornecedor-cnpj     = '00'.
    mo_cut->ms_fornecedor-email    = 'joao@padaria.com'.
    mo_cut->ms_fornecedor-telefone = '11999990001'.
    mo_cut->ms_fornecedor-status    = 'A'.

  ENDMETHOD.


  METHOD cnpj_aceita_dv_correto.

    cl_abap_unit_assert=>assert_true(
      act = mo_cut->is_cnpj_valido( '12345678000195' )
      msg = 'CNPJ com digito verificador correto deveria ser aceito' ).

  ENDMETHOD.


  METHOD cnpj_aceita_campo_preenchido.

    "REGRESSAO: o parametro chega de ZST_FORNECEDOR-CNPJ. Quando esse campo
    "era CHAR18 vinha com brancos a direita, e o operador CN os tratava como
    "caractere nao numerico, recusando um CNPJ valido. O teste equivalente com
    "literal de 14 posicoes nao pegava o defeito.
    CLEAR mo_cut->ms_fornecedor.
    mo_cut->ms_fornecedor-cnpj = '12345678000195'.

    cl_abap_unit_assert=>assert_true(
      act = mo_cut->is_cnpj_valido( mo_cut->ms_fornecedor-cnpj )
      msg = 'CNPJ valido vindo do campo da estrutura deveria ser aceito' ).

  ENDMETHOD.


  METHOD cnpj_rejeita_dv_errado.

    "Este e o CNPJ do cenario de referencia do MM: o sufixo 01 foi inventado
    "sequencialmente e nao corresponde ao digito verificador (correto: 95).
    cl_abap_unit_assert=>assert_false(
      act = mo_cut->is_cnpj_valido( '12345678000101' )
      msg = 'CNPJ com digito verificador errado deveria ser rejeitado' ).

  ENDMETHOD.


  METHOD cnpj_rejeita_repetido.

    cl_abap_unit_assert=>assert_false(
      act = mo_cut->is_cnpj_valido( '00000000000000' )
      msg = 'CNPJ com todos os digitos iguais deveria ser rejeitado' ).

    cl_abap_unit_assert=>assert_false(
      act = mo_cut->is_cnpj_valido( '11111111111111' )
      msg = 'CNPJ com todos os digitos iguais deveria ser rejeitado' ).

  ENDMETHOD.


  METHOD cnpj_rejeita_tamanho.

    cl_abap_unit_assert=>assert_false(
      act = mo_cut->is_cnpj_valido( '123' )
      msg = 'CNPJ curto deveria ser rejeitado' ).

  ENDMETHOD.


  METHOD cnpj_rejeita_com_mascara.

    cl_abap_unit_assert=>assert_false(
      act = mo_cut->is_cnpj_valido( '12.345.678/0001-95' )
      msg = 'CNPJ mascarado deveria ser rejeitado' ).

  ENDMETHOD.


  METHOD cnpj_rejeita_nao_numerico.

    cl_abap_unit_assert=>assert_false(
      act = mo_cut->is_cnpj_valido( '1234567800019X' )
      msg = 'CNPJ com letra deveria ser rejeitado' ).

  ENDMETHOD.


  METHOD cnpj_campo_e_char14.

    "O campo tem o tamanho exato do CNPJ sem mascara, igual a coluna da
    "ZTB_FORNECEDORES e ao MaxLength do metadata OData. Um valor mascarado
    "nao cabe: e truncado. Por isso tirar a mascara e responsabilidade da UI.
    CLEAR mo_cut->ms_fornecedor.
    mo_cut->ms_fornecedor-cnpj = '12.345.678/0001-95'.

    cl_abap_unit_assert=>assert_equals(
      act = strlen( mo_cut->ms_fornecedor-cnpj )
      exp = 14
      msg = 'Campo CNPJ deveria ser CHAR14' ).

    cl_abap_unit_assert=>assert_false(
      act = mo_cut->is_cnpj_valido( mo_cut->ms_fornecedor-cnpj )
      msg = 'Valor mascarado truncado nao deveria passar como CNPJ valido' ).

  ENDMETHOD.


  METHOD preparar_normaliza_campos.

    CLEAR mo_cut->ms_fornecedor.

    mo_cut->ms_fornecedor-nome     = '  Padaria   do   Joao  '.
    mo_cut->ms_fornecedor-cnpj     = '12345678000195'.
    mo_cut->ms_fornecedor-telefone = '(11) 99999-0001'.
    mo_cut->ms_fornecedor-email    = ' Joao@Padaria.COM '.

    mo_cut->preparar_fornecedor( ).

    cl_abap_unit_assert=>assert_equals(
      act = |{ mo_cut->ms_fornecedor-cnpj }|
      exp = `12345678000195`
      msg = 'CNPJ ja limpo deveria passar inalterado' ).

    cl_abap_unit_assert=>assert_equals(
      act = |{ mo_cut->ms_fornecedor-telefone }|
      exp = `11999990001`
      msg = 'Telefone deveria ficar somente com digitos' ).

    cl_abap_unit_assert=>assert_equals(
      act = |{ mo_cut->ms_fornecedor-email }|
      exp = `joao@padaria.com`
      msg = 'E-mail deveria ficar minusculo e sem espacos' ).

    cl_abap_unit_assert=>assert_equals(
      act = |{ mo_cut->ms_fornecedor-nome }|
      exp = `Padaria do Joao`
      msg = 'Nome deveria ter espacos condensados' ).

  ENDMETHOD.


  METHOD validar_exige_nome.

    dado_fornecedor_base( ).
    CLEAR mo_cut->ms_fornecedor-nome.

    mo_cut->validar_fornecedor( iv_mode = mo_cut->mc_create ).

    cl_abap_unit_assert=>assert_true(
      act = tem_msg( `nome do fornecedor` )
      msg = 'Nome vazio deveria gerar erro' ).

  ENDMETHOD.


  METHOD validar_exige_email_valido.

    dado_fornecedor_base( ).
    mo_cut->ms_fornecedor-email = 'joao-sem-arroba.com'.

    mo_cut->validar_fornecedor( iv_mode = mo_cut->mc_create ).

    cl_abap_unit_assert=>assert_true(
      act = tem_msg( `E-mail` )
      msg = 'E-mail sem @ deveria gerar erro' ).

  ENDMETHOD.


  METHOD validar_exige_telefone.

    dado_fornecedor_base( ).
    "20 digitos - exatamente o que esta gravado no fornecedor 000001
    mo_cut->ms_fornecedor-telefone = '12376512351236512736'.

    mo_cut->validar_fornecedor( iv_mode = mo_cut->mc_create ).

    cl_abap_unit_assert=>assert_true(
      act = tem_msg( `Telefone` )
      msg = 'Telefone fora de 10/11 digitos deveria gerar erro' ).

  ENDMETHOD.


  METHOD validar_aceita_dados_bons.

    dado_fornecedor_base( ).

    mo_cut->validar_fornecedor( iv_mode = mo_cut->mc_create ).

    "Nome, e-mail e telefone estao corretos: so o CNPJ (proposital) reclama.
    cl_abap_unit_assert=>assert_false(
      act = tem_msg( `nome do fornecedor` )
      msg = 'Nome valido nao deveria gerar erro' ).

    cl_abap_unit_assert=>assert_false(
      act = tem_msg( `E-mail` )
      msg = 'E-mail valido nao deveria gerar erro' ).

    cl_abap_unit_assert=>assert_false(
      act = tem_msg( `Telefone` )
      msg = 'Telefone valido nao deveria gerar erro' ).

  ENDMETHOD.


  METHOD update_exige_status_valido.

    dado_fornecedor_base( ).
    mo_cut->ms_fornecedor-status = 'X'.

    mo_cut->validar_fornecedor( iv_mode = mo_cut->mc_update ).

    cl_abap_unit_assert=>assert_true(
      act = tem_msg( `Status inv` )
      msg = 'Status fora de A/I deveria gerar erro na alteracao' ).

  ENDMETHOD.


  METHOD update_aceita_status_a_e_i.

    dado_fornecedor_base( ).
    mo_cut->ms_fornecedor-status = 'I'.

    mo_cut->validar_fornecedor( iv_mode = mo_cut->mc_update ).

    cl_abap_unit_assert=>assert_false(
      act = tem_msg( `Status inv` )
      msg = 'Status I deveria ser aceito na alteracao' ).

  ENDMETHOD.


  METHOD create_nao_valida_status.

    "Na criacao o status e fixado em 'A' por PREENCHER_CAMPOS, entao o que
    "vier no payload e irrelevante e nao deve ser cobrado do usuario.
    dado_fornecedor_base( ).
    mo_cut->ms_fornecedor-status = 'X'.

    mo_cut->validar_fornecedor( iv_mode = mo_cut->mc_create ).

    cl_abap_unit_assert=>assert_false(
      act = tem_msg( `Status inv` )
      msg = 'Criacao nao deveria validar status' ).

  ENDMETHOD.


  METHOD update_nao_conflita_consigo.

    "Ao alterar, o proprio registro nao pode ser acusado de CNPJ duplicado.
    "Usa um fornecedor real da tabela para nao depender de ID fixo.
    SELECT SINGLE id_forn, cnpj
      FROM ztb_fornecedores
      INTO @DATA(ls_existente)
      WHERE cnpj <> @space.

    IF sy-subrc <> 0.
      "Sem massa cadastrada nao ha o que verificar.
      RETURN.
    ENDIF.

    dado_fornecedor_base( ).
    mo_cut->ms_fornecedor-id_forn = ls_existente-id_forn.
    mo_cut->ms_fornecedor-cnpj    = ls_existente-cnpj.

    mo_cut->validar_fornecedor( iv_mode = mo_cut->mc_update ).

    cl_abap_unit_assert=>assert_false(
      act = tem_msg( `ja cadastrado` )
      msg = 'O proprio fornecedor nao deveria ser acusado de CNPJ duplicado' ).

    cl_abap_unit_assert=>assert_false(
      act = tem_msg( `já cadastrado` )
      msg = 'O proprio fornecedor nao deveria ser acusado de CNPJ duplicado' ).

  ENDMETHOD.


  METHOD buscar_inexistente_da_erro.

    mo_cut->buscar_fornecedor( iv_idforn = '999999' ).

    cl_abap_unit_assert=>assert_true(
      act = tem_msg( `encontrado` )
      msg = 'Fornecedor inexistente deveria gerar erro' ).

  ENDMETHOD.

ENDCLASS.
