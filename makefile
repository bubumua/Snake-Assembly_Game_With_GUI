EXE = sc.exe		#指定输出文件
OBJS = sc.obj		#需要的目标文件
RES = sc.res		#需要的资源文件

ML_FLAG = /c /coff		#编译选项 
# /c	option tells ml to Assemble only and not attempt to link
# /coff	creates the obj file in the Common Object File Format, this is what we use for x86 on Windows.
# /Cp	option tells ml to preserve the case of all identifiers
# /Gz	函数调用类型用“StdCall”形式
LINK_FLAG = /subsystem:windows	#连接选项
# 链接成PE文件：Link /subsystem:windows xx.obj yy.lib zz.res
# 链接成控制台文件：Link /subsystem:console xx.obj yy.lib zz.res
# 链接成DLL文件：Link /subsystem:windows /dll /def:aa.def xx.obj yy.lib zz.res
# /subsystem:xxx	指定程序运行的操作系统
# /dll				生成动态链接库文件
# /def:xxx.def		用于在编写动态链接库文件时指定列表定义文件，列表定义文件用来指定要导出的函数列表

$(EXE): $(OBJS) $(RES)
	Link $(LINK_FLAG) $(OBJS) $(RES)

.asm.obj:
	ml $(ML_FLAG) $<
.rc.res:
	rc $<

clean:
	del *.obj
	del *.res

# nmake /A /P /f 描述文件名 clean
# /A：不检测文件时间，强制更新所有文件
# /P：在make命令执行的过程中显示详细信息
# /f 描述文件名：默认的描述文件名是makefile，/f可以指定自定义的描述文件
# clean		delete files in 'clean:'