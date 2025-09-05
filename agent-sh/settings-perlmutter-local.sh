
# SETTINGS PERLMUTTER LOCAL SH
# For small login-node debugging runs on Perlmutter

# Software locations on Perlmutter:
SFW=/global/cfs/cdirs/m5071/sfw
EXAEPI=$SFW/ExaEpi-mpich
# MPICH=/global/cfs/cdirs/m3623/wozniak/sfw/mpich-4.3.0
SWIFT=/global/u1/w/wozniak/Public/sfw/Miniconda/312-Swift/swift-t
CONDA=/global/u1/w/wozniak/Public/sfw/Miniconda/312-Swift

# Activate Anaconda for Swift/T
# Turn off error checking for Anaconda:
set +eu
PATH=$CONDA/bin:$PATH
source $CONDA/etc/profile.d/conda.sh
conda activate $CONDA
# Add JVM location for Swift/T:
PATH=$CONDA_PREFIX/lib/jvm:$PATH
# Restore error checking:
set -eu

PATH=$THIS:$SWIFT/stc/bin:$PATH
# :$MPICH/bin
# :$EXAEPI/bin
