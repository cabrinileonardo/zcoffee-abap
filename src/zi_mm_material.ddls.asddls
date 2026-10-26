@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Consulta consolidada de materiais'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_MM_MATERIAL
  as select from mara

    left outer join makt on  mara.matnr = makt.matnr
                          and makt.spras = $session.system_language
{
  key mara.matnr           as Material,
      mara.mtart           as TipoMaterial,
      mara.matkl           as GrupoMercadorias,
      mara.meins           as UnidadeMedida,
      mara.mbrsh           as SetorIndustrial,
      mara.lvorm           as MarcadoParaEliminacao,
      makt.maktx           as DescricaoMaterial,
      makt.spras           as Idioma
}
