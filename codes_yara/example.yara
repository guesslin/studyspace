rule dummy
{
    condition:
        false
}

rule Example
{
    strings:
        $my_text_string = "text here"
        $my_hex_string = { E2 34 A1 C8 23 FB}

    condition:
        $my_hex_string or $my_text_string
}

rule WildcardExample
{
    strings:
        $hex_string = { E2 34 ?? C8 A? FB }

    condition:
        $hex_string
}

rule JumpExample
{
    strings:
        $hex_string = { F4 23 [4-6] 62 B4}
        // Jump any arbitrary sequence from 4 to 6 bytes
        // EXAMPLES: 
        //      F4 23 01 02 03 04 62 B4
        //      F4 23 01 02 03 04 05 62 B4
        //      F4 23 01 02 03 04 05 06 62 B4
    condition:
        $hex_string
}

rule AlternativesExample
{
    strings:
        $hex_string = { F4 23 ( 62 B4 | 56 ) 45}

    condition:
        $hex_string
}

rule AlternativesExample2
{
    strings:
        $hex_string = { F2 23 ( 62 B4 | 45 | C4 ?? 6A ) 45}

    condition:
        $hex_string
}

rule TextExample
{
    strings:
        $text_string = "foobar"

    condition:
        $text_string
}

rule CaseInsensitiveTextExample
{
    strings:
        $text_string = "foobar" nocase
        // nocase modifier after text string make the text string case-insensitive

    condition:
        $text_string
}

rule WideCharTextExample
{
    strings:
        $wide_string = "Borland" wide
        // wide modifier after text string make the text string map to two bytes per character
        // "Borland" wide ==> "B\0o\0r\0l\0a\0n\0d\0" == " 42 00 6F 00 72 00 6C 00 61 00 6E 00 64 00"
        // usually seen in executable file
        // ONLY interleaves the ASCII codes of the character in the string with zeroes
        // Not support UTF-16 and non-English characters

    condition:
        $wide_string
}

rule WideCharTextExample2
{
    strings:
        $wide_string = "Borland" wide ascii
        // Add ascii to search BOTH normal ASCII and wide form
        // the sequence of wide and ascii doesn't matter

    condition:
        $wide_string
}

rule FullWordExample
{
    strings:
        $fullword_string = "domain" fullword
        // fullword modifier
        // mydomain not match this rule
        // but my-domain does match this rule

    condition:
        $fullword_string
}

rule RugExpExample
{
    strings:
        $re1 = /md5: [0-9a-zA-Z]{32}/
        $re2 = /state: (on|off)/
        // Use Regular Expressions like in Perl
        // Also take the following modifiers
        // nocase, ascii, wide, fullword

    condition:
        $re1 and $re2
}

rule ConditionExample
{
    strings:
        $a = "text1"
        $b = "text2"
        $c = "text3"
        $d = "text4"

    condition:
        ( $a or $b ) and ( $c or $d )
}

rule CountExample
{
    strings:
        $a = "text1"
        $b = "text2"

    condition:
        #a == 6 and #b >= 10
        // #a means the times of string $a occurrences
}

// String offset or Virtual address
rule AtExample
{
    strings:
        $a = "dummy1"
        $b = "dummy2"

    condition:
        $a at 100 and $b at 200
        // NOTICE offset is count in decimal not in hex unless with 0x prefix
}

rule InExample
{
    strings:
        $a = "dummy1"
        $2 = "dummy2"
        
    condition:
        $a in (0..100) and $b in (100..filesize)
}

rule FilesizeExample
{
    condition:
        filesize > 200KB
}

// Executable entry point
rule EntryPointExample
{
    strings:
        $a = { E8 00 00 00 00 }

    condition:
        $a at entrypoint
        // work for PE file or ELF file
        // if a process, entrypoint translate to 
}

rule EntryPointExample2
{
    strings:
        $a = { 9C 50 66 A1 ?? ?? ?? 00 66 A9 ?? ?? 58 0F 85 }

    condition:
        $a in (entrypoint..entrypoint + 10)
        
}

rule IsPE
{
    condition:
        uint16(0) == 0x5A4D and
        uint32(uint32(0x3C)) == 0x00004550
}

// set of strings
rule OfExample1
{
    strings:
        $a = "dummy1"
        $b = "dummy2"
        $c = "dummy3"

    condition:
        2 of ($a, $b, $c)
}

rule OfExample2
{
    strings:
        $foo1 = "dummy1"
        $foo2 = "dummy2"
        $foo3 = "dummy3"

    condition:
        2 of ($foo*) // equivalent to 2 of ($foo1, $foo2, $foo3)
}

rule OfExample4
{
    strings:
        $a = "dummy1"
        $b = "dummy2"
        $c = "dummy3"

    condition:
        1 of them // equivalent to 1 of ($*) OR 1 of ($a, $b, $c)
        // all of them
        // any of them
        // all of ($a*)
}
