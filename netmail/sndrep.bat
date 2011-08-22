netmailbot ^
-to ignored ^
-from "<<from>>" ^
-subject "RacWare Report" ^
-server smtp.bizmail.yahoo.com ^
-authlogin egerez@eonsum.com -authpassword ege7334 ^
-logfile "log.txt" ^
-dsn "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=\netmail\;Extended properties=Text;" ^
-dbquery "SELECT * FROM rarep.txt" ^
-dbemailcolumn "to" ^
-dbreplacementids "<<to>>=to,<<from>>=from,<<report>>=report,<<attachment>>=attachment" ^
-bodyfile "body.txt" ^
-attachment "<<attachment>>" ^
-personalize ^
-debug


