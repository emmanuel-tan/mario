REFERENCE="./data/smoke-test/chr20.fa.gz"
REFERENCE_INDEX="./data/smoke-test/chr20.fa.index"
READS="./data/smoke-test/H06HDADXX130110.1.ATCACGAT.20k_reads_1.fastq"
OUTPUT="./tests/out.sam"

bwa-mem2 index -p $REFERENCE_INDEX $REFERENCE
bwa-mem2 mem -t 4 $REFERENCE_INDEX $READS > $OUTPUT