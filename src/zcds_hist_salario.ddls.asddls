@AbapCatalog.sqlViewName: 'ZV_HSALARIO'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Historico de Funcionarios'
@Metadata.ignorePropagatedAnnotations: true
define view ZCDS_HIST_SALARIO
  as select from zrh_hist_salario
{

  key id_hsal        as Id,
      funcionario_id as FuncionarioId,
      salario_antigo as SalarioAntigo,
      salario_novo   as SalarioNovo,
      moeda          as Moeda,
      data_alteracao as DataAlteracao,
      hora_alteracao as HoraAlteracao,
      usuario        as Usuario
}
