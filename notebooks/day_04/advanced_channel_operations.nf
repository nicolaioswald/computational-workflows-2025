params.step = 0


workflow {

    // Task 1 - Read in the samplesheet.

    if (params.step == 1) {
        channel.fromPath('samplesheet.csv')
            .splitCsv(header:true)
            .view()
    }

    // Task 2 - Read in the samplesheet and create a meta-map with all metadata and another list with the filenames ([[metadata_1 : metadata_1, ...], [fastq_1, fastq_2]]).
    //          Set the output to a new channel "in_ch" and view the channel. YOU WILL NEED TO COPY AND PASTE THIS CODE INTO SOME OF THE FOLLOWING TASKS (sorry for that).

    if (params.step == 2) {
        channel.fromPath('samplesheet.csv')
            .splitCsv(header:true)
            .map { rec -> meta = [sample: rec.sample, strandedness: rec.strandedness]
                         files = [rec.fastq_1, rec.fastq_2]
                         [meta, files] }
            .set { in_ch }
        
        in_ch.view()
            
    }

    // Task 3 - Now we assume that we want to handle different "strandedness" values differently. 
    //          Split the channel into the right amount of channels and write them all to stdout so that we can understand which is which.

    if (params.step == 3) {
        channel.fromPath('samplesheet.csv')
            .splitCsv(header:true)
            .map { rec -> meta = [sample: rec.sample, strandedness: rec.strandedness]
                         files = [rec.fastq_1, rec.fastq_2]
                         [meta, files] }
            .set { in_ch }
        
        // in_ch.view()

        in_ch
            .branch { it ->
                auto: it[0].strandedness == 'auto'
                forward: it[0].strandedness == 'forward'
                reverse: it[0].strandedness == 'reverse'
            }
            .set { strandedness_ch }

        strandedness_ch.auto.view { it -> "Auto channel: ${it}" }
        strandedness_ch.forward.view { it -> "Forward channel: ${it}" }
        strandedness_ch.reverse.view { it -> "Reverse channel: ${it}" }
    }

    // Task 4 - Group together all files with the same sample-id and strandedness value.

    if (params.step == 4) {
        channel.fromPath('samplesheet.csv')
            .splitCsv(header:true)
            .map { rec -> meta = [sample: rec.sample, strandedness: rec.strandedness]
                         files = [rec.fastq_1, rec.fastq_2]
                         [meta, files] }
            .set { in_ch }

        in_ch
            .groupTuple(by: 0)
            .view { it -> "Grouped channel: ${it}" }
            .map { meta, lists -> [meta, lists.flatten()] }
            .view()
    }

}