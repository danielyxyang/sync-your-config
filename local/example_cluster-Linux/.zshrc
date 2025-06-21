# Source global definitions
if [ -f /etc/profile ]; then
    . /etc/profile
fi

module load stack/.2024-06-silent gcc/12.2.0 python/3.11.6

# ENVIRONMENT VARIABLES

[[ ! "${PATH}" =~ "${SYC_SHARE}/slurm" ]] && {
  export PATH="${SYC_SHARE}/slurm:${PATH}"
}

# ALIAS AND FUNCTIONS

alias squeue-l='squeue -O "JobArrayID:15  ,UserName:15  ,Partition:10  ,Name:15  ,StateCompact:2  ,NumCPUs:.4  ,MinMemory:.7  ,tres-per-job:.16  ,TimeUsed:.10  ,TimeLimit:.10  ,ReasonList"'

