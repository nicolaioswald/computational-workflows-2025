params.step = 0
params.zip = 'zip'


process SAYHELLO {
    debug true

    script:
    """
    echo 'Hello World!'
    """    
}


process SAYHELLO_PYTHON {
    debug true

        script:
        """
        python "${projectDir}/scripts/say_hello.py"
        """
}

process SAYHELLO_PARAM {
    debug true
    input:
    val greetings
    script:
    """
    echo $greetings
    """
}

process SAYHELLO_FILE {
    debug true
    input:
    val greeting

    script:
    """
    echo $greeting > greeting.txt
    """
}

process UPPERCASE {
    debug true

    input:
    val s

    output:
    path "upper.txt"

    script:
    """
    echo "$s" | tr '[:lower:]' '[:upper:]' > upper.txt
    """
}

process PRINTUPPER {
    debug true

    input:
    path x

    script:
    """
    cat $x
    """
}

process COMPRESS {
    debug true

    input:
    path x

    output:
    path "*"

    script:
    if( params.zip == 'zip' ) {
        """
        zip ${x}.zip ${x}
        """
    } else if( params.zip == 'gzip' ) {
        """
        gzip -c ${x} > ${x}.gz
        """
    } else if( params.zip == 'bzip2' ) {
        """
        bzip2 -c ${x} > ${x}.bz2
        """
    }
}

process COMPRESS_ALL {
    debug true

    input:
    path x

    output:
    // path "*.zip"
    // path "*.gz"
    // path "*.bzip2"
    tuple path("*.zip"), path("*.gz"), path("*.bzip2")

    script:
    """
    zip ${x}.zip ${x}
    gzip -c ${x} > ${x}.gz
    bzip2 -c ${x} > ${x}.bzip2
    """
}

process WRITETOFILE {
    debug true

    publishDir "results", mode: 'copy'

    input:
    // val columns
    val lines

    output:
    path "names.tsv"

    script:
    """
    echo -e "Name\tTitle" > names.tsv
    echo -e "$lines" | tr -d ' [],' >> names.tsv
    """
}

workflow {

    // Task 1 - create a process that says Hello World! (add debug true to the process right after initializing to be able to print the output to the console)
    if (params.step == 1) {
        SAYHELLO()
    }

    // Task 2 - create a process that says Hello World! using Python
    if (params.step == 2) {
        SAYHELLO_PYTHON()
    }

    // Task 3 - create a process that reads in the string "Hello world!" from a channel and write it to command line
    if (params.step == 3) {
        greeting_ch = channel.of("Hello world!")
        SAYHELLO_PARAM(greeting_ch)
    }

    // Task 4 - create a process that reads in the string "Hello world!" from a channel and write it to a file. WHERE CAN YOU FIND THE FILE?
    if (params.step == 4) {
        greeting_ch = Channel.of("Hello world!")
        SAYHELLO_FILE(greeting_ch)
    }

    // Task 5 - create a process that reads in a string and converts it to uppercase and saves it to a file as output. View the path to the file in the console
    if (params.step == 5) {
        greeting_ch = Channel.of("Hello world!")
        out_ch = UPPERCASE(greeting_ch)
        out_ch.view()
    }

    // Task 6 - add another process that reads in the resulting file from UPPERCASE and print the content to the console (debug true). WHAT CHANGED IN THE OUTPUT?
    if (params.step == 6) {
        greeting_ch = Channel.of("Hello world!")
        UPPERCASE(greeting_ch)
        PRINTUPPER(UPPERCASE.out)
    }

    
    // Task 7 - based on the paramater "zip" (see at the head of the file), create a process that zips the file created in the UPPERCASE process either in "zip", "gzip" OR "bzip2" format.
    //          Print out the path to the zipped file in the console
    if (params.step == 7) {
        greeting_ch = Channel.of("Hello world!")
        UPPERCASE(greeting_ch)
        COMPRESS(UPPERCASE.out).view()

    }

    // Task 8 - Create a process that zips the file created in the UPPERCASE process in "zip", "gzip" AND "bzip2" format. Print out the paths to the zipped files in the console

    if (params.step == 8) {
        greeting_ch = Channel.of("Hello world!")
        UPPERCASE(greeting_ch)
        COMPRESS_ALL(UPPERCASE.out).collect().view()
    }

    // Task 9 - Create a process that reads in a list of names and titles from a channel and writes them to a file.
    //          Store the file in the "results" directory under the name "names.tsv"

    if (params.step == 9) {
        in_ch = channel.of(
            ['name': 'Harry', 'title': 'student'],
            ['name': 'Ron', 'title': 'student'],
            ['name': 'Hermione', 'title': 'student'],
            ['name': 'Albus', 'title': 'headmaster'],
            ['name': 'Snape', 'title': 'teacher'],
            ['name': 'Hagrid', 'title': 'groundkeeper'],
            ['name': 'Dobby', 'title': 'hero'],
        )

        in_ch
            .flatMap { rec -> "${rec.name}\t${rec.title}\n" }
            .collect()
            .view()
            | WRITETOFILE
    }

}