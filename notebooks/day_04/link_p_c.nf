#!/usr/bin/env nextflow

process SPLITLETTERS {
    debug true

    publishDir 'results', mode: 'copy'

    input:
    tuple val(meta), val(names)

    output:
    path "${names.out_name}_block_*.txt"

    script:
    """
    echo "${names.input_str}" > tmp.txt
    fold -w "${meta.block_size}" "tmp.txt" | awk '{ print > "${names.out_name}_block_" NR ".txt" }'
    """
} 

process CONVERTTOUPPER {
    debug true

    publishDir 'results', mode: 'copy'

    input:
    path x

    output:
    stdout

    script:
    """
    cat ${x} | tr '[:lower:]' '[:upper:]'
    """
}

process WRITETOFILE {
    debug true
    publishDir "results", mode: "copy"

    input:
    val block

    output:
    path "chunk_*_upper.txt"

    script:
    """
    printf "%s" "${block}" > 'chunk_${block}_upper.txt'
    """
}


workflow { 
    // 1. Read in the samplesheet (samplesheet_2.csv)  into a channel. The block_size will be the meta-map
    channel.fromPath('samplesheet_2.csv')
        .splitCsv(header:true)
        .map { rec -> meta = [block_size: rec.block_size as Integer]
                     names = [input_str: rec.input_str, out_name: rec.out_name]
                     [meta, names] }
        .set { in_ch }
        // in_ch.view()

    // 2. Create a process that splits the "in_str" into sizes with size block_size. The output will be a file for each block, named with the prefix as seen in the samplesheet_2
    SPLITLETTERS(in_ch)
    // 4. Feed these files into a process that converts the strings to uppercase. The resulting strings should be written to stdout
    SPLITLETTERS.out.flatten()
        | CONVERTTOUPPER


    // read in samplesheet}
    // split the input string into chunks
    // lets remove the metamap to make it easier for us, as we won't need it anymore
    // convert the chunks to uppercase and save the files to the results directory
    WRITETOFILE(CONVERTTOUPPER.out
                              .map { it -> it.strip() })    // remove newlines
        .view{ it -> "Output path: $it" }
    


}