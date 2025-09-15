set hhc="D:\Data\Progs\HTML Help Workshop\hhc.exe"
copy /b /y history_begin.txt+history_en.txt+"..\readme.beta.txt"+history_end.txt html\ay_en_history.htm
%hhc% Ay_Emul.hhp
del /q html\ay_en_history.htm
copy /b /y history_begin.txt+history_ru.txt+"..\readme.beta.txt"+history_end.txt html\ay_ru_history.htm
%hhc% Ay_Emul.ru.hhp
del /q html\ay_ru_history.htm
