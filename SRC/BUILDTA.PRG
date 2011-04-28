*
SET DELETE ON
SELECT 3
USE C:KRAGNT INDEX C:KRAGNT
SELECT 2
USE J:AGNT
SELECT 1
USE J:RAAGNT
GO TOP
DO WHILE .NOT. EOF ()
   if empty (a->fatc)
      skip
      loop
   endif
   SELECT 3
   SEEK A->FATC
   IF EOF ()
      SELECT 2
      APPEND BLANK
      replace fatc with A->fatc, fcompany with A->Fcompany
      replace fstd with A->FSTD, fcsm with A->FCSM, fspecial with A->FSPECIAL
      replace faddr with A->Faddr, fcity with A->Fcity, fcontact with A->Fcontact
      replace fstate with A->Fstate, fzip with A->Fzip, fmoddt with date ()
      replace fphone with A->Fphone, ffax with A->FFax
   ELSE
      SELECT 2
      APPEND BLANK
      replace fatc with A->fatc, fcompany with C->AGENT
      replace faddr with C->ADDR1, FADDR1 WITH C->ADDR2
      replace fstd with C->COMMPCT
      REPLACE fcity with A->Fcity, fcontact with A->Fcontact
      replace fstate with A->Fstate, fzip with A->Fzip, fmoddt with date ()
      replace fphone with A->Fphone, ffax with A->FFax
   ENDIF
   SELECT 1
   SKIP
ENDDO
