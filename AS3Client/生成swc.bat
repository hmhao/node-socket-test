set CompilerPath=E:\FlashDevelop\Tools\flexsdk\bin
set ProjectDir=%~dp0
set ProjectSrc=%ProjectDir%src
set IncludeLib=%ProjectDir%lib\json.swc
set Output=%ProjectDir%SocketIO.swc
%CompilerPath%\compc.exe -omit-trace-statements=true -target-player=10.2 -o %Output% -sp %ProjectSrc% -compiler.library-path+=%ProjectDir%lib -include-libraries %IncludeLib% -is+=%ProjectSrc%\com,%ProjectSrc%\net,%ProjectSrc%\io
echo output Swc success....
echo pass anykey
pause>nul