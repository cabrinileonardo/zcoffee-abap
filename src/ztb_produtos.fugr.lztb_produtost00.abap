*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_PRODUTOS....................................*
DATA:  BEGIN OF STATUS_ZTB_PRODUTOS                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_PRODUTOS                  .
CONTROLS: TCTRL_ZTB_PRODUTOS
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_PRODUTOS                  .
TABLES: ZTB_PRODUTOS                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
