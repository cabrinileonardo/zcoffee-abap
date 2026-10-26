*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_FUNCIONARIO.................................*
DATA:  BEGIN OF STATUS_ZTB_FUNCIONARIO               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_FUNCIONARIO               .
CONTROLS: TCTRL_ZTB_FUNCIONARIO
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_FUNCIONARIO               .
TABLES: ZTB_FUNCIONARIO                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
