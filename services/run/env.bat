@ECHO OFF
ECHO "Setting up the sp environment..."
IF NOT DEFINED SP_ROOT (
	ECHO "ERROR: SP_ROOT MUST BE DEFINED"
	EXIT /B -1  )

IF NOT DEFINED SP_SYS (
	ECHO "ERROR: SP_SYS MUST BE DEFINED"
	EXIT /B -2 )
	
SET PATH=%PATH%;%SP_ROOT%\framework;%SP_ROOT%\framework\q;%SP_ROOT%\framework\q\%SP_SYS%
ECHO "Done"

