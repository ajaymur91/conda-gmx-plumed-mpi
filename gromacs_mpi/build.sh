#!/bin/bash

$PREFIX/bin/plumed-patch -p --runtime -e gromacs-$PKG_VERSION
mkdir build
cd build

## See INSTALL of gromacs distro
for ARCH in SSE2 AVX_256 AVX2_256 AVX_512; do
  cmake_args=(
    -DCMAKE_C_COMPILER=mpicc
    -DCMAKE_CXX_COMPILER=mpicxx
    -DGMX_GPU=OFF
    -DSHARED_LIBS_DEFAULT=ON
    -DBUILD_SHARED_LIBS=ON
    -DGMX_PREFER_STATIC_LIBS=NO
    -DGMX_BUILD_OWN_FFTW=OFF
    -DGMX_DEFAULT_SUFFIX=ON
    -DCMAKE_PREFIX_PATH="${PREFIX}"
    -DGMX_INSTALL_PREFIX="${PREFIX}"
    -DCMAKE_INSTALL_PREFIX="${PREFIX}"
    -DGMX_SIMD="${ARCH}"
    -DCMAKE_INSTALL_BINDIR="bin.${ARCH}"
    -DCMAKE_INSTALL_LIBDIR="lib.${ARCH}"
    -DGMX_MPI=ON
    -DGMX_THREAD_MPI=OFF
  )
  cmake .. "${cmake_args[@]}"
  make -j "${CPU_COUNT}"
  make install
done

gmx='gmx_mpi'

mkdir -p "${PREFIX}/etc/conda/activate.d"
touch "${PREFIX}/bin/${gmx}"
chmod +x "${PREFIX}/bin/${gmx}"

# On Linux, `cat /proc/cpuinfo`
# can have lines that look like
#
# flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 sdbg fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb invpcid_single ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow vnmi flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt xsaveopt xsavec xgetbv1 xsaves dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp pku ospke md_clear flush_l1d arch_capabilities
#
# where only the available features are listed. Either way, we then use
# bash extended pattern matching to find the features we need.
case "$OSTYPE" in
    *)       hardware_info_command="cat /proc/cpuinfo | grep -m1 '^flags'"
             ;;
esac

# Search first for AVX512, then AVX2, then AVX. Fall back on SSE2
{ cat <<EOF
#! /bin/bash
function _gromacs_bin_dir() {
  local arch
  arch='SSE2'
  case \$( ${hardware_info_command} ) in
    *avx512f*)
      test -d "${PREFIX}/bin.AVX_512" && \
        "${PREFIX}/bin.AVX_512/identifyavx512fmaunits" | grep -q '2' && \
        arch='AVX_512'
    ;;
    *\ avx2\ * | *avx2_0*)
      test -d "${PREFIX}/bin.AVX2_256" && \
        arch='AVX2_256'
    ;;
    *\ avx\ * | *avx1_0*)
      test -d "${PREFIX}/bin.AVX_256" && \
        arch='AVX_256'
  esac
  printf '%s' "${PREFIX}/bin.\${arch}"
}
EOF
} | tee "${PREFIX}/bin/${gmx}" > "${PREFIX}/etc/conda/activate.d/gromacs_activate.sh"

cat >> "${PREFIX}/etc/conda/activate.d/gromacs_activate.sh" <<EOF
. "\$( _gromacs_bin_dir )/GMXRC" "\${@}"
EOF

cat >> "${PREFIX}/bin/${gmx}" <<EOF
exec "\$( _gromacs_bin_dir )/${gmx}" "\${@}"
EOF
