netmailbot ^
-to ignored ^
-from "<<from>>" ^
-subject "Dollar Reservation Confirmation" ^
-server smtp.bizmail.yahoo.com ^
-authlogin egerez@eonsum.com -authpassword ege7334 ^
-logfile "log.txt" ^
-dsn "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=\netmail\;Extended properties=Text;" ^
-dbquery "SELECT * FROM rezdata.txt" ^
-dbemailcolumn "to" ^
-dbreplacementids "<<to>>=to,<<from>>=from,<<rzheader>>=rzheader,<<rzbody>>=rzbody,<<rzfooter>>=rzfooter" ^
-bodyfile "rezmsg.htm" ^
-personalize ^
-debug