@AbapCatalog.sqlViewName: 'ZV_RH_ZCOFFEE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consulta de dados para o Módulo RH'
@Metadata.ignorePropagatedAnnotations: true

define view ZIRH_ZCOFFEE
  as select from ztb_funcionario
{
  key id_func      as ID,
      nome         as Nome,
      cpf          as CPF,
      email        as Email,
      telefone     as Telefone,
      dt_nasc      as Nascimento,
      data_adm     as Admissao,
      cargo        as Cargo,
      salario      as Salario,
      moeda        as Moeda,
      status       as Status,
      login_user   as Login
}
